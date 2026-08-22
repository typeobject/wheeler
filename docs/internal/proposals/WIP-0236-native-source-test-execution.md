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
| Superseded by | Native package test descriptor compilation |

## Summary

Compile and execute one bounded Wheeler test source in a single native invocation.

`wheeler.runtime.testing.runners.test_source_execution` invokes the canonical native compiler driver and returns the exact verified artifact length in caller-owned storage. `NativeSourceTestRun.w` copies that committed prefix into exact-size owned storage, invokes runtime artifact execution once, and publishes a fixed outcome.

This is the first test path in which Java supplies source bytes rather than a precompiled artifact. Java launches the VM and checks independent expected bytes. It does not compile the artifact consumed by the native runtime.

## Runtime boundary

`compileTestSource` accepts:

- one nonempty UTF-8 source of at most 4,096 bytes
- one exact 32,768-byte caller-owned artifact buffer

It calls `wheeler.compiler.driver::compileMinimal`, requires a nonempty bounded result, and returns the committed artifact length. The wrapper adds no parser, lowering rule, verifier, or artifact encoder.

The compiler writes into fixed recovery storage. Artifact execution must not consume unused capacity, because trailing zeros are not artifact bytes. The conformance publisher copies exactly `artifactLength` bytes into a second owned buffer before verification and execution.

## Execution

`NativeSourceTestRun.w` allocates fresh compiler artifact, exact executable, and 1,024-byte trace buffers. It calls `executeBoundedArtifact` once and publishes 14 bytes:

```text
u32 artifact_length
u8  passed
u32 executed_steps
u8  global_count
u32 error_offset
```

Integers use little-endian encoding. The publisher sets output length only after compilation and execution complete, then drops every owned buffer and region.

This frame is conformance evidence, not profile-2 report authority. The next package-runner step must feed the compiled artifact into the canonical case/report composition path rather than adding another report format.

## Evidence

`NativeSourceTestRunExampleTest` constructs one combined native compiler and runtime program. It sends passing and assertion-failing module sources as UTF-8 host input.

For each source the test independently compiles stage-0 module bytes and checks the native artifact length. It checks nonzero execution steps, zero globals, pass classification, error presence, and terminal publication. The runtime compiles and executes each source exactly once with fresh storage.

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
