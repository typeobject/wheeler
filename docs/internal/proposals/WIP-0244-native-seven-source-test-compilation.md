# WIP-0244: Native seven-source test compilation

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, package, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, native testing, module compilation |
| Depends on | WIP-0235, WIP-0243 |
| Supersedes | WIP-0243 six-source compiler bound |
| Superseded by | Native eight-source test compilation |

## Summary

Compile six canonical local imported sources and their manifest-selected root through native source compilation authority.

The authority raises its source bound to seven, reserves 28,672 private source bytes and seven allocations, and dispatches to `wheeler.compiler.driver::compileMinimalWithSixConstantImports`. Report reduction remains unaware of source count and compiler arity.

## Dispatch and ownership

Seven fixed branches cover every root ordinal. Each branch removes the root from canonical source-plan order and passes the six remaining values to imported arguments without another sort.

All package, lock, source framing, UTF-8, module, import, cycle, manifest-root, descriptor, and shard checks precede source allocation. Each source remains bounded to 4,096 bytes. Compilation authority freezes each copied frame once, drops all seven values, and returns only a committed artifact length.

The report runner copies that prefix into exact artifact storage. Verification, execution, diagnostics, identities, report reduction, and summary reduction use the same path as transported artifacts.

## Evidence

`NativeCompiledTestRunnerExampleTest` adds a sixth constant module at `src/F.w`. The root imports all six modules in canonical module-name order and remains the seventh source.

A stage-0 artifact descriptor and a zero-artifact native source descriptor produce identical 39-byte profile-2 products. The same focused native closure checks every smaller source count and assertion-failing source behavior.

The runtime archive contains 247,624 bytes with SHA-256 `7fbbf8bceb3112e6f5a7badc11a58406019c6c788154aa58fbf653ef476ec385` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the new runtime archive exactly.

## Acceptance

- [x] Compilation authority accepts one through seven sources.
- [x] Private storage matches seven maximum-size source values.
- [x] Root dispatch covers all seven ordinals.
- [x] Imported arguments retain source-plan order.
- [x] Dispatch uses the canonical six-import compiler operation.
- [x] Exact artifact-prefix ownership remains unchanged.
- [x] Seven-source native and transported products match byte for byte.
- [x] Smaller source-count products remain unchanged.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Let compiler arity enter descriptor framing

Rejected. Source count belongs to the validated source plan, not the case descriptor.

### Reorder imports during dispatch

Rejected. Canonical source-plan order already binds compiler input.

### Reuse report storage for source values

Rejected. Compiler attempt lifetime remains private.

### Claim arbitrary source graphs

Rejected. Seven fixed slots are still a bounded bootstrap profile.

## References

- [WIP-0235](WIP-0235-native-import-cycle-rejection.md)
- [WIP-0243](WIP-0243-native-six-source-test-compilation.md)
