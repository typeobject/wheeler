# WIP-0209: Native one-case test runner

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and conformance maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Native testing, semantic reports, runner composition |
| Depends on | WIP-0018, WIP-0020, WIP-0205, WIP-0208 |
| Supersedes | Host composition of one passing native test report |
| Superseded by | None |
| Follow-up | WIP-0210 passing and failing report composition |

## Summary

Execute one bounded classical test artifact and publish its byte-identical profile-2 report identity entirely inside Wheeler.

The superseded `TestArtifactPassReport.w` composed native execution, artifact hashing, execution identity, transition coverage, coverage identity, assertion counting, case framing, and canonical report reduction. `NativeOneCaseTestRunner.w` supplies one fixed conformance case's package metadata and performs only final publication.

This closes the first Wheeler-written runner vertical slice. Discovery, multi-case scheduling, and failing-case diagnostics remain separate WIP-0018 work.

## Pipeline

The runtime operation performs these steps once:

1. execute the verified artifact and retain its bounded opcode trace
2. hash the exact artifact bytes
3. derive the WIP-0208 execution identity from artifact metadata and outcome values
4. derive and reduce WIP-0020 transition fragments
5. derive the WIP-0205 coverage identity over the measured report prefix
6. count successful `EXPECT_TRUE` and `EXPECT_EQ` transitions
7. frame one complete passing case
8. invoke the WIP-0201 canonical report reducer

Only the final 32-byte report identity reaches host output.

## Bounds and ownership

Package name, version, and target are capped at 255 bytes. Runner, case, and source identities are exact lowercase hexadecimal values validated by WIP-0201.

The report frame is measured before allocation and cannot exceed 1,190 bytes. Runner staging owns 101,000 bytes in ten allocations, including trace, coverage fragments, coverage report, three identities, report frame, and transient SHA-256 state. Nested reducers retain their own private regions.

Every allocation is dropped after complete report publication.

## Accepted profile

`BootstrapCoverageFragments.w` supports the admitted passing classical artifact trace. The artifact carries no measurement, quantum job, workflow, or direct output result. Failure diagnostics and wider trace forms remain open.

The conformance executable fixes package `pkg`, version `1`, target `test`, and stable runner, case, and source identities. The reusable runtime operation accepts those values as borrowed inputs and contains no fixture constants.

## Evidence

`NativeCoverageRunExampleTest` compiles `CoverageSubject` through the Wheeler-native module compiler and passes the resulting artifact directly to the Wheeler runner.

Java independently derives artifact SHA-256, the complete stage-0 execution identity, domain-separated coverage identity, successful assertion count, and final profile-2 report transcript. The native runner reproduces all 32 report bytes.

The runtime archive contains 167,971 bytes with SHA-256 `97935fcdf5576c9501f99ee9b4e348a25bbd33a5068218d48a7705161155d12d`. Its schema-3 lock retains root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 130,276 bytes with SHA-256 `e0df1f1f315fa696c906723b4a4c3410a7c48f6b440797abac5c8c7861342e64`. Its lock names root manifest identity `27cf6ff4e593e9317956ce47c2d1654e8f6f9fa0a640567de03d94302619ab7f` and the rebuilt runtime archive exactly.

## Acceptance

- [x] One artifact executes exactly once inside Wheeler.
- [x] Artifact, execution, and coverage identities are composed natively.
- [x] Assertion count comes from the retained native trace.
- [x] The complete passing case frame remains private.
- [x] Final report identity matches an independent stage-0 transcript.
- [x] Runtime and conformance archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Return report components to Java

Rejected. Java would remain the semantic report reducer.

### Hash the full coverage buffer

Rejected. Only the exact measured canonical report prefix enters coverage identity.

### Re-execute for coverage

Rejected. Execution identity, assertions, and coverage must describe one attempt.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0020](WIP-0020-semantic-coverage-and-evidence-accounting.md)
- [WIP-0201](WIP-0201-bounded-native-multi-case-reports.md)
- [WIP-0205](WIP-0205-native-test-coverage-identity.md)
- [WIP-0208](WIP-0208-native-artifact-execution-identity.md)
- [WIP-0210](WIP-0210-native-failing-test-reports.md)
