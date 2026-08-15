# WIP-0066: Boolean reversible result slots

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler source, compiler, verifier, and runtime maintainers |
| Created | 2026-08-15 |
| Updated | 2026-08-15 |
| Area | Reversible source, Boolean results, result slots |
| Depends on | WIP-0041, WIP-0065 |
| Supersedes | Boolean profile split from WIP-0065 |
| Superseded by | None |

## Summary

Define and implement Boolean payloads for reversible source result slots. Keep the presence bit and payload bit as two distinct Boolean locals, preserve exact relation operands in both directions, and extend stage 0 before the native compiler claims parity.

## Problem

The admitted WIP-0041 source profile returns `long`. Stage 0 rejects `rev boolean` before lowering, so the native compiler has no source authority to match. WIP-0065 now completes signed one-source, immediate, two-source, local-call, imported-call, relocation, linking, and execution evidence. Folding a new source-language result kind into that closed call matrix would obscure the language decision and its verifier consequences.

A Boolean result slot cannot reuse the signed payload rule. The slot has one Boolean presence local and one Boolean payload local. Result relations must preserve Boolean source types and reject arithmetic operation codes. Function flags, local types, return instructions, proof subjects, and runtime extraction must agree on that shape.

## Invariants

- Presence and payload occupy distinct trailing Boolean locals.
- A Boolean relation reads only preserved Boolean parameters or prior Boolean locals.
- Signed arithmetic opcodes never enter a Boolean result relation.
- Forward and inverse relation instruction bytes are identical.
- The function result descriptor remains Boolean and uses the implicit-slot flag.
- Generated-inverse proofs bind the final Boolean function ID.
- Unsupported or mixed payload types fail before artifact publication.

## Bounds

- 64 source-local reversible callables
- 256 locals per callable
- 32,768 instructions per source-local artifact
- 262,144 code bytes before source-local container publication
- 32,768-byte canonical source-local artifact

## Plan

1. [x] Specify the admitted `rev boolean` source forms and diagnostics.
2. [x] Lower one preserved Boolean source into an explicit result-slot relation.
3. [x] Publish Boolean presence and payload local-type rows.
4. [x] Extend native function and instruction verification for Boolean payload slots.
5. [x] Match stage 0 byte for byte through proof and artifact publication.
6. [x] Execute forward and inverse after clearing history.
7. [x] Reject signed sources, arithmetic relations, missing payloads, and mixed call results atomically.
8. [x] Add the profile to the public language and bytecode references after implementation.

## Implementation

Stage 0 admits `rev boolean` with a canonical Boolean literal or one preserved Boolean parameter. `ClassicalLocalAssembler` publishes a Boolean presence local followed by a Boolean payload local and emits `RESULT_FILL_CONSTANT` or `RESULT_FILL_SOURCE`. The bytecode verifier treats result-call slots as outputs, enforces zero-or-one Boolean constants, rejects Boolean binary relations, and keeps signed arithmetic unchanged.

The direct native source path carries the Boolean result type through source products, local composition, function descriptors, proof publication, and generated inverse code. `InstructionVerifier.w` and `FunctionVerifier.w` independently require the exact Boolean payload type and reject Boolean arithmetic. The structured fixture matches the complete stage-0 artifact byte for byte. Its malformed arithmetic fixture traps with the output buffer untouched.

The runtime fixture executes `CALL_RESULT_SLOT`, commits the history boundary, and executes `UNCALL_RESULT_SLOT` with the retained relation witness. The inverse restores vacancy without reading rewind history.

## Acceptance

- Stage 0 and the native compiler emit identical Boolean result-slot artifacts.
- The independent reader and native verifier accept the complete artifact.
- Forward followed by inverse restores exact state without rewind.
- Every malformed or mixed-type form leaves artifact and identity outputs untouched.

## Rejected alternatives

### Encode Boolean payloads as signed zero or one

Rejected. Type identity is part of the function and proof contract.

### Infer payload type from the return opcode

Rejected. The descriptor and local-type rows authorize execution before the body runs.

## References

- [WIP-0041](WIP-0041-reversible-result-slots-and-explicit-presence-values.md)
- [WIP-0065](WIP-0065-reversible-call-and-result-portfolio.md)
