# WIP-0287: Native call and branch coverage

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, coverage, testing, and self-hosting maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Semantic coverage, native execution, self-hosting |
| Depends on | WIP-0286 |
| Supersedes | Linear entry-function native coverage projection |
| Superseded by | Native direction and rewind coverage |

## Summary

Publish exact function, instruction, and conditional-branch coordinates from native execution.

The old bootstrap reducer consumed only opcode words. It assigned every transition to one caller-supplied function and used transition order as the instruction index. That was sufficient for a linear one-function fixture. It was wrong as soon as WIP-0285 executed an imported helper.

The interpreter now emits one bounded event tuple per executed transition:

- the unchanged two-byte opcode.
- the physical function identifier.
- the function-local instruction ordinal.
- `none`, `fallthrough`, or `taken` branch state.

The coverage fragment encoder consumes those tuples directly. It no longer reconstructs coordinates from transition order or accepts a caller-provided function identifier.

## Interpreter state

The execution loop tracks the current function and instruction ordinal beside the byte cursor. Calls save the caller function and return instruction in the bounded frame store. Returns restore both. Direct and conditional jumps set the next instruction ordinal to the verified target.

The interpreter writes `fallthrough` for `JUMP_IF_ZERO` when the condition is nonzero and `taken` when it is zero. Other opcodes retain `none`. The runner supplies trace arrays with exactly `MAX_INTERPRETED_STEPS` entries. No event can outlive its execution arena.

The raw two-byte opcode stream is unchanged. `NativeVm.w` therefore preserves the established opcode-trace digest while semantic coverage gains the missing coordinates.

## Reduction

`BootstrapCoverageFragments.w` computes key and JSON lengths from the exact branch spelling. Keys and report suffixes use the traced function and instruction values. `CoverageReducer.w` still performs canonical sorting and duplicate reduction.

Unknown branch states reject before publication. Unsupported opcodes retain the existing fail-closed behavior.

## Evidence

`nativeCallAndBranchCoverageMatchesStageZero` compiles one imported Boolean helper and a root that calls it twice. The first call takes the helper's conditional fallthrough path. The second takes its branch target. Native execution and Java stage-0 observation produce byte-identical canonical coverage reports. The report contains physical function 1 and both branch outcomes.

The compiler package now publishes report identity `bfa2de7a7819131f9a679d02bef8f83f0e44bde029878b02897c05ee0bb7cf2e`. All seven cases pass. Their coverage identities changed because imported helper transitions now carry function-local coordinates and real branch outcomes rather than entry-function linear approximations.

## Acceptance

- [x] Every native event records its physical function identifier.
- [x] Every native event records its function-local instruction ordinal.
- [x] Call frames preserve caller function and return instruction.
- [x] Conditional branches distinguish taken and fallthrough paths.
- [x] Nonbranch events retain the `none` state.
- [x] Coverage fragments consume traced coordinates without caller repair.
- [x] Raw opcode trace identities remain unchanged.
- [x] Imported-call coverage is byte-identical to stage zero.
- [x] The native compiler package passes with corrected coverage identities.
- [x] Runtime and conformance archives and locks are rebuilt exactly.
- [x] Focused VM, coverage, runner, package, documentation, workspace, and file-length policy pass.

The runtime archive contains 387,140 bytes with SHA-256 `0537e28f3d08d08606e8d4a4a41fa6d6b4ca8120823e03123df85760d3661fc1` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 134,770 bytes with SHA-256 `7846984c8dc361b1ba6552904ee76d7ccc7f5c8500cfd670ad994c47a86db6d2` and root manifest identity `b9beb8697bb55c654a74476b69a5a21fbcded9791e04f771ab4b25186d2d1349`.

The compiler archive remains 3,024,011 bytes with SHA-256 `f368a20b722ed114247166df99f4a482fb099041d5ebfa4858a0c192429da70f` and root manifest identity `9b2cebe76654d6f2cb4d2ec3e3c2762bfc8e72009a796f7e28adf5903428bb99`.

## Rejected alternatives

### Derive instruction indices from transition order

Rejected. Calls, returns, branches, and loops break that correspondence.

### Decode artifact control flow in the coverage reducer

Rejected. The executor already knows the selected edge. Reinterpretation would create a second execution authority.

### Alter the opcode trace encoding

Rejected. Opcode trace identity and semantic coverage are separate contracts.

## References

- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0020](WIP-0020-semantic-coverage-and-evidence-accounting.md)
- [WIP-0285](WIP-0285-native-compiler-callable-suite.md)
- [WIP-0286](WIP-0286-native-interpreter-layout-authority.md)
