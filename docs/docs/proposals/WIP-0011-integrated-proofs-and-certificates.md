# WIP-0011: Integrated proofs and certificates

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler language, type-system, proof, compiler, bytecode, and tooling maintainers |
| Created | 2026-07-17 |
| Updated | 2026-07-17 |
| Area | Language, proofs, contracts, certificates, trusted kernel |
| Depends on | WIP-0001, WIP-0002, WIP-0005, WIP-0007 |
| Supersedes | None |
| Superseded by | None |

## Summary

Proofs are a Wheeler language feature. Contracts attach to ordinary, reversible, coherent, unitary, and hybrid declarations; theorem declarations inhabit the same module and type system as executable code; proof blocks use structured, source-located syntax checked by a small deterministic kernel. Tree-sitter, package metadata, bytecode, diagnostics, documentation, and editor tooling expose the same proof structure.

Proof text is not a comment, free-form `because` string, provider assertion, or host-language annotation. Propositions refer to Wheeler's reversible typed IR relations—forward transition, exact inverse, logged rewind boundary, coherent permutation, unitary adjoint, measurement/workflow transition—not an optimizing host IR or provider circuit. A successful theorem produces a bounded canonical certificate tied to exact declarations, semantic region identities, type/effect assumptions, and compiler profile. Consumers may verify that certificate without rerunning a solver or trusting the compiler that produced it.

Wheeler distinguishes mathematical claims from empirical evidence. A unitary, inverse, ownership, totality, or resource theorem is checked against formal semantics. A sampled hardware statement is an `experiment` with target, calibration, estimator, shots, uncertainty, and confidence provenance; it cannot satisfy a theorem requiring universal or exact evidence.

## Motivation

Reversibility and quantum computation carry proof obligations in ordinary programming:

- a generated inverse must restore owned state under its preconditions;
- coherent lifting must denote an exact finite permutation;
- ancillas must return to declared clean values;
- a unitary method and its generated adjoint must compose to identity;
- optimizer and compiler rewrites must preserve a semantic region;
- target plans must satisfy qubit, depth, error, event, and retry bounds;
- affine quantum resources must not be cloned, leaked, or used after measurement;
- replay must reproduce classical reduction without claiming to reconstruct quantum state.

Leaving these claims in prose prevents the compiler and package system from checking them. Building a separate proof language duplicates names, types, modules, source maps, effects, and quantum semantics. Integrating proof syntax lets executable declarations and claims evolve under one resolver and one compatibility model.

The trusted base must remain small. Elaborators, automation, SMT integrations, and circuit simplifiers may search for proofs, but only a bounded kernel validates canonical proof terms.

## Goals

- Add contracts, theorem declarations, proof values, and structured proof blocks to Wheeler syntax.
- Resolve proof references through ordinary packages, modules, visibility, and overload rules.
- Reuse Wheeler types, effects, ownership, reversible semantics, quantum region IR, and source locations.
- Check generated inverse, coherent eligibility, clean ancilla, unitary, equivalence, and resource claims.
- Emit canonical independently checkable certificates tied to exact artifact identities.
- Keep the trusted proof kernel small enough to implement, audit, self-host, and ship in the recovery graph.
- Support deterministic bounded automation without making solver behavior part of theorem validity.
- Represent empirical quantum evidence without conflating it with formal proof.
- Give editors stable syntax nodes, highlighting, folding, navigation, hover, and diagnostics for proofs.

## Non-goals

- Accept natural-language justifications as proof terms.
- Treat passing tests, simulation, or hardware samples as universal theorems.
- Embed unrestricted Lean, Coq, Isabelle, SMT-LIB, Python, or Java objects in Wheeler source or `.wbc`.
- Make theorem checking depend on network access, provider credentials, wall-clock time, random search, or mutable solver versions.
- Prove arbitrary real-number equalities by floating-point evaluation.
- Require every program to prove every useful property before it can execute.
- Hide an unsafe axiom behind a compiler optimization or target adapter.

## Source model

