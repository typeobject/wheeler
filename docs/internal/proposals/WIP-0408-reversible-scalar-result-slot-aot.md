# WIP-0408: Reversible scalar result-slot AOT

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and native backend maintainers |
| Created | 2026-08-26 |
| Updated | 2026-08-26 |
| Area | Native bootstrap, AOT lowering, reversible calls, result slots |
| Depends on | WIP-0001, WIP-0008, WIP-0026, WIP-0041, WIP-0401, WIP-0405 |
| Supersedes | Scalar AOT rejection of implicit result-slot functions |
| Superseded by | None |

## Summary

Lower canonical `CALL_RESULT_SLOT` and `UNCALL_RESULT_SLOT` calls for signed and Boolean scalar results. The callee owns one implicit two-local slot containing a Boolean occupancy tag and a typed payload. Its exact fill relation creates the result in the forward direction and clears the same result in the inverse direction.

This is explicit reversible execution. It neither reconstructs `StepRecord` history nor treats `UNCALL_RESULT_SLOT` as rewind.

## Admitted profile

An implicit result-slot helper retains the existing scalar bounds of sixteen parameters, 256 locals, 512 instructions per direction, 24 functions, depth 64, and one 65,536-instruction fuel account. Its last two locals are the result slot. The tag is Boolean. The payload equals the declared signed or Boolean result type.

Each direction has exactly two instructions. The first instruction is the same canonical relation in both bodies. The second is `RETURN_RESULT_SLOT` over the implicit slot. The admitted relations are:

- `RESULT_FILL_CONSTANT` for signed and Boolean constants.
- `RESULT_FILL_SOURCE` over a preserved parameter of the result type.
- `RESULT_FILL_BINARY` over a signed parameter and one immediate.
- `RESULT_FILL_BINARY_SOURCES` over two signed parameters.

Binary relations retain the canonical checked add, subtract, multiply, divide, remainder, XOR, and AND operation set. Boolean constants remain zero or one.

## Call contract

A result-slot call carries a helper ID, contiguous argument window, exact argument count, and caller-owned two-local slot. The argument window cannot overlap the slot. Caller tag and payload types must equal the callee ABI.

`CALL_RESULT_SLOT` requires `(tag, payload) = (0, 0)`. It executes the forward relation and returns `(1, expected)`.

`UNCALL_RESULT_SLOT` requires tag one. It executes the inverse body, checks the payload against the same relation and current arguments, and returns `(0, 0)`. A changed argument, changed payload, occupied forward slot, vacant inverse slot, overflow, invalid division, or malformed relation traps. No direction infers or repairs a payload.

Result-slot edges participate in status-writer reachability, cycle analysis, call-depth accounting, and the shared execution-fuel bound. The exact two-instruction relation body carries no global mutation.

## Independent evaluation

`ScalarAotEvaluator` owns compile-time scalar execution, shared globals, result slots, output, fuel, and call depth. Extraction from profile validation keeps operand policy separate from execution and leaves both files below 1,000 lines.

The evaluator initializes an implicit callee slot from caller state. A forward fill checks vacancy before storing its exact relation. An inverse fill checks occupancy and payload before clearing both locals. `RETURN_RESULT_SLOT` copies both values back to the caller. Static failure publishes no runtime text.

Checked remainder preserves the canonical `Long.MIN_VALUE % -1 == 0` result. Native lowering avoids the x86 `idiv` exception for that pair. Division of `Long.MIN_VALUE` by minus one and every zero divisor still trap.

## Machine ABI

The caller transfers ordinary scalar arguments through the established register and stack ABI. R10 carries the result tag and R11 the payload into the helper. The helper copies both into its frame before executing the relation.

`RETURN_RESULT_SLOT` returns the tag in RAX and payload in R8. RDX remains the private helper-trap flag. The caller checks RDX before storing either returned value. Stack argument cleanup precedes caller-slot stores, so arguments seven through sixteen use the same aligned call area as ordinary scalar helpers.

Relation lowering computes the expected payload with the existing checked arithmetic emitter. Forward code checks two zero words and writes one plus the payload. Inverse code checks one plus the exact payload and clears both words. Every check branches to status 126 before process output.

