# WIP-0410: Cryptographic ELF repository authorization

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler package, repository, native, and security maintainers |
| Created | 2026-08-26 |
| Updated | 2026-08-26 |
| Area | Native release, ELF, Ed25519, repository trust |
| Depends on | WIP-0009, WIP-0024, WIP-0377 |
| Supersedes | Opaque detached ELF signature evidence |
| Superseded by | None |

## Summary

Verify detached Ed25519 authorization before publishing a repository signing record for an ELF image. The authorization binds one repository trust domain, complete unsigned native record, unsigned PREV, exact distribution bytes, and trusted public key. The physical command consumes the canonical repository policy and refuses keys outside the selected repository.

Apple code signing and PE Authenticode remain platform-specific attached-signing work. This WIP does not generalize their trust models from ELF evidence.

## Authorization transport

`RepositoryNativeImageSignature` owns one strict schema-1 transport:

```yaml
schema: 1
repository: "<sha256>"
unsigned-record: "<sha256>"
unsigned-prev: "<sha256>"
distribution-artifact: "<sha256>"
key: "<sha256>"
algorithm: "ed25519"
signature: "<canonical-base64>"
```

The message is the ordered concatenation of:

1. `wheeler-native-image-repository-signature-1` plus one zero byte.
2. The 32-byte repository identity.
3. The complete canonical unsigned native image record.
4. The exact unsigned ELF bytes.

The distribution identity equals unsigned PREV because repository-detached signing cannot alter the image. The verifier first runs `UnsignedNativeImageRecord.verifyContent`, then checks every envelope identity, canonical X.509 Ed25519 key identity, and the 64-byte signature.

Authorization transports remain bounded to 16,384 strict-UTF-8 bytes. Parsing requires the exact field set, order, quoting, lowercase identities, algorithm spelling, canonical base64, complete consumption, and byte-for-byte reconstruction.

## Signing record authority

`NativeImageSigningRecord.create` no longer accepts `repository-detached`. Attached Apple and Authenticode metadata continue through that method. Detached ELF records require `createRepositoryDetached`, a parsed authorization, and its public key.

`verify` likewise rejects detached records. `verifyRepositoryDetached` repeats content, repository, key, signature, authorization-transport identity, signing-record identity, length, and signer checks. A caller cannot accidentally treat a hash-only detached record as cryptographic evidence.

The signing record stores the authorization transport identity and byte count as signature evidence. Its signer field is the verified public-key identity. The signing-tool identity remains provenance and grants no authority.

## Repository policy

The physical command is:

```text
wheeler image record-repository-signing <unsigned-record.yaml> \
  --unsigned <application> \
  --policy <wheeler.repositories.yaml> \
  --repository <alias> \
  --signature <authorization.yaml> \
  --tool <identity> \
  -o <signing-record.yaml>
```

The command reads bounded physical nonsymlink files. It parses the schema-2 repository policy, selects one enabled alias, matches the authorization repository identity, and requires the authorization key in that repository's trusted key set. It then verifies the signature and publishes the signing record atomically.

`record-signing` now admits attached Apple and Authenticode methods only. The former generic repository-detached route rejects. There is no public-key-only command that bypasses repository policy.

## Failure boundary

Reject non-ELF input, damaged unsigned bytes, wrong repository, wrong unsigned record or PREV, changed distribution bytes, untrusted or malformed keys, disabled repositories, forged signatures, noncanonical authorization, unsupported algorithms, malformed base64, oversized transports, and generic detached-record construction.

Failure publishes no signing record. Verification does not fetch keys, infer a repository from a path, merge trust domains, accept a lower-priority key, consult a certificate store, or treat signing-tool identity as authorization.

## Evidence

`RepositoryNativeImageSignatureTest` uses the first RFC 8032 Ed25519 key pair. It signs, parses, reconstructs, and verifies one exact ELF distribution. Repository, image, key, signature, schema, and size substitutions reject independently. The canonical authorization identity is:

```text
74b2c461fae281237c764e4e0258606da7579eb9f84091c7a56f5797859a3d45
```

`NativeImageReleaseRecordTest` derives a complete adapter-verified ELF record, creates a cryptographically verified detached signing record, repeats verification, rejects a forged authorization, rejects changed image bytes, and proves the generic detached constructor is closed.

`ImageCommandTest` generates one Ed25519 authorization, installs its key in one enabled physical repository policy, publishes the signing record, and repeats direct verification. The same authorization fails under a policy with no trusted key.

## Acceptance

- [x] Ed25519 signs a domain-separated complete unsigned ELF release.
- [x] Repository, unsigned record, PREV, distribution, and key identities are explicit.
- [x] Exact image verification precedes signature verification.
- [x] Authorization transport is strict, canonical, bounded, and reconstructible.
- [x] Detached signing records require cryptographic verification.
- [x] Generic opaque detached construction and verification reject.
- [x] Physical publication requires one enabled repository and trusted key.
- [x] Untrusted keys publish no record.
- [x] Attached Apple and Authenticode records remain separate and unclaimed.

## Rejected alternatives

### Trust the signer hash field

Rejected. A claimed key identity does not prove possession or authorization.

### Accept a command-line public key without policy

Rejected. Cryptographic validity without repository authorization is not release trust.

### Sign only PREV

Rejected. The complete unsigned record carries target, plan, ABI, capsule, and byte-count authority.

### Copy repository snapshot signatures

Rejected. Native releases use a distinct domain and message shape. Cross-protocol signatures must not verify.

### Treat ELF evidence as Apple or Authenticode validation

Rejected. Attached platform formats have different bytes, certificate policies, and operating-system authorities.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0024](WIP-0024-system-package-exports.md)
- [WIP-0377](WIP-0377-native-image-release-records.md)
