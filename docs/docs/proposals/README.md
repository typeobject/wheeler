---
slug: /proposals/
sidebar_position: 1
---

# Wheeler Improvement Proposals

A Wheeler Improvement Proposal, or WIP, records a decision that is too large for an issue or pull request. It explains the problem, sets the rules, assigns ownership, chooses a design, and says how the work will be tested and adopted.

WIPs are Wheeler's long-term decision record; a `WIP-NNNN` number identifies a proposal. It does not mean the work is currently underway. Proposals may describe planned, accepted, or active work. Guides and reference pages describe features that work today, so they must not present an unfinished WIP as current behavior.

## When to write a WIP

Write a WIP for a change to:

- source syntax, types, proof rules, or visible behavior;
- reversibility, retained history, uncomputation, or irreversible effects;
- the VM instruction set, memory model, scheduler, concurrency, transactions, or synchronization;
- bytecode containers, loaders, verification, versioning, or compatibility;
- quantum state, gates, measurement, simulation, or hardware backends;
- the trusted computing base for proofs or program checks;
- ownership shared by the compiler, runtime, tools, or modules;
- determinism, limits, safety, security, diagnostics, or failure behavior;
- a compatibility removal or migration that crosses several modules or tools.

A local refactor, small bug fix, test, documentation correction, or private optimization does not need a WIP. Write one only when the change affects one of these contracts.

## Statuses

| Status | Meaning |
| --- | --- |
| Draft | The author is still shaping the problem and design. |
| Review | The proposal is ready for review of its meaning, implementation, and migration. |
| Accepted | Maintainers approved the decision, but implementation has not started. |
| Implementing | Work is underway, and the progress checklist must stay current. |
| Implemented | Tests, documentation, migration, and required deletion are complete. |
| Superseded | A later WIP replaces all or part of this decision. |
| Withdrawn | The proposal will not move forward. |

Only maintainers may change a WIP to **Accepted**, **Implemented**, **Superseded**, or **Withdrawn**. A major change to the meaning or architecture sends an accepted proposal back to **Review**.

## How to create a proposal

1. Copy [the template](TEMPLATE.md) to `WIP-NNNN-short-title.md`; use the next unused four-digit number.
2. Fill in every metadata field, including owners, dates, and dependencies.
3. Write the summary, motivation, and use cases before choosing opcodes, classes, or APIs.
4. Define the semantic model and its invariants. When state can change, explain forward and reverse behavior.
5. Keep the proposal focused on one main decision with an acceptance suite that can finish on its own.
6. Change the status to **Review** and ask each affected owner for feedback.
7. Resolve every open question, or give it an owner and decision date.
8. After acceptance, implement the design in reviewable stages. Update the progress checklist in the same pull requests.
9. Update the current reference docs after the feature works.
10. Mark the proposal **Implemented** only when tests, docs, migration, and required deletion are done.

Once a proposal leaves **Draft**, its number and filename stay fixed. A Draft may be renamed or split before review when its scope is wrong. Update every link in the same change, do not reuse another proposal's number, and do not leave a redirect file that creates two sources of truth. Git keeps the old history. Never reuse the number of a withdrawn proposal. When a later decision replaces a reviewed proposal, keep both files and connect them through `Supersedes` and `Superseded by`.

`Depends on` lists hard implementation requirements. Put related but nonblocking work in References. Status shows how mature the decision is, not how urgent the work is.

## Design expectations

A Wheeler proposal should:

- define visible behavior before choosing an encoding or Java API;
- name one owner for each piece of mutable state;
- separate operations that are truly reversible from operations that need saved history;
- explain measurement, I/O, exceptions, allocation, thread interaction, and other irreversible boundaries;
- define scheduling and replay order when concurrency changes;
- cover malformed input, resource limits, and history exhaustion;
- explain bytecode and stored-state compatibility when a representation changes;
- keep classical reversal, quantum behavior, and proof claims separate;
- include executable laws or conformance fixtures for important rules;
- name obsolete code, formats, and compatibility paths that must be removed.

Write "Not applicable" and give a reason for sections that do not apply. Split work that can be accepted, implemented, or rolled back alone. Put final API reference in the manual after implementation. Keep task planning in issues.

## Cross-proposal IR invariant

Every WIP must preserve one Wheeler intermediate-language model. Canonical `.wbc` 1.0 is the only semantic artifact. It contains the closed typed IR needed by the selected target: classical register and region bodies, reversible relations and inverse bodies, ordered hybrid workflows, backend-neutral quantum regions, effects, ownership, proofs, and bounds.

WIP-0029 may add non-executable generic typed bodies as a versioned library section inside `.wbc`. Those bodies do not create a separate source-template or host-object authority.

