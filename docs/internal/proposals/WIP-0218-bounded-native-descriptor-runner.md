# WIP-0218: Bounded native descriptor runner

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and conformance maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, bounded scheduling, report composition |
| Depends on | WIP-0018, WIP-0201, WIP-0217 |
| Supersedes | Fixed two-case runtime runner |
| Superseded by | None |

## Summary

Replace the fixed two-case runtime scheduler with one counted descriptor runner for zero through 64 cases.

`wheeler.runtime.testing.runners.test_runner` preflights the complete descriptor transport, derives identities, applies shard selection, executes each selected artifact once, and feeds the selected rows into the existing profile-2 report and summary reducers. The fixed `TwoCaseTestRunner.w` implementation and two-case conformance target names are deleted.

## Frame

The frame carries WIP-0216 package metadata, a one-byte descriptor count, and exactly that many descriptor records. Counts above 64 reject before descriptor execution. A zero count is valid and produces the canonical empty identity and successful zero summary.

The preflight pass checks every name, source, and artifact boundary and requires the final descriptor to end at the input boundary. Execution starts only after the complete frame passes.

## Scheduling

The execution pass handles descriptors in transport order. Each case receives:

- its transported declaration identity and name
- a native SHA-256 source identity
- a native case identity
- full-digest shard assignment
- a fresh artifact execution region when selected

Unselected artifact bytes remain borrowed and are neither copied nor verified. Selected result rows are retained in arrival order. `TestReportIdentity.w` and `TestSummary.w` independently sort and reject duplicate identities.

The runner reads terminal status back from the complete canonical case row. It does not execute an artifact twice to obtain summary data.

## Bounds

The runner admits at most 64 descriptors. Each source and artifact remains bounded at 32,768 bytes. Report rows occupy at most 342,080 bytes. Raw summary identities occupy 2,048 bytes and statuses occupy 64 bytes.

The outer region owns 700,000 bytes in 32 allocations. One selected artifact and one case result are live at a time. Input sources and unselected artifacts remain borrowed. The report and summary reducers retain their own closed regions.

## Publication

The conformance target is now `nativetestrunner` in module `wheeler.conformance.testing.runners.native_test_runner`. It publishes the 39-byte product returned by `runTests` and owns no scheduling semantics.

## Evidence

`NativeCoverageRunExampleTest` covers:

- zero descriptors
- two descriptors with pass and assertion failure
- three descriptors with pass, assertion failure, and interpreter-bound failure
- shards selecting zero or one descriptor
- verifier rejection
- complete-frame truncation
- empty package metadata
- a declared count of 65

Independent Java transcripts sort all three semantic rows and reproduce the report identity and summary byte for byte.

The runtime archive contains 186,423 bytes with SHA-256 `fa1fd95edbca4f91b0eb9008d628f064d4613fb44e988d0cdaed698259ac4367` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1`. Its lock names the runtime archive exactly and retains root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2` after the target rename.

## Acceptance

- [x] One runtime operation handles zero through 64 descriptors.
- [x] Complete transport preflight precedes all execution.
- [x] Selected artifacts execute exactly once with fresh storage.
- [x] Report and summary reduction consume every selected row.
- [x] Zero-, two-, and three-case products match independent transcripts.
- [x] Fixed two-case runtime and conformance names are deleted.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Add separate runners for each count

Rejected. Count is data, not a semantic profile.

### Execute again to derive summary status

Rejected. Report identity and summary must describe the same retained attempt.

### Allocate every artifact simultaneously

Rejected. Active execution needs one artifact buffer. Input transport already owns the remaining bytes.

### Publish partial rows while scanning

Rejected. Malformed trailing descriptors must reject before any product becomes visible.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0201](WIP-0201-bounded-native-multi-case-reports.md)
- [WIP-0217](WIP-0217-runtime-test-runner-authority.md)
