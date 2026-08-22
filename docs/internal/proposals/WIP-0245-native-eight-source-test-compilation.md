# WIP-0245: Native eight-source test compilation

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, package, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, native testing, module compilation |
| Depends on | WIP-0235, WIP-0244 |
| Supersedes | WIP-0244 seven-source compiler bound |
| Superseded by | Counted native source-graph compilation |

## Summary

Complete the public fixed-arity native compiler profile in the canonical test runner.

`TestSourceCompilation.w` now accepts one root and up to seven canonical local imported sources. It reserves 32,768 private source bytes and eight allocations, selects the root by validated manifest ordinal, preserves source-plan order for imported arguments, and dispatches to `wheeler.compiler.driver::compileMinimalWithSevenConstantImports` at the maximum arity.

The report runner remains unchanged. Native source compilation and transported artifacts continue through one verifier, interpreter, diagnostic, identity, profile-2 report, and summary path.

## Fixed profile boundary

Eight sources are not an arbitrary limit chosen by the runner. They close every public fixed-arity compiler-driver operation:

- one root with no imported source
- one root with one through seven imported sources

Every source remains bounded to 4,096 bytes and the complete plan remains bounded to 32,768 bytes. The eight-source source arena therefore matches the complete plan ceiling. Source count beyond eight rejects before manifest identity, lock validation, shard selection, compilation, or publication.

The next expansion must use a counted graph compiler API. Adding another hand-written argument permutation without such an API is forbidden.

## Dispatch

Eight fixed branches cover root ordinals zero through seven. Each branch removes only the selected root from plan order and passes all other sources to imported arguments in ascending ordinal.

Compilation authority freezes each source frame exactly once. It drops all eight values and the private source region after the compiler returns a nonzero committed length. The caller copies only that prefix into exact artifact storage.

## Evidence

`NativeCompiledTestRunnerExampleTest` adds a seventh constant module at `src/G.w`. The root at `src/Test.w` imports all seven modules in canonical module-name order.

The test independently compiles the eight-source graph with stage 0. It compares the complete 39-byte product for that transported artifact with native zero-artifact source mode. Report identity and summary match byte for byte.

The focused test compiles one combined native compiler/runtime closure and retains parity for every accepted source count from one through eight, including passing and assertion-failing roots.

The runtime archive contains 251,485 bytes with SHA-256 `ff2466c1962880fce9bb37f133a27bfffe458314ab883462832aeee0e64926e6` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the new runtime archive exactly.

## Acceptance

- [x] Compilation authority accepts one through eight sources.
- [x] The source arena matches the 32,768-byte plan ceiling.
- [x] Root dispatch covers every accepted ordinal.
- [x] Imported arguments retain canonical source-plan order.
- [x] Dispatch covers every public fixed compiler-driver arity.
- [x] Exact artifact-prefix ownership remains unchanged.
- [x] Eight-source native and transported products match byte for byte.
- [x] One-through-seven-source products remain unchanged.
- [x] Counts above eight reject before compilation or publication.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Add a ninth fixed source slot

Rejected. The compiler driver has no eighth imported-source operation. Counted graph compilation must replace fixed permutations.

### Raise the source arena above the plan ceiling

Rejected. No validated source bytes exist beyond 32,768.

### Let root selection follow argument position

Rejected. The validated manifest remains sole root authority.

### Keep separate report evidence per arity

Rejected. Byte parity through one canonical report path is stronger and smaller.

## References

- [WIP-0235](WIP-0235-native-import-cycle-rejection.md)
- [WIP-0244](WIP-0244-native-seven-source-test-compilation.md)
