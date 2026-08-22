# WIP-0250: Single-pass artifact verification

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler verifier, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, native runtime, test execution |
| Depends on | WIP-0202, WIP-0206, WIP-0217 |
| Supersedes | Reverification during native failure diagnostics |
| Superseded by | None |

## Summary

Verify each selected artifact once, retain the verification outcome, and remove the interpreter entry that silently verified again.

The old path had two verifier authorities:

1. `Interpreter.w::executeArtifact` verified before interpretation.
2. `TestArtifactReport.w` invoked the verifier again to distinguish malformed artifacts from execution failures.

A malformed selected artifact therefore consumed two verifier attempts. The second result was deterministic, but it obscured attempt accounting and blocked validation between verification and execution.

## Runtime boundary

`Interpreter.w` now exports only `executeVerifiedArtifact`. The operation assumes its caller has accepted the exact immutable artifact bytes. The old `executeArtifact` operation is deleted rather than retained as a compatibility alias.

`ArtifactExecution.w::executeBoundedArtifact` owns the test-runtime boundary:

- invoke `verifyArtifact` once
- retain `ArtifactOutcome.verified`
- execute only when verification succeeds
- return a zero-step verifier outcome otherwise

`TestArtifactReport.w` reads the retained Boolean when choosing `WTEST004`. It does not invoke the verifier.

The standalone conformance VM invokes the verifier once and then calls `executeVerifiedArtifact`. It retains its previous fail-closed behavior for malformed input.

## Attempt semantics

Verification failure performs no interpreter transition and writes no trace opcode. Execution failure retains the exact interpreter offset and traced transition count. Assertion and ordinary interpreter diagnostics remain unchanged.

The artifact bytes cannot change between verification and execution because both operations borrow the same immutable `byteview`. No copied or decoded artifact replaces the verified input.

Unselected descriptors still allocate no artifact storage and consume no verifier or interpreter attempt.

## Harness closure

The one-case report fixture previously reused the full native compiler/test-runner module map. Removing an incidental interpreter import exposed hundreds of unreachable compiler modules. The fixture now builds the exact verifier, interpreter, coverage, report, identity, metadata, and SHA-256 closure it executes. The canonical combined source runner still uses the full compiler closure.

## Evidence

The focused artifact suite proves:

- passing and assertion-failing artifacts retain their stage-0 report identities
- malformed artifacts still publish stable `WTEST004` report rows
- metadata and execution identities remain byte-identical
- native coverage retains exact transition products
- the standalone native VM retains bounded artifact behavior
- source-discovered parameterless and parameterized runner products remain unchanged

Source inspection leaves one `verifyArtifact` call in `ArtifactExecution.w`, one explicit call in the standalone `NativeVm.w`, and none in `Interpreter.w` or `TestArtifactReport.w`.

The runtime archive contains 265,348 bytes with SHA-256 `005967bc1565cb14cdbad753477f3429c483ab5c201818d6404b1667cd167400` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 131,107 bytes with SHA-256 `6251649a78a99d521e6828066a677a1ba4cbf47a9f7cf293d9f67fce7b9af575` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the new runtime archive exactly.

## Acceptance

- [x] A selected test artifact consumes one verifier attempt.
- [x] Verification failure performs no interpreter transition.
- [x] `ArtifactOutcome` retains verifier status.
- [x] Failure diagnostics do not reverify.
- [x] The interpreter exposes only a preverified execution operation.
- [x] The standalone VM verifies once before preverified execution.
- [x] Unselected descriptors consume no verifier attempt.
- [x] Existing passing, failing, malformed, metadata, coverage, and identity products remain stable.
- [x] Runtime and conformance archives and the dependent lock are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Keep both interpreter entry points

Rejected. Two similarly named entries would restore ambiguous verifier ownership.

### Reverify only malformed outcomes

Rejected. A diagnostic cannot create another semantic attempt.

### Trust callers without a verifier boundary

Rejected. Each executable publisher must prove acceptance before calling the preverified interpreter.

### Cache decoded verifier state

Rejected. The current verifier publishes acceptance, not a second mutable artifact representation.

## References

- [WIP-0202](WIP-0202-runtime-artifact-execution-authority.md)
- [WIP-0206](WIP-0206-complete-native-artifact-outcomes.md)
- [WIP-0217](WIP-0217-runtime-test-runner-authority.md)
