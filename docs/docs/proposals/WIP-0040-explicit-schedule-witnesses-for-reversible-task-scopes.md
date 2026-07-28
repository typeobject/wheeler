# WIP-0040: Explicit schedule witnesses for reversible task scopes

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler language, compiler, verifier, VM, concurrency, reversibility, proof, and tooling maintainers |
| Created | 2026-07-27 |
| Updated | 2026-07-27 |
| Area | Language inverse, structured tasks, schedule witnesses, shared atomics |
| Depends on | WIP-0031, WIP-0035, WIP-0036, WIP-0039 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler adds language-level inverse execution for eligible WIP-0039 task scopes.

A task-scope inverse is new forward execution. It never consumes the original VM journal. A scope with disjoint task-owned mutable state may derive an inverse from ownership and frame evidence. A scope whose tasks interact through atomics requires an explicit bounded affine `TaskScheduleWitness`.

The witness records only inter-task evidence that final state cannot reconstruct. It contains task selection order, shared observations, atomic outcomes, admitted synchronization decisions, ownership relations, and logged overwritten values. WIP-0035 continues to own each task's branch and loop witnesses.

Inverse execution validates a quiescent completed scope, consumes witness entries in reverse semantic event order, and executes accepted event inverses as ordinary new WIP-0039 work. Those inverse events create normal global history and may themselves rewind.

A complete inverse is garbage-clean. It restores application state and every witness slot to the declared clean state. Leaving the answer right and the evidence drawer full is not an inverse.

The first interacting profile keeps a total schedule witness. A successor may compress it to a causal partial order only after WIP-0011 accepts the needed independence and causal-safety evidence.

The acceptance fixture is reversible bounded bakery. Forward execution fills a witness. Source inverse consumes it and restores task state, atomics, results, control witnesses, schedule entries, read evidence, overwrite evidence, and ownership evidence.

## Motivation

WIP-0039 exact rewind depends on retained machine history. A language inverse may run after that history was committed, after persistence and restore, or after unrelated later work. It cannot use private StepRecord data.

Disjoint tasks are simple. Their relations compose because their mutable frame sets do not overlap.

Interacting tasks are not simple. An atomic read may choose a branch. Compare-exchange may succeed only under one interleaving. Two bakery tasks may receive equal tickets and order by stable identity. Final shared state often erases those facts.

The missing information must be explicit bounded state. This WIP provides that state without renaming rewind, inventing per-task undo stacks, duplicating WIP-0035 control history, or making external effects reversible.

## Use cases

### Disjoint reversible workers

A parent splits an owner into proven-disjoint affine ranges. Each child applies a reversible function. The generated inverse applies child inverses to matching results. No schedule witness is needed.

### Atomic protocol

Tasks exchange values through atomic operations under a finite schedule. Forward execution retains observations and overwritten values. Inverse execution consumes them newest first.

### Reversible bakery

A fixed task set runs the WIP-0039 bakery fixture. Forward execution fills task control witnesses, schedule entries, atomic observations, ticket evidence, and ownership evidence. Inverse execution cleans all of them.

### Inverse after commit

A caller keeps the affine witness, commits VM rewind history, and later invokes source inverse. The inverse succeeds because its evidence is owned source state.

### Finite coherent model

WIP-0015 may interpret encoded schedules as clean reversible model data and uncompute the model. A live TaskScope and its witness are not directly coherent.

## Goals

- Define inverse relations for disjoint task scopes.
- Define witnessed inverse relations for bounded interacting scopes.
- Keep language inverse separate from VM rewind.
- Reuse WIP-0031 `ReversibleFunction`.
- Reuse WIP-0035 branch and loop witnesses.
- Account witness state through WIP-0036.
- Require quiescent exclusive ownership before inverse.
- Consume interacting evidence in reverse global event order.
- Validate state before every inverse mutation.
- Permit inverse after VM history commit.
- Make inverse execution normally rewindable.
- Reject external, measurement, target, FFI, and barrier effects.
- Make reversible bakery an end-to-end gate.

