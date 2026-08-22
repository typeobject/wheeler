# WIP-0215: Native test failure diagnostics

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and conformance maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, diagnostics, execution failures |
| Depends on | WIP-0018, WIP-0203, WIP-0214 |
| Supersedes | Caller-supplied native failure diagnostics |
| Superseded by | None |

## Summary

Move terminal native test diagnostic classification into the runtime artifact reporter.

The old reporter API accepted arbitrary failure code and message buffers from every caller. Both conformance runners supplied `WTEST003` regardless of whether the interpreter rejected the artifact, observed a failed assertion, or exhausted its execution bound. That interface let fixture code decide production semantics.

`TestArtifactReport.w` now classifies the retained `ArtifactOutcome` and artifact itself. Callers supply metadata and receive a complete case row.

## Classification

Failures map in this order:

1. verifier rejection: `WTEST004`, `native artifact verification failed`
2. `EXPECT_EQ` or `EXPECT_TRUE` failure: `WTEST003`, `native test assertion failed`
3. any other bounded interpreter error: `WTEST005`, `native artifact execution failed`

Verification runs before reading the error-site opcode. A rejected artifact therefore cannot turn an unchecked offset into a buffer access. A verified error offset must identify an instruction in the canonical artifact.

Assertion and workflow counts still come from the retained trace. Verification failures contain no assertion step. Runtime-bound exhaustion counts every assertion that completed before termination.

## Interface removal

`writeArtifactCaseResult` and `deriveArtifactReportIdentity` no longer accept diagnostic buffers. `NativeOneCaseTestRunner.w` removes 36 bytes and two allocations from metadata. `NativeTwoCaseTestRunner.w` removes the same duplicated fixture state from staging.

There is no compatibility overload. Native callers cannot override runtime diagnostic policy.

## Evidence

`NativeCoverageRunExampleTest` covers all terminal classes:

- `assert(false)` emits `WTEST003`
- a corrupted archive magic byte emits `WTEST004` with zero assertions
- a verified 5,000-iteration loop exhausts the 4,096-step interpreter bound and emits `WTEST005`

Independent Java transcripts include each diagnostic, assertion count, artifact digest, report identity, and summary. The corrupted artifact also remains harmless when its shard is not selected.

The runtime archive contains 175,011 bytes with SHA-256 `46743bf703f9a3afa4f90baa54b849a69931e3ac5fd87d818c124ed1307b5254` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 139,525 bytes with SHA-256 `099446930ce6276e5f9bd033a2783bfc6dfb466956510f499a845b1dccd580e4`. Its lock names the runtime archive exactly and retains root manifest identity `8e8fe8757e7729a9399b59b2d7ec53170b8828434e9e0268405a1652c3bf3048`.

## Acceptance

- [x] Runtime code owns failure diagnostic classification.
- [x] Verifier, assertion, and interpreter failures have distinct stable diagnostics.
- [x] Invalid artifacts cannot drive unchecked opcode reads.
- [x] Caller-supplied diagnostic parameters are deleted.
- [x] Independent report transcripts cover every failure class.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Keep diagnostic arguments for future adapters

Rejected. The arguments are semantic override hooks, not adapters.

### Treat every interpreter error as an assertion

Rejected. It hides invalid artifacts and execution-bound failures from users.

### Infer verifier failure from an empty trace

Rejected. A valid artifact can fail before a nonzero opcode enters the trace.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0203](WIP-0203-native-test-artifact-outcomes.md)
- [WIP-0214](WIP-0214-native-runner-summary-publication.md)