Proof syntax is part of the ordinary grammar. The exact spelling remains subject to parser implementation, but the language model has four integrated forms.

### Contracts

A declaration may state preconditions, postconditions, frame conditions, effects, resource bounds, and loop invariants:

```java
rev long increment(long value)
  requires value < Long.MAX_VALUE
  ensures result == old(value) + 1
  ensures inverse(result) == old(value)
  modifies nothing
{
  return value + 1;
}
```

`old(expression)` names the value at the declaration boundary selected by the contract. It is not VM history access. `result` has the declaration's return type. `modifies` names owned mutable locations or `nothing`; effects and quantum resource transitions are also available as typed contract terms.

A `rev` contract is checked in both directions. Forward preconditions become obligations for callers. The generated inverse receives the mechanically derived inverse relation plus any explicit inverse-side conditions.

### Theorems

A theorem is a declaration with typed parameters, proposition result, visibility, and optional generic or finite-domain bounds:

```java
theorem qftRoundTrip(qreg_shape shape)
  requires shape.qubits > 0
  shows adjoint(qft(shape)) >> qft(shape) == identity(shape)
{
  proof {
    ...
  }
}
```

The theorem body cannot perform ordinary I/O, target submission, measurement, mutable allocation outside proof arenas, clock access, randomness, or undeclared effects. It elaborates to a proof term checked by the kernel.

WIP-0028 exposes ownership, lifetime, and frame propositions without allowing proofs to bypass verifier safety. WIP-0029 generic theorems quantify over kinded parameters; WIP-0030 class laws and associated reductions name exact coherent evidence; WIP-0031 certificates bind effect rows, inverse/adjoint characteristics, and specialization-commutation claims. Safety-critical classes such as coherent basis, permutation, and unitary evidence require compiler- or kernel-admitted certificates; an ordinary instance declaration cannot notarize itself.

### Proof blocks

Proof blocks contain a small structured statement set:

- `let` binds a typed term;
- `have name: proposition by proof;` establishes an intermediate fact;
- `show proposition;` selects the current goal;
- `apply theorem(arguments);` applies a checked theorem;
- `rewrite theorem(arguments);` rewrites through proved equality;
- `calc { term == term by proof; ... }` chains typed relations;
- `cases value { ... }` eliminates a tagged variant or finite proposition;
- `induction value invariant proposition { ... }` applies an accepted induction principle;
- `exact proofValue;` closes the goal with an explicit term;
- `qed;` closes a goal only when no obligations remain.

Every construct has a concrete syntax node and elaboration rule. There is no `because "free-form explanation"` escape hatch.

### Proof values

Proofs may be passed, returned, stored in immutable package metadata, or erased after certificate emission according to type and visibility. A proposition `P` has proof type `Proof<P>`. Runtime code cannot forge that value from bytes; certificate decoding invokes the kernel.

Proof irrelevance applies to semantic equality unless a declaration explicitly processes certificate metadata. Two valid proofs of the same proposition do not make executable values unequal.

## Proposition language

The first proposition profile includes:

- typed equality and inequality;
- Boolean connectives and implication;
- bounded universal and existential quantification;
- algebraic data constructors and exhaustive cases;
- finite integer and bit-vector arithmetic;
- sequence length, indexing bounds, permutation, and multiset relations;
- ownership, disjointness, move, borrow, consumed, and clean-resource predicates;
- declaration effects and frame conditions;
- function composition, identity, inverse, and involution;
- quantum region composition, adjoint, unitary, global-phase equivalence, and clean ancillas;
- measurement result schema and probability-distribution relations where exact finite semantics exist;
- qubit, ancilla, gate, depth, measurement, target-cycle, history, event, memory, stack, and retry bounds;
- canonical artifact, package, module, declaration, region, target-plan, and compiler identities.

Unbounded integer, rational, algebraic, complex, or real reasoning is added only with canonical term encodings and kernel rules. Floating-point values obey their executable finite semantics; a proof cannot silently reinterpret them as mathematical reals.

