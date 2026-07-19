---
sidebar_position: 2
---

# WIP-XXXX: Short decision title

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Name or team |
| Created | YYYY-MM-DD |
| Updated | YYYY-MM-DD |
| Area | Language, VM, bytecode, compiler, runtime, quantum, proofs, tools, or another short area |
| Depends on | None or earlier WIP numbers |
| Supersedes | None |
| Superseded by | None |

## Summary

State the decision in one short paragraph. A reader should understand the direction without reading the full proposal.

## Motivation

Describe the real problem, who faces it, and why a local fix would leave the larger contract unclear. Separate current behavior from the intended behavior.

## Use cases

Give two to four concrete cases that exercise the contract; when relevant, include reversal, failure, lifecycle, malformed input, or concurrency. Use cases explain why the contract exists. They are not a task list.

## Goals

- List visible outcomes.

## Non-goals

- Name related work that this proposal does not cover.

## Terms and semantic model

Define key terms, machine state, values, and transitions. State each rule clearly enough for another implementation or a conformance test. Prefer pseudocode, transition rules, or a small diagram when prose would be unclear.

## Ownership and boundaries

Explain what the language, compiler, bytecode verifier, VM, runtime, tools, and host integrations own. Name the authority for shared mutable state. Also say what information may cross each boundary.

## Design

Describe the chosen contract and its main data structures or operations. Explain how it fits Wheeler's shared reversible typed IR: intrinsic or checked inverse, logged rewind, irreversible barrier, coherent permutation, unitary adjoint, or an explicit nonunitary workflow edge.

Cover deterministic behavior, validation, diagnostics, lifecycle, and extension points. Define APIs and encodings only after the semantic contract is clear.

## Reversibility and history

Define forward and reverse transitions. For each affected operation, say whether it is bijective, uses retained history, needs uncomputation, or is intentionally irreversible. Describe history records, order, ownership, limits, exhaustion, checkpoints, and behavior after exceptions or process exit.

Write "Not applicable" and give a reason when the proposal cannot change machine state.

## Concurrency and determinism

Cover scheduling, synchronization, memory visibility, transaction boundaries, cross-thread history, replay, deadlock behavior, and stable ordering where they apply. Name nondeterministic inputs and explain how Wheeler records or rejects them.

## Quantum and proof implications

Explain effects on quantum state, gates, measurement, simulators, hardware backends, proof duties, soundness, and the trusted computing base. Keep quantum reversal, classical rollback, and formal proof claims separate.

Write "Not applicable" and give a reason when these areas are unchanged.

## Bytecode, persistence, and compatibility

Describe instruction encoding, artifact containers, verification, loaders, stored history, version negotiation, and rolling compatibility. State how old artifacts are accepted, rejected, or migrated. Write "Not applicable" and give a reason when no serialized boundary changes.

## Safety, limits, and failures

Cover malformed input, arithmetic traps, invalid state, resource limits, history exhaustion, cancellation, unsupported capabilities, and diagnostics. State which failures can recover and whether reversal still works after each failure class.

## Migration and deletion

1. List implementation stages in dependency order.
2. Name old types, adapters, opcodes, fields, files, or formats removed after each stage.
3. Do not leave two authoritative implementations in place.

## Progress

- [ ] First milestone that can be checked on its own.
- [ ] Conformance or semantic-law fixtures pass.
- [ ] The required old path is removed.

Keep this list factual while the WIP is **Implementing**. Remove stale narrative that Git history already preserves.

## Testing and acceptance

- [ ] Focused tests cover forward behavior.
- [ ] Reverse execution restores the defined state after every affected successful transition.
- [ ] Failed or partial transitions follow the stated rollback rule.
- [ ] Encoders and decoders round-trip valid data and reject malformed input as specified.
- [ ] Concurrent and replay behavior is deterministic where promised.
- [ ] Tests cover resource and history limits.
- [ ] Tests cover quantum backend parity and proof soundness when they apply.
- [ ] An end-to-end fixture crosses every changed module boundary.
- [ ] Current reference docs describe the implemented result without depending on this proposal.

Remove checklist items that do not apply, or mark them inapplicable and explain why.

## Alternatives

Describe serious options and why they were rejected. Do not invent weak choices just to fill this section.

## Open questions

- Question. **Owner:** name. **Decide by:** date.

Write `None` when no design questions remain for acceptance.

## References

- Link related WIPs, current reference pages, issues, papers, or outside specifications. Proposals may link to the manual. Current docs should not depend on an unfinished proposal.
