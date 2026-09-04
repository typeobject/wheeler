# WIP-0223: Native target source-plan validation

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and package maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Native testing, target sources, canonical framing |
| Depends on | WIP-0009, WIP-0018, WIP-0222 |
| Supersedes | Opaque runner target-source plans |
| Superseded by | None |
| Follow-up | WIP-0224 strict target-source UTF-8 |

## Summary

Validate canonical modular target-source framing before hashing or case execution.

`wheeler.runtime.testing.runners.test_source_plan` checks source count, logical paths, canonical ordering, source lengths, and the exact plan boundary. `TestRunner.w` accepts the source identity only after this validation succeeds.

## Accepted plan

The validator accepts 1 to 64 source entries in the package `TargetSourceSet.canonicalInput` encoding. Each entry contains:

1. four-byte big-endian logical-path length
2. 1 to 255 path bytes
3. four-byte big-endian source length
4. 1 or more source bytes

The complete plan contains at most 32,768 bytes. The declared source count must consume the exact range with no truncation or trailing bytes.

## Logical paths

Paths use ASCII letters, digits, slash, dot, underscore, and hyphen. They must be relative, end in `.w`, contain no empty segment, and contain no `.` or `..` segment.

Entries sort by unsigned path bytes and must be unique. A repeated or descending path rejects before source hashing. Absolute paths and host-specific separators never enter the identity.

Strict UTF-8 source validation and selector-to-manifest matching remain package-layer work. This slice establishes the canonical binary boundary consumed by native identity and scheduling.

## Implementation

The validator borrows the runner input and allocates no storage. One pass retains only the previous path range. Big-endian lengths match stage-0 `DataOutputStream` framing.

The validator bounds work to 64 entries, 255 bytes per path comparison, and 32,768 total plan bytes.

## Failure behavior

Source-plan validation runs after manifest selection but before manifest hashing, source hashing, descriptor identity, shard assignment, artifact verification, or execution. Rejection leaves the complete 39-byte output untouched.

## Evidence

`NativeCoverageRunExampleTest` independently builds a one-entry modular plan for `src/Test.w` with Java `ByteBuffer` big-endian fields. Native and Java SHA-256 identities match through every case and report transcript.

The test changes the declared source count to zero and separately changes the path to an absolute path. Both inputs trap before publication. Existing descriptor-count, manifest, shard, diagnostic, and reduction checks remain intact.

The runtime archive contains 196,698 bytes with SHA-256 `6ec97305548f2dcfa021b4e34978a6fe6487720c69e0ae122051c1b282f0efd7` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1`. Its lock names the new runtime archive exactly and retains root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`.

## Acceptance

- [x] Native code validates exact canonical source-plan framing.
- [x] Source counts and all lengths are bounded.
- [x] Logical paths are relative, normalized, unique, and sorted.
- [x] Truncation and trailing bytes reject.
- [x] Validation allocates no storage and precedes identity derivation.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Hash an unchecked byte blob

Rejected. An identity over malformed framing cannot represent a canonical target source set.

### Sort paths inside the runner

Rejected. Package discovery must supply canonical order. Repairing malformed input would create a second source-selection policy.

### Store all path ranges

Rejected. Comparing each path with its predecessor proves strict canonical order with constant storage.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0222](WIP-0222-native-target-source-identity.md)
- [WIP-0224](WIP-0224-native-target-source-utf8.md)
