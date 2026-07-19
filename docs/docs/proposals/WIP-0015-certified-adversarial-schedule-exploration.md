# WIP-0015: Certified adversarial schedule exploration

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler concurrency, distributed systems, runtime, quantum, proof, and package maintainers |
| Created | 2026-07-18 |
| Updated | 2026-07-18 |
| Area | Protocol models, finite schedules, reversible exploration, replay, proofs |
| Depends on | WIP-0002, WIP-0004, WIP-0007, WIP-0008, WIP-0009, WIP-0010, WIP-0011, WIP-0012, WIP-0013 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler may eventually explore every execution admitted by a finite distributed-protocol model and bounded fault grammar. `Murphy.w` is the driving application: search schedules in increasing length, replay proposed failures deterministically, prove each accepted counterexample, prove no shorter schedule fails, or return a checked bounded-safety result.

The schedule space is generated from the protocol, initial state, event grammar, and fault budget. Production traffic and logs are optional debugging inputs, not semantic inputs or proof evidence.

This WIP reserves no current syntax. It defines the model and trust boundary required before protocol-artifact, logged-transition, coherent-interpreter, or schedule-proof syntax can be accepted. Modeled transitions must lower to Wheeler's reversible IR with explicit inverse witnesses or logged destruction; external delivery and failure observations remain workflow events rather than magically reversible network packets.

## Motivation

Concurrency defects depend on event order and failure placement. Randomized stress testing can expose them but cannot establish coverage, preserve timing-independent reproducers, or prove bounded absence. Existing model checking addresses much of this problem; Wheeler must not claim novelty for bounded state exploration alone.

The proposed Wheeler integration has narrower value:

- finite protocol and event artifacts have canonical identities;
- every modeled destructive transition carries an explicit inverse witness;
- candidate state can be uncomputed during search;
- target evidence, deterministic replay, and proof are distinct artifacts;
- long-running search uses durable event/recovery semantics;
- counterexamples and certificates ship as ordinary Wheeler packages.

## Goals

- Define canonical finite protocol artifacts and state schemas.
- Define canonical schedule encodings with no duplicate semantic schedule unless an explicit equivalence relation is certified.
- Model delivery, loss, duplication, crash, restart, partition, healing, timeout, and time advance under exact bounds.
- Make enabledness and fault-budget accounting deterministic and checked.
- Reverse model transitions with explicit witnesses rather than whole-cluster snapshots.
- Search schedule lengths in increasing order.
- Replay and normalize every proposed counterexample classically.
- Prove the exact violation and absence of every shorter counterexample.
- Prove bounded safety only with a universal kernel-checked certificate.
- Return `inconclusive` when neither proof is available.
- Publish a portable replay package with exact protocol, state, schedule, trace, bounds, and certificates.

## Non-goals

- Reverse physical failures, network loss, or time.
- Infer a protocol model from logs.
- Treat randomized testing, target samples, confidence, timeout, or search exhaustion as proof.
- Establish unbounded safety or liveness from a finite run.
- Model weak memory, Byzantine faults, real clocks, storage corruption, cryptography, or fairness unless explicitly selected.
- Trust a quantum target, solver, model checker, trace minimizer, or report generator.
- Replace mature classical model checkers without measured benefit.
- Promise useful quantum acceleration before a concrete clean oracle and resource plan exist.

## Terms

A **protocol artifact** is canonical verified Wheeler bytecode plus public state, message, transition, effect, and invariant metadata. It contains no host process, socket, provider object, or credential.

A **cluster state** is a finite value containing every modeled replica, network, timer, logical-clock, and identifier-allocation component.

A **timeline event** is one canonical scheduler or fault action with explicit operands.

A **timeline** is a bounded canonical event vector, declared length, and fault counts derived from its active events.

An event is **enabled** when its preconditions hold in the state immediately before it. Disabled events make an encoding invalid; they are not implicit no-ops.

An **event witness** contains exactly the state needed to reverse one modeled transition.

A **counterexample** is an enabled canonical timeline whose exact replay violates a named safety proposition.

A **minimal counterexample** has a checked failure proof and a checked proof that no shorter admitted timeline fails under the same model.

A **bounded-safety proof** establishes that no admitted timeline through the selected maximum length violates the proposition.

## Model identity

