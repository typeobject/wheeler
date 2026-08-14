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

Wheeler will provide one bounded coverage system built on canonical IR observation maps and VM or runtime events. The report keeps several dimensions separate. Classical coverage includes declarations, instructions, choices, conditions, match arms, calls, and traps. Reversible coverage tracks forward work, language inverses, and rewind. Other dimensions cover coherent permutations, unitary and adjoint regions, measurement, workflow and replay states, quantum structure and samples, and proof-kernel duties.

These dimensions do not mean the same thing, so the reports keep them separate.

Coverage state belongs to the caller and stays outside program state. It cannot add hidden counters, change bytecode control flow, consume Wheeler history, measure quantum state, submit a job again, or approve an unchecked proof. Serial, parallel, sharded, retried, and replayed runs reduce to canonical reports with explicit attempt and evidence identities.

A green `100%` means every selected denominator point was observed under the named policy. It does not prove correctness, reversibility, coherence, security, or usefulness.

## Motivation

Normal coverage tools count source lines or instrument branches. Wheeler needs those basics, but one percentage would hide important differences:

- Running a reversible function forward does not cover its inverse.
- VM rewind is not language-level inverse execution.
- Generated uncomputation matters only when workspace returns clean.
- Replaying saved evidence is not retrying an effect.
- Adding a measurement counter cannot observe a coherent branch.
- Hardware execution gives sampled evidence, not exact path coverage.
- Kernel rule execution does not prove that a theorem is true.
- A recovered workflow attempt is not a new attempt.
- Source points, lowered instructions, generated inverses, and native probes need a checked mapping.
- Distributed merges must reject duplicate attempts instead of counting them twice.

Without one model, each backend will choose convenient counters and dashboards will compare unrelated values. This WIP defines observation and accounting before those percentages become compatibility promises.

## Use cases

1. A classical package suite executes both outcomes of a decision and all finite-enum match arms. The report binds each source point to exact lowered bytecode points and records complete decision coverage.

2. A reversible test executes a function forward and invokes its generated inverse. The report records forward, inverse, pair, restoration, and clean-workspace observations. A test using VM rewind covers rewind points but leaves inverse coverage absent.

3. A coherent circuit executes on an exact simulator. The collector records circuit operations and adjoint structure from runtime events without measuring hidden state. A separate exact test may establish state restoration. Coverage itself does not.

4. A hardware run records submitted circuit points, target/job identity, shots, and measurement outcomes. Replay reuses those evidence IDs and does not increase unique job coverage. Retry contributes a distinct attempt and job.

5. Twenty test shards emit partial reports. The reducer verifies artifact, map, policy, and attempt identities, unions hit sets, sums deduplicated counts with checked arithmetic, and emits the byte-identical report produced by a serial run.

6. A compiler refactor preserves source coverage points but changes lowering. Cross-build aggregation succeeds only through an explicit map-lineage record proving equal source points. Artifact-level reports remain separate.

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
- Merge reports from unrelated artifacts only because paths and line numbers look similar.
- Permit arbitrary inline exclusions or denominator changes that are invisible in package review.
- Make wall-clock duration or profiler sampling part of semantic coverage.
- Replace test results, proof certificates, target evidence, fuzz findings, or schedule-exploration certificates.
- Require production artifacts to retain source paths or coverage maps.

## Terms and semantic model

A **coverage point** is a canonical typed identity for one observable compiler/runtime event role.

A **coverage map** is a verified immutable relation among source points, bytecode points, generated points, and runtime event kinds for one exact artifact.

A **coverage policy** selects dimensions, denominators, generated-code treatment, exclusions, count mode, thresholds, and limits. Its identity is part of every report.

An **observation** is a runner-owned record that one point occurred in one exact WIP-0018 attempt, execution direction, target/evidence context, and event sequence.

A **hit set** records whether selected points occurred. A **count map** records bounded nonnegative occurrence counts. Counts are secondary evidence. Threshold policy defaults to hit sets.

A **denominator** is the exact canonical set of points eligible under one policy. A point absent from the denominator cannot improve or damage its percentage.

A **partial report** contains observations for a closed set of attempt identities. A **coverage report** is the canonical reduction of compatible partial reports plus all missing denominator points and threshold outcomes.

A **lineage record** is a checked mapping between source point sets of different exact artifacts. It permits source-level comparison, never artifact-level count fusion.

## Point identities

Every point identity includes its domain and semantic owner. The first profile defines:

