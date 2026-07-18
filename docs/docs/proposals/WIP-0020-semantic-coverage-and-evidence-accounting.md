# WIP-0020: Semantic coverage and evidence accounting

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler, VM, runtime, quantum, proof, package, test, and tools maintainers |
| Created | 2026-07-18 |
| Updated | 2026-07-18 |
| Area | Source and bytecode coverage, inverse and rewind accounting, quantum evidence, report merging, thresholds |
| Depends on | WIP-0001, WIP-0002, WIP-0004, WIP-0005, WIP-0009, WIP-0011, WIP-0013, WIP-0015, WIP-0018 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler will provide one bounded coverage system over canonical compiler observation maps and VM/runtime events. It reports classical declarations, instructions, decisions, conditions, match arms, calls, traps, reversible forward/inverse pairs, rewind, workflow/replay states, quantum circuit structure and sampled outcomes, and proof-kernel obligations without pretending those dimensions mean the same thing.

Coverage observation is caller-owned and outside program state. It cannot add hidden counters, alter bytecode control flow, consume Wheeler history, measure a quantum state, resubmit a job, or bless an unchecked proof. Serial, parallel, sharded, retried, and replayed runs reduce to canonical reports with explicit attempt and evidence identities.

A green `100%` means every selected denominator point was observed under the stated policy. It does not mean the program is correct, reversible, coherent, secure, useful, or house-trained.

## Motivation

Conventional coverage tools count source lines or instrument branches. Wheeler needs those basics, but a single percentage would erase important distinctions:

- executing a reversible function forward does not cover its inverse;
- rewinding VM history is not inverse execution;
- generated uncomputation is useful only if workspace is clean;
- replaying recorded evidence is not retrying an effect;
- a coherent branch cannot be observed by inserting a measurement counter;
- a quantum circuit submitted to hardware yields sampled evidence, not exact path coverage;
- kernel rule execution is not theorem correctness;
- a recovered workflow attempt is not a fresh attempt;
- source points, lowered instructions, generated inverses, and native probes need a checked correspondence;
- distributed report merging must reject duplicate attempts rather than count them twice because CI was feeling productive.

Without a shared model, every backend will choose convenient counters and dashboards will compare unrelated numbers. This WIP defines observation and accounting before percentages become compatibility commitments.

## Use cases

1. A classical package suite executes both outcomes of a decision and all finite-enum match arms. The report binds each source point to exact lowered bytecode points and records complete decision coverage.

2. A reversible test executes a function forward and invokes its generated inverse. The report records forward, inverse, pair, restoration, and clean-workspace observations. A test using VM rewind covers rewind points but leaves inverse coverage absent.

3. A coherent circuit executes on an exact simulator. The collector records circuit operations and adjoint structure from runtime events without measuring hidden state. A separate exact test may establish state restoration; coverage itself does not.

4. A hardware run records submitted circuit points, target/job identity, shots, and measurement outcomes. Replay reuses those evidence IDs and does not increase unique job coverage. Retry contributes a distinct attempt and job.

5. Twenty test shards emit partial reports. The reducer verifies artifact, map, policy, and attempt identities, unions hit sets, sums deduplicated counts with checked arithmetic, and emits the byte-identical report produced by a serial run.

6. A compiler refactor preserves source coverage points but changes lowering. Cross-build aggregation succeeds only through an explicit map-lineage record proving equal source points; artifact-level reports remain separate.

## Goals

- Define canonical source, bytecode, runtime, workflow, quantum, proof, and generated-code observation points.
- Collect observations without changing Wheeler program semantics.
- Keep language inverse, VM rewind, uncomputation, replay, retry, and recovery distinct.
- Support decision, condition, match-arm, call, trap, and bounded MC/DC accounting.
- Report quantum structural execution and sampled evidence without implicit measurement.
- Report proof obligation/rule exercise without claiming theorem quality.
- Integrate case, attempt, target, and fixture identities from WIP-0018.
- Merge serial, concurrent, and distributed reports deterministically and reject duplication.
- Apply exact, reviewable denominator and threshold policies.
- Emit a canonical semantic report plus terminal, JSON, LCOV, Cobertura, and website adapters.
- Run coverage under the self-hosted compiler and native VM before deleting host-only collectors.

## Non-goals

