# WIP-0014: Bounded certified program synthesis

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler language, synthesis, proof, quantum, runtime, and package maintainers |
| Created | 2026-07-18 |
| Updated | 2026-07-18 |
| Area | Finite types, synthesis, model checking, quantum search, proofs, packages |
| Depends on | WIP-0004, WIP-0007, WIP-0008, WIP-0009, WIP-0010, WIP-0011, WIP-0012, WIP-0013 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler may later support bounded certified program synthesis. The system would search a finite, canonical grammar of Wheeler IR operations for a program that meets a finite mathematical specification. It would then check the program exactly, prove minimality within the chosen grammar and resource metric, and publish proof-carrying source with canonical `.wbc`.

Candidate syntax, search encodings, SAT terms, and provider circuits are derived data. Only independently verified closed IR and kernel evidence may be published as accepted output.

`Foundry.w` is the main application. Its first target is the smallest reversible comparator network, within a stated comparator limit, that sorts eight 4-bit integers while keeping and cleaning an exact inverse witness.

This WIP does not reserve source syntax today. It defines the semantic parts and acceptance rules that a later syntax proposal must satisfy.

## Motivation

Wheeler already has several useful parts for bounded synthesis:

- finite encodings that support exact enumeration and coherent interpretation;
- explicit inverses and uncomputation;
- provider-neutral quantum regions and target capabilities;
- durable replayable workflows;
- a small certificate kernel;
- canonical compiler and package identities.

The synthesis service must not become a second compiler, proof authority, package format, or target API. Search may use heuristics, distributed workers, quantum assistance, or a different algorithm later. Acceptance remains deterministic and content-addressed.

The input is a specification, a candidate grammar, and fixed limits. There's no training dataset, model checkpoint, or sampled correctness standard.

## Goals

- Define finite-domain types with canonical inhabitant encodings and bounded enumeration.
- Define canonical first-class candidate programs independently of source formatting.
- Interpret candidate programs reversibly with explicit clean workspace contracts.
- Permit quantum search to rank or propose candidates without treating samples as proof.
- Check candidate correctness over the complete declared finite domain.
- Check minimality relative to one exact grammar, semantics profile, resource metric, and bound.
- Emit canonical proof terms and independently check them in the Wheeler kernel.
- Publish an ordinary Wheeler package with source, `.wbc`, certificates, and provenance.
- Make cancellation, retry, replay, budget exhaustion, and partial search non-authoritative.

## Non-goals

- Solve unbounded synthesis or evade undecidability.
- Infer a specification from a corpus.
- Treat test coverage, simulation, confidence, or target success as formal correctness.
- Claim global algorithmic minimality outside the declared candidate grammar.
- Add a trusted quantum oracle, solver, proof-search service, or package publisher.
- Hide candidate garbage, execution history, solver assumptions, or target capabilities.
- Promise a hardware date or resource estimate before lowering and certificate formats exist.

## Terms

A **finite type** has a canonical finite inhabitant set, canonical total order, canonical fixed-width or bounded encoding, and checked cardinality.

A **candidate grammar** is a finite typed program language with one canonical encoding per semantic candidate admitted by that grammar. Grammar identity includes instruction semantics, operand domains, normalization rules, program bounds, and resource metric.

A **specification** is a closed proposition over finite inputs and explicit outputs, effects, inverse witnesses, and resource claims.

A **search result** is evidence that identifies candidates worth exact checking. It is not a proof.

A **correctness certificate** proves that one exact candidate satisfies one exact specification under one semantics profile.

A **minimality certificate** proves that no candidate with a strictly smaller declared metric satisfies that specification within the same grammar and bounds.

## Semantic model

### Finite domains

Every quantified type supplies:

- canonical type identity;
- exact cardinality;
- canonical inhabitant encoding and decoding;
- rejection of noncanonical bit patterns;
- deterministic enumeration order;
- bounded equality and hashing;
- no ambient host object or address.

Cardinality arithmetic is checked and bounded. A quantifier whose domain exceeds the selected proof/checking profile is rejected before search.

### Candidate identity

Candidate source text isn't the search identity. A grammar-specific canonical AST or instruction vector is. Equivalent encodings are removed by construction or by a deterministic normalization certificate.

For comparator networks, each instruction names two distinct indices in canonical order. Inactive slots have one required zero encoding. Network length is part of the candidate value. Scheduling symmetries may be normalized only by a checked rule.

### Reversible candidate evaluation

A candidate evaluator receives clean explicit workspace. It may mutate a working input and inverse witness, but must uncompute decoder scratch, temporary execution state, and oracle flags before returning. The Boolean acceptance bit is the only allowed oracle output.

Sorting is not intrinsically reversible. A compare-exchange operation records whether it swapped. Its inverse uses that bit to restore the pair and clears the bit after reconstructing the original predicate. Hidden VM history is not a substitute for this source-level witness.