- source declaration entry and normal/abrupt exit.
- executable source statement.
- decision and outgoing edge.
- independently evaluable Boolean condition and outcome.
- finite match arm and explicit trap/default edge.
- function call site and resolved callee.
- bytecode function, instruction, branch edge, call edge, return, and trap.
- generated inverse instruction and its exact forward mate.
- uncomputation boundary and clean-resource check.
- VM checkpoint, rewind request, rewind record, and restored checkpoint.
- workflow transition, effect request, evidence publication, replay, retry, commit, abort, and recovery.
- quantum circuit operation, gate/adjoint pair, control relation, measurement site, and sampled outcome.
- proof obligation, kernel rule invocation, certificate acceptance, and certificate rejection.

Source point identities use exact package/source content, declaration, syntax-node range, and role. Bytecode points use exact artifact, function, instruction offset, and role. Generated points identify their generator and source/IR cause.

Absolute host paths, checkout roots, compiler temporary names, and display line numbers are presentation metadata, not identity. Line numbers may change while source-node identity changes or remains related through lineage. They never authorize an automatic merge.

## Compiler coverage maps

The compiler emits an optional canonical coverage/debug section in `.wbc` format 1.0 after WIP-0001 accepts its encoding and verification. The map contains:

- exact source identities and normalized logical paths.
- source syntax-node ranges.
- bytecode function/instruction ranges.
- decision, condition, and edge topology.
- match-arm and trap topology.
- generated inverse/adjoint/uncompute origins.
- points classified as user, generated-required, generated-diagnostic, or unreachable-by-construction.
- map profile and compiler identity.

The verifier rejects overlapping illegal ranges, dangling points, impossible edges, duplicate identities, forged forward/inverse relationships, invalid source ranges, unknown required roles, and maps exceeding limits.

Map bytes participate in canonical artifact identity like every other artifact byte. A stripped artifact is therefore a different artifact and supports only artifact events that its runtime can identify. There is no invisible sidecar selected by basename.

The compiler may emit a separate content-addressed map for production privacy, but artifact metadata must bind its digest and profile exactly. Missing or mismatched maps fail source-level collection.

## Collection boundary

The VM emits typed observation events at already-defined transition boundaries to a caller-owned bounded collector. The collector is not addressable by Wheeler code and cannot influence branch selection, local values, storage, machine status, retained history, quantum state, or effect payloads.

Collection failure is fail-closed when coverage is required. The VM stops before losing the next required observation and reports a collection-limit diagnostic. In advisory mode, collection may stop and mark the report incomplete. Incomplete reports never satisfy thresholds.

A conforming native backend emits events corresponding to verified bytecode transitions or supplies a certified mapping from native probe to bytecode point. Statistical program-counter sampling is profiler data, not semantic coverage.

Compiler-inserted executable counter instructions are forbidden in the canonical profile. They alter control flow, resource bounds, history, and often the bug being pursued, which is impressive efficiency in the wrong direction.

## Classical decisions and conditions

Statement coverage requires entry to each selected executable syntax point. Declaration coverage requires entry to the declaration body. Decision coverage requires every feasible declared outgoing edge. Condition coverage requires each independently evaluated condition to produce each feasible Boolean outcome.

Short-circuit and coherent Boolean operators retain their actual language semantics. A condition not evaluated due to short circuit is not hit.

Bounded modified condition/decision coverage (MC/DC) may be selected for ordinary classical decisions. The report stores canonical witness attempt/value pairs showing an independent effect on the decision. The reducer validates witness topology. Raw hit counts cannot satisfy MC/DC.

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

Forward/inverse pair coverage requires both exact mated points under one compatible state/test contract. Round-trip coverage also requires an explicit WIP-0018 restoration assertion. Clean-uncompute coverage requires a successful resource-cleanliness assertion. None follows from only hitting both instructions.

VM rewind observations refer to undo records and checkpoints, not inverse bytecode points. Rewound forward observations remain in the attempt hit set because execution happened. A report also carries **net-state accounting** showing which checkpoint was ultimately retained. Attempt coverage and net-state accounting are separate views.

History overflow preserves observations through the last completed transition and marks the attempt/report partial or failed according to test policy. It never erases the inconvenient part of the run.

## Workflows, effects, replay, and retry

Workflow points bind exact transition and effect-site identities. Reports distinguish requested, externally accepted, evidence-published, reduced, committed, aborted, replayed, retried, and recovered states.

Replay references the original evidence and attempt lineage. It may cover replay-reducer points but does not add a unique effect submission or hardware job. Retry has a new effect/job identity and contributes a distinct attempt.

A crash-recovery test can therefore require both recovery-state coverage and exactly one unique external submission. Counting transition hits alone is insufficient.

