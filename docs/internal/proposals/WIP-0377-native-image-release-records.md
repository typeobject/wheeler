# WIP-0377: Native image release records

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler native, package, security, and release maintainers |
| Created | 2026-08-25 |
| Updated | 2026-08-25 |
| Area | Native release, unsigned PREV, signing, reproducibility |
| Depends on | WIP-0023, WIP-0024, WIP-0026, WIP-0368, WIP-0372, WIP-0374, WIP-0375 |
| Supersedes | Signing fields inside native build identity |
| Superseded by | None |

## Summary

Canonical release records separate reproducible unsigned native output from later platform signing. `UnsignedNativeImageRecord` names one complete adapter-verified image. `NativeImageSigningRecord` names one post-build distribution artifact and its signature evidence without feeding either into the native image plan or unsigned PREV.

This WIP records signing products. It does not sign, trust a signer, verify a cryptographic signature, notarize an Apple artifact, validate an Authenticode certificate chain, or define repository policy. WIP-0024 owns those effects and trust decisions.

## Unsigned output record

The schema-1 unsigned transport is:

```yaml
schema: 1
unsigned-native-image:
  format: "elf"
  target: "x86_64-unknown-linux-gnu"
  plan: "<sha256>"
  platform-abi: "<sha256>"
  capsule: "<sha256>"
  prev: "<sha256>"
  bytes: 4652
```

Construction accepts complete retained native bytes, the exact WIP-0368 plan, and the exact platform ABI. It dispatches to the ELF, Mach-O, or PE verifier. The selected adapter checks layout, permissions, locator, runtime, capsule, plan, ABI, canonical reconstruction, and PREV before the record exists.

The record identity is SHA-256 of its strict canonical UTF-8 transport. `verify` repeats complete adapter verification and requires every field to match. `verifyContent` provides a narrower retained-byte check for a later signing step after the full record has already been established.

Unsigned images remain bounded to 67,108,864 bytes. Record transports remain bounded to 16,384 bytes.

## Signing record

The schema-1 signing transport is:

```yaml
schema: 1
native-image-signing:
  method: "repository-detached"
  unsigned-record: "<sha256>"
  unsigned-prev: "<sha256>"
  distribution-artifact: "<sha256>"
  distribution-bytes: 4652
  signature-evidence: "<sha256>"
  signature-bytes: 64
  signer: "<sha256>"
  signing-tool: "<sha256>"
```

Three methods are closed in schema 1:

| Method | Format | Distribution rule |
| --- | --- | --- |
| `repository-detached` | ELF | Distribution bytes equal the exact unsigned image. Signature evidence is separate. |
| `apple-code-signature` | Mach-O | Distribution bytes differ from the unsigned image. |
| `authenticode` | PE/COFF | Distribution bytes differ from the unsigned image. |

A method for one format cannot sign another format record. Attached signing must change distribution bytes. Detached signing must retain them byte for byte. All methods require nonempty separately identified signature evidence, signer identity, and signing-tool identity.

Distribution artifacts admit at most 75,497,472 bytes. Signature evidence admits at most 1,048,576 bytes. The signing record transport admits at most 16,384 bytes. Record construction consumes retained arrays, stores only content identities and lengths, and exposes no mutable input.

The signing record repeats unsigned PREV for direct audit but also binds the complete unsigned record identity. It does not alter that record, the plan identity, capsule identity, or PREV.

## Physical commands

The image command publishes records only after reading exact bounded nonsymlink files:

```text
wheeler image record-elf <application> --plan <plan.yaml> --abi <abi.yaml> -o <unsigned-record.yaml>
wheeler image record-macho <application> --plan <plan.yaml> --abi <abi.yaml> -o <unsigned-record.yaml>
wheeler image record-pe <application.exe> --plan <plan.yaml> --abi <abi.yaml> -o <unsigned-record.yaml>
wheeler image record-signing <unsigned-record.yaml> --unsigned <application> --method <method> --distribution <artifact> --signature <evidence> --signer <identity> --tool <identity> -o <signing-record.yaml>
```