### Search

Search consumes a finite candidate encoding and an exact predicate. Implementations may use classical enumeration, SAT, SMT, specialized network search, amplitude amplification, or a composition. Search algorithms are outside the trusted computing base.

A quantum execution records semantic-region identity, target descriptor, lowering policy, job lineage, shots, uncertainty, resource use, and durable event history. Measurement yields candidate evidence only.

Absence at a candidate length requires a checked nonexistence certificate. Timeout, cancellation, an empty sample set, or a provider's failure to return a candidate proves nothing.

### Exact checking

The selected candidate is checked again without trusting search evidence. An implementation may use:

- exhaustive reversible evaluation;
- canonical bit-vector evaluation;
- proof-producing SAT/SMT;
- specialized comparator-network lemmas;
- checked combinations of these methods.

All methods elaborate to bounded canonical proof terms. The kernel does not invoke a solver or quantum target.

### Minimality

Minimality is lexicographic only when declared as such. A metric might be comparator count, depth, expensive-gate count, ancilla width, bytecode length, or a canonical tuple. The certificate identifies the metric and proves absence for every strictly smaller metric value admitted by the bounded grammar.

The claim does not extend to another instruction set, arithmetic semantics, width, approximation policy, hidden history allowance, or computational model.

## Syntax requirements

A future syntax proposal must define, instead of only illustrate:

- `type`, finite-width integer, finite array, and index declarations;
- generic and dependent bounds;
- `borrow`, `inout`, move, and lifetime behavior;
- `requires`, `ensures`, `old`, invariants, and resource clauses;
- first-class specifications, propositions, proof values, and proof blocks;
- `forall finite` and `exists finite` elaboration;
- coherent lambdas and reversible candidate interpretation;
- synthesis and experiment declarations;
- effect and capability interfaces;
- durable `record await`, checkpoints, commits, and cancellation;
- generated-source and certificate attachment syntax;
- module/package declarations and visibility.

The [Foundry design page](../future/foundry.md) is syntax input for those proposals. It is not grammar authority.

## Trusted boundary

The trusted path contains only:

1. canonical artifact decoding;
2. ordinary bytecode and ownership verification;
3. finite-type and candidate-grammar identity checks;
4. proof-term decoding and bounded kernel checking;
5. package/archive identity verification.

Quantum targets, model checkers, SAT/SMT solvers, candidate selectors, proof search, source generation, registry transport, and user interfaces are untrusted producers. A defect may lose work or produce a rejected certificate; it cannot establish a false theorem.

## Durable execution

Each search length is a transaction phase. The run records submitted work and evidence, verifies any absence certificate, then commits that length as impossible. Recovery resumes from the latest verified commit.

A candidate found after a crash is rechecked. Replay may reproduce the decision to inspect a recorded candidate but does not resubmit quantum work. Retry creates new job and evidence identities. Cancellation and timeout leave the current length unresolved.

Winning target evidence must be stored outside loop-local scope and tied to the candidate selected from it. Package provenance cannot refer to whichever evidence variable happened to be evaluated last.

## Package output

The generated package contains:

- canonical manifest and module names;
- generated Wheeler source;
- canonical `.wbc` and compiler identity;
- specification and candidate-grammar identities;
- correctness and minimality certificates;
- explicit assumptions and semantics/resource profiles;
- search/model-check provenance and winning evidence identity;
- dependency lock and exact package inputs.

Publication requires an explicit capability and follows WIP-0009 immutability rules. Search credentials, provider objects, local cache paths, and unbounded logs are excluded.

## Determinism and bounds

Every source of work is bounded. Limits cover finite cardinality, candidate bits and length, interpreter steps, workspace words, qubits, gates, shots, job attempts, events, proof nodes, certificate bytes, kernel recursion, package bytes, and total duration.

Parallel or distributed search may finish in any order. Candidate selection reduces results by canonical metric then candidate encoding. Proof diagnostics and package members reduce in canonical order. Scheduling, hash iteration, wall clock, provider queue order, and allocation address cannot change a successful package.

## Failure behavior

The implementation fails closed on:

- noncanonical finite values or candidate encodings;
- cardinality or resource arithmetic overflow;
- dirty oracle workspace;
- candidate interpreter traps;
- stale or mismatched target evidence;
- unknown proof rules or assumptions;
- malformed, oversized, or incomplete certificates;
- a candidate that exact checking rejects;
- an absence proof that the kernel rejects;
- compiler, grammar, specification, or resource identity mismatch;
- package output without authority.

No partial package is published. A failed publication leaves a checked theorem valid and creates no release.

## Implementation order

