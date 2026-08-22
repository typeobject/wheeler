# WIP-0236: Native source test execution

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, native testing, source compilation |
| Depends on | WIP-0007, WIP-0018, WIP-0202, WIP-0235 |
| Supersedes | Separate native source-compilation and artifact-execution probes |
| Superseded by | WIP-0237 native compiled test reports |

## Summary

Compile and execute one bounded Wheeler test source in a single native invocation.

The original `wheeler.runtime.testing.runners.test_source_execution` invoked the canonical native compiler driver and returned the exact verified artifact length in caller-owned storage. WIP-0240 removes that wrapper after moving its role into source-plan compilation authority. The original `NativeSourceTestRun.w` cut point copied that committed prefix into exact-size owned storage, invoked runtime artifact execution once, and published a fixed outcome.

This is the first test path in which Java supplies source bytes rather than a precompiled artifact. Java launches the VM and checks independent expected bytes. It does not compile the artifact consumed by the native runtime.

## Runtime boundary

`compileTestSource` accepts:

- one nonempty UTF-8 source of at most 4,096 bytes
- one exact 32,768-byte caller-owned artifact buffer

It calls `wheeler.compiler.driver::compileMinimal`, requires a nonempty bounded result, and returns the committed artifact length. The wrapper adds no parser, lowering rule, verifier, or artifact encoder.

The compiler writes into fixed recovery storage. Artifact execution must not consume unused capacity, because trailing zeros are not artifact bytes. The original conformance publisher copied exactly `artifactLength` bytes into a second owned buffer before verification and execution. WIP-0237 preserves this rule in the canonical test runner.

## Execution

The original `NativeSourceTestRun.w` allocated fresh compiler artifact, exact executable, and 1,024-byte trace buffers. It called `executeBoundedArtifact` once and published 14 bytes:

```text
u32 artifact_length
u8  passed
u32 executed_steps
u8  global_count
u32 error_offset
```

Integers used little-endian encoding. The publisher set output length only after compilation and execution completed, then dropped every owned buffer and region.

This frame was conformance evidence, not profile-2 report authority. WIP-0237 moved the proven boundary into canonical case and report composition, then deleted the fixed frame and publisher.

## Evidence

The original `NativeSourceTestRunExampleTest` constructed one combined native compiler and runtime program. It sent passing and assertion-failing module sources as UTF-8 host input.

For each source the test independently compiled stage-0 module bytes and checked the native artifact length. It checked nonzero execution steps, zero globals, pass classification, error presence, and terminal publication. WIP-0237 replaced this temporary evidence with complete canonical report parity.

The runtime archive contains 229,767 bytes with SHA-256 `562ab741696bd7cc3450ee67deccabacb1051c04487ef0ee08125c59db8b6349` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 133,424 bytes with SHA-256 `a31350bc4dbd68598fa19cf770d6b1294559280b8497fb732c5c99780c6fbd24`. Its lock names the new runtime archive exactly and its expanded manifest has identity `704df5ad8eaf63aeb743af7e24d43f8737cf99daacecf208e71e56fec283f1a9`.

## Acceptance

- [x] Runtime source compilation delegates to the canonical native compiler driver.
- [x] Compiler output stays in caller-owned bounded storage.
- [x] Execution consumes only the committed artifact prefix.
- [x] Passing and assertion-failing sources execute natively.
- [x] Each source gets fresh compiler and interpreter storage.
- [x] Conformance publishes only after terminal execution.
- [x] Java supplies source bytes, not the executed artifact.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Execute the full compiler output capacity

Rejected. Unwritten capacity is not artifact data and must not enter verification.

### Recompile in Java for execution

Rejected. Independent stage-0 compilation may check evidence, but native bytes own the attempt.

### Add a second test report format

Rejected. The fixed frame is a conformance probe. Canonical reporting remains profile 2.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0202](WIP-0202-runtime-artifact-execution-authority.md)
- [WIP-0235](WIP-0235-native-import-cycle-rejection.md)
- [WIP-0237](WIP-0237-native-compiled-test-reports.md)