## Effects and totality

A proof declaration is deterministic and total under declared bounds. The checker verifies termination through one of:

- structural recursion on a finite value;
- a decreasing well-founded measure;
- a statically bounded loop;
- application of an accepted total theorem.

Proof elaboration may allocate in a bounded private arena and emit diagnostics. Those implementation effects do not enter theorem terms. Kernel checking has explicit term-node, recursion-depth, rewrite-step, memory-byte, and elapsed-policy ceilings.

An exhausted automation budget means “proof not established,” not false. A certificate that already exists is checked under kernel limits independent of the search process that found it.

## Reversibility claims

The compiler generates a proof obligation for each `rev` declaration:

```text
forall owned input satisfying precondition:
  inverse(forward(input)) == input
  and forward(inverse(output)) == output
```

The exact relation includes modified state, returned values, traps excluded by preconditions, and frame conditions. Logged or barrier effects prevent an intrinsic inverse theorem unless the proposition explicitly models retained history or effect contracts.

Generated-inverse bytecode can discharge local opcode laws compositionally. Loops, allocation, aliasing, and calls require corresponding invariants and callee certificates. Testing an inverse over sample values remains a test, not this theorem.

VM rewind has a separate transition theorem over `StepRecord`; it is not used to prove a language-level inverse.

## Quantum claims

Quantum proof terms refer to canonical semantic region IR, not OpenQASM text, Qiskit objects, native gate schedules, or provider display circuits.

The initial exact quantum rules cover:

- semantic gates and their adjoints;
- composition and tensor product;
- permutation matrices from coherent finite functions;
- generated circuit adjoints;
- basis-state action;
- finite exact amplitudes where the scalar profile supports them;
- equality up to declared global phase;
- ancilla preparation and clean return;
- no-cloning and affine ownership transitions.

A theorem about ideal region unitarity survives target lowering only as an ideal semantic claim. A theorem about a physical implementation additionally needs a verified lowering certificate and a formal target model. Calibration samples cannot turn an ideal theorem into a physical guarantee.

Measurement changes the proposition domain. Post-measurement claims describe distributions, typed outcomes, ownership transitions, and classical continuation state. They do not assert an inverse collapse.

## Experiments and empirical claims

Empirical evidence uses an integrated but distinct declaration:

```java
experiment bellCorrelation(Target target)
  requires target supports STATIC_CIRCUIT
  estimates correlation(q[0], q[1])
  confidence 0.99
  shots 4096
{
  ...
}
```

An experiment result records semantic region, target descriptor, lowering policy, calibration identity when supplied, job lineage, estimator, shots, uncertainty, confidence method, and bounded diagnostics. Replay can reproduce downstream classical decisions from recorded evidence; fresh execution creates new evidence.

An experiment may discharge a proposition explicitly typed as empirical, such as a confidence interval under named assumptions. It cannot inhabit `Proof<Unitary<R>>`, exact equality, or a universal theorem.

## Contracts on hybrid code

Hybrid declarations may state event and continuation properties:

- accepted result applies at most once;
- replay performs no target submission;
- retry creates a fresh lineage;
- discarded branches cannot mutate active state;
- commit advances the history horizon;
- result schema and target identity match the continuation;
- event, shot, cost, and retry limits hold.

These theorems range over the deterministic event reducer and abstract target lifecycle. Provider cancellation success is not assumed unless the target model supplies that premise.

Transaction contracts identify reversible, prepared-external, observed, and committed phases. A post-observation abort theorem may prove classical checkpoint restoration and branch discard; it cannot claim physical quantum-state restoration.

## Proof elaboration and kernel

Proof processing has two trust layers.

The **elaborator** resolves names, infers omitted arguments, expands notation, runs bounded tactics, invokes optional external search tools, and emits a fully explicit canonical proof term. Elaborator defects may reject valid programs or produce bad terms, but cannot make a bad term pass the kernel.

The **kernel** checks:

