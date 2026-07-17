---
slug: /proposals/
sidebar_position: 1
---

# Wheeler Improvement Proposals

A Wheeler Improvement Proposal, or WIP, records a decision that is too broad to leave buried in an issue or pull request. It states the problem, defines the relevant semantics and invariants, assigns ownership, chooses a design, and describes how the decision will be tested and adopted.

WIPs are Wheeler's durable decision log. A numbered `WIP-NNNN` is a proposal identifier; it does not mean that the work is necessarily “in progress.” Proposals describe proposed, accepted, or in-progress contracts. User guides and reference pages describe behavior that exists today and should not present an unfinished WIP as implemented behavior.

## When to write a WIP

Write a WIP for a change to:

- source-language syntax, typing, proof rules, or observable semantics;
- the definition of reversibility, retained history, uncomputation, or irreversible effects;
- the VM instruction set, memory model, scheduler, concurrency, transactions, or synchronization;
- bytecode containers, loaders, verification, versioning, or compatibility;
- quantum state, gate, measurement, simulation, or hardware-backend semantics;
- the trusted computing base for proofs or program verification;
- compiler, runtime, tool, or module ownership across project boundaries;
- determinism, resource limits, safety, security, diagnostics, or failure behavior;
- a compatibility removal or migration spanning multiple modules or tools.

A local refactor, isolated bug fix, test addition, documentation correction, or private optimization does not need a WIP unless it changes one of those contracts.

## Statuses

| Status | Meaning |
| --- | --- |
| Draft | The author is shaping the problem and design. |
| Review | The proposal is ready for semantic, implementation, and migration review. |
| Accepted | Maintainers approved the decision; implementation has not started. |
| Implementing | Work is underway, and the progress checklist must stay current. |
| Implemented | The acceptance suite, documentation, migration, and required deletion are complete. |
| Superseded | A later WIP replaces all or part of the decision. |
| Withdrawn | The proposal will not be pursued. |

Only maintainers change a WIP to **Accepted**, **Implemented**, **Superseded**, or **Withdrawn**. A material semantic or architectural change sends an accepted proposal back to **Review**.

## How to create a proposal

1. Copy [the template](TEMPLATE.md) to `WIP-NNNN-short-title.md`, using the next unused four-digit number.
2. Fill in every metadata field, including dependencies, owners, and dates.
3. Write the summary, motivation, and concrete use cases before choosing opcodes, classes, or APIs.
4. State the semantic model and invariants. Define forward and reverse behavior explicitly when state can change.
5. Keep the scope to one primary decision with an acceptance suite that can finish independently.
6. Mark the proposal **Review** and request feedback from every affected boundary owner.
7. Resolve open questions or assign each one an owner and decision date.
8. After acceptance, implement the design in reviewable stages and update the progress checklist in the same pull requests.
9. Update current reference documentation once behavior is implemented.
10. Mark the proposal **Implemented** only after tests, documentation, migration, and required deletion are complete.

WIP numbers and filenames never change. Do not reuse the number of a withdrawn proposal. If a later decision replaces an earlier one, retain both files and connect them through the `Supersedes` and `Superseded by` fields.

`Depends on` lists hard implementation prerequisites, not every related proposal. Put non-blocking relationships in References. Status records decision maturity, not implementation priority.

## Design expectations

Wheeler proposals should:

- define observable semantics before selecting an encoding or Java API;
- identify one authoritative owner for each piece of mutable state;
- distinguish logically reversible operations from operations made reversible by retained history;
- state what happens at measurements, I/O, exceptions, allocation, thread interaction, and other irreversible boundaries;
- specify scheduler and replay determinism when concurrency is affected;
- define malformed-input behavior, resource bounds, and history exhaustion;
- describe bytecode and persisted-state compatibility when representation changes;
- separate classical reversible semantics, quantum semantics, and proof claims rather than treating them as interchangeable;
- include executable laws or conformance fixtures for important invariants;
- name obsolete code, formats, and compatibility paths that will be removed.

Use “Not applicable” with a reason for unaffected template sections. Split work that can be accepted, implemented, or rolled back independently. Exact API reference belongs in the manual after implementation; task-level planning belongs in issues.

## Initial sequence

The first proposals deliberately establish semantics before broad language implementation:

1. **Make the reversible core executable.** WIP-0001 defines the artifact, verifier, machine state, instruction reversal, bounded history, and a bytecode-to-VM acceptance path.
2. **Unify classical and quantum programming.** WIP-0002 lets a coherently eligible `rev` function execute as classical bytecode or lower to a unitary operation, while keeping preparation and measurement explicit.
3. **Run on real targets without making one provider the language.** WIP-0003 defines capability-based targets, a semantic simulator, and a Qiskit-compatible adapter for current systems.
4. **Make hybrid execution durable and honest about irreversibility.** WIP-0004 defines asynchronous jobs, continuations, result provenance, rollback, replay, retry, and history horizons.

Deterministic shared-memory concurrency and a trusted proof/certificate system should be proposed after these contracts are stable. They depend on the state, effect, quantum-resource, and history definitions rather than defining competing versions of them.

## Proposals

| WIP | Status | Decision | Area |
| --- | --- | --- | --- |
| [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md) | Draft | Reversible bytecode and machine-state contract | VM, bytecode, artifacts, history |
| [WIP-0002](WIP-0002-unified-classical-quantum-semantics.md) | Draft | Unified classical and quantum semantics | Language, hybrid execution, quantum IR |
| [WIP-0003](WIP-0003-quantum-target-and-qiskit-backend.md) | Draft | Quantum target contract and Qiskit-compatible backend | Targets, Qiskit, simulators, hardware |
| [WIP-0004](WIP-0004-hybrid-jobs-history-and-replay.md) | Draft | Hybrid jobs, history, and replay | Runtime, jobs, transactions, replay |
