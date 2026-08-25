# WIP-0369: Canonical application capsules

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler package, bytecode, runtime, native, security, and release maintainers |
| Created | 2026-08-24 |
| Updated | 2026-08-24 |
| Area | Native bootstrap, application capsules, package receipts, immutable resources |
| Depends on | WIP-0009, WIP-0022, WIP-0023, WIP-0026, WIP-0368 |
| Supersedes | Unframed executable payload bundles |
| Superseded by | None |

## Summary

Fix schema 1 of the format-neutral application capsule embedded in native Wheeler images.

A capsule binds one package target and entry function to exact runtime, bytecode, proof, target, platform, and limit profiles. It carries a closed package-receipt set and one sorted immutable entry table over WBC, resources, proofs, native providers, and provenance. Every entry is uncompressed and content-addressed. The complete canonical byte string is the capsule identity.

This WIP accepts the capsule, root, entry, and package-receipt schemas. It does not accept a native segment locator, execute WBC, validate WBC internals, or publish an executable image.

## Framing

All integers are unsigned little-endian values. Parsers reject values that do not fit the implementation's bounded signed index space.

| Offset | Width | Field |
| ---: | ---: | --- |
| 0 | 8 | `WHLCAP\0\1` magic and schema |
| 8 | 4 | Complete capsule bytes |
| 12 | 4 | First payload offset and exact metadata bytes |
| 16 | 4 | Package receipt count |
| 20 | 4 | Entry count |
| 24 | 8 | Zero reserved field |

The root record follows the 32-byte header. It contains, in order:

1. root package-instance identity.
2. target, root-WBC logical name, and qualified entry function.
3. runtime, bytecode, proof, target, platform-ABI, and execution-limit identities.
4. embedded-VM or AOT mode.
5. a sorted distinct required-capability list.

Every identity is a 32-byte SHA-256 value. Text is a two-byte length followed by strict UTF-8. Text fields admit at most 256 bytes. Logical entry names are relative package paths without empty, dot, parent, backslash, NUL, leading-slash, or trailing-slash components.

Package receipts and entry descriptors follow the header. Zero alignment padding and entry payloads follow the metadata. Parsers require exact consumption. Schema 1 has no trailer.

## Package receipts

A package receipt records:

```text
repository snapshot
package coordinate
RREV
variant
build-input identity
PREV
selected export
package-instance identity
```

Snapshot, RREV, build input, PREV, and instance fields are SHA-256 identities. The package coordinate includes one exact version. Variant and selected-export names are canonical tokens.

Receipts sort by coordinate, variant, and package-instance identity. Package-instance identities are unique. Exactly one receipt must match both the root package instance and selected root target. Receipts are runtime evidence. They cannot trigger package resolution, repository access, or fallback lookup.

## Entry descriptors

An entry descriptor contains:

| Width | Field |
| ---: | --- |
| 1 | Kind |
| 1 | Flags |
| 2 | Zero reserved field |
| 4 | Power-of-two alignment |
| 4 | Absolute payload offset |
| 4 | Payload bytes |
| 2 + name | Strict-UTF-8 logical name |
| 32 | SHA-256 payload identity |

Schema 1 fixes these kinds in order:

| Code | Kind |
| ---: | --- |
| 0 | WBC |
| 1 | Immutable resource |
| 2 | Proof data |
| 3 | Native provider data |
| 4 | Provenance data |

Bit 0 means required. Bit 1 marks the sole startup WBC. Unknown flag bits reject. Startup on a non-WBC entry rejects. Exactly one entry must match the root WBC name and carry the startup bit. All logical names are unique across kinds, which keeps audit extraction from creating kind-dependent path collisions.

Entries sort by kind code, unsigned UTF-8 name bytes, and content identity. Offsets are absolute from the first header byte. Each payload starts at its declared alignment. Padding is zero. Schema 1 performs no compression, deduplication, sparse storage, external reference, encryption, or signature wrapping.

## Bounds

| Item | Bound |
| --- | ---: |
| Complete capsule | 33,554,432 bytes |
| Metadata | 1,048,576 bytes |
| Entries | 128 |
| Package receipts | 64 |
| Required capabilities | 32 |
| One entry | 16,777,216 bytes |
| Text field | 256 UTF-8 bytes |
| Entry alignment | 65,536 bytes |

The root WBC is nonempty. Other entry kinds may carry an empty content object with the ordinary SHA-256 identity. Construction fails before allocating a capsule beyond the complete bound. Parsing checks transport bounds before copying entry payloads.