## Failure boundary

Reject a noncanonical function shape, nonidentical relation, wrong slot base, argument overlap, type mismatch, unsupported operation, Boolean value outside zero and one, missing inverse body, malformed terminal, out-of-range call target, unassigned caller state, relation mismatch, exhausted fuel or depth, or any prior scalar-profile failure.

An occupied forward slot is valid WBC but invalid execution state. Independent evaluation rejects that state with no runtime publication. Runtime-dependent relation failure exits with status 126 and publishes no application output.

## Evidence

`ScalarAotCallArtifacts.resultSlotArtifact` contains five helpers. It exercises constant, source, immediate-binary, source-binary, and Boolean-source relations. The entry fills and clears each caller slot, observes every payload, and publishes status 42. `occupiedResultSlotArtifact` performs a second forward call without an inverse clear and fails during independent evaluation. `wideResultSlotArtifact` succeeds with sixteen arguments across registers and the aligned stack area. Argument seventeen rejects before lowering. Its WBC is `8307662a8e1ed6723fc39266911cc2ca444897e43d35d787eaa6ae32e937ace9` and its runtime is `3aab2bc57ae9fa0b13cb3196253e7b46d1b1c1d7bfe0edc5686fa415e7f5a431`.

`LinuxX8664ScalarAotCompilerTest.lowersReversibleScalarResultSlots` binds the accepted WBC to a canonical capsule, native plan, and ELF and checks every identity. On x86-64 Linux the ELF executes every relation in both directions, exits with status 42, writes exact `Wheeler\n`, and writes no standard error. `lowersCanonicalRemainderEdge` independently launches the minimum-signed remainder by minus one, observes status zero, and pins WBC `b58f22ae80febf5f4eb312ffe55b2bb6137db3f60f9fa695ffafbac1fe7b7b98` and runtime `933e22071d51952c7f5abb3e7d03ff9fff0e8a3bbfa9ea233a5d070d8ef7a026`.

| Product | Identity |
| --- | --- |
| WBC | `961b66d9f5e73540a95f9425f6403f7697e513eef64c7c2f907a9d678a5db34a` |
| runtime | `480022e7d0bc97ddd745dbb7d77b567cbede3efbb7f09396b957fb99dc5f2300` |
| capsule | `d88799a39344339e1e9210b814fb2a9b6c2154fb19b63c2fcc690a0771413156` |
| native plan | `c868b08c922cc5d4a53a5dce961d0948cf27200b0f04c0f26a0764e4acff8c3c` |
| unsigned PREV | `7b8f8769e083a7152836aa2ef13a21c080839b3eb2563e2b4922e78d20e1b7f6` |

## Acceptance

- [x] Signed and Boolean result slots retain exact caller and callee types.
- [x] Every canonical scalar fill relation lowers without opcode rewriting.
- [x] Forward calls require vacancy and return an occupied exact payload.
- [x] Inverse calls require the exact relation and clear both slot words.
- [x] Register and stack argument widths retain the sixteen-argument bound.
- [x] Result-slot calls share globals, fuel, and depth accounting.
- [x] Occupied forward state rejects before runtime publication.
- [x] WBC, runtime, capsule, plan, ELF, and PREV identities remain exact.
- [x] Native x86-64 Linux launch observes all forward and inverse relations.

## Rejected alternatives

### Rewrite result slots as ordinary value calls

Rejected. An ordinary value call has no occupancy relation and no checked inverse clear.

### Retain a helper-local hidden payload

Rejected. Caller-owned slot state is part of the canonical instruction contract.

### Use RDX for the payload

Rejected. RDX already carries the helper trap result and must be checked before caller mutation.

### Treat inverse execution as rewind

Rejected. The inverse proves a current-state relation. It does not restore retained machine history.

## References

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0041](WIP-0041-reversible-result-slots-and-explicit-presence-values.md)
- [WIP-0401](WIP-0401-bounded-recursive-scalar-aot-calls.md)
- [WIP-0405](WIP-0405-directional-scalar-aot-calls.md)
- [WIP-0407](WIP-0407-helper-owned-process-status-aot.md)