Every investigation identity includes:

- protocol artifact and compiler identities;
- protocol schema and semantics profile;
- initial cluster-state identity;
- event grammar and canonical encoding identity;
- enabledness rules;
- fault-budget type and concrete value;
- message, node, timer, queue, map, and step ceilings;
- arithmetic and overflow semantics;
- safety proposition identity;
- trace-normalization profile;
- proof-kernel profile.

Changing any component creates a different claim. A proof about five crash-stop replicas cannot be relabeled as a proof about seven Byzantine replicas.

## Canonical schedules

A schedule encoding has one declared active prefix. Inactive slots contain one required zero value. Fault counts are computed from active events and must equal any cached count fields. IDs use canonical finite encodings. Partition sides are disjoint and normalized. Time advances are positive and bounded.

Two independent messages may commute. The first profile may retain both orders as distinct schedules. Partial-order reduction enters only with a checked independence relation and a certificate that the removed order cannot change enabledness or the safety result.

Invalid encodings, disabled events, overflowed IDs, exceeded queues, and exhausted fault budgets reject before model mutation or produce a clean false oracle mark according to the declared classifier contract.

## Reversible model transitions

A model transition may wrap an ordinary nonreversible application handler. Its reversibility comes from an explicit event witness:

- delivery retains the removed envelope, previous recipient, emitted envelopes, and previous message-ID cursor;
- drop retains the removed envelope;
- duplication retains the inserted envelope and previous cursor;
- crash moves volatile state into the witness;
- restart retains previous volatile state and all recovery effects;
- partition/heal retains previous network state;
- timeout retains timer, replica, emitted-message, and cursor state;
- time advance retains previous logical time.

The witness belongs to the finite simulation. It does not claim physical rollback. A transition whose inverse requires unbounded or omitted data is outside the profile.

The inverse consumes the witness, restores the exact state, and returns the witness slot to `Clean`. A full timeline inverse traverses witnesses in reverse event order.

## Safety propositions

Safety predicates are total bounded functions over modeled state. They cannot perform I/O, consult wall time, submit jobs, sample randomness, or observe host allocation.

A replicated property must identify its view. “Total money” may mean each replica independently, one committed logical ledger, or a quorum-derived view. Summing replicated copies is not conservation. “Applied at most once” counts externally visible effects under a declared observation model, not how many replicas store an `Applied` marker.

Liveness is separate. A finite schedule cannot establish eventual delivery without a fairness and horizon model.

## Search and shortestness

Search proceeds by timeline length. A target or classical search engine may propose candidate encodings. Every proposal is decoded and replayed by the deterministic checker.

Failure to find a candidate at length `L` does not permit search at `L+1` when shortestness is claimed. Advancement requires a checked certificate that no length-`L` counterexample exists. The accumulated prefix establishes global length minimality for the first accepted counterexample.

Delta debugging may remove events from a known failing timeline, but its result is only locally minimized unless all shorter lengths are proved absent.

Search implementations may use explicit state, symbolic execution, SAT/SMT, dynamic partial-order reduction, protocol lemmas, quantum amplitude amplification, or combinations. None enter the trusted computing base.

## Coherent classification

A coherent classifier:

1. decodes one canonical schedule into clean bounded workspace;
2. records event enabledness reversibly;
3. executes the finite protocol interpreter and witnesses;
4. evaluates one pure safety predicate;
5. toggles or phase-marks one answer bit;
6. reverses timeline execution, enabledness, and decoding;
7. returns all cluster, witness, decoder, map, queue, and predicate workspace clean.

Every protocol operation reachable by the classifier needs exact finite coherent semantics. Host I/O, logged VM history, floating-point nondeterminism, unbounded allocation, dynamic provider calls, and unsupported handler effects reject coherent lowering.

A quantum target returns candidate evidence. It cannot establish absence, minimality, or safety.

## Replay and durable execution

The normalized replay artifact records:

- exact protocol, initial state, event grammar, and budget identities;
- canonical timeline;
- transition trace in event order;
- final safety result and first violating transition when defined;
- checker/compiler identities;
- proof subjects and certificate identities.

Replay never resubmits search. Retry creates a new target job and evidence identity. Search length, accepted absence proofs, candidate evidence, and publication state are durable workflow data. A crash after a length proof resumes at the next length. A crash before commit rechecks the evidence and proof.

