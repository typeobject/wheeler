# WIP-0242: Native five-source test compilation

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, package, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, native testing, module compilation |
| Depends on | WIP-0235, WIP-0241 |
| Supersedes | WIP-0241 four-source compiler bound |
| Superseded by | WIP-0243 native six-source test compilation |

## Summary

Compile four canonical local imported sources and their manifest-selected root through `TestSourceCompilation.w`.

Compilation authority raises its accepted source count from four to five, expands private source storage to 20,480 bytes and five allocations, and dispatches the selected root plus four imported values to `wheeler.compiler.driver::compileMinimalWithFourConstantImports`. The report runner and profile-2 format do not change.

## Dispatch and order

Five fixed branches cover root ordinals zero through four. Each branch removes the root from its plan position and passes every remaining source to imported arguments in ascending source-plan order. Manifest root selection remains independent of path order, module order, and graph inference.

Each source retains the 4,096-byte ceiling. The complete validated plan retains the 32,768-byte ceiling. Compilation happens only after complete authorization and shard selection.

The compiler writes to exact recovery capacity. Compilation authority returns only a nonzero committed length, and the runner copies only that prefix into the artifact consumed by verification and execution.

## Evidence

`NativeCompiledTestRunnerExampleTest` adds a fourth constant module at `src/D.w` and keeps the manifest root last at `src/Test.w`. The root imports all four modules in canonical module-name order.

The test independently compiles all five sources with stage 0. A transported descriptor and a zero-artifact native source descriptor then produce the same complete 39-byte profile-2 identity and summary. Existing one-through-four-source parity remains in the same focused run.

The runtime archive contains 241,938 bytes with SHA-256 `fdedaef11da3bddd7deb8c17d5cff00cae57df11b434d1cb4317e778b9df157d` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the new runtime archive exactly.

## Acceptance

- [x] Compilation authority accepts one through five sources.
- [x] Private source storage matches five maximum-size source values.
- [x] Root dispatch covers every in-range ordinal.
- [x] Imported arguments retain canonical plan order.
- [x] Dispatch uses the canonical four-import compiler operation.
- [x] Exact artifact-prefix ownership remains unchanged.
- [x] Five-source native and transported products match byte for byte.
- [x] Earlier source-count products remain unchanged.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Return source values to the report runner

Rejected. WIP-0240 established compilation authority to keep source lifetime out of report reduction.

### Use path order as root order

Rejected. The manifest selects the root and the source plan only orders transport.

### Publish compiler recovery capacity

Rejected. Unwritten capacity is not artifact data.

### Claim unbounded graph support

Rejected. Five fixed source slots remain a bounded driver profile.

## References

- [WIP-0235](WIP-0235-native-import-cycle-rejection.md)
- [WIP-0241](WIP-0241-native-four-source-test-compilation.md)
- [WIP-0243](WIP-0243-native-six-source-test-compilation.md)