- Define correctness, test quality, proof strength, quantum advantage, security, or performance with one score.
- Instrument by mutating source, inserting hidden globals, or rewriting verified control flow.
- Observe coherent control by measuring it.
- Count VM rewind as generated inverse execution or replay as a fresh effect.
- Merge reports from unrelated artifacts merely because paths and line numbers look similar.
- Permit arbitrary inline exclusions or denominator changes that are invisible in package review.
- Make wall-clock duration or profiler sampling part of semantic coverage.
- Replace test results, proof certificates, target evidence, fuzz findings, or schedule-exploration certificates.
- Require production artifacts to retain source paths or coverage maps.

## Terms and semantic model

A **coverage point** is a canonical typed identity for one observable compiler/runtime event role.

A **coverage map** is a verified immutable relation among source points, bytecode points, generated points, and runtime event kinds for one exact artifact.

A **coverage policy** selects dimensions, denominators, generated-code treatment, exclusions, count mode, thresholds, and limits. Its identity is part of every report.

An **observation** is a runner-owned record that one point occurred in one exact WIP-0018 attempt, execution direction, target/evidence context, and event sequence.

A **hit set** records whether selected points occurred. A **count map** records bounded nonnegative occurrence counts. Counts are secondary evidence; threshold policy defaults to hit sets.

A **denominator** is the exact canonical set of points eligible under one policy. A point absent from the denominator cannot improve or damage its percentage.

A **partial report** contains observations for a closed set of attempt identities. A **coverage report** is the canonical reduction of compatible partial reports plus all missing denominator points and threshold outcomes.

A **lineage record** is a checked mapping between source point sets of different exact artifacts. It permits source-level comparison, never artifact-level count fusion.

## Point identities

Every point identity includes its domain and semantic owner. The first profile defines:

- source declaration entry and normal/abrupt exit;
- executable source statement;
- decision and outgoing edge;
- independently evaluable Boolean condition and outcome;
- finite match arm and explicit trap/default edge;
- function call site and resolved callee;
- bytecode function, instruction, branch edge, call edge, return, and trap;
- generated inverse instruction and its exact forward mate;
- uncomputation boundary and clean-resource check;
- VM checkpoint, rewind request, rewind record, and restored checkpoint;
- workflow transition, effect request, evidence publication, replay, retry, commit, abort, and recovery;
- quantum circuit operation, gate/adjoint pair, control relation, measurement site, and sampled outcome;
- proof obligation, kernel rule invocation, certificate acceptance, and certificate rejection.

Source point identities use exact package/source content, declaration, syntax-node range, and role. Bytecode points use exact artifact, function, instruction offset, and role. Generated points identify their generator and source/IR cause.

Absolute host paths, checkout roots, compiler temporary names, and display line numbers are presentation metadata, not identity. Line numbers may change while source-node identity changes or remains related through lineage; they never authorize an automatic merge.

## Compiler coverage maps

The compiler emits an optional canonical coverage/debug section in `.wbc` format 1.0 after WIP-0001 accepts its encoding and verification. The map contains:

- exact source identities and normalized logical paths;
- source syntax-node ranges;
- bytecode function/instruction ranges;
- decision, condition, and edge topology;
- match-arm and trap topology;
- generated inverse/adjoint/uncompute origins;
- points classified as user, generated-required, generated-diagnostic, or unreachable-by-construction;
- map profile and compiler identity.

The verifier rejects overlapping illegal ranges, dangling points, impossible edges, duplicate identities, forged forward/inverse relationships, invalid source ranges, unknown required roles, and maps exceeding limits.

Map bytes participate in canonical artifact identity like every other artifact byte. A stripped artifact is therefore a different artifact and supports only artifact events that its runtime can identify. There is no invisible sidecar selected by basename.

The compiler may emit a separate content-addressed map for production privacy, but artifact metadata must bind its digest and profile exactly. Missing or mismatched maps fail source-level collection.

## Collection boundary

The VM emits typed observation events at already-defined transition boundaries to a caller-owned bounded collector. The collector is not addressable by Wheeler code and cannot influence branch selection, local values, storage, machine status, retained history, quantum state, or effect payloads.

Collection failure is fail-closed when coverage is required. The VM stops before losing the next required observation and reports a collection-limit diagnostic. In advisory mode, collection may stop and mark the report incomplete; incomplete reports never satisfy thresholds.

A conforming native backend emits events corresponding to verified bytecode transitions or supplies a certified mapping from native probe to bytecode point. Statistical program-counter sampling is profiler data, not semantic coverage.

Compiler-inserted executable counter instructions are forbidden in the canonical profile. They alter control flow, resource bounds, history, and often the bug being pursued, which is impressive efficiency in the wrong direction.

