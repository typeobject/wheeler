# WIP-0251: Native artifact function binding

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, compiler, package, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, native testing, artifact authorization |
| Depends on | WIP-0230, WIP-0249, WIP-0250 |
| Supersedes | Caller-selected transported test function identity |
| Superseded by | Native test artifact source binding |

## Summary

Bind each selected transported test artifact to the manifest-selected root module and native-discovered test declaration before interpretation.

WIP-0249 proved descriptor names against source declarations. It did not prove that the artifact carried the same function. A caller could pair `test::passes` with a valid artifact whose first function belonged to another module. The verifier accepted the artifact as internally sound, and the runner executed it under the source-derived case identity.

The runner now derives the expected artifact function name:

```text
<root-module>::<declaration>
```

For parameter rows, the descriptor's `[<ordinal>]` suffix does not enter the function name. Stage 0 compiles all rows from the same declared function and installs each row value in the synthetic entry.

## Metadata authority

Artifact section projection is general runtime authority, not test-report authority. `TestArtifactMetadata.w` moved to `runtime/ArtifactMetadata.w`, and its module is now `wheeler.runtime.artifact_metadata`.

The module still exposes verified program, kind, global, and string projections. It now also exposes exact function-name ranges and byte comparison. The old module and class names are deleted. Conformance publishers and execution-identity code import the runtime module directly.

## Root and function derivation

`TestSourcePlan.w::validatedSourceStart` exposes a source start only after complete plan validation. `TestSourceModules.w::validatedSourceModuleText` exposes the canonical module-name range from that validated source.

`TestRunner.w` combines:

- the module name from the manifest-selected root source
- `::`
- the native-discovered descriptor suffix after `<target>::`
- no parameter-row ordinal suffix

The result must equal function descriptor zero in the verified artifact. Stage-0 test artifacts place the declared test function at zero and the synthetic test entry after it.

## Execution boundary

`ArtifactExecution.w` verifies the exact immutable bytes once. Only after verification may `ArtifactMetadata.w` project the function table. A mismatched function sets `ArtifactOutcome.authorized` false and performs no interpreter transition.

`TestArtifactReport.w::writeNamedArtifactCaseResult` requires authorization before report construction. Authorization failure traps before any report row or summary publication. Malformed artifacts retain `WTEST004`. Metadata is never projected from verifier-rejected bytes.

Source-compiled entry mode does not use transported function binding. Its artifact comes from the native compiler invocation over the validated source plan. Legacy transported entry artifacts without source test declarations retain the generic verified-artifact profile.

## Sharding

The runner constructs and checks an expected function only after case identity and shard assignment. Unselected descriptors consume no artifact copy, verifier, metadata, or interpreter attempt.

## Evidence

`rejectsArtifactProgramsOutsideTheRootModule` independently compiles `pkg.other::passes`, then supplies that valid artifact beside source declaring `pkg.test::passes` and descriptor `test::passes`.

Descriptor discovery succeeds, artifact verification succeeds, and function authorization fails. The interpreter performs no transition, the runner traps, and all 39 output bytes remain zero.

The positive one-case, counted, parameter-row, and canonical-order fixtures prove exact binding for `pkg.test` artifacts. Generic artifact metadata, execution identity, coverage, malformed diagnostics, and one-case report products remain stable after the module move.

The runtime archive contains 273,249 bytes with SHA-256 `7ad84b2eb00c892e689b358badd4bdbb04502dc184a69eef64622a4a50cd70d1` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 131,094 bytes with SHA-256 `b866164f0216db3c6b2e0662e0c36510863a4324a0481b4a4831b3890c0d5a3b` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the new runtime archive exactly.

## Acceptance

- [x] Runtime artifact metadata owns function-name projection.
- [x] The old test-scoped metadata module is deleted.
- [x] The expected function uses the manifest-selected root module.
- [x] The expected declaration comes from native-discovered descriptor binding.
- [x] Parameter ordinals do not alter the declared function name.
- [x] Verification precedes metadata projection.
- [x] Authorization precedes interpretation and publication.
- [x] Unselected descriptors consume no artifact attempt.
- [x] A valid foreign-module artifact traps with untouched output.
- [x] Positive parameterless and parameterized artifacts retain canonical reports.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Compare the artifact program name

Rejected. Stage-0 program names identify the enclosing class, not the selected test case.

### Compare only the unqualified declaration

Rejected. Two modules may declare the same test name.

### Include the row ordinal in the function name

Rejected. Rows share one declared function and differ in synthetic entry arguments.

### Read function tables before verification

Rejected. Section offsets are untrusted until the verifier accepts the complete artifact.

### Report authorization mismatch as a failed test

Rejected. Source-to-artifact mismatch is malformed transport, not test-body behavior.

## References

- [WIP-0230](WIP-0230-native-root-module-binding.md)
- [WIP-0249](WIP-0249-native-parameter-row-discovery.md)
- [WIP-0250](WIP-0250-single-pass-artifact-verification.md)
