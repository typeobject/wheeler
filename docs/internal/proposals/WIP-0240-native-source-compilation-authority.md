# WIP-0240: Native source compilation authority

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, native testing, compiler dispatch |
| Depends on | WIP-0237, WIP-0238, WIP-0239 |
| Supersedes | Runner-local source extraction and fixed-arity dispatch |
| Superseded by | WIP-0241 native four-source test compilation |

## Summary

Move source-plan compilation out of the canonical report runner and into one focused runtime module.

`TestRunner.w` should own transport preflight, package authorization, shard selection, case execution, and report publication. It should not own compiler source allocation or fixed-arity argument permutation. `TestSourceCompilation.w` now owns the accepted one-to-three-source compiler profile.

The old `TestSourceExecution.w` wrappers are deleted. They exposed arity-specific calls while leaving source projection and root dispatch in `TestRunner.w`. Keeping both layers would split compilation policy without reducing the trusted path.

## Interface

`validCompilableSourcePlan` consumes a previously validated source plan and checks the compiler-specific bounds:

- one through three sources
- at most 4,096 bytes per source

`compileValidatedSourcePlan` accepts that plan, the manifest-selected root ordinal, and exact 32,768-byte artifact recovery storage. It allocates a private 12,288-byte, three-object source region, copies source frames by validated ordinal, freezes exact UTF-8 values, and dispatches to the canonical compiler driver.

The function returns only a nonzero committed artifact length. It does not verify, execute, classify, hash, report, or publish the artifact.

## Dispatch ownership

The module owns all fixed-arity permutations:

- one source calls `compileMinimal`
- two sources call `compileMinimalWithConstantImport`
- three sources call `compileMinimalWithConstantImports`

For imported graphs, non-root arguments retain canonical source-plan order. The selected root occupies only the root argument. The report runner sees one operation regardless of source count.

This boundary makes subsequent source-count growth local. Adding another proven driver arity changes compilation authority and its focused evidence, not descriptor reduction.

## Allocation and failure

The report runner checks `validCompilableSourcePlan` after complete source-plan validation and before manifest identity, lock validation, shard selection, compilation, or publication.

Only a selected source descriptor invokes `compileValidatedSourcePlan`. The compilation module checks the same bound at its public mutation boundary, allocates fresh source storage, and drops every frozen value and the source region before return.

Compiler output remains caller-owned recovery storage. The report runner still copies only the returned prefix into exact artifact storage before verification and execution. A source, compiler, ownership, or bound failure leaves report output untouched.

## Legacy removal

`TestSourceExecution.w` is removed from the runtime package and library root. `NativeTestRunnerProgram.java` now assembles `TestSourceCompilation.w` instead.

No compatibility alias remains. All native test source compilation passes through `compileValidatedSourcePlan`.

## Evidence

The existing canonical report parity test exercises all accepted arities through the new module:

- one passing source
- one assertion-failing source
- one imported source plus its root
- two imported sources plus their root

Each native result matches the corresponding transported stage-0 artifact result byte for byte. The same focused run compiles one combined native compiler/runtime closure, so missing imports, invalid ownership, duplicate locals, and unsupported syntax fail before execution.

`TestRunner.w` falls from 584 lines to a focused transport and report implementation. `TestSourceCompilation.w` is 119 lines after formatting. Both remain below the repository limit with room for bounded growth.

The runtime archive contains 238,402 bytes with SHA-256 `b34778c3401b35bf1624b8e7cf3440d65fb222784d79d4163b7642086315fb97` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the new runtime archive exactly.

## Acceptance

- [x] One module owns source-plan compiler bounds and dispatch.
- [x] Report reduction no longer allocates or freezes compiler source values.
- [x] Root permutation is absent from `TestRunner.w`.
- [x] All accepted arities preserve exact report parity.
- [x] Source compilation still occurs only after shard selection.
- [x] Compiler output remains private until exact-prefix copy.
- [x] The fixed-arity wrapper module and imports are deleted.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Keep thin fixed-arity wrappers

Rejected. They validate the same byte bounds but leave source ownership and dispatch in another module.

### Put report composition into compilation authority

Rejected. Compiler output and test report semantics are independent boundaries.

### Allocate source values in the report arena

Rejected. A private source region gives the compiler attempt one clear lifetime and keeps report capacity independent of source count.

### Preserve old names as aliases

Rejected. No external package API uses them, and aliases would retain dead authority.

## References

- [WIP-0237](WIP-0237-native-compiled-test-reports.md)
- [WIP-0238](WIP-0238-native-two-source-test-compilation.md)
- [WIP-0239](WIP-0239-native-three-source-test-compilation.md)
- [WIP-0241](WIP-0241-native-four-source-test-compilation.md)
