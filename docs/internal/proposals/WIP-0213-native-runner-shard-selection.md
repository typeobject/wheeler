# WIP-0213: Native runner shard selection

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and conformance maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, shard selection, execution scheduling |
| Depends on | WIP-0018, WIP-0197, WIP-0212 |
| Supersedes | Unconditional two-case native execution |
| Superseded by | WIP-0214 identity and summary publication |

## Summary

Apply runtime-owned deterministic shard selection before native case execution.

`NativeTwoCaseTestRunner.w` now accepts a shard index and count, frames each WIP-0212 identity for `assignedToShard`, and executes only selected artifacts. Zero, one, or two selected rows enter the same canonical report reducer.

## Input

The runner frame begins with two-byte little-endian shard index and shard count. Two length-prefixed artifacts follow. Complete framing is validated before identity derivation or execution.

WIP-0197 validates nonzero count, index range, lowercase identity text, and full-digest modular assignment. The runner does not reproduce digest arithmetic.

## Scheduling

Both case identities derive before selection. Each identity is copied into one reused 68-byte shard frame. Index and count remain fixed for the invocation.

An unselected artifact is never verified or executed. Its bytes remain transport data needed only to advance the bounded frame. Selected cases still receive fresh machine storage.

The profile admits:

- shard `0/1`: both cases
- shard `1/3`: passing case only
- shard `2/3`: failing case only
- shard `0/3`: no cases

Each selected set produces the exact profile-2 report for that set.

## Ownership

The runner adds one shard frame to WIP-0212 staging. Its bound is 88,234 bytes in 18 allocations. Case result buffers remain fixed because selection changes active length, not worst-case capacity.

## Evidence

`NativeCoverageRunExampleTest` independently computes the case identities and shard assignments. Serial execution retains the reverse-order two-case report.

The test corrupts the unselected failing artifact on shard `1/3`. The passing report still succeeds. Shard `2/3` emits only the failed result. Shard `0/3` accepts two corrupted, unselected artifacts and emits the canonical empty report. These fixtures prove selection precedes artifact verification and execution.

Truncated transport still rejects before any selected execution or publication.

The runtime archive remains 173,870 bytes with SHA-256 `1753fe7a2cd9d3f55e8e8ad67c5283c78db6b729f6cea0a18bd74d061e94002f` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 138,633 bytes with SHA-256 `4f83c2d3c2624834e72b5640e14b0fbc8abfe26960aec5278598786cb5338dea`. Its lock retains root manifest identity `8e8fe8757e7729a9399b59b2d7ec53170b8828434e9e0268405a1652c3bf3048` and names the runtime archive exactly.

## Acceptance

- [x] Runtime shard semantics select native cases.
- [x] Unselected artifacts are not verified or executed.
- [x] Empty, passing-only, failing-only, and complete reports match stage 0.
- [x] Selected cases retain fresh execution storage.
- [x] Malformed transport rejects before publication.
- [x] Runtime and conformance archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Execute then discard unselected results

Rejected. Shards bound work as well as report membership.

### Assign shards from source identity

Rejected. WIP-0018 assigns the complete case identity digest.

### Let Java filter artifact inputs

Rejected. Host filtering would remain discovery and scheduling authority.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0197](WIP-0197-runtime-test-selection-authority.md)
- [WIP-0212](WIP-0212-native-runner-case-identities.md)
- [WIP-0214](WIP-0214-native-runner-summary-publication.md)