1. Complete finite widths, bounded arrays, ownership, regions, and deterministic collections.
2. Complete module linking, package APIs, and Wheeler-native execution.
3. Complete proposition/proof-term schemas and the finite proof kernel.
4. Add canonical finite-type enumeration and proof rules.
5. Add first-class canonical candidate grammars and a classical reversible interpreter.
6. Build a tiny exhaustive synthesis fixture without quantum search.
7. Add proof-producing correctness and bounded minimality certificates.
8. Add durable candidate-search workflows and explicit proof-search capabilities.
9. Add coherent candidate interpretation and quantum-search planning.
10. Add `Foundry.w` only when the ordinary compiler, VM/runtime, targets, kernel, package manager, Tree-sitter grammar, tests, and documentation execute it end to end.

## Progress

- [x] Canonical `.wbc`, reversible execution, rewind, typed finite scalar/aggregate values, bounded control, initial owned regions, durable hybrid runs, finite proof rules, and content-addressed packages provide partial prerequisites.
- [ ] Finite-domain generic types and canonical enumeration are implemented.
- [ ] Candidate grammar values and a reversible interpreter are implemented.
- [ ] General proposition and proof-term schemas are implemented.
- [ ] Proof-producing exhaustive model checking is implemented.
- [ ] Bounded minimality certificates are implemented.
- [ ] Coherent candidate interpretation and amplitude-amplification planning are implemented.
- [ ] Durable synthesis search and absence-proof accumulation are implemented.
- [ ] Generated module/package publication is implemented.
- [ ] `Foundry.w` is an ordinary executable, tested package instead of documentation syntax.

## Testing and acceptance

- [ ] Every finite type round-trips every inhabitant and rejects every noncanonical encoding in its bounded test domain.
- [ ] Candidate encoding has no duplicate semantic networks after declared normalization.
- [ ] Candidate forward/inverse execution restores input, witness, decoder scratch, oracle flags, and workspace exactly.
- [ ] Exhaustive checking rejects a deliberately wrong comparator, omitted comparator, and corrupted trace rule.
- [ ] Correctness certificate rejects one changed instruction, operand, bound, type profile, or specification identity.
- [ ] Minimality certificate rejects one omitted shorter candidate and one changed metric.
- [ ] Empty samples, target timeout, cancellation, and retry never become absence evidence.
- [ ] Replay consumes recorded evidence without a new submission; retry uses a new identity.
- [ ] Classical and quantum-assisted searches select the same canonical winner when both complete under a small conformance bound.
- [ ] Kernel checking is deterministic under proof-search, solver, thread, and declaration order.
- [ ] Generated source compiles to the certified artifact and the package verifies offline from its exact lock/vendor inputs.
- [ ] Publication is immutable, capability-gated, atomic, and leaves no partial release on failure.
- [ ] Resource exhaustion at every layer produces a bounded stable diagnostic.

## Security considerations

Candidate and proof search process adversarial generated data. All decoders are bounded. Solvers and target providers run outside the trusted process or under explicit capabilities. Certificate checking does not execute producer code. Generated source receives no authority by virtue of being generated.

A proof of finite correctness is not a proof that the specification is desirable, the cost model predicts hardware, the package has no side channels outside the modeled effects, or a larger-domain generalization holds.

## Alternatives

### Treat exhaustive tests as a certificate

Rejected. A test transcript is too large and proves canonical coverage only when the checker already trusts its enumeration and reduction. A bounded proof term states the finite reasoning directly.

### Trust the synthesis or quantum service

Rejected. Search is the largest and least deterministic component. It is the wrong trust anchor.

### Publish only generated source

Rejected. Recompilation can change meaning unless compiler, dependencies, profiles, and certificate subjects are fixed. The package carries all of them.

### Claim unrestricted minimality

Rejected. Minimality without a grammar and metric is not a finite proposition.

## Open questions

- Which finite-type primitives keep enumeration, coherent encoding, and kernel terms small (owner: type and proof maintainers; decision point: before finite quantifiers)?
- Which candidate normalization rules are cheap enough to check but strong enough to remove comparator-network symmetries (owner: synthesis maintainers; decision point: before candidate encoding)?
- Which proof-producing engine establishes useful network absence bounds without entering the TCB (owner: proof-search maintainers; decision point: before minimality certificates)?
- Which target capability describes coherent finite model checking without describing it as one hardware instruction (owner: target maintainers; decision point: before quantum search planning)?
- Which resource metric is the first accepted comparator-network minimality claim: comparator count, depth, or lexicographic pair (owner: application maintainers; decision point: before the first Foundry fixture)?

## References

- [Foundry future-system design](../future/foundry.md)
- [WIP-0004](WIP-0004-hybrid-jobs-history-and-replay.md)
- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0010](WIP-0010-executable-application-portfolio.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0012](WIP-0012-wheeler-standard-library.md)
- [WIP-0013](WIP-0013-typed-frames-control-flow-and-storage.md)
