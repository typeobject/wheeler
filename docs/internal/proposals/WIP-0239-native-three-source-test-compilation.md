# WIP-0239: Native three-source test compilation

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, package, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, native testing, module compilation |
| Depends on | WIP-0235, WIP-0238 |
| Supersedes | WIP-0238 two-source compilation bound |
| Superseded by | WIP-0240 native source compilation authority |

## Summary

Compile two canonical local imported sources and their manifest-selected root inside the native test runner.

The runner extends source-mode dispatch from two source frames to three. It projects all three validated frames in canonical path order, freezes each exact UTF-8 value, and places the manifest-selected root in the root argument of the canonical compiler driver. The two remaining values retain source-plan order as imported arguments.

The compiled artifact enters the existing exact-prefix verifier, interpreter, case composition, profile-2 report, and summary path. Transported artifacts remain unchanged.

## Bounds

A zero-artifact descriptor still requires one case. Its source plan may now contain one, two, or three sources. Every source remains bounded to 4,096 bytes and the complete source plan remains bounded to 32,768 bytes.

The runner validates all source lengths before shard selection. It allocates source bytes only for a selected descriptor. Three-source dispatch adds no dynamic collection and no collision authority.

This WIP covers two imported slots because `wheeler.compiler.driver::compileMinimalWithConstantImports` is already a canonical, closure-tested operation. Larger fixed driver arities and counted graph compilation remain separate changes.

## Dispatch

For three sources the runner allocates source zero, one, and two by validated ordinal. It then freezes all three buffers and dispatches by `compiledRootOrdinal`:

- root 0 receives imported sources 1 and 2
- root 1 receives imported sources 0 and 2
- root 2 receives imported sources 0 and 1

The runner uses independent exhaustive equality checks rather than an unsupported `else if` form. Complete manifest validation proves the root ordinal is in range before dispatch.

The original `compileTwoImportedTestSources` wrapper validated all three source bounds, required exact artifact recovery capacity, delegated to `compileMinimalWithConstantImports`, and returned only a nonempty committed artifact length. WIP-0240 folds that dispatch into one source-plan compilation authority.

## Atomicity

Descriptor framing, source framing, UTF-8, module declarations, module uniqueness, local import resolution, import order, acyclicity, manifest selection, lock provenance, and shard assignment precede compilation.

The compiler writes into private 32,768-byte recovery storage. The runner copies exactly the returned artifact length into fresh storage. Verifier, interpreter, diagnostics, identities, report reduction, and summary reduction consume that exact value. Any compiler or execution trap leaves the 39-byte publisher output untouched.

## Evidence

`NativeCompiledTestRunnerExampleTest` adds two canonical constant modules and a root that imports both. Paths order imported source A, imported source B, then root source. The manifest selects the third source explicitly.

The test independently compiles all three modules with stage 0 and sends those artifact bytes through the transported descriptor path. It then sends the same manifest, lock, source plan, and case name with a zero artifact length. The complete 39-byte native products match byte for byte.

The same test program retains passing, failing, and one-import parity. This checks that wider dispatch does not change established source or transported-artifact semantics.

The runtime archive contains 241,043 bytes with SHA-256 `8a326371108580652511a4b47d06b15866ba4e4426c8a411479e4be6428011ef` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the new runtime archive exactly.

## Acceptance

- [x] Source mode accepts at most three validated sources.
- [x] Every source keeps the 4,096-byte bound.
- [x] The manifest-selected root may occupy any source ordinal.
- [x] Imported arguments retain canonical source-plan order.
- [x] Compilation delegates to the canonical two-import driver operation.
- [x] Only the committed artifact prefix reaches verification and execution.
- [x] Three-source native and transported products match byte for byte.
- [x] One- and two-source report parity remains unchanged.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Infer the root from the last source

Rejected. The test exercises that order, but dispatch follows the manifest ordinal and handles all three positions.

### Sort imported modules again

Rejected. The validated source plan already owns canonical path order.

### Add a mutable source vector

Rejected. Three fixed bounded slots are sufficient for this driver arity and avoid a second collection implementation.

### Jump directly to counted closure compilation

Rejected. The counted compiler path needs a package graph input and larger resource proof. Fixed arities remain useful verified stepping stones.

## References

- [WIP-0235](WIP-0235-native-import-cycle-rejection.md)
- [WIP-0238](WIP-0238-native-two-source-test-compilation.md)
- [WIP-0240](WIP-0240-native-source-compilation-authority.md)