Output uses the shared atomic physical-leaf boundary. A linked or nonregular output rejects without mutation. No record command invokes a signer, searches for credentials, reads trust policy, or executes native bytes.

## Parsing and rejection

Both parsers accept only strict UTF-8, exact schema and field sets, canonical field order, canonical quoted scalars, lowercase SHA-256 identities, canonical positive decimal lengths, exact reconstruction, and complete consumption.

Reject unknown formats or methods, schema drift, field drift, reordered data, malformed UTF-8, noncanonical decimals, excess bytes, zero lengths, identity drift, wrong method-to-format binding, changed detached distribution bytes, unchanged attached distribution bytes, damaged unsigned input, damaged signature evidence, and any mismatch during retained-input verification.

Parsers do not repair release metadata. A valid hash record remains evidence of bytes, not proof that a signature is valid or trusted.

## Evidence

`NativeImageReleaseRecordTest` builds and independently verifies one complete canonical ELF, derives its unsigned record, round-trips strict transport, and requires repeat verification against exact image, plan, and ABI. Damage to the image rejects.

The fixture constructs a detached repository record over exact unsigned bytes and separate signature evidence. It requires stable record identities, exact unsigned links, and rejection of changed distribution or evidence bytes. Separate Mach-O and PE records prove attached distribution identity and format-specific method rejection.

Malformed schema, unknown methods, extra fields, malformed UTF-8, noncanonical decimals, zero lengths, and oversized transports reject.

`ImageCommandTest` publishes unsigned records for independently built ELF, Mach-O, and PE images. Each record matches direct adapter construction. The ELF case then consumes retained unsigned image and signature-evidence files to publish and reverify one detached signing record.

The canonical ELF output-record identity is:

```text
84a4fb6195bbf6cb7248b2779855c97d4ef57b5d248857357041d45db3106ee4
```

Its detached signing-record identity is:

```text
e00e64063584d4d31bee456bd360cb1a0e779dba3fccf689367ae6074bf3fc94
```

## Acceptance

- [x] Complete unsigned output verification precedes output-record construction.
- [x] Output records bind format, target, plan, ABI, capsule, PREV, and exact length.
- [x] Signing records bind the complete unsigned record and repeat unsigned PREV.
- [x] ELF detached signing retains exact unsigned distribution bytes.
- [x] Mach-O and PE attached signing require changed distribution bytes.
- [x] Signature evidence, signer, and signing tool have separate identities.
- [x] Strict parsers reject malformed, mixed, repaired, or noncanonical records.
- [x] Physical commands publish each output and signing record atomically after complete input checks.
- [x] Signing products do not feed back into build-input identity or unsigned PREV.
- [x] No cryptographic verification, notarization, or trust claim is made.

## Rejected alternatives

### Put signatures in `NativeImagePlan`

Rejected. Nondeterministic signing bytes would feed output back into its own build identity and destroy unsigned reproduction.

### Use signed artifact identity as PREV

Rejected. PREV identifies exact reproducible unsigned bytes. Platform distribution identities form later release edges.

### Treat a signer hash as signature verification

Rejected. Metadata cannot establish cryptographic validity, certificate policy, revocation state, or repository trust.

### Permit one generic signing method

Rejected. Detached ELF evidence and attached Mach-O or PE bytes have different distribution invariants. Schema 1 states them directly.

### Omit the unsigned record identity

Rejected. Repeating PREV alone would lose target, plan, ABI, capsule, and byte-count bindings needed by release audit.

## References

- [WIP-0023](WIP-0023-recipe-repositories-and-reproducible-builds.md)
- [WIP-0024](WIP-0024-system-package-exports.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0368](WIP-0368-platform-abi-and-native-image-identities.md)
- [WIP-0372](WIP-0372-canonical-elf-capsule-images.md)
- [WIP-0374](WIP-0374-canonical-mach-o-capsule-images.md)
- [WIP-0375](WIP-0375-canonical-pe-capsule-images.md)