Cancellation, timeout, stale target descriptors, and unavailable proof search leave the current length unresolved. They do not become safety evidence.

## Proof obligations

A counterexample certificate proves:

- artifact and initial-state identity;
- canonical timeline and budget compliance;
- enabledness of every event in sequence;
- exact transition reduction;
- the final named safety violation.

A minimality certificate proves absence at every shorter length. A bounded-safety certificate proves absence through the configured maximum.

Proof-producing search may use induction over the transition trace, finite enumeration, bit-vector certificates, SAT resolution, BDD certificates, partial-order lemmas, or protocol invariants. All elaborate to bounded canonical terms checked without invoking the producer.

## Result model

The result is a closed variant:

- `CounterexampleFound(counterexample, failureProof, minimalityProof)`;
- `BoundedSafe(safetyProof)`;
- `Inconclusive(evidence, boundedDiagnostic)`.

No Boolean `safe` result exists without a proof value. Reports must preserve this distinction visually and in machine-readable encoding.

## I/O schedule integration

WIP-0032 owns I/O requests, scopes, operations, cancellation, completion, and receipts. This WIP may explore a finite WIP-0032 model by choosing admitted completion orders, partial progress, cancellation races, credit exhaustion, and uncertainty outcomes; it does not define another scheduler or I/O method family.

A replay package records canonical operation and schedule identities, not payloads or native queue state. A checked schedule can establish behavior of the finite model. It cannot turn simulated persistence into device evidence or infer that a timed-out external effect never occurred.

## Package output

A counterexample replay package contains:

- protocol package and lock identities;
- initial state;
- event/fault profile and concrete budget;
- canonical timeline and normalized trace;
- safety failure and minimality certificates;
- optional human explanation derived from the trace;
- checker and proof-kernel profiles.

A bounded-safe package substitutes the universal certificate. An inconclusive report may include evidence but cannot be imported where `Proof<BoundedSafe>` is required.

Publication is immutable, atomic, capability-gated, and offline-verifiable. Credentials, cloud dashboard URLs, ambient cache paths, and unbounded logs are excluded.

## Determinism and limits

The implementation bounds protocol bytes, nodes, state objects, messages, timers, events, event operands, queue/map capacity, handler steps, emitted messages, fault counts, candidate bits, logical time, search attempts, shots, jobs, durable events, trace bytes, proof nodes, recursion, diagnostics, and package bytes.

Candidate and diagnostic reduction uses timeline length then canonical encoding. Parallel completion, target queue order, hash insertion, solver order, host scheduling, wall clock, and allocation address cannot change a successful result.

## Failure behavior

The system fails closed on:

- malformed or noncanonical protocol/state/schedule data;
- schema, compiler, model, budget, or proposition mismatch;
- disabled event or exceeded bounded collection;
- arithmetic, ID, time, or cardinality overflow;
- incomplete event witness or dirty inverse workspace;
- unsupported coherent effect;
- stale, duplicated, or mismatched search evidence;
- replay disagreement;
- rejected proof term;
- missing shorter-length certificate;
- unauthorized or partial publication.

A failed transition traps before partial model mutation. A failed investigation produces no false safe result and no partial release.

## Security considerations

The interpreted protocol, schedules, target responses, solver certificates, and generated explanations are adversarial input. All decoders and traces are bounded. Protocol interpretation grants no filesystem, network, process, credential, clock, random, or target capability. Proof checking executes no producer code.

A bounded proof does not establish that the model matches production, excludes side channels, uses a correct safety property, or covers omitted fault classes. Reports state assumptions prominently.

## Implementation order

1. Complete owned collections, finite IDs, modules, and package linking.
2. Specify deterministic structured concurrency and a finite scheduler model.
3. Add canonical protocol artifact and state schemas.
4. Implement classical event execution with explicit witnesses and exact inverse tests.
5. Implement deterministic replay and portable replay packages.
6. Add finite safety propositions and proof-producing trace checking.
7. Add length-indexed exhaustive/symbolic search and absence certificates.
8. Add durable search workflows and recovery matrices.
9. Add coherent finite protocol interpretation for a tiny eligible profile.
10. Add optional quantum candidate search with explicit target planning.
11. Check in `Murphy.w` only when compiler, VM/runtime, Tree-sitter, kernel, package tooling, examples, and docs execute it end to end.