## Non-goals

- Define WIP-0039 exact rewind or task scheduling.
- Add another callable kind.
- Hide evidence in VM history or compiler runtime state.
- Add hidden branch or loop logs.
- Make I/O, cancellation, measurement, reset, target work, or FFI reversible.
- Freeze task source punctuation.
- Define mutex, channel, semaphore, or condition-variable inverse.
- Invert a live or externally aliased scope.
- Add causal out-of-order debugger rollback.
- Directly lift live task scheduling into coherent execution.
- Claim unbounded safety or liveness from finite fixtures.

## Terms and semantic model

### Scope profiles

A reversible task scope has one profile:

```text
DisjointTaskScope
WitnessedTaskScope
```

A DisjointTaskScope requires reversible child bodies, pairwise-disjoint mutable frames, immutable shared input, no atomics, no nonstructural blocking, no barriers, exact result rejoin, and valid WIP-0035 control flow.

A WitnessedTaskScope permits WIP-0039 atomics under finite bounds. Every event needs an accepted inverse or logged inverse entry. Every schedule choice and required observation remains explicit. The scope returns quiescent.

### Witness hierarchy

```text
no witness
    < synchronization witness
    < causal partial-order witness
    < total schedule witness
    < full VM event journal
```

The first disjoint profile uses no schedule witness. The first interacting profile uses a total schedule witness. The VM journal remains separate.

### TaskScheduleWitness

```text
TaskScheduleWitness {
    artifact_id
    task_extension_id
    scope_descriptor_id
    task_tree_shape
    event_count
    schedule_entries
    shared_event_entries
    synchronization_entries
    ownership_entries
    required_control_witness_ids
    initial_shape_id
    final_shape_id
    status
}
```

Status is `Clean`, `Filled`, `Consuming`, or `Consumed`. Only Clean may enter forward execution. Only Filled may enter inverse execution.

A ScheduleEntry names event index, TaskId, semantic operation identity, and enabledness class. It stores no host thread or timestamp.

A shared event entry retains only evidence that explicit task state and WIP-0035 witnesses do not already retain. Forms include atomic load, store, exchange, compare-exchange, fetch, spawn, and join evidence.

Read evidence keeps exact read-from identity even when equal values came from different writes. Value equivalence is useful for search reduction. It is not exact provenance.

### Quiescent inverse boundary

Inverse requires every child completed and joined, no blocked task, no live external or target operation, no barrier in the scope, no escaping AtomicRef, exclusive ownership of every AtomicCell, expected filled control witnesses, a Filled TaskScheduleWitness, and an exact final scope shape.

### Forward and inverse laws

```text
forward_D(
    owned_input,
    shared_initial,
    CleanWitness
) = (
    owned_output,
    shared_final,
    FilledWitness
)

inverse_D(
    owned_output,
    shared_final,
    FilledWitness
) = (
    owned_input,
    shared_initial,
    CleanWitness
)
```

Inverse consumes entries in descending event index. Each inverse event is new WIP-0039 execution.

### No StepRecord authority

A TaskScheduleWitness cannot point to machine history, depend on history retention, request `rewindOne`, restore a whole snapshot, or cross artifact and scope identities without validation.

An implementation may share codecs between event records and witness entries only when identity, ownership, lifetime, and semantics remain distinct.

## Ownership

WIP-0005 and WIP-0006 own final source form. WIP-0031 owns `ReversibleFunction` and effects. WIP-0035 owns branch, match, and loop witnesses. WIP-0036 owns witness resources. WIP-0028 owns witness ownership and moves.

The compiler owns disjoint frame analysis, witness schemas, inverse event selection, child inverse generation, control-witness composition, resources, and source mapping.

The verifier owns scope profile, child reversibility, effect exclusion, witness type and bounds, identities, event compatibility, quiescence, escaping-reference rejection, inverse validity, and final cleanliness.

