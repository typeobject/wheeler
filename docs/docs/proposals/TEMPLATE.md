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
| Area | Language, VM, bytecode, compiler, runtime, quantum, proofs, tools, or another concise area |
| Depends on | None or earlier WIP numbers |
| Supersedes | None |
| Superseded by | None |

## Summary

State the decision in a short paragraph. A reader should understand the direction without reading the entire proposal.

## Motivation

Describe the concrete problem, who encounters it, and why a local repair would leave the larger contract unresolved. Distinguish current behavior from intended behavior.

## Use cases

Give two to four concrete scenarios that exercise the proposed contract. Include at least one reverse-execution, failure, lifecycle, malformed-input, or concurrent case when applicable. Use cases explain why the contract exists; they are not implementation task lists.

## Goals

- List observable outcomes.

## Non-goals

- Name tempting adjacent work this proposal does not take on.

## Terms and semantic model

Define important terms, machine state, values, and state transitions. State invariants precisely enough for an independent implementation or conformance test. Prefer pseudocode, transition rules, or a small diagram over ambiguous prose.

## Ownership and boundaries

State what the language, compiler, bytecode verifier, VM, runtime, tools, and host integrations own. Name the authoritative component for shared mutable state and identify information that may cross each boundary.

## Design

Describe the chosen contract and its major data structures or operations. Cover deterministic behavior, validation, diagnostics, lifecycle, and extension points. Introduce concrete APIs and encodings only after the semantic contract is clear.

## Reversibility and history

Define forward and reverse transitions. State whether each affected operation is bijective, uses retained history, requires uncomputation, or is intentionally irreversible. Specify history records, ordering, ownership, bounds, exhaustion, checkpoints, and behavior across exceptions or process termination.

Write “Not applicable” with a reason if the proposal cannot change machine state.

## Concurrency and determinism

Describe scheduling, synchronization, memory visibility, transaction boundaries, inter-thread history, replay, deadlock behavior, and deterministic ordering as applicable. Identify nondeterministic inputs and how they are recorded or rejected.

## Quantum and proof implications

Describe effects on quantum state, gates, measurement, simulation or hardware backends, proof obligations, soundness, and the trusted computing base. Keep quantum reversibility, classical rollback, and formal proof claims distinct.

Write “Not applicable” with a reason when these boundaries are unaffected.

## Bytecode, persistence, and compatibility

Describe instruction encoding, artifact containers, verification, loaders, persisted history, version negotiation, and rolling compatibility. State how old artifacts are accepted, rejected, or migrated. Write “Not applicable” with a reason when no serialized boundary changes.

## Safety, limits, and failures

Specify malformed input, arithmetic traps, invalid state, resource limits, history exhaustion, cancellation, unsupported capabilities, and diagnostic behavior. State which failures are recoverable and whether reversal remains possible after each failure class.

## Migration and deletion

1. List implementation stages in dependency order.
2. Name old types, adapters, opcodes, fields, files, or formats deleted after each stage.
3. Avoid an indefinite period with two authoritative implementations.

## Progress

- [ ] First independently verifiable milestone.
- [ ] Conformance or semantic-law fixtures pass.
- [ ] Required old path is deleted.

Keep this checklist factual while the WIP is **Implementing**. Remove stale narrative that can be recovered from Git history.

## Testing and acceptance

- [ ] Forward behavior is covered by focused tests.
- [ ] Reverse execution restores the defined state for every affected successful transition.
- [ ] Failed or partial transitions obey the specified rollback rule.
- [ ] Encoding and decoding round-trip and reject malformed input as specified.
- [ ] Concurrent and replay behavior is deterministic where promised.
- [ ] Resource and history bounds are tested.
- [ ] Quantum backend parity and proof soundness cases are covered when applicable.
- [ ] An end-to-end fixture crosses every changed module boundary.
- [ ] Current reference documentation describes the implemented result without relying on this proposal.

Remove or mark inapplicable checklist items with a reason rather than claiming irrelevant coverage.

## Alternatives

Describe serious alternatives and why they were rejected. Do not invent weak alternatives merely to fill the section.

## Open questions

- Question — **Owner:** name — **Decide by:** date

Use `None` when acceptance has no unresolved design questions.

## References

- Link related WIPs, current reference pages, issues, papers, or external specifications. Links point from the proposal to the manual; current documentation should not rely on an unfinished proposal.