## Progress

- [x] Wheeler has canonical bytecode, bounded frames/control/storage, explicit rewind, durable hybrid events, replay/retry separation, finite proof rules, exact package identities, and sealed build plans as partial prerequisites.
- [ ] Deterministic structured concurrency and finite scheduler semantics are implemented.
- [ ] Canonical protocol artifacts and cluster-state schemas are implemented.
- [ ] Explicit reversible event witnesses and timeline inversion are implemented.
- [ ] Portable normalized replay packages are implemented.
- [ ] General finite safety propositions and trace certificates are implemented.
- [ ] Length-indexed counterexample absence and minimality certificates are implemented.
- [ ] Coherent protocol interpretation and clean failure oracles are implemented.
- [ ] Quantum-assisted candidate search is implemented and capability-planned.
- [ ] `Murphy.w` is an ordinary executable conformance package.

## Testing and acceptance

- [ ] Every event kind has forward, inverse, disabled, bound, malformed-witness, trace, and replay tests.
- [ ] Timeline forward followed by inverse restores cluster, network, timers, ID cursors, witnesses, and allocator state exactly.
- [ ] Canonical decoding rejects duplicate encodings, forged fault counts, invalid partitions, disabled events, and dirty inactive slots.
- [ ] Replay is byte-identical under thread, map insertion, allocation, and target completion order.
- [ ] A seeded double-credit defect yields the expected seven-event counterexample and exact first violating transition.
- [ ] One changed event, protocol instruction, initial balance, budget, or arithmetic profile invalidates the failure certificate.
- [ ] A local delta-debug result is not labeled shortest without all shorter-length proofs.
- [ ] Empty samples, timeout, cancellation, stale jobs, and target failure produce `Inconclusive`, never `BoundedSafe`.
- [ ] Bounded-safe certification rejects one omitted enabled schedule.
- [ ] Replay performs no target submission; retry receives a new evidence identity.
- [ ] Crash/recovery at every durable phase neither skips a length nor applies evidence twice.
- [ ] Coherent classification returns all non-answer registers and workspaces clean.
- [ ] Classical and coherent classifiers agree for every schedule in a tiny complete domain.
- [ ] Capability denial occurs before protocol or host effects.
- [ ] Counterexample and safe packages verify offline from exact locked inputs.
- [ ] Resource exhaustion produces stable bounded diagnostics and no partial report.

## Alternatives

### Randomized stress testing only

Rejected as the semantic boundary. Stress tests remain useful candidate producers but neither cover a declared finite space nor prove absence.

### Snapshot the full cluster at every branch

Rejected as the Wheeler model. It is a valid model-checker implementation strategy, but it does not exercise explicit ownership, inverse witnesses, or coherent cleanup and can obscure omitted state.

### Trust a model checker or quantum target's “safe” result

Rejected. Producers emit checkable certificates or evidence. The kernel establishes the claim.

### Report the shortest trace found

Allowed only as “shortest known.” The unqualified word “shortest” requires checked absence of every shorter admitted timeline.

## Open questions

- Which structured-concurrency semantics are small enough for canonical finite protocol artifacts? — **Owner:** concurrency maintainers — **Decide by:** before protocol schema
- Which event independence relation supports useful checked partial-order reduction? — **Owner:** model-checking maintainers — **Decide by:** before absence certificates
- Which proof format handles bounded transition reachability and nonreachability without trusting the solver? — **Owner:** proof maintainers — **Decide by:** before safety certification
- Which application effects are eligible for coherent finite interpretation? — **Owner:** quantum/compiler maintainers — **Decide by:** before failure-oracle lowering
- Which observation model defines “applied at most once” for replicated external effects? — **Owner:** application maintainers — **Decide by:** before the ledger fixture

## References

- [Murphy future-system design](../future/murphy.md)
- [WIP-0002](WIP-0002-unified-classical-quantum-semantics.md)
- [WIP-0004](WIP-0004-hybrid-jobs-history-and-replay.md)
- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0010](WIP-0010-executable-application-portfolio.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0014](WIP-0014-bounded-certified-program-synthesis.md)
- [WIP-0032](WIP-0032-unified-io-fabric-and-durability-receipts.md)
