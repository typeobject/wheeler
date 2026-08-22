# WIP-0241: Native four-source test compilation

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, package, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, native testing, module compilation |
| Depends on | WIP-0235, WIP-0240 |
| Supersedes | WIP-0240 three-source compiler bound |
| Superseded by | Native five-source test compilation |

## Summary

Compile three canonical local imported sources and their manifest-selected root through native source compilation authority.

`TestSourceCompilation.w` raises its accepted source count from three to four. The report runner does not change. The compilation module projects four exact source frames, places the selected root in the root slot, retains canonical source-plan order for the other three arguments, and invokes `wheeler.compiler.driver::compileMinimalWithThreeConstantImports`.

The returned committed artifact enters the existing exact-prefix profile-2 path.

## Bounds and ownership

Source mode still accepts one case and zero transported artifact bytes. The source plan may carry one through four sources. Each source remains at most 4,096 bytes and the complete plan remains at most 32,768 bytes.

Compilation authority expands its private source region to 16,384 bytes and four allocations. It freezes each copied source exactly once and drops all four UTF-8 values before dropping the region. Recovery artifact storage remains caller-owned and exactly 32,768 bytes.

The report arena does not grow. Source capacity and report capacity remain separate.

## Root dispatch

Four fixed permutations cover root ordinals zero through three. Each permutation passes the other source values to imported slots in ascending plan ordinal. The compiler driver remains responsible for module graph semantics and canonical artifact construction.

Complete manifest validation proves that root selection matches a source path and declared module before compilation authority receives the ordinal. Complete local import validation and cycle rejection precede dispatch.

## Evidence

`NativeCompiledTestRunnerExampleTest` adds three canonical constant modules at paths `src/A.w`, `src/B.w`, and `src/C.w`. The root at `src/Test.w` imports all three and remains the fourth source in plan order.

The test compares native source-mode output against a transported artifact independently compiled by stage 0 from the same four modules. Their complete 39-byte report identity and summary match. The same focused closure retains one-, two-, and three-source parity.

This evidence covers the root-at-three permutation. The dispatch branches are symmetric and bounded, while manifest-root selection already has independent evidence that lexical position is not authority.

The runtime archive contains 239,929 bytes with SHA-256 `792bf3137412226a64d014e31948270e0d9e294c3bb636f7941ee27c7d762fc2` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the new runtime archive exactly.

## Acceptance

- [x] Compilation authority accepts one through four sources.
- [x] Four source values use private bounded storage.
- [x] Root ordinal determines only the root argument.
- [x] Imported arguments retain canonical plan order.
- [x] Dispatch delegates to the canonical three-import compiler operation.
- [x] Report reduction remains independent of compiler arity.
- [x] Four-source native and transported products match byte for byte.
- [x] Earlier source-count products remain unchanged.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Grow report-runner source branches again

Rejected. WIP-0240 established one compilation boundary so arity growth stays local.

### Reorder imported sources by module name

Rejected. Canonical source-plan order already binds the source set and artifact input.

### Share source storage with report rows

Rejected. Compiler attempt lifetime and report publication lifetime are separate.

### Claim counted graph support

Rejected. Four fixed source slots do not establish the bounds or API for arbitrary graphs.

## References

- [WIP-0235](WIP-0235-native-import-cycle-rejection.md)
- [WIP-0240](WIP-0240-native-source-compilation-authority.md)