## Classical decisions and conditions

Statement coverage requires entry to each selected executable syntax point. Declaration coverage requires entry to the declaration body. Decision coverage requires every feasible declared outgoing edge. Condition coverage requires each independently evaluated condition to produce each feasible Boolean outcome.

Short-circuit and coherent Boolean operators retain their actual language semantics. A condition not evaluated due to short circuit is not hit.

Bounded modified condition/decision coverage (MC/DC) may be selected for ordinary classical decisions. The report stores canonical witness attempt/value pairs showing an independent effect on the decision. The reducer validates witness topology; raw hit counts cannot satisfy MC/DC.

Compiler-proved unreachable edges are excluded only when the map binds a checked proof or canonical finite-type fact. Optimizer omission alone does not make a source branch metaphysically impossible.

## Reversible execution, rewind, and history

Coverage records execution direction for each bytecode point:

```text
forward
language-inverse
uncompute
vm-rewind
replay-reduction
```

Forward/inverse pair coverage requires both exact mated points under one compatible state/test contract. Round-trip coverage additionally requires an explicit WIP-0018 restoration assertion. Clean-uncompute coverage requires a successful resource-cleanliness assertion. None follows from merely hitting both instructions.

VM rewind observations refer to undo records and checkpoints, not inverse bytecode points. Rewound forward observations remain in the attempt hit set because execution happened. A report also carries **net-state accounting** showing which checkpoint was ultimately retained. Attempt coverage and net-state accounting are separate views.

History overflow preserves observations through the last completed transition and marks the attempt/report partial or failed according to test policy. It never erases the inconvenient part of the run.

## Workflows, effects, replay, and retry

Workflow points bind exact transition and effect-site identities. Reports distinguish requested, externally accepted, evidence-published, reduced, committed, aborted, replayed, retried, and recovered states.

Replay references the original evidence and attempt lineage. It may cover replay-reducer points but does not add a unique effect submission or hardware job. Retry has a new effect/job identity and contributes a distinct attempt.

A crash-recovery test can therefore require both recovery-state coverage and exactly one unique external submission. Counting transition hits alone is insufficient.

Output, filesystem, network, and provider payloads remain private caller-owned effects. Coverage stores bounded identities and status classes, not credentials or arbitrary payload bytes.

## Quantum coverage

Quantum coverage has two noninterchangeable profiles.

**Structural execution coverage** records that verified circuit operations, controls, generated adjoints, measurements, resets where legal, and target-lowering nodes were constructed/submitted/executed according to runtime events. It does not observe amplitudes or “which coherent branch ran.”

**Sampled evidence coverage** records measurement-site outcomes, shots, target/job/evidence identities, and declared statistical bins. It reports observed support under that sample only. Unobserved outcomes are not proved impossible; observed outcomes are not exact probabilities.

Exact simulator assertions from WIP-0018 may attach state-restoration or amplitude evidence identities. Coverage records that the assertion executed and passed but does not duplicate its numerical or proof semantics.

Inserting measurement, dephasing, random seeds, or target queries solely for coverage is forbidden. Generated adjoint pair coverage requires actual adjoint execution, not the presence of a pretty dagger in a diagram.

## Proof coverage

Proof coverage records exact propositions, obligations, certificate identities, kernel rule invocations, and terminal acceptance/rejection. It answers questions such as “did this suite exercise the forged-subject rejection path?”

It does not rank theorem importance, prove completeness, or imply that a theorem covers source statements. Search, name resolution, and certificate parsing are separate points from kernel acceptance.

Thresholds may require selected proof obligations to have accepted certificates and selected negative corpus classes to reach rejection rules. The report links the exact kernel/profile identity.

## Generated, excluded, and unreachable points

Generated-required points, including generated inverses and adjoints selected by policy, are visible denominators. Generated-diagnostic scaffolding may be reported separately. User source cannot hide points with comments or attributes.

Exclusions live in reviewed package coverage policy and identify exact point IDs plus reason codes. Allowed reasons initially include foreign/provider boundary, platform-impossible target, checked unreachable proof, and generated presentation adapter. “Annoying red bar” did not survive review.

Policy changes alter policy identity and invalidate threshold comparison until explicitly accepted. Reports display excluded points and reasons; exclusion is not deletion.

## Counts, attempts, and deterministic merge

Each observation binds a unique attempt identity from WIP-0018. Partial reports declare a closed sorted attempt set and digest. Merge rejects:

- duplicate attempt identities with unequal payloads;
- overlapping attempt sets unless payloads are byte-identical and deduplicated;
- different artifact/map/policy identities;
- incompatible target, kernel, or report profiles;
- count overflow or exhausted merge limits;
- missing required evidence.

Hit sets merge by union. Counts sum once per unique attempt using checked bounded arithmetic. Sampled outcomes additionally retain shot/evidence identities so replay cannot inflate counts.

Canonical output sorts denominator points, attempts, observations, witnesses, diagnostics, and evidence by identity. Worker order and report filename are irrelevant.

Cross-artifact source comparison requires an explicit lineage record and emits a comparison report with per-artifact counts. It never fabricates one combined artifact report.

## Thresholds and presentation

Threshold policies may require exact hit ratios or complete sets for declarations, statements, decisions, conditions, match arms, inverse pairs, clean uncompute, workflow states, quantum structural points, sampled bins, or proof obligations.

Ratios are canonical integer pairs, never floating-point thresholds. A policy may apply to the whole package and named source/module groups. Empty denominators report `not-applicable`; they do not receive 100% by divine intervention.

Threshold evaluation occurs after canonical reduction and before successful publication status. Test failures and threshold failures are independent outcomes. Coverage from failing tests remains valid attempted-execution evidence unless collection itself is invalid.

The canonical Wheeler coverage value is the authority. Terminal summaries, JSON, LCOV, Cobertura XML, annotated source, and WIP-0019 website pages are adapters. Formats unable to represent inverse, quantum, workflow, or proof dimensions must label omissions and cannot become release authorities.

## Reversibility and determinism

Coverage collection is an irreversible external observation. It has no language inverse and is not erased by machine rewind. This is intentional: the observer remembers that the program visited the ditch even if the VM backed out carefully.

Given identical artifact, map, policy, selected attempt/event/evidence inputs, the semantic report is byte-identical. Wall time, host process ID, thread name, filesystem order, renderer, and locale are excluded.

Parallel collection uses per-attempt bounded buffers or a deterministic event reducer. Contention may affect performance but not event identity, sequence within one machine, or final reduction.

## Persistence and compatibility

Coverage maps use an optional verified format-1 artifact section or exact bound sidecar. Coverage reports use a canonical Wheeler value schema with explicit profile and required-feature identities. This WIP introduces no bytecode format 2 and no package vocabulary fork.

Unknown required point kinds, dimensions, merge semantics, or threshold rules reject. Unknown optional presentation fields may be ignored after canonical validation.

Partial reports publish atomically after each closed attempt set. Final reports publish atomically after merge and threshold evaluation. A failed run may publish a valid final coverage report with failed test status; a malformed or incomplete report cannot satisfy release policy.

## Safety, privacy, and limits

Collection bounds points, map bytes, events per attempt, attempts, counters, MC/DC witnesses, evidence references, merge inputs, diagnostics, source excerpts, output bytes, quantum outcomes, proof rules, and total work.

Coverage paths are package-relative logical paths. Reports exclude source text by default and include bounded excerpts only under explicit local policy. Private declarations may be counted without publishing names outside an authorized report.

Provider credentials, raw network payloads, host paths, user names, environment variables, and unredacted test output never enter canonical reports. Digests identify evidence but do not grant permission to fetch it.

Malformed maps, forged probes, invalid lineage, duplicate attempts, count overflow, unavailable exact maps, stale evidence, and unsupported dimensions fail closed. Thresholds cannot be evaluated over an incomplete denominator.

## Ownership and boundaries

The compiler owns source/IR/bytecode correspondence and coverage-map emission. The bytecode verifier owns map structural and instruction consistency. The VM/runtime owns typed transition events. WIP-0018 owns cases, attempts, assertions, and test outcomes.

Quantum targets own execution evidence, not coverage interpretation. The proof kernel owns certificate outcomes. The package system owns coverage policy and exact source sets. The coverage reducer owns canonical merge, denominator, counts, witnesses, thresholds, and reports. WIP-0019 owns website rendering only.

## Migration and deletion