- canonical term decoding;
- declaration, type, effect, and identity references;
- variable scope and substitution;
- proposition formation;
- introduction and elimination rules;
- equality and rewrite rules;
- accepted arithmetic and finite-domain decision procedures;
- recursion and induction principles;
- quantum semantic primitives;
- resource-bound composition;
- absence of undeclared axioms.

The kernel does not search. It is deterministic, bounded, and implemented in Wheeler under the self-hosting plan. A minimal independent checker remains part of certificate conformance and diverse bootstrap work.

## Axioms and assumptions

Wheeler has no implicit user-defined axiom syntax. Trusted axioms are versioned kernel primitives or packages explicitly marked as assumption providers by host policy. A theorem certificate records the transitive set of axioms and assumptions it uses.

Package policy may reject certificates using unsafe assumptions, classical choice, unverified arithmetic oracles, external solver attestations, target noise models, or experimental premises.

`assume` is permitted only inside an `experiment`, a theorem parameter, or a declaration explicitly producing a conditional theorem. It creates a visible premise; it never closes a goal silently.

## Modules and APIs

Theorems, propositions, proof-producing functions, and contracts use normal package/module visibility. Public declaration identity includes observable contracts and theorem signatures. Strengthening a postcondition may be compatible; strengthening a required precondition is not silently compatible.

Imports can select executable and proof namespaces without duplicating declaration identity. Cyclic theorem dependencies are rejected unless accepted mutual induction rules apply.

Documentation renders contracts next to declarations, theorem statements with assumption sets, and certificate status. Source navigation moves between an executable declaration, generated obligations, proofs, and uses.

## Bytecode and certificates

`.wbc` gains versioned proof metadata sections only through an accepted bytecode extension. Canonical records include:

- proposition and proof-term tables;
- contracts attached to declaration identities;
- theorem signatures and visibility;
- explicit proof terms or content-addressed certificate attachments;
- used axiom and assumption sets;
- kernel, scalar, arithmetic, quantum-semantics, and resource-model profile identities;
- optional source maps with no semantic authority.

Executable loading may omit proof payloads when policy does not require them, but cannot claim a proof was checked without a verified certificate identity. Optimizers using proof-directed transformations retain the exact input theorem and transformation certificate identities.

Unknown required proof records fail closed. Certificate compression is bounded and does not alter canonical uncompressed identity.

## Diagnostics and tooling

Proof diagnostics report source goal, local hypotheses, expected proposition, actual proof type, failed kernel rule, and bounded context. They do not dump unbounded terms or solver logs.

Tree-sitter supplies nodes and queries for contracts, theorem headers, proposition expressions, proof blocks, proof statements, and experiment declarations. Editors can fold proof bodies, highlight goals and declarations, navigate theorem references, and show checked, stale, missing, or assumption-bearing status.

Formatting is deterministic and preserves structured proof layout. Renaming uses semantic identities and updates proof references with ordinary code.

## Concurrency and determinism

Independent proof elaboration may run concurrently, but certificate bytes and diagnostics are reduced in canonical declaration order. Solver response order, hash iteration, task scheduling, wall-clock timing, and cache location cannot affect theorem identity.

Proof caches key exact source declaration, imported API, semantic IR, elaborator profile, kernel profile, and options. Every cache hit is kernel-checked or covered by a verified content identity under package policy.

## Safety and limits

Source and certificate limits include proposition depth, quantified domain size, proof nodes, local hypotheses, rewrite steps, normalization fuel, recursion depth, arithmetic term width, matrix dimension, qubit count, resource-polynomial size, diagnostics, attachment bytes, and total kernel memory.

Decoders reject cycles where acyclic terms are required, invalid de Bruijn or symbol references, duplicate records, noncanonical terms, forged identities, unknown rules, profile mismatch, excessive expansion, and trailing payload.

Kernel failure cannot produce an executable artifact marked as proved. Policy decides whether an unproved optional theorem blocks ordinary compilation; required contracts and transformation certificates always block their dependent operation.

## I/O receipts and conditional proofs