The VM executes generated inverse events under WIP-0039. It does not interpret a witness as debugger history.

WIP-0011 owns accepted inverse, frame, quiescence, and cleanliness propositions. Tools own visualization and diagnostics. Editing evidence changes its identity.

## Design

### No new callable kind

A declaration containing an accepted task scope remains a WIP-0031 `ReversibleFunction`. Its semantic signature includes task and shared effects, witness ownership, bounds, inverse descriptor, trap exclusions, and frame relation.

### Source model

This WIP does not freeze punctuation. Accepted syntax must reveal scope profile, witness input and output, bounds, child identities, owned inputs and outputs, shared atomic scope, and inverse availability.

Compiler-generated witness locals remain explicit typed IR owners with effects, resources, debug identity, and diagnostics. Surface sugar may hide punctuation, not retained information.

### Disjoint inverse

For disjoint children:

```text
forward = F0 tensor F1 tensor ... tensor Fn
inverse = inverse(F0) tensor inverse(F1) tensor ... tensor inverse(Fn)
```

The compiler may run inverse children in reverse canonical TaskId order. Disjointness makes semantic order irrelevant. Canonical order keeps traces and diagnostics stable.

### Witnessed forward

Before scope entry, forward execution verifies Clean status, capacity, scope identity, task tree, shared shape, and control-witness owners.

For each event it validates the WIP-0039 schedule choice, checks capacity, executes the event, appends one ScheduleEntry, appends needed shared evidence, binds control-witness identity, and advances event count.

Scope completion validates quiescence and marks the witness Filled.

### Witnessed inverse

Before mutation, inverse verifies Filled status, artifact, descriptor, exact final shape, exclusive shared ownership, child inverse descriptors, and control-witness states. It then marks the witness Consuming.

For each event newest first, it reads the ScheduleEntry, selects the inverse continuation, validates current task and shared state, consumes evidence, executes the semantic inverse, appends a normal WIP-0039 event, and clears the witness slot.

After the last event it requires initial scope shape, completed child inverses, clean control witnesses, clean shared entries, clean schedule entries, and Clean witness status.

A mismatch traps before the next mutation. Already completed inverse events remain ordinary history and may rewind.

### Atomic inverse rules

Load restores prior local state and validates retained observation evidence when control used it. Store restores the retained previous cell. Exchange restores both cell and local relation. Compare-exchange validates success and observed state. Fetch operations use an accepted paired inverse or retained prior cell.

All rules execute in reverse global event order. Per-task completion order has no authority.

### Task lifecycle inverse

Inverse spawn removes an inverse-task continuation only after descendant entries are consumed. Inverse completion reconstructs the preceding child state. Inverse join restores child result and affine handle relation.

### Future causal compression

A successor may replace total schedule with task order, read-from, modification order, conflicts, synchronization, task-tree order, and ownership transfer. Reverse topological execution requires WIP-0011-checked independence. Touching different TaskIds is not proof.

### Commit independence

A Filled witness may survive WIP-0039 COMMIT when it is owned source state, no loan crosses the horizon, referenced identities remain available, and no external barrier occurred.

### External rejection

Witnessed scopes reject I/O submission, live await, file and network effects, process and clock effects, randomness, FFI, target work, measurement, reset, receipts, workflow commit, callbacks, and external cleanup cancellation.

Compensation does not make these effects reversible.

### Bakery inverse

Forward bakery leaves tickets and choosing flags clear, critical owner empty, entry count complete, task results joined, and witness Filled.

Inverse restores initial atomics, task inputs and outputs, task tree, joins, control witnesses, shared evidence, schedule slots, and witness status.

Rewinding the inverse run restores the completed forward state and Filled witness.

## Reversibility and history

This WIP defines language inverse, not debugger rewind. Forward and inverse each create normal global task history.

TaskScheduleWitness stores source relation evidence. WIP-0036 accounts it separately from VM history, WIP-0035 control witnesses, workspace, task events, and peak tasks.

