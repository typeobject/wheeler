# WIP-0237: Native compiled test reports

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Self-hosting, native testing, report authority |
| Depends on | WIP-0018, WIP-0217, WIP-0235, WIP-0236 |
| Supersedes | WIP-0236 fixed source-execution conformance frame |
| Superseded by | None |
| Follow-up | WIP-0238 native two-source test compilation |

## Summary

Compile a validated package source inside the canonical native test runner and feed the resulting artifact into the existing profile-2 report path.

A zero artifact length now selects source compilation. The marker is valid only for a single descriptor over a one-source target plan. Nonzero lengths retain transported-artifact behavior without report changes.

The runtime validates the complete descriptor transport, source plan, source module, import graph, manifest, lock, and shard assignment before compilation. It copies only the committed compiler output prefix into exact owned storage, executes once, and composes the same case row, report identity, summary, diagnostics, execution identity, coverage identity, and artifact identity used for transported artifacts.

## Descriptor rule

Each case descriptor remains:

```text
u8  case_name_length
byte case_name[case_name_length]
u32 artifact_length
byte artifact[artifact_length]
```

`artifact_length == 0` means compile the selected source. It does not mean an empty artifact.

The source mode requires `case_count == 1`. After complete plan validation, the runner requires exactly one source and at most 4,096 source bytes. Multi-source compilation needs graph compiler selection and belongs in a separate WIP.

The preflight scan sees every descriptor and rejects a source marker in a multi-case transport before package validation, compilation, execution, or publication.

## Source extraction

`TestSourcePlan.w` owns extraction from its validated frame. `validatedSingleSourceLength` and `copyValidatedSingleSource` accept only a plan which has already passed `validTargetSourcePlan`. They assert the one-source count and preserve the exact source bytes. They do not parse modules or repair text.

The original runner froze copied bytes as UTF-8 only after strict UTF-8 and module validation. WIP-0240 moves that ownership into `compileValidatedSourcePlan`, which delegates to the matching canonical compiler driver operation and returns its committed artifact length.

## Artifact ownership

Both descriptor modes stage bytes into an exact 32,768-byte recovery buffer. The runner then allocates an exact `executionArtifactLength` buffer and copies the committed prefix.

The verifier and interpreter never observe unused compiler capacity. The temporary source, compiler output, exact artifact, trace, case result, and report storage remain attempt-owned and are dropped before terminal return.

## Canonical parity

`NativeCompiledTestRunnerExampleTest` runs passing and assertion-failing source through two paths:

1. a zero-length descriptor compiled by the native runner
2. an independently stage-0-compiled nonempty artifact descriptor

Both paths carry the same validated manifest, lock, source plan, case name, source identity, and runner identity. Their complete 39-byte report identity and summary products must match byte for byte. Matching products cover artifact identity, diagnostics, assertion count, execution identity, coverage identity, status, and summary reduction.

Java constructs transport bytes, launches the VM, and compiles independent expected artifacts. It does not provide the artifact consumed by source mode.

## Legacy removal

The fixed 14-byte `NativeSourceTestRun` conformance probe and its dedicated Java test are removed. They established the compiler-to-interpreter boundary in WIP-0236 but carried a private result format. The canonical runner now owns that path, so retaining the probe would preserve a second reporting interface without semantic value.

`NativeTestRunnerProgram.java` centralizes the combined compiler/runtime closure used by report examples. Coverage tests no longer duplicate that source graph.

The runtime archive contains 232,364 bytes with SHA-256 `869559574150055e26d5cf716829839305f9aaf4da857787562ccb701cb8fe9c` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

Removing the temporary conformance target restores the 131,032-byte conformance archive with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the new runtime archive exactly.

## Acceptance

- [x] Zero artifact length selects native source compilation unambiguously.
- [x] Complete transport validation precedes compilation.
- [x] Manifest, lock, source plan, module, import, and shard checks precede compilation.
- [x] Source mode is bounded to one case and one source.
- [x] Unselected source descriptors are not compiled or executed.
- [x] Execution consumes only the exact committed artifact prefix.
- [x] Passing compiled source matches transported-artifact report bytes.
- [x] Failing compiled source matches transported-artifact diagnostics and report bytes.
- [x] The private fixed source-execution result format is deleted.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Keep zero length as an empty artifact

Rejected. Empty bytes cannot form a verified Wheeler artifact. The value is available as an explicit source-compilation marker.

### Publish the fixed WIP-0236 frame beside profile 2

Rejected. Two reporting paths would split status, diagnostic, identity, and reduction authority.

### Compile before shard selection

Rejected. Unselected cases must consume no compiler, verifier, or interpreter attempt.

### Claim multi-source support

Rejected. The minimal compiler operation accepts one source. Import graph compilation requires a separate bounded graph contract.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0217](WIP-0217-runtime-test-runner-authority.md)
- [WIP-0235](WIP-0235-native-import-cycle-rejection.md)
- [WIP-0236](WIP-0236-native-source-test-execution.md)
- [WIP-0238](WIP-0238-native-two-source-test-compilation.md)