"Reversible IR" does not mean every operation is bijective. Each operation declares one explicit relation:

- an intrinsic or checked inverse for information-preserving classical work;
- bounded logged history for destructive work that supports VM rewind but has no intrinsic inverse;
- an explicit barrier for irreversible host observation;
- an exact finite permutation for coherent classical lifting;
- an adjoint-bearing semantic region for unitary quantum work;
- an explicit measurement, reset, target, or workflow transition when information crosses domains.

Source syntax, generic specialization, class evidence, tests, proofs, packages, native lowering, and documentation must keep those differences. No WIP may treat rewind as inverse, replay as physical reversal, compensation as uncomputation, a provider circuit as semantic IR, or an unchecked annotation as proof. Host ASTs, JVM bytecode, LLVM IR, native objects, and provider payloads are derived implementation data. Verified Wheeler IR remains authoritative.

## Proposals

| WIP | Status | Decision | Area |
| --- | --- | --- | --- |
| [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md) | Implementing | Reversible bytecode and machine-state contract | VM, bytecode, artifacts, history |
| [WIP-0002](WIP-0002-unified-classical-quantum-semantics.md) | Implementing | Unified classical and quantum semantics | Language, hybrid execution, quantum IR |
| [WIP-0003](WIP-0003-quantum-target-and-qiskit-backend.md) | Implementing | Quantum target contract and OpenQASM interoperability | Targets, OpenQASM, simulators, hardware |
| [WIP-0004](WIP-0004-hybrid-jobs-history-and-replay.md) | Implementing | Hybrid jobs, history, and replay | Runtime, jobs, transactions, replay |
| [WIP-0005](WIP-0005-wheeler-source-language.md) | Implementing | Wheeler source language profile | Language, compiler, ergonomics |
| [WIP-0006](WIP-0006-concrete-syntax-tooling-and-teaching.md) | Implementing | Concrete syntax, editor tooling, and teaching profile | Parser, Tree-sitter, documentation |
| [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md) | Implementing | Self-hosting compiler and reproducible bootstrap | Compiler, language, trust chain |
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
| [WIP-0019](WIP-0019-integrated-documentation-publication.md) | Implementing | Integrated documentation publication | Wheeler API docs, safe static rendering, Javadoc, links and search |
| [WIP-0020](WIP-0020-semantic-coverage-and-evidence-accounting.md) | Draft | Semantic coverage and evidence accounting | Classical, reversible, quantum, workflow and proof coverage |
| [WIP-0021](WIP-0021-uniform-call-and-assertion-syntax.md) | Implementing | Uniform call and assertion syntax | Source syntax, assertions, reversible and quantum evidence, typed test doubles |
| [WIP-0022](WIP-0022-package-instances-and-resolution.md) | Draft | Package instances and deterministic target graphs | Packages, resolver, modules, lockfiles |
| [WIP-0023](WIP-0023-recipe-repositories-and-reproducible-builds.md) | Draft | Recipe repositories and reproducible package revisions | Repositories, revisions, provenance, publication |
| [WIP-0024](WIP-0024-system-package-exports.md) | Draft | Canonical install images and system-package export | Debian, RPM, distribution tooling |
| [WIP-0025](WIP-0025-native-ffi-and-system-integration.md) | Draft | Native ABI descriptors, FFI, and system capabilities | Language, runtime, native ABI, packages |
| [WIP-0026](WIP-0026-self-contained-native-executables.md) | Draft | Self-contained platform-native Wheeler executables | Native images, ELF, Mach-O, PE, embedded WBC |
| [WIP-0028](WIP-0028-deterministic-ownership-borrowing-and-regions.md) | Draft | Deterministic ownership, borrowing, regions, and no implicit tracing GC | Ownership, borrowing, memory, regions, destruction |
| [WIP-0029](WIP-0029-parametric-polymorphism-and-bounded-specialization.md) | Draft | Parametric polymorphism, kinds, const generics, and bounded specialization | Types, generics, kinds, specialization |
| [WIP-0030](WIP-0030-coherent-type-classes-and-associated-types.md) | Draft | Coherent type classes, associated types, instances, and laws | Classes, evidence, laws, packages |
| [WIP-0031](WIP-0031-reversible-quantum-and-effect-polymorphism.md) | Draft | Effect-, reversible-, coherent-, and unitary-polymorphic callables | Effects, callables, reversibility, quantum operations |
| [WIP-0032](WIP-0032-unified-io-fabric-and-durability-receipts.md) | Draft | Unified asynchronous I/O fabric, operation graphs, and durability receipts | I/O, storage, networking, RDMA, durability, quantum workflows |
