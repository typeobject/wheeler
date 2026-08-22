# WIP-0214: Native runner summary publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and conformance maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, report summaries, publication |
| Depends on | WIP-0018, WIP-0198, WIP-0213 |
| Supersedes | Identity-only two-case runner output |
| Superseded by | None |

## Summary

Publish canonical selected, passed, failed, and successful fields beside the native semantic report identity.

`NativeTwoCaseTestRunner.w` now retains each selected raw case identity and terminal status, invokes the WIP-0198 runtime reducer, and publishes one fixed 39-byte product: 32 report-identity bytes followed by the seven-byte summary.

## Summary input

The runner builds the exact WIP-0198 frame after shard selection:

1. two-byte selected count
2. each selected raw 32-byte case identity
3. one status byte, zero for pass and one for fail

Rows retain execution order. `TestSummary.w` independently sorts raw identities, rejects duplicates, and counts statuses. Report identity and summary therefore cross-check the same selected set through separate reducers.

## Output

Bytes 0 through 31 contain the profile-2 report identity. Summary fields follow as little-endian values:

- selected at bytes 32 and 33
- passed at bytes 34 and 35
- failed at bytes 36 and 37
- successful at byte 38

The one-case conformance target retains its historical 32-byte identity output. The 39-byte product belongs to the sharded two-case runner profile.

## Ownership

The runner preserves both raw case identities rather than overwriting one shared digest. It adds one maximum 68-byte summary frame, one seven-byte summary, and one private 32-byte report identity.

The outer region now owns at most 88,373 bytes in 22 allocations. `TestSummary.w` retains its independently bounded radix-reduction region.

## Evidence

`NativeCoverageRunExampleTest` independently appends summary bytes to every expected report identity:

- serial `0/1`: selected two, passed one, failed one, unsuccessful
- shard `1/3`: selected one, passed one, failed zero, successful
- shard `2/3`: selected one, passed zero, failed one, unsuccessful
- shard `0/3`: selected zero, passed zero, failed zero, successful

All four native products match byte for byte. Unselected corrupted artifacts remain unexecuted.

The runtime archive remains 173,870 bytes with SHA-256 `1753fe7a2cd9d3f55e8e8ad67c5283c78db6b729f6cea0a18bd74d061e94002f` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 140,302 bytes with SHA-256 `ceadc1ec25aa6c773b7ed958a36a36fe1742e22e25d3411b60e8d2af3697e9bf`. Its lock retains root manifest identity `8e8fe8757e7729a9399b59b2d7ec53170b8828434e9e0268405a1652c3bf3048` and names the runtime archive exactly.

## Acceptance

- [x] Summary membership matches native shard selection.
- [x] Raw identities and statuses enter the runtime reducer.
- [x] Empty, pass-only, fail-only, and mixed counts are exact.
- [x] Identity and summary publish as one fixed product.
- [x] Conformance archive and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Count booleans directly in the runner

Rejected. WIP-0198 owns duplicate rejection, ordering, and summary semantics.

### Parse the report identity

Rejected. A digest does not expose report membership or status.

### Publish summary before report reduction

Rejected. Both products become visible only after every selected case reduces successfully.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0198](WIP-0198-runtime-test-summary-authority.md)
- [WIP-0213](WIP-0213-native-runner-shard-selection.md)