Output, filesystem, network, and provider payloads remain private caller-owned effects. Coverage stores bounded identities and status classes, not credentials or arbitrary payload bytes.

## I/O lifecycle coverage

WIP-0032 coverage distinguishes request construction, submission, progress, terminal completion, cancellation relation, uncertainty, resource release, reaping, replay, and each visibility or persistence transition. A completion hit cannot cover a durability point, and replay cannot inflate unique live submissions.

Reports retain bounded operation, request, resource, backend-profile, receipt, and attempt identities. They exclude payloads, credentials, descriptors, remote keys, and native queue state. Physical completion order is evidence only when the program explicitly observes a selection race.

## Quantum coverage

Quantum coverage has two noninterchangeable profiles.

Structural execution coverage records when verified circuit operations, controls, generated adjoints, measurements, legal resets, and target-lowering nodes were constructed, submitted, or executed. It cannot observe amplitudes or identify a coherent branch as having run.

**Sampled evidence coverage** records measurement-site outcomes, shots, target/job/evidence identities, and declared statistical bins. It reports observed support under that sample only. Unobserved outcomes are not proved impossible. Observed outcomes are not exact probabilities.

Exact simulator assertions from WIP-0018 may attach state-restoration or amplitude evidence identities. Coverage records that the assertion executed and passed but does not duplicate its numerical or proof semantics.

Inserting measurement, dephasing, random seeds, or target queries solely for coverage is forbidden. Generated adjoint pair coverage requires actual adjoint execution, not the presence of a pretty dagger in a diagram.

## Proof coverage

Proof coverage records exact propositions, obligations, certificate identities, kernel rule invocations, and terminal acceptance or rejection. It can show whether the suite exercised the forged-subject rejection path.

It does not rank theorem importance, prove completeness, or imply that a theorem covers source statements. Search, name resolution, and certificate parsing are separate points from kernel acceptance.

Thresholds may require selected proof obligations to have accepted certificates and selected negative corpus classes to reach rejection rules. The report links the exact kernel/profile identity.

## Generated, excluded, and unreachable points

Generated-required points, including generated inverses and adjoints selected by policy, are visible denominators. Generated-diagnostic scaffolding may be reported separately. User source cannot hide points with comments or attributes.

Exclusions live in reviewed package coverage policy and identify exact point IDs plus reason codes. Allowed reasons initially include foreign or provider boundaries, platform-impossible targets, checked unreachable proofs, and generated presentation adapters. A failing coverage indicator is not an allowed reason.

Policy changes alter policy identity and invalidate threshold comparison until explicitly accepted. Reports display excluded points and reasons. Exclusion is not deletion.

## Counts, attempts, and deterministic merge

Each observation binds a unique attempt identity from WIP-0018. Partial reports declare a closed sorted attempt set and digest. Merge rejects:

- duplicate attempt identities with unequal payloads.
- overlapping attempt sets unless payloads are byte-identical and deduplicated.
- different artifact/map/policy identities.
- incompatible target, kernel, or report profiles.
- count overflow or exhausted merge limits.
- missing required evidence.

Hit sets merge by union. Counts sum once per unique attempt using checked bounded arithmetic. Sampled outcomes also retain shot/evidence identities so replay cannot inflate counts.

Canonical output sorts denominator points, attempts, observations, witnesses, diagnostics, and evidence by identity. Worker order and report filename are irrelevant.

Cross-artifact source comparison requires an explicit lineage record and emits a comparison report with per-artifact counts. It never fabricates one combined artifact report.

## Thresholds and presentation

Threshold policies may require exact hit ratios or complete sets for declarations, statements, decisions, conditions, match arms, inverse pairs, clean uncompute, workflow states, quantum structural points, sampled bins, or proof obligations.

Ratios are canonical integer pairs, never floating-point thresholds. A policy may apply to the whole package and named source/module groups. Empty denominators report `not-applicable`. They do not receive 100% by divine intervention.

Threshold evaluation occurs after canonical reduction and before successful publication status. Test failures and threshold failures are independent outcomes. Coverage from failing tests remains valid attempted-execution evidence unless collection itself is invalid.

The canonical Wheeler coverage value is the authority. Terminal summaries, JSON, LCOV, Cobertura XML, annotated source, and WIP-0019 website pages are adapters. Formats unable to represent inverse, quantum, workflow, or proof dimensions must label omissions and cannot become release authorities.

## Reversibility and determinism

Coverage collection is an irreversible external observation. It has no language inverse and is not erased by machine rewind. This is intentional: the observer remembers that the program visited the ditch even if the VM backed out carefully.