## Identity and verification

```text
capsule_id = sha256(canonical_capsule_bytes)
```

The identity is not stored inside the capsule. Doing so would create a self-hash cycle. WIP-0368 stores the resulting identity in the native image plan. The unsigned native image later receives its own PREV.

`ApplicationCapsule.parse` verifies magic, complete length, metadata length, counts, reserved fields, strict UTF-8, hashes, root bindings, kinds, flags, alignments, ranges, ordering, padding, and trailing-byte absence. It reconstructs the object and requires byte-for-byte equality with canonical encoding. This rejects reordered, overlapping, repaired, over-aligned, under-aligned, or malleable transports rather than normalizing them.

Returned entry arrays are owned copies. Mutating caller input or a returned array cannot change a capsule or identity.

The maintained three-entry fixture has 717 metadata bytes and 4,176 complete bytes. Its identity is:

```text
393cbf9eb8c023ee47302b5f932a9c5ac2d63b02b2dc19c0e1983639e84b5dd7
```

Its root WBC begins on a 4,096-byte boundary. The resource begins on a 64-byte boundary. Reversing construction order produces the same bytes.

## Failure boundary

Reject bad magic, lengths, counts, reserved bits, unknown kinds or flags, malformed UTF-8, invalid paths, duplicate names or instances, absent or ambiguous roots, digest mismatch, range escape, overlap, nonzero padding, unsupported alignment, excess metadata, excess payload, and trailing bytes.

Capsule verification does not establish that a WBC is well-formed, that proof data proves anything, that a provider matches the platform ABI, or that a native segment is read-only and nonexecutable. The bytecode verifier, proof checker, provider verifier, and native image adapter retain those jobs. Startup must complete all four checks before calling the root.

## Evidence

`ApplicationCapsuleTest` fixes the canonical fixture bytes, lengths, identity, root, receipts, ordering, and alignments. It mutates header, reserved space, UTF-8, padding, entry bytes, startup flags, and trailing bytes independently. It checks identity sensitivity for runtime mode, package PREV, and resource content.

The same suite admits exactly 128 entries and 64 package receipts, round-trips that terminal profile, and rejects entry 129 and receipt 65. It also rejects duplicate paths and package instances, missing roots, parent paths, unpaired Unicode surrogates, non-power-of-two alignment, startup resources, and unordered capabilities.

`ApplicationCapsuleExampleTest` builds one root WBC and immutable resource, verifies the capsule without adjacent files, binds its computed identity into a native image plan, and executes the no-authority root through WIP-0371 startup.

## Acceptance

- [x] The capsule header has fixed magic, schema, lengths, counts, and reserved bytes.
- [x] Root semantics and all profile identities enter canonical bytes.
- [x] Package receipts bind repository, package, build, output, export, and instance evidence.
- [x] Entries bind kind, name, identity, offset, length, alignment, flags, and bytes.
- [x] Ordering, zero padding, exact consumption, and SHA-256 identities are canonical.
- [x] Limits are explicit and exact terminal entry and receipt profiles pass.
- [x] Malformed, corrupted, ambiguous, reordered, padded, and trailing transports fail closed.
- [x] Inputs and returned payloads cannot mutate retained capsule state.

## Rejected alternatives

### Canonical YAML around raw files

Rejected. Native startup needs one bounded table with direct checked ranges and no second filename namespace. YAML remains suitable for build plans and receipts outside the image.

### Put the capsule identity in its header

Rejected. A direct whole-byte identity cannot include itself. The image plan binds the external digest.

### Compress schema 1

Rejected. A compression profile adds tool identity, bombs, scratch memory, and canonicalization work before the first startup path exists. A successor may add one versioned deterministic codec with independent bounds.

### Permit one logical name per kind

Rejected. Audit extraction and human inspection need one path authority. Kind-sensitive collisions are needless ambiguity.

### Validate WBC while decoding framing

Rejected. Framing owns byte integrity. The bytecode verifier owns executable semantics and runs after the complete capsule transport passes.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0022](WIP-0022-package-instances-and-resolution.md)
- [WIP-0023](WIP-0023-recipe-repositories-and-reproducible-builds.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0368](WIP-0368-platform-abi-and-native-image-identities.md)
- [WIP-0370](WIP-0370-application-capsule-inspection.md)
- [WIP-0371](WIP-0371-embedded-application-capsule-startup.md)
