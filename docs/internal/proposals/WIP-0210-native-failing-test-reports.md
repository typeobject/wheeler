# WIP-0210: Native failing test reports

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and conformance maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Native testing, failure diagnostics, semantic reports |
| Depends on | WIP-0018, WIP-0203, WIP-0209 |
| Supersedes | Pass-only native artifact report composition |
| Superseded by | None |
| Follow-up | WIP-0211 shared multi-case row composition |

## Summary

Reduce a failed native artifact execution into the byte-identical profile-2 semantic report.

`TestArtifactReport.w` replaces the pass-only module. One public operation executes the artifact exactly once, branches on the closed runtime outcome, and builds either the WIP-0209 passing result or a failed result with artifact identity, diagnostic, assertion count, and no execution or coverage identity.

## Failure result

The caller supplies one stable diagnostic code and bounded message as test policy. The runtime operation supplies:

- exact artifact SHA-256
- status `FAIL`
- assertion attempts counted from the retained opcode trace
- zero workflow steps
- empty execution identity
- empty coverage identity

The native interpreter now recovers committed trace length on error by scanning the initialized opcode prefix. Opcode zero is not a canonical instruction. Both bytes are checked, so future opcodes with a zero low byte remain visible.

## Framing and bounds

Failure codes are nonempty and at most 255 bytes. Messages are at most 4,096 bytes. The shared report frame grows to 5,413 bytes and is still allocated at exact measured length.

Pass and failure composition share field, hexadecimal identity, signed scalar, artifact hashing, and report-reduction code. The superseded `TestArtifactPassReport.w` source is deleted.

The conformance runner supplies `WTEST003` and `native test assertion failed` for its assertion fixture. Production runner policy will map other interpreter errors to their accepted codes before package-runner promotion.

## Failure behavior

A failed outcome cannot enter pass composition. A successful outcome cannot enter failure composition. Invalid diagnostics, inconsistent identities, report overflow, or wrong output capacity trap before publication.

## Evidence

`NativeCoverageRunExampleTest` compiles `FailingSubject` through the Wheeler-native compiler. Its only body instruction fails `assert(false)`.

Java independently hashes the exact artifact and complete failed-case transcript: fixed package metadata, `FAIL`, `WTEST003`, the native message, one assertion attempt, zero workflow steps, and empty execution and coverage identities. Wheeler reproduces all 32 final report bytes.

The existing passing fixture still reproduces its prior WIP-0209 identity after the module replacement.

The runtime archive contains 172,992 bytes with SHA-256 `6557e3ad8e8ee30bf7ca2d4da776e7d00d33270881aa383ff24b83a5b6bab3c6`. Its schema-3 lock retains root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 130,629 bytes with SHA-256 `8473ce4db446a8a9ba50d5d1a693892def24972245d6cbd74c57ce6e99e77a3e`. Its lock retains root manifest identity `27cf6ff4e593e9317956ce47c2d1654e8f6f9fa0a640567de03d94302619ab7f` and names the rebuilt runtime archive exactly.

## Acceptance

- [x] Failed execution becomes a canonical profile-2 case.
- [x] Assertion attempts come from the failed execution trace.
- [x] Failure omits execution and coverage identities exactly.
- [x] Pass and failure framing share one runtime module.
- [x] The pass-only source path is deleted.
- [x] Runtime and conformance archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Trap on failed test execution

Rejected. A failed test is semantic report data, not runner failure.

### Publish partial coverage for failure

Rejected. The accepted stage-0 failed result leaves coverage identity empty.

### Retain separate pass and failure frame builders

Rejected. Duplicate case framing would drift at the report boundary.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0203](WIP-0203-native-test-artifact-outcomes.md)
- [WIP-0209](WIP-0209-native-one-case-test-runner.md)
- [WIP-0211](WIP-0211-native-two-case-test-runner.md)
