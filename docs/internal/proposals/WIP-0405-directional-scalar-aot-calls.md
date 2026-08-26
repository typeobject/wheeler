# WIP-0405: Directional scalar AOT calls

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and native backend maintainers |
| Created | 2026-08-26 |
| Updated | 2026-08-26 |
| Area | Native bootstrap, AOT lowering, reversible calls, inverse bodies |
| Depends on | WIP-0001, WIP-0008, WIP-0026, WIP-0401, WIP-0404 |
| Supersedes | Forward-body-only scalar AOT function admission |
| Superseded by | WIP-0407 for status ownership, WIP-0408 for result-slot directions |

## Summary

Lower canonical parameterless `CALL` and `UNCALL` instructions for scalar void helpers. A helper may carry one bounded forward body and one bounded inverse body. `CALL` enters the forward body. `UNCALL` enters the inverse body. Both directions retain shared globals, one execution-fuel account, checked traps, and the existing depth-64 call bound.

This is directional execution, not rewind. Native history, step reversal, commit horizons, and history exhaustion remain outside this leaf.

## Profile

The entry remains forward-only. A directional helper has no parameters, no result, no implicit result slot, and at most 512 instructions in each direction. Each body ends with canonical `RETURN` and satisfies the ordinary scalar opcode profile independently.

`CALL` may target any admitted parameterless void helper. `UNCALL` additionally requires a nonempty inverse body. Neither form is rewritten as `CALL_VOID`. Canonical opcode and direction remain visible inputs to lowering.

Typed `CALL_VALUE` and `CALL_VOID` continue to enter forward bodies. WIP-0408 admits parameterized signed and Boolean inverse calls through the canonical result-slot ABI. Other typed directional ABIs remain rejected.

## Validation

Validation walks forward and inverse bodies separately. Branch targets are relative to their own body. Local types, global bounds, status ownership, terminals, I/O capabilities, loop limits, call signatures, and opcode operands retain the same checks in both directions.

The call-graph scan covers both bodies and all four admitted call forms. A cycle in either direction enables the shared call-depth cell. The depth bound applies across mixed forward and inverse calls rather than restarting at a direction change.

The static evaluator selects `function.body(direction)` at each call. It creates a fresh local frame, shares globals and output state, consumes common fuel, and enters the same depth budget used by forward calls.

## Machine lowering

Every helper direction receives a distinct machine offset and an independent trap epilogue. Call relocations bind a function ID and one direction bit. Missing inverse offsets are internal errors after validation, never a forward fallback.

Both call forms:

1. Consume caller instruction fuel.
2. Increment and check shared call depth when the graph is recursive.
3. Issue one relative x86 call to the selected body.
4. Restore depth after return.
5. Inspect the callee trap flag before continuing.

The inverse body shares R14 globals, R15 fuel, optional R13 call depth, and the entry's bounded I/O state. It receives no ambient authority. WIP-0407 permits it to mutate shared process status without granting direct exit authority.

## Reversibility boundary

An inverse body is verified executable code. `UNCALL` running that code is not equivalent to rewinding a completed `CALL` unless the program's proof and history conditions establish that relation.

This profile does not retain prior locals or logged global values after return. It does not expose reverse instruction stepping. WIP-0406 lowers the forward value transition for `CHECKPOINT` and `COMMIT`. It does not retain their history observations or history exhaustion. WIP-0408 adds explicit result-slot calls without conflating them with history rewind. WIP-0001 parity remains open until those observations agree with the Wheeler interpreter.

## Failure boundary

Reject an inverse on the entry, a parameterized or result-bearing directional helper, an oversized body, `UNCALL` without an inverse, a malformed branch or operand in either direction, a call graph without a reachable status writer, call-depth exhaustion, fuel exhaustion, or any prior scalar-profile failure.

Static failure publishes no runtime text. Runtime depth, arithmetic, assertion, or fuel failure exits with status 126 and publishes no application output.

## Evidence

`ScalarAotArtifacts.directionalCallArtifact` defines one helper whose forward body increments `counter` and whose inverse decrements it. The entry calls forward twice, checks two, uncalls once, checks one, and publishes the result as process status.

`LinuxX8664ScalarAotCompilerTest.lowersForwardAndInverseScalarCalls` independently evaluates the WBC, binds it to a canonical capsule, native image plan, and ELF, and checks every identity. On x86-64 Linux the image enters both machine bodies, exits with status one, writes exact `Wheeler\n`, and writes no standard error.

| Product | Identity |
| --- | --- |
| WBC | `b5907c5d8e3169c09a5e5d04a3b9b7a73dbc190d6d7ba4fc8984c3fda6186763` |
| runtime | `cc5edc6502c39037e7c7eba018855b901845ef4391e69399159eb29fca036209` |
| capsule | `69e3db35fb636680c5e3df441e264ef27a5031863c1477a15439fad3d6367e8c` |
| native plan | `728420ab46abb7aa066b93d8e1fbc5531000570b53eb486a7f34a893de3f9fc3` |
| unsigned PREV | `17723dda0eee581a9d7b5a3623cb0324098647dac057fc8e8ffdc20543c5a7c1` |

## Acceptance

- [x] Forward and inverse bodies are validated independently.
- [x] `CALL` and `UNCALL` bind disjoint body offsets.
- [x] Missing inverse bodies reject without forward fallback.
- [x] Globals and fuel remain shared across directions.
- [x] Recursive mixed-direction graphs retain depth 64.
- [x] Every callee trap propagates before caller continuation.
- [x] WBC, runtime, capsule, plan, ELF, and PREV identities remain exact.
- [x] Native x86-64 Linux launch observes the inverse result.

## Rejected alternatives

### Lower `UNCALL` to the forward body

Rejected. Direction is a semantic operand, not a backend hint.

### Synthesize inverses in the native backend

Rejected. Canonical WBC already carries the verified inverse body.

### Reuse one helper offset with a runtime direction branch

Rejected. Distinct offsets keep relocations closed and remove mutable direction state.

### Claim rewind parity from one inverse call

Rejected. Rewind includes retained machine history and control observations absent here.

## References

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0401](WIP-0401-bounded-recursive-scalar-aot-calls.md)
- [WIP-0404](WIP-0404-scalar-global-replacement-aot.md)
- [WIP-0406](WIP-0406-forward-control-marker-aot.md)
- [WIP-0407](WIP-0407-helper-owned-process-status-aot.md)
- [WIP-0408](WIP-0408-reversible-scalar-result-slot-aot.md)
