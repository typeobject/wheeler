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

## Proposals

| WIP | Status | Decision | Area |
| --- | --- | --- | --- |
| [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md) | Implementing | Reversible bytecode and machine-state contract | VM, bytecode, artifacts, history |
| [WIP-0002](WIP-0002-unified-classical-quantum-semantics.md) | Implementing | Unified classical and quantum semantics | Language, hybrid execution, quantum IR |
| [WIP-0003](WIP-0003-quantum-target-and-qiskit-backend.md) | Implementing | Quantum target contract and OpenQASM interoperability | Targets, OpenQASM, simulators, hardware |
| [WIP-0004](WIP-0004-hybrid-jobs-history-and-replay.md) | Implementing | Hybrid jobs, history, and replay | Runtime, jobs, transactions, replay |
| [WIP-0005](WIP-0005-wheeler-source-language.md) | Implementing | Wheeler source language profile | Language, compiler, ergonomics |
| [WIP-0006](WIP-0006-concrete-syntax-tooling-and-teaching.md) | Implementing | Concrete syntax, editor tooling, and teaching profile | Parser, Tree-sitter, documentation |
| [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md) | Draft | Self-hosting compiler and reproducible bootstrap | Compiler, language, trust chain |
| [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md) | Draft | Java-free runtime and native bootstrap | Runtime, native code, distribution |
| [WIP-0009](WIP-0009-wheeler-package-and-build-system.md) | Implementing | Wheeler package and build system | Packages, builds, registry, tooling |
| [WIP-0010](WIP-0010-executable-application-portfolio.md) | Draft | Executable application portfolio | Examples, conformance, applications |
| [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md) | Draft | Integrated proofs and certificates | Language, proofs, trusted kernel |
| [WIP-0012](WIP-0012-wheeler-standard-library.md) | Draft | Wheeler standard library | Types, collections, quantum resources |
| [WIP-0013](WIP-0013-typed-frames-control-flow-and-storage.md) | Implementing | Typed frames, control flow, and bounded storage | Types, VM, storage, bootstrap |
| [WIP-0014](WIP-0014-bounded-certified-program-synthesis.md) | Draft | Bounded certified program synthesis | Finite types, synthesis, quantum search, proofs, packages |
| [WIP-0015](WIP-0015-certified-adversarial-schedule-exploration.md) | Draft | Certified adversarial schedule exploration | Protocol models, concurrency, replay, proofs |
| [WIP-0016](WIP-0016-nonconfigurable-source-formatter.md) | Draft | One nonconfigurable source formatter with documentation enforcement | Source formatting, documentation, editor and build tooling |
| [WIP-0017](WIP-0017-compile-time-constants-and-finite-enums.md) | Implementing | Compile-time constants and finite enums | Named values, finite types, reversible and coherent semantics |
| [WIP-0018](WIP-0018-integrated-deterministic-testing.md) | Draft | Integrated deterministic testing | Test declarations, runners, fixtures, replay, quantum and proof assertions |
| [WIP-0019](WIP-0019-integrated-documentation-publication.md) | Draft | Integrated documentation publication | Wheeler API docs, Markdown, Javadoc, Docusaurus, links and search |