WIP-0032 receipt-chain, range-disjointness, graph-ordering, idempotency-key, operation-lifecycle, and backend-profile obligations may be WIP-0011 proof subjects. The kernel can prove that accepted evidence satisfies a declared rule; it cannot prove that an unmodeled device actually persisted bytes, that a network peer acted, or that a replica survived a failure nobody modeled.

Durability theorems therefore bind the exact protected subject, failure model, operation, backend/profile evidence, assumptions, and receipt chain. A proof cannot cast `WriteCompleted` into `DataStable` or empirical provider output into theorem authority.

## Application fixtures

The integrated proof profile is driven by executable applications:

- `InverseLaw.w`: generated inverse and frame-condition obligations;
- `QFTProof.w`: unitary and adjoint round trip;
- `CircuitEquivalence.w`: source and normalized circuit equality up to global phase;
- `ResourceBound.w`: qubit, ancilla, gate, depth, event, and retry ceilings;
- `PackageProvenance.w`: archive and build-plan identity;
- `Teleportation.w`: ownership and post-measurement correction contract;
- `ErrorCorrectionCycle.w`: target-resident effect and resource report;
- self-hosting compiler passes: certificate-backed normalization and bytecode verification laws.

Each fixture first lands as an executable law if necessary, then gains a formal theorem without changing the executable semantics it claims.

## Migration and deletion

1. Specify proposition AST, proof term, kernel rules, identities, and limits independently of surface tactics.
2. Add contracts and theorem headers to the parser, resolver, type checker, Tree-sitter grammar, and documentation renderer.
3. Implement a small kernel for equality, finite logic, bit vectors, records, variants, and bounded induction.
4. Generate and check inverse obligations for straight-line `rev` functions.
5. Add semantic quantum gate, composition, adjoint, global-phase, and ancilla rules.
6. Add structured proof blocks and deterministic elaboration.
7. Add canonical `.wbc` certificate sections and independent decoding tests.
8. Upgrade QFT, circuit normalization, resource, and package fixtures.
9. Implement the kernel and elaborator in Wheeler and include them in self-host and package recovery checks.
10. Delete any ad hoc proof parser, free-form justification field, unchecked optimization assertion, or duplicate external claim schema.

## Progress

- [x] Canonical function, inverse, quantum region, workflow, package-plan, and event identities provide proof subjects.
- [x] Executable inverse and adjoint laws exist as test fixtures.
- [ ] Proposition and proof-term schemas are accepted.
- [ ] Contract and theorem syntax parses and resolves.
- [ ] Finite classical proof kernel checks canonical terms.
- [x] Explicit generated-inverse theorems over straight-line reversible functions emit canonical certificates checked independently from compiler lowering.
- [x] The Wheeler-written bounded compiler slice parses an optional inverse theorem, derives its fifth sorted string and seventh section, emits the 28-byte `GENERATED_INVERSE` payload, verifies the profile in Wheeler, and produces bytes accepted by the independent proof kernel. This is certificate emission, not the full Wheeler kernel sneaking in through the kitchen window.
- [ ] The finite kernel checks exact QFT adjoint involution and same-register adjacent-inverse rewrite certificates; semantic composition, general rewrite equivalence, scalar normalization, and global-phase rules remain.
- [ ] Straight-line function step-bound certificates are checked against exact instruction bodies and the program ceiling; composition, loops, recursion, circuits, workflows, and target-plan resource bounds remain.
- [ ] Experiment declarations integrate with hybrid provenance without inhabiting theorem types.
- [ ] Wheeler-written kernel and elaborator bootstrap reproducibly.
- [ ] Package and editor tooling expose proof APIs and status.

## Testing and acceptance