Witness exhaustion traps before the overflowing event. A failed inverse leaves completed inverse events in normal history. The VM does not restore a secret snapshot.

## Concurrency and determinism

For exact artifact, descriptor, initial state, SchedulePlan, witness schema, effects, and bounds, forward produces one exact Filled witness. Inverse consumes it in one exact reverse order.

Host workers, completion order, maps, addresses, and clocks cannot change witness bytes. Disjoint scopes remain schedule-independent under accepted frame evidence, while traces still use canonical order.

## Quantum and proof implications

Live witnessed scopes are not coherent because they use shared mutation, schedule observations, retained witnesses, and task control.

A separate finite WIP-0015 model may begin and end with clean reversible workspace.

Proof obligations include inverse after forward, enabledness, replay, child inverse validity, disjoint frames, atomic restoration, task-tree restoration, quiescence, witness cleanliness, and bounded mutual exclusion.

WIP-0011 owns theorem forms. Test output does not acquire a theorem costume by standing near a certificate.

## Bytecode, persistence, and compatibility

WIP-0040 uses required metadata under WIP-0038. It needs scope-profile, witness-schema, inverse-event, child-inverse, control-witness, shape, resource, and bound descriptors.

The first implementation may lower inverse work to ordinary WIP-0039 task, atomic, and verifier-checked witness operations.

A witness is a canonical owned value. Persistence stores its schema, artifact identity, and bounds. It never serializes VM history or native stacks.

Artifacts without this extension remain valid and simply lack task-scope inverse availability. A semantic witness-layout change requires a version change.

## Safety, limits, and failures

The compiler or verifier rejects nonreversible child calls, hidden barriers, missing inverse events, unbounded schedules, hidden control history, escaping atomic references, outside shared aliases, nonquiescent final state, shape mismatch, witness mismatch, coherent task effects, external effects, and forged inverse descriptors.

The VM traps before the next inverse mutation on identity mismatch, unexpected task or operation, atomic state mismatch, dirty witness slots, missing control evidence, owner or join mismatch, event-index mismatch, witness exhaustion, or task and history exhaustion.

Inverse failure never claims external restoration. External effects were excluded before forward execution.

## Migration and deletion

1. Implement WIP-0039.
2. Add canonical TaskScheduleWitness encoding.
3. Add disjoint frame analysis and generated disjoint inverses.
4. Add task lifecycle and atomic witness entries.
5. Compose WIP-0035 control witnesses.
6. Add WIP-0036 accounting.
7. Generate witnessed inverse continuations.
8. Add reversible bakery and proof obligations.
9. Add testing, coverage, and debugger distinctions.
10. Delete prototypes that read original StepRecords, use per-task undo stacks, or hide evidence.

## Progress

- [ ] Disjoint task-scope relation is accepted.
- [ ] TaskScheduleWitness type and bounds are accepted.
- [ ] Forward execution fills canonical entries.
- [ ] Inverse consumes entries newest first.
- [ ] WIP-0035 witnesses compose without duplication.
- [ ] WIP-0036 reports witness and history separately.
- [ ] Inverse events create normal WIP-0039 history.
- [ ] Inverse after commit succeeds.
- [ ] Reversible bakery restores exact initial state.
- [ ] Coherent lifting rejects.
- [ ] Finite WIP-0015 model interpretation remains possible.
- [ ] Hidden-history prototypes are deleted.

## Testing and acceptance

