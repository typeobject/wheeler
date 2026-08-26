# WIP-0407: Helper-owned process status AOT

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and native backend maintainers |
| Created | 2026-08-26 |
| Updated | 2026-08-26 |
| Area | Native bootstrap, AOT lowering, process status, helper state |
| Depends on | WIP-0001, WIP-0008, WIP-0026, WIP-0390, WIP-0405 |
| Supersedes | Entry-only mutation of scalar global zero |
| Superseded by | WIP-0409 for capsule binding |

## Summary

Let an admitted helper publish Linux process status through scalar global zero. Forward and inverse helper bodies may use canonical global updates, swaps, logged replacement, or local stores over that slot. The entry may halt after a reachable helper write without copying the result through an entry local.

This removes an AOT-only ownership rule absent from canonical Wheeler bytecode and the stage-0 VM. It does not grant a helper direct process-exit authority. The generated epilogue still reads global zero once after the entry halts.

## Status authority

Scalar global zero remains the sole process-status slot. It starts at zero and must receive at least one write on the entry's reachable call graph. Any admitted function may perform that write because Wheeler globals are shared program state.

The validator follows `CALL`, `UNCALL`, `CALL_VALUE`, and `CALL_VOID` edges from the entry. Directional calls inspect the selected forward or inverse body. A status write is one of:

- `ADD_CONST`, `SUB_CONST`, `XOR_CONST`, or `SET_LOGGED` targeting global zero.
- `SWAP` naming global zero on either side.
- `LOCAL_STORE_GLOBAL` targeting global zero.

A write in an unreachable helper does not satisfy publication. Cycles terminate through one visited bit per function and direction. The search changes no execution bound and does not infer a value.

## Validation and evaluation

Every function body retains ordinary operand, type, terminal, call, and global checks. Helper status writes no longer fail ownership validation. The entry still ends in `HALT`, while helpers retain their typed return terminals.

Static evaluation uses one shared global array and one shared `statusStored` bit across all calls. A helper write sets the bit. The final status must still lie between zero and 124. Missing writes, arithmetic traps, failed expectations, and out-of-range results reject before runtime publication.

Dynamic-I/O programs cannot be fully evaluated before input exists. Reachable-writer analysis proves that one selected body can publish status. The runtime epilogue still rejects input-dependent status values outside the portable process range.

## Machine lowering

No new instruction encoder is required. R14 already names the shared global table in every frame. Helpers use the same direct update, replacement, swap, and store sequences as the entry.

After `HALT`, the entry epilogue reads global zero, checks the portable process range, writes committed output when present, restores its frame, and enters the Linux exit path. A helper cannot bypass those checks or exit early.

Call depth and fuel remain shared. Inverse helper status writes use the inverse machine body selected by WIP-0405.

## Failure boundary

Reject a program with no reachable status writer, malformed call direction, invalid global operand, missing inverse, unsupported function signature, out-of-range final status, fuel or call-depth exhaustion, or any prior scalar-profile failure. Static rejection publishes no runtime text. Runtime failure exits with status 126 and publishes no application output.

## Evidence

`ScalarAotArtifacts.helperStatusArtifact` defines a reversible parameterless helper whose forward body increments status and whose inverse decrements it. The entry calls forward twice, checks two, uncalls once, checks one, and halts without an entry store. `noStatusWriterArtifact` contains only `NOP` and `HALT` and rejects before lowering.

`LinuxX8664ScalarAotCompilerTest.publishesStatusThroughDirectionalHelpers` independently evaluates the WBC, binds it to a canonical capsule, native image plan, and ELF, and checks every identity. On x86-64 Linux the image executes both helper directions, exits with status one, writes exact `Wheeler\n`, and writes no standard error.

| Product | Identity |
| --- | --- |
| WBC | `ede040399a9e6f3e37c4a47856ca4e6b8e620be87cdd6c74e03c0c54b686dd7c` |
| runtime | `8080b55ad8724f148f857273b42341328d51057fe8dc42865f646173842e96d5` |
| capsule | `ef1d0ec4128b0f79d3f42cdef45893c12e5a443b8e775108c14b0f47b012aa44` |
| native plan | `0fbedea0eface26051ba4faf0d639c03af6b930bbd6f04266e31361bc34e63a6` |
| unsigned PREV | `55cccb4b0e7780dce302b0be50a113db4c32bac98efe1370fcf496dc6452b847` |

## Acceptance

- [x] Helpers may mutate scalar global zero through every admitted global form.
- [x] Forward and inverse calls share the status slot.
- [x] Reachability includes all admitted call forms and directions.
- [x] An unreachable writer does not satisfy publication.
- [x] Missing reachable status publication rejects before lowering.
- [x] Final status range checks remain in evaluation and machine code.
- [x] WBC, runtime, capsule, plan, ELF, and PREV identities remain exact.
- [x] Native x86-64 Linux launch observes helper-published status.

## Rejected alternatives

### Copy every helper result through the entry

Rejected. It rewrites valid shared-global Wheeler programs for an AOT policy.

### Treat any dormant helper as publication evidence

Rejected. Unreachable code cannot establish a process observation.

### Give helpers a process-exit syscall

Rejected. The entry epilogue remains the sole host exit authority.

### Keep the entry-only restriction

Rejected. Canonical Wheeler global ownership does not contain that rule.

## References

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0390](WIP-0390-x86-64-linux-shared-scalar-globals.md)
- [WIP-0405](WIP-0405-directional-scalar-aot-calls.md)
- [WIP-0408](WIP-0408-reversible-scalar-result-slot-aot.md)
- [WIP-0409](WIP-0409-exact-native-capsule-binding.md)
