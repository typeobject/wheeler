# WIP-0243: Native six-source test compilation

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, package, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Self-hosting, native testing, module compilation |
| Depends on | WIP-0235, WIP-0242 |
| Supersedes | WIP-0242 five-source compiler bound |
| Superseded by | None |
| Follow-up | WIP-0244 native seven-source test compilation |

## Summary

Compile five canonical local imported sources and their manifest-selected root through native source compilation authority.

`TestSourceCompilation.w` raises its accepted source count to six, expands private source storage to 24,576 bytes and six allocations, and invokes `wheeler.compiler.driver::compileMinimalWithFiveConstantImports`. The report runner, artifact verifier, interpreter, profile-2 report, and summary remain unchanged.

## Dispatch

Six fixed branches cover root ordinals zero through five. Each branch removes only the root value from canonical source-plan order. The five remaining source values enter imported arguments in their original order.

Manifest validation selects the root before shard assignment. Source allocation and compilation still happen only for a selected zero-artifact descriptor. Every source retains the 4,096-byte bound and the complete plan retains the 32,768-byte bound.

Compilation authority returns only a nonzero committed artifact length. The runner copies that prefix into exact storage before verification and execution. Recovery capacity never enters artifact identity.

## Evidence

`NativeCompiledTestRunnerExampleTest` adds a fifth constant module at `src/E.w`. The root imports all five modules in canonical module-name order and remains last in source-plan order.

The test independently compiles the six-source set through stage 0, transports that artifact through the canonical runner, and compares its complete 39-byte product with native zero-artifact source mode. Report identity and summary match byte for byte. The focused run retains parity checks for every smaller accepted source count and for assertion failure.

The runtime archive contains 244,431 bytes with SHA-256 `ddd787b2a421ee6e1e8bcc2f36d1df36284fbeb6d403d7b091eae2ce948c5a15` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the new runtime archive exactly.

## Acceptance

- [x] Compilation authority accepts one through six sources.
- [x] Private source storage matches six maximum-size values.
- [x] Root dispatch covers all six ordinals.
- [x] Imported arguments retain source-plan order.
- [x] Dispatch uses the canonical five-import compiler operation.
- [x] Exact artifact-prefix ownership remains unchanged.
- [x] Six-source native and transported products match byte for byte.
- [x] Smaller source-count products remain unchanged.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Move fixed dispatch back into the runner

Rejected. Compiler arity remains an implementation detail of source compilation authority.

### Infer root position from source count

Rejected. Only the validated manifest owns root selection.

### Publish fixed recovery storage

Rejected. Unwritten bytes are not part of a compiler artifact.

### Claim counted source-graph support

Rejected. Six source slots remain a fixed bounded profile.

## References

- [WIP-0235](WIP-0235-native-import-cycle-rejection.md)
- [WIP-0242](WIP-0242-native-five-source-test-compilation.md)
- [WIP-0244](WIP-0244-native-seven-source-test-compilation.md)
