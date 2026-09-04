# WIP-0219: Shared runner manifest identity

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and package maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Native testing, package identity, descriptor framing |
| Depends on | WIP-0018, WIP-0195, WIP-0218 |
| Supersedes | Per-descriptor manifest identity fields |
| Superseded by | None |
| Follow-up | WIP-0220 native manifest hashing |

## Summary

Move the package manifest identity from every descriptor into the package-level runner header.

WIP-0195 defines a case identity from package manifest identity, complete case name, and source identity. The first WIP-0216 frame transported that 32-byte manifest digest once per case under an imprecise declaration-identity name. Every case in one selected package target must share one manifest. Repetition widened the transport and allowed internally inconsistent package runs.

`TestRunner.w` now accepts one raw manifest identity after package name, version, and target. Every case transcript uses its canonical lowercase text. Descriptor rows carry only case name, source, and artifact.

## Frame

The package header contains:

1. shard index and count
2. package name
3. package version
4. target name
5. raw 32-byte package manifest identity
6. descriptor count

Each descriptor contains case name, exact source bytes, and exact artifact bytes. A zero-case run still binds the package manifest identity in its invocation frame, although the profile-2 empty report identity remains runner-only by definition.

## Identity closure

One raw manifest digest is copied into runtime-owned storage before case processing. `writeTestIdentityTextAt` writes the same exact text into each WIP-0195 transcript.

A transport cannot assign different package manifests to sibling cases. Package metadata, source hash, case identity, artifact identity, execution identity, coverage identity, report identity, and summary now form one closed run input.

The runtime does not claim that the raw digest matches a manifest document yet. Native package parsing and lock verification remain the next discovery boundary.

## Bounds

Removing one 32-byte field from every descriptor saves up to 2,016 bytes at the 64-case limit after adding the single header digest. Runtime storage retains one 32-byte raw manifest value rather than allocating and dropping one per descriptor.

The existing 700,000-byte and 32-allocation region remains a conservative closed bound.

## Evidence

`NativeCoverageRunExampleTest` writes one synthetic package manifest digest in the header. Its independent Java transcript feeds that digest into every case identity. Zero-, two-, and three-case reports, all shard profiles, and all failure classes remain byte-identical.

The test mutates the descriptor count at its new post-manifest offset to 65 and proves rejection before publication.

The runtime archive contains 186,463 bytes with SHA-256 `1ae138f62bfc461fb97eee781699f403073e5370db75d99da3cbfe3863987959` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1`. Its lock names the new runtime archive exactly and retains root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`.

## Acceptance

- [x] One package-level manifest identity feeds every case transcript.
- [x] Descriptor rows no longer repeat package identity.
- [x] Stage-0 WIP-0195 case identities remain byte-identical.
- [x] Zero through 64 cases retain complete preflight.
- [x] Documentation names manifest identity consistently.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Keep one manifest identity per descriptor

Rejected. A package run has one locked manifest and must not admit sibling disagreement.

### Derive package identity from name and version

Rejected. Name and version do not bind targets, dependencies, capabilities, or source policy.

### Claim the digest verifies an omitted manifest

Rejected. Framing closes identity use. A later package parser must close identity provenance.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0195](WIP-0195-native-test-case-identity.md)
- [WIP-0218](WIP-0218-bounded-native-descriptor-runner.md)
- [WIP-0220](WIP-0220-native-runner-manifest-hashing.md)