- [ ] Parser and Tree-sitter corpora cover the initial inverse, adjoint, circuit-equivalence, and static-step-bound theorem forms; contracts, general propositions, proof blocks, and experiments remain.
- [ ] Negative syntax and type tests reject free-form justification, unresolved theorem names, malformed goals, effectful proofs, and invalid `old` or `result` use.
- [ ] Kernel malformed-input corpus rejects forged, cyclic, noncanonical, stale, oversized, and unknown-rule certificates.
- [ ] An independent checker agrees with the Wheeler kernel on the canonical certificate corpus.
- [x] Generated-inverse certificates reconstruct the straight-line intrinsic subset and reject nonreversible subjects, unsupported/logged/barrier operations, changed inverse bodies, unknown rules, and malformed metadata.
- [ ] Coherent certificates prove exact finite permutation and reject nonunitary or hidden-measurement bodies.
- [ ] QFT carries a generated-adjoint structural certificate and an executable round-trip law; a kernel theorem for semantic composition to identity within an exact scalar profile remains.
- [x] Circuit rewrite certificates accept deterministic adjacent-inverse cancellation and reject a deliberately changed gate.
- [ ] Static step certificates reject a false bound and bind the exact function ID/body; region, target-plan, compiler-profile, and compositional bound identities remain.
- [ ] Sampled experiment evidence cannot type-check where an exact theorem proof is required.
- [ ] Replay preserves empirical downstream decisions without changing experiment evidence into formal proof.
- [ ] Proof output and diagnostics are deterministic under task, map, solver, and cache-order variation.
- [ ] Kernel limits fail closed without partially proved artifacts.
- [ ] Self-hosted stages produce byte-identical proof metadata and verify their own required compiler certificates.
- [ ] `wheeler` packages, locks, verifies, documents, and publishes proof-bearing APIs without hidden host tools.

## Alternatives

### Keep proofs in comments or documentation

Rejected. They cannot participate in type checking, optimization, package APIs, independent verification, or stale-identity detection.

### Use free-form tactic scripts as certificates

Rejected. Search scripts are not stable evidence and require trusting tactic implementations. Wheeler stores explicit kernel-checkable terms.

### Delegate theorem validity to an SMT solver

Rejected as the trust boundary. Solvers may search or emit certificates, but deterministic kernel checking establishes validity.

### Use a separate proof language

Rejected. It duplicates Wheeler names, modules, types, effects, ownership, regions, source maps, packages, and tooling, and permits the two semantic models to drift.

### Treat simulation as proof

Rejected. Simulation can establish exact finite cases under its model or provide empirical evidence; it does not imply a universal theorem or physical hardware guarantee.

## Open questions

- Which minimal dependent or indexed type features are required for useful resource and quantum-shape propositions? — **Owner:** type-system and proof maintainers — **Decide by:** before proposition schema acceptance
- Which exact scalar representation should support finite quantum certificates without trusting floating-point approximations? — **Owner:** quantum and proof maintainers — **Decide by:** before QFT certificate implementation
- Which proof terms remain inline in `.wbc` and which use content-addressed package attachments? — **Owner:** bytecode and package maintainers — **Decide by:** before certificate section acceptance
- Which automation tools belong in the recovery graph while keeping the kernel small? — **Owner:** bootstrap and proof maintainers — **Decide by:** before self-hosted elaboration

## References

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0002](WIP-0002-unified-classical-quantum-semantics.md)
- [WIP-0004](WIP-0004-hybrid-jobs-history-and-replay.md)
- [WIP-0005](WIP-0005-wheeler-source-language.md)
- [WIP-0006](WIP-0006-concrete-syntax-tooling-and-teaching.md)
- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0010](WIP-0010-executable-application-portfolio.md)
- [WIP-0012](WIP-0012-wheeler-standard-library.md)
- [WIP-0028](WIP-0028-deterministic-ownership-borrowing-and-regions.md)
- [WIP-0029](WIP-0029-parametric-polymorphism-and-bounded-specialization.md)
- [WIP-0030](WIP-0030-coherent-type-classes-and-associated-types.md)
- [WIP-0031](WIP-0031-reversible-quantum-and-effect-polymorphism.md)
- [WIP-0032](WIP-0032-unified-io-fabric-and-durability-receipts.md)
