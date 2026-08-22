# WIP-0211: Native two-case test runner

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and conformance maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, multi-case execution, canonical reduction |
| Depends on | WIP-0018, WIP-0201, WIP-0210 |
| Supersedes | One-case-only native runner composition |
| Superseded by | None |

## Summary

Execute two bounded classical artifacts, retain two complete case results, and reduce one arrival-independent profile-2 report inside Wheeler.

`TestArtifactReport.w` now exposes `writeArtifactCaseResult`. The operation executes one artifact and writes a complete counted-report row without hashing a one-case report. `deriveArtifactReportIdentity` wraps that same row operation for the existing one-case API. Pass and failure semantics have one implementation.

`NativeTwoCaseTestRunner.w` consumes two length-prefixed artifacts, executes them in input order, appends both rows, and delegates final ordering and identity to WIP-0201.

## Input and execution

The conformance input contains a four-byte little-endian artifact length, the first artifact, a second length, and the second artifact. Each artifact is capped at 32,768 bytes. The complete input must end with the second artifact.

The first artifact passes and carries case identity four. The second artifact fails and carries case identity two. Physical completion order is therefore the reverse of semantic report order.

Each artifact executes once in fresh runtime storage. The runner retains no machine state between cases.

## Case-row boundary

A case row contains package, version, target, case and source identities, artifact identity, diagnostics, execution and coverage identities, status, assertion count, and workflow steps. Its fixed caller buffer is 5,345 bytes. The operation returns the exact active prefix.

Passing rows own execution and coverage composition. Failing rows own diagnostics and leave those identities empty. The one-case and two-case runners both consume this boundary.

## Ownership

The two-case conformance runner owns at most 88,000 bytes in 15 allocations: two copied artifacts, ten metadata values, two case buffers, and one exact final frame.

Runtime case execution retains its existing private trace and reducer storage. Final report publication occurs only after both rows and canonical reduction succeed.

## Evidence

`NativeCoverageRunExampleTest` supplies a passing `CoverageSubject` first and failing `FailingSubject` second. Java independently hashes the report in canonical case-identity order: failure identity two, then pass identity four.

The native report matches all 32 bytes despite opposite physical order. Truncating the second artifact rejects before execution and leaves every output byte untouched. Existing one-case pass and failure identities remain unchanged after the row refactor.

The runtime archive contains 172,888 bytes with SHA-256 `0e1ad90b5ac06875e8c3d83224ab20666c1bb76ed97c6cfb969885b711eefaff`. Its schema-3 lock retains root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 136,368 bytes with SHA-256 `eb3fdf592f39a35bd8eee4ffef49a609f15f1dca111cfbc52b97dd31bf7b4b62`. Its lock names root manifest identity `8e8fe8757e7729a9399b59b2d7ec53170b8828434e9e0268405a1652c3bf3048` and the rebuilt runtime archive exactly.

## Acceptance

- [x] Two fresh artifact executions produce two complete case rows.
- [x] Physical order differs from canonical report order.
- [x] WIP-0201 performs final ordering and report hashing.
- [x] One-case and multi-case paths share case construction.
- [x] Truncated input rejects before publication.
- [x] Runtime and conformance archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Combine one-case report identities

Rejected. A report identity is not a mergeable case representation.

### Duplicate case framing in the two-case runner

Rejected. Pass and failure semantics belong to one runtime row operation.

### Preserve input order

Rejected. Worker or transport order cannot enter semantic identity.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0201](WIP-0201-bounded-native-multi-case-reports.md)
- [WIP-0210](WIP-0210-native-failing-test-reports.md)