1. Define point kinds, identities, map encoding, report schema, diagnostics, and threshold policy.
2. Add statement, instruction, decision, and branch events to the stage-0 compiler/VM without executable instrumentation.
3. Integrate exact WIP-0018 attempt identities and deterministic partial/final reports.
4. Add condition, match-arm, call, trap, MC/DC witness, and package policy support.
5. Add inverse, rewind, uncompute, workflow, replay, retry, and recovery dimensions.
6. Add quantum structural/sampled and proof-obligation dimensions.
7. Implement deterministic sharded merge and WIP-0019 report pages.
8. Port map generation and reduction to Wheeler; compare map/report bytes with stage 0.
9. Add native probe correspondence and Java-free collection.
10. Delete JaCoCo as a semantic release authority, ad hoc counters, duplicate source mapping, and host-only reducers after parity. Host adapters may remain for Java seed-code coverage while that code exists.

## Progress

- [ ] Coverage point, map, observation, policy, and report contracts are accepted.
- [ ] Classical source/bytecode points collect without program instrumentation.
- [ ] WIP-0018 attempts merge deterministically across serial and sharded runs.
- [ ] Inverse, rewind, workflow, quantum, and proof dimensions execute distinctly.
- [ ] Wheeler and stage-0 reducers emit byte-identical reports.
- [ ] Superseded semantic coverage authorities are deleted.

## Testing and acceptance

- [ ] Source, bytecode, generated, and runtime point mappings reject every dangling, duplicate, overlapping, and forged relation in a malformed corpus.
- [ ] Collection on/off produces identical Wheeler machine states, output effects, histories, circuits, jobs, and proof results.
- [ ] Decision, condition, match-arm, trap, call, and bounded MC/DC fixtures produce exact expected denominators and witnesses.
- [ ] Forward, language inverse, uncompute, VM rewind, replay, retry, and recovery observations never alias.
- [ ] Rewind preserves attempted hit coverage while net-state accounting reflects restoration.
- [ ] Quantum collection adds no measurement and distinguishes structural execution, sampled outcomes, exact assertions, and proof.
- [ ] Proof coverage distinguishes lookup, obligation, rule execution, acceptance, and rejection.
- [ ] Duplicate shard attempts and replayed job evidence cannot inflate hit sets, counts, shots, or submissions.
- [ ] Serial, randomized-worker, and distributed reductions emit byte-identical semantic reports.
- [ ] Stripped/mismatched maps, invalid lineage, stale evidence, overflow, and exhausted limits fail closed.
- [ ] Exclusion and threshold policy changes alter identity and remain visible in reports.
- [ ] Terminal, JSON, LCOV, Cobertura, and website adapters disclose unsupported dimensions.
- [ ] A self-hosted compiler test run emits source-through-native coverage without Java collection.
- [ ] Current reference documentation describes only implemented coverage dimensions.

## Alternatives

### Keep JaCoCo as the Wheeler coverage authority

Rejected. JaCoCo usefully covers Java seed code, but Java bytecode probes cannot identify Wheeler source decisions, inverse pairs, VM rewind, quantum circuits, workflow replay, or proof obligations.

### Insert counter instructions during compilation

Rejected. Counters alter verified control flow, bounds, exact history, reversible semantics, circuit construction, and artifact identity. Typed external transition events provide a cleaner boundary.

### Report one weighted score

Rejected. Weighting incompatible dimensions hides information and creates a gameable number. Reports may present a dashboard, but release policy names exact dimensions and denominators.

### Count both coherent branches as covered when a controlled gate executes

Rejected. Coherent control is not a classical branch trace, and measuring it would change the computation. Structural control coverage says only that the controlled operation executed.

### Drop coverage from failed tests

Rejected. Failure paths are often the useful paths. Valid observations remain evidence; test outcome and threshold outcome are separate.

## Open questions

- Which source syntax-node identity survives harmless formatting while remaining exact enough for audit? — **Owner:** compiler and formatter maintainers — **Decide by:** before map acceptance
- Which condition forms enter first-profile MC/DC without exponential witness growth? — **Owner:** compiler and test maintainers — **Decide by:** before condition coverage implementation
- Should production sidecar maps be encrypted, access-controlled by publication policy, or simply omitted? — **Owner:** release and security maintainers — **Decide by:** before production integration
- Which native probe correspondence requires kernel checking rather than differential conformance? — **Owner:** native runtime and proof maintainers — **Decide by:** before Java-free promotion

## References

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0002](WIP-0002-unified-classical-quantum-semantics.md)
- [WIP-0004](WIP-0004-hybrid-jobs-history-and-replay.md)
- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0013](WIP-0013-typed-frames-control-flow-and-storage.md)
- [WIP-0015](WIP-0015-certified-adversarial-schedule-exploration.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0019](WIP-0019-integrated-documentation-publication.md)