- [ ] A disjoint two-task scope inverts without a schedule witness.
- [ ] Reordering disjoint inverse tasks preserves semantic state.
- [ ] Forged disjointness fails verification.
- [ ] A witnessed scope rejects non-Clean input.
- [ ] Forward fills one schedule entry per event.
- [ ] A changed task selection invalidates witness identity.
- [ ] A changed atomic observation traps before inverse mutation.
- [ ] A changed child body or inverse descriptor invalidates the relation.
- [ ] WIP-0035 witnesses remain separate and return clean.
- [ ] Original history may commit before source inverse.
- [ ] Inverse creates new history and may rewind.
- [ ] Rewinding inverse restores Filled witness and forward final state.
- [ ] External and target effects reject before forward execution.
- [ ] Witness exhaustion traps before the overflowing event.
- [ ] Reversible bakery restores every atomic, owner, task, result, and witness slot.
- [ ] Bakery inverse does not read original StepRecords.
- [ ] Direct coherent lifting rejects.
- [ ] A finite model interpreter passes clean uncomputation tests.
- [ ] Coverage reports task inverse separately from VM rewind.

## Alternatives

### Use original history

Rejected. Language inverse cannot depend on debugger retention.

### One undo stack per task

Rejected. Shared observations have global order.

### Hide witness state

Rejected. Retained information must remain visible in IR, effects, ownership, resources, and diagnostics.

### Infer schedule from final state

Rejected. Equal final states may require different inverse event orders.

### Invert a live scope

Rejected. Live dependents make the relation ambiguous without causal rollback.

### Add a callable kind

Rejected. WIP-0031 ReversibleFunction already names the relation.

### Make live scheduling coherent

Rejected. Coherent search uses a separate finite model.

## Open questions

- What syntax exposes the affine witness. **Owner:** language maintainers. **Decide by:** before Review.
- May surface syntax omit a compiler-generated parameter when typed IR still exposes it. **Owner:** tooling maintainers. **Decide by:** before parser implementation.
- Does a disjoint scope use no witness or a zero-sized nominal witness. **Owner:** type maintainers. **Decide by:** before generic APIs.
- Which atomics enter the first witnessed profile. **Owner:** VM maintainers. **Decide by:** before extension allocation.
- Which WIP-0011 certificate proves a bounded scope inverse. **Owner:** proof maintainers. **Decide by:** before theorem claims.
- Does WIP-0037 gain a TaskScope structural node. **Owner:** IR maintainers. **Decide by:** before graph integration.

## References

- [WIP-0039](WIP-0039-deterministic-structured-task-machine-and-global-rewind.md)
- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0015](WIP-0015-certified-adversarial-schedule-exploration.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0020](WIP-0020-semantic-coverage-and-evidence-accounting.md)
- [WIP-0028](WIP-0028-deterministic-ownership-borrowing-and-regions.md)
- [WIP-0031](WIP-0031-reversible-quantum-and-effect-polymorphism.md)
- [WIP-0035](WIP-0035-reversible-and-coherent-control-flow.md)
- [WIP-0036](WIP-0036-symbolic-resource-contracts-and-compositional-cost-evidence.md)
- [WIP-0037](WIP-0037-hierarchical-semantic-routine-graphs.md)
- [WIP-0038](WIP-0038-regular-instruction-forms-and-extension-registry.md)
- James Hoey and Irek Ulidowski, [*Reversing an Imperative Concurrent Programming Language*](https://doi.org/10.1016/j.scico.2022.102873), 2022.
- Shunya Oguchi and Shoji Yuen, [*CRIL*](https://arxiv.org/abs/2309.07310), 2023.
- Ivan Lanese, Iain Phillips, and Irek Ulidowski, [*An Axiomatic Theory for Reversible Computation*](https://arxiv.org/abs/2307.13360), 2023.
- Pietro Lami, [*Reversibility for Concurrent Memory Models*](https://doi.org/10.48676/unibo/amsdottorato/12274), 2024.
- Pratyush Agarwal et al., [*Stateless Model Checking under a Reads-Value-From Equivalence*](https://arxiv.org/abs/2105.06424), 2021.
- Leslie Lamport, [bakery algorithm specification and checked proof](https://lamport.azurewebsites.net/tla/boulangerie.html).
- Gadi Taubenfeld, [*The Black-White Bakery Algorithm*](https://www.disc-conference.org/wp/mirrors/disc2004/abstracts/22.html), 2004.