Given identical artifact, map, policy, selected attempt/event/evidence inputs, the semantic report is byte-identical. Wall time, host process ID, thread name, filesystem order, renderer, and locale are excluded.

Parallel collection uses per-attempt bounded buffers or a deterministic event reducer. Contention may affect performance but not event identity, sequence within one machine, or final reduction.

## Persistence and compatibility

Coverage maps use an optional verified format-1 artifact section or exact bound sidecar. Coverage reports use a canonical Wheeler value schema with explicit profile and required-feature identities. This WIP introduces no bytecode format 2 and no package vocabulary fork.

Unknown required point kinds, dimensions, merge semantics, or threshold rules reject. Unknown optional presentation fields may be ignored after canonical validation.

Partial reports publish atomically after each closed attempt set. Final reports publish atomically after merge and threshold evaluation. A failed run may publish a valid final coverage report with failed test status. A malformed or incomplete report cannot satisfy release policy.

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
8. Port map generation and reduction to Wheeler. Compare map/report bytes with stage 0.
9. Add native probe correspondence and Java-free collection.
10. Delete JaCoCo as a semantic release authority, ad hoc counters, duplicate source mapping, and host-only reducers after parity. Host adapters may remain for Java seed-code coverage while that code exists.

## Progress

- [x] The stage-0 VM emits immutable observations for successful transitions without changing executable code. Forward, language-inverse, rewind-forward, and rewind-inverse coverage stay separate. A successful `JUMP_IF_ZERO` records whether the branch was taken. The reducer emits sorted checked counts and a domain-separated report identity. Tests require identical terminal and rewound snapshots with collection on or off. Classical package tests collect the report in a fresh VM, print its identity, and bind that identity into the test report. Quantum cases do not claim a classical transition report. A policy with no denominator reports no percentage.
- [x] The first classical transition-coverage profile accepts typed observations and canonical points keyed by direction, function, instruction, opcode, and branch result. Its sorted JSON report and domain-separated identity are accepted. Source relations, threshold policy, and proof stages now occupy separate identified profiles. Quantum and complete workflow dimensions remain.
- [x] Classical bytecode transition points collect through the VM observer without adding counter instructions or changing `.wbc`. Validated source-point and generated-inverse relations remain a separate map and join profile, so base transition identity never depends on retained source paths.
- [x] WIP-0018 assigns complete case identities to shards by digest and merges shard outcomes in canonical case order. Arrival-order variation reproduces the serial semantic report identity, and duplicate case identities reject.
- [x] The implemented classical reducer distinguishes forward, language inverse, rewind-forward, and rewind-inverse observations in one canonical report. Proof stages occupy a separate reducer. Complete workflow and quantum dimensions remain outside the transition profile.
- [x] `wheeler.runtime.coverage_reducer` validates at most 64 bounded canonical point fragments, sorts source-order-independent keys without host collections, combines duplicate counts, renders exact decimal fields, and returns the profile-1 length only after complete reduction. The runtime authority is a package-safe library method. `wheeler.conformance.runtime.native_coverage_reducer` owns the executable output publication boundary. Differential execution feeds two forward-and-rewind runs in reverse arrival order and matches every stage-0 report byte.
- [ ] Superseded semantic coverage authorities are deleted.

## Testing and acceptance

