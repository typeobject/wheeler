# WIP-0404: Scalar global replacement AOT

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and native backend maintainers |
| Created | 2026-08-26 |
| Updated | 2026-08-26 |
| Area | Native bootstrap, AOT lowering, global state, logged replacement |
| Depends on | WIP-0008, WIP-0026, WIP-0390, WIP-0403 |
| Supersedes | Load-and-store substitution for scalar global replacement |
| Superseded by | WIP-0407 for status ownership, WIP-0409 for capsule binding |

## Summary

Lower canonical scalar `SWAP` and `SET_LOGGED` instructions without rewriting their WBC identities. Swaps retain both exact signed values. Logged replacement retains its exact signed immediate and the forward state visible to later helpers and the entry.

This leaf executes one forward native process. It does not claim a native history log, inverse direction, rewind, checkpoint, or commit horizon.

## Validation

`SWAP` carries two in-range global indexes. Equal indexes remain the canonical no-op defined by the bytecode verifier. `SET_LOGGED` carries one in-range global and one signed 64-bit immediate.

The entry and helpers may mutate every admitted scalar global. A swap or logged replacement involving global zero counts as process-status publication when its body is reachable from the entry.

Every accepted function still has one canonical terminal. Read-only expectations do not replace the entry's final status publication.

## Evaluation

Independent static evaluation exchanges both selected global values or replaces the selected value with the complete immediate. The evaluator uses the same global array across every call frame. A helper replacement is therefore visible to its caller and subsequent helpers.

Static evaluation computes the final status before runtime text is published. WIP-0407 carries helper status mutation through the same shared state.

## Machine lowering

R14 remains the base of the bounded shared global table.

`SET_LOGGED` loads the complete immediate into RAX and stores all 64 bits into the selected slot. `SWAP` loads the left slot into RAX and the right slot into RCX, stores RAX to the right slot, then stores RCX to the left slot. Equal slots preserve their value.

Both instructions consume the shared execution fuel before mutation. They add no host import, relocation, stack record, or hidden table.

## Reversibility boundary

`SWAP` is intrinsically reversible. Its forward machine sequence preserves enough value information for the process result, but this AOT leaf exposes no inverse entry.

`SET_LOGGED` is reversible only with its prior value in Wheeler history. The generated one-way executable does not fabricate that history. WIP-0405 adds bounded inverse helper calls. Native rewind remains required before the complete classical bootstrap profile can replace the Wheeler interpreter.

The absence of rewind is explicit rather than represented by a partial log or an unchecked local rewrite.

## Failure boundary

Reject malformed operands, out-of-range globals, unsupported history operations, fuel exhaustion, or any prior scalar-profile failure. Rejection publishes no runtime text. Runtime fuel failure exits with status 126 and publishes no application output.

## Evidence

`ScalarAotArtifacts.globalReplacementArtifact` starts `left` at 11 and `right` at 22. A void helper swaps them and replaces `right` with 51. The entry checks both values, swaps again, and publishes 51 as process status. WIP-0407 replaces the former helper-status rejection fixtures with direct helper publication evidence.

`LinuxX8664ScalarAotCompilerTest.lowersScalarGlobalReplacement` binds the accepted WBC to a canonical capsule, native image plan, and ELF. On x86-64 Linux the image executes both global forms through the helper boundary, exits with status 51, writes exact `Wheeler\n`, and writes no standard error.

| Product | Identity |
| --- | --- |
| WBC | `c8536b97e8b990f2e8e830c9dfe8dcc9d443bb990462b81714cf10031dc6e3a6` |
| runtime | `bfb148909213143318d0b39316de7094f75679b3c868237399b8012d6b54fb18` |
| capsule | `524256617fa8ef2f9d14e2ea575d9869584c0cf947a704d323432312991a5c07` |
| native plan | `e849cccdf7e3b36ad0260c266583889636e0565ff42d62eceeb6a8a094820232` |
| unsigned PREV | `4324c04fb30dd57d9b160482912835340673d05c5afcb7557d4bf18af26d4255` |

## Acceptance

- [x] Canonical scalar swaps retain both complete signed values.
- [x] Logged replacement retains the complete signed immediate.
- [x] Helper mutations are visible to the entry.
- [x] Equal-index swaps retain canonical no-op behavior.
- [x] WIP-0407 admits helper mutation of process status.
- [x] Every accepted mutation consumes shared fuel.
- [x] Missing reachable status writers reject before publication.
- [x] WBC, runtime, capsule, plan, ELF, and PREV identities remain exact.
- [x] Native x86-64 Linux launch observes exact status and output.

## Rejected alternatives

### Rewrite replacement as a local store

Rejected. Opcode identity and logged reversibility remain part of canonical WBC semantics.

### Use one truncated machine immediate

Rejected. Wheeler scalar globals and immediates are signed 64-bit values.

### Keep a helper-local shadow global table

Rejected. Wheeler globals are shared across calls.

### Record an incomplete native history

Rejected. A forward-only backend must not claim rewind authority.

## References

- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0390](WIP-0390-x86-64-linux-shared-scalar-globals.md)
- [WIP-0403](WIP-0403-scalar-global-instruction-aot.md)
- [WIP-0405](WIP-0405-directional-scalar-aot-calls.md)
- [WIP-0407](WIP-0407-helper-owned-process-status-aot.md)
- [WIP-0409](WIP-0409-exact-native-capsule-binding.md)