- [x] `SemanticCoverageMap` binds normalized source ranges, exact canonical artifact identity, authored or generated-inverse origin, execution direction, function, contiguous instruction window, and the window's opcode identity. Construction rejects dangling windows, duplicate rows, overlaps within one bytecode body, forward claims for generated inverses, forged opcode identities, malformed source coordinates, and unknown functions. Joining rejects observed runtime points without one exact relation or with a forged opcode or branch shape. `SemanticCoverage` separately reduces adjacent transition edges by workflow epoch, hierarchical task, direction, both endpoints, and branch outcome. The source join validates both path endpoints and binds the path-report identity without claiming a complete path denominator.
- [x] The classical coverage fixture runs observed and plain VMs through forward execution and complete rewind and compares every snapshot and history boundary exactly. Circuit, job, and proof collection remain outside the current profile.
- [x] The accepted runtime collector records each verified instruction transition without instrumentation, distinguishes taken and fallthrough branches, direct calls, assertions, traps, forward and inverse execution, and rewind of each direction, and reproduces exact report identities across reruns. Match-arm and MC/DC denominators remain.
- [x] Forward, language inverse, rewind-forward, and rewind-inverse are separate closed observer enum values and separate point-identity fields, so the implemented classical dimensions cannot alias. Uncompute, replay, retry, and recovery remain outside this observer profile.
- [x] Rewind retains the earlier forward and inverse hit records and adds direction-specific rewind observations while the observed machine returns to its exact initial snapshot.
- [x] Current quantum evidence accounting adds no measurement. It keeps exact-quantum, sampled-quantum, and proof evidence in distinct closed kinds, while circuit execution remains structural runtime evidence. Source relation production by the compiler remains with WIP-0018, while relation validation and joining are implemented here.
- [x] `ProofObserver` emits ordered lookup, obligation, rule-execution, acceptance, and rejection stages. `ProofCoverage` reduces rule, subject, stage, and checked hit count under a separate profile and identity. Accepted and rejected certificates retain different evidence, and neither result changes proof-kernel decisions.
- [x] The current test reducer rejects duplicate case identities while merging shards. Hybrid replay consumes one reduced applied-observation map and performs no target submission, so duplicate event delivery and replay cannot inflate current case outcomes, measurements, jobs, or submissions. General quantum coverage counters remain.
- [x] The accepted test-report reducer sorts by complete case identity, assigns shards from that digest, rejects duplicate terminal rows, and emits the same profile-2 semantic report identity for serial, reversed-arrival, and concurrently produced shards. Distributed transport and retry policy remain outside this slice.
- [x] The accepted profile rejects duplicate and malformed identities, mismatched artifact or result lineage, stale target evidence, a 65,536th report row, oversized diagnostics, quantum results above eight MiB, and exhausted execution or event limits before report publication or continuation mutation. General source-map stripping remains.
- [x] `SemanticCoveragePolicy` binds sorted direction and opcode exclusions plus bounded minimum-point and per-point hit thresholds into one identity. Evaluation reports every exclusion, threshold, included and excluded count, pass result, base coverage identity, and policy identity. Changing any semantic axis changes policy and evaluation identities. Caller set order does not.
- [x] `SemanticCoverageRenderer` emits deterministic terminal, JSON, LCOV, Cobertura XML, and static website views. Every adapter carries the canonical report identity and names source lines, source branches, proof obligations, quantum state, and empirical targets as unsupported. LCOV and Cobertura use explicit synthetic bytecode coordinates instead of forging source mappings. Rendering changes neither canonical bytes nor identity.
- [ ] A self-hosted compiler test run emits source-through-native coverage without Java collection.
- [x] `reference/coverage.md` documents successful classical transition points and adjacent path edges, validated source and generated-body relations, proof stages, explicit policy, adapters, report identities, and current runner integration. It excludes compound-condition and match-arm denominators, trapped attempts, attempt lineage, quantum structure, and Wheeler-written reduction.

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

Rejected. Failure paths are often the useful paths. Valid observations remain evidence. Test outcome and threshold outcome are separate.

## Open questions

- Which source syntax-node identity survives harmless formatting while remaining exact enough for audit (owner: compiler and formatter maintainers. Decision point: before map acceptance)?
- Which condition forms enter first-profile MC/DC without exponential witness growth (owner: compiler and test maintainers. Decision point: before condition coverage implementation)?
- Should production sidecar maps be encrypted, access-controlled by publication policy, or omitted (owner: release and security maintainers. Decision point: before production integration)?
- Which native probe correspondence requires kernel checking instead of differential conformance (owner: native runtime and proof maintainers. Decision point: before Java-free promotion)?

## Integration with reversible concurrency

### Structured-task coverage

Coverage families include scope enter and exit, spawn, start, completion, join, scheduler selection, atomic operations, read-from, block, wake, deadlock, task-scope inverse, machine rewind, and schedule replay.

Runner worker order is not task coverage. Reduction does not manufacture hits for omitted schedules unless a policy reports certified equivalence-class coverage.

Task inverse, exact rewind, causal rollback, external replay, and quantum adjoint remain separate dimensions.

## References
- [WIP-0039](WIP-0039-deterministic-structured-task-machine-and-global-rewind.md)
- [WIP-0040](WIP-0040-explicit-schedule-witnesses-for-reversible-task-scopes.md)

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0002](WIP-0002-unified-classical-quantum-semantics.md)
- [WIP-0004](WIP-0004-hybrid-jobs-history-and-replay.md)
- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0013](WIP-0013-typed-frames-control-flow-and-storage.md)
- [WIP-0015](WIP-0015-certified-adversarial-schedule-exploration.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0019](WIP-0019-integrated-documentation-publication.md)
- [WIP-0032](WIP-0032-unified-io-fabric-and-durability-receipts.md)
