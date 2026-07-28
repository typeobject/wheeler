# WIP-0039: Deterministic structured task machine and global rewind

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler language, compiler, verifier, VM, runtime, concurrency, and tooling maintainers |
| Created | 2026-07-27 |
| Updated | 2026-07-27 |
| Area | Language, VM, structured tasks, scheduling, shared atomics, rewind |
| Depends on | WIP-0001, WIP-0013, WIP-0028, WIP-0031, WIP-0038 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler adds a bounded deterministic task machine for classical and hybrid continuations. Tasks form one lexical tree. They use deterministic hierarchical identities and one verified selection policy.

Every accepted instruction, task lifecycle transition, scheduler transition, and shared atomic operation appends one record to one global event journal. Exact VM rewind consumes that journal in reverse global order. A task-private history never authorizes shared-state rewind.

Each event also records bounded causal metadata. The metadata covers task program order, task-tree relations, atomic modification order, exact read-from identity, conflicting observations, ownership transfer, and admitted synchronization. WIP-0015 may use it for schedule reduction. Causal out-of-order rollback remains a later proposal.

The first memory model is sequential consistency over explicit signed and Boolean atomic cells. Ordinary mutable owners remain task-local. The reference machine may execute every task on one host thread. A parallel implementation must commit the same semantic event order.

WIP-0040 defines source-level inverse execution for eligible task scopes. This WIP defines exact global rewind only. It also leaves I/O lifecycle, quantum target work, static quantum parallelism, and final source spelling with their current owners.

The acceptance program is a bounded one-shot Lamport bakery mutex. It must preserve mutual exclusion under every admitted schedule in the chosen complete finite domain and rewind the whole task machine to its exact initial state.

## Motivation

The current VM has one frame stack and one ordered history. Shared-memory tasks cannot preserve exact rewind with one undo stack per task.

```text
task A: x.store(1)
task B: observed = x.load()
```

If `B` observes `1`, undoing only `A` leaves an observation without its cause. Spawn, completion, join, read-modify-write, and ownership transfer create the same problem.

Host scheduling cannot define Wheeler order. Core count, preemption, work stealing, native lock fairness, allocation addresses, and completion timing must not change artifacts, replay, limits, diagnostics, or proofs.

WIP-0015 also needs explicit finite task choices. A canonical scheduler gives reproducible ordinary execution. Replay and exploration plans expose other checked choices without turning a disabled task into an implicit no-op.

Bakery is the first useful boundary test. It needs shared registers, schedule-sensitive polling, stable process identities, ticket ordering, bounded fairness, and no built-in mutex. If the machine cannot execute and rewind it, the concurrency contract is mostly a brochure.

## Research basis

| Research | Wheeler adoption |
| --- | --- |
| Lami's concurrent memory models | Model tasks, memory model, and scheduler as explicit state. Start with sequential consistency. |
| CRIL | Use hierarchical task identity, lifecycle events, and causal annotations. |
| Hoey and Ulidowski | Use stable event origins and require complete restoration without leftover evidence. |
| CauDEr imperative primitives | Record reads, absence, ranges, and whole-structure observations as real dependencies. |
| Axiomatic causal reversibility | Reserve causal safety and liveness for a checked later rollback proposal. |
| DMP, CoreDet, and TERN | Separate semantic communication order from host scheduling and completion. |
| CHESS and context bounding | Provide controlled replay and bounded schedule exploration. |
| Reads-value-from model checking | Permit optional search reduction without weakening exact read provenance. |
| Reversible session research | Defer channels until atomic task semantics and WIP-0032 boundaries work. |
| Quantum session types | Move each quantum owner to one task or split it into disjoint affine views. |
| Parallel quantum logics and QParallel | Keep static unitary parallelism in WIP-0037 DisjointGroup. |
| Lamport and Black-White Bakery proofs | Use one-shot bounded Lamport bakery first and Black-White Bakery for repeated entry. |

These results agree on one useful warning. Concurrent reversal needs more state than a pile of local stacks and more discipline than a cheerful thread pool.

## Semantic authorities

The design keeps these structures separate:

```text
J = total semantic event journal
G = causal dependency metadata
W = explicit source inverse witness
S = schedule plan or replay trace
R = external workflow observations and receipts
Q = static quantum routine and dependency graph
```

Their authorities are:

```text
rewindOne consumes the newest record in J
future causal rollback may use G
reverse task scope consumes W as new forward work
schedule replay and exploration consume S
external replay consumes R
unitary adjoint and target planning operate over Q
```

Exact backtracking, causal rollback, language inverse, and replay are not aliases.

## Use cases

### Structured private workers

A parent moves disjoint owners into child tasks and joins results. Immutable values may be shared only with compiler-approved evidence. Results requested as a vector use canonical TaskId order.

### Bakery mutual exclusion

A fixed task set shares signed and Boolean atomic cells for `choosing`, `ticket`, `criticalOwner`, and `entryCount`. Every task writes its own ticket cells and reads all ticket cells.

### Explicit schedule replay

A runner supplies a finite TaskId sequence. Every selected task must exist and be runnable. Replaying the same plan produces the same event trace and final state.

### Bounded exploration

WIP-0015 enumerates or synthesizes task selections and atomic interleavings. This WIP owns enabledness and transitions. WIP-0015 owns search, reduction, counterexamples, and proof.

### Hybrid continuation

A WIP-0004 continuation may resume into a task machine. Submission, live await, measurement, target completion, and accepted external results remain workflow horizons.

## Goals

- Define bounded lexical task scopes.
- Define deterministic hierarchical TaskIds and stable EventIds.
- Define spawn, execution, completion, join, and scope exit.
- Define canonical, replay, and exploration schedule profiles.
- Define one global event order and exact rewind law.
- Record bounded causal metadata without exposing causal rollback.
- Add sequentially consistent signed and Boolean atomics.
- Reject ordinary shared mutable aliases.
- Preserve current artifacts through root task zero.
- Permit a one-host-thread reference implementation.
- Export checked enabledness and access footprints to WIP-0015.
- Bound tasks, events, atomics, schedules, history, and diagnostics.
- Pass the bakery fixture without a built-in mutex.

## Non-goals

- Freeze `async`, `concurrent`, `parallel`, `await`, or task punctuation.
- Satisfy WIP-0032 required physical overlap with one host thread.
- Define I/O requests, cancellation, completion, or backend scheduling.
- Define a source inverse for interacting task scopes.
- Define causal out-of-order debugger rollback.
- Define relaxed, acquire, release, or architecture memory order.
- Permit ordinary mutable data races or detached tasks.
- Add mutex, channel, semaphore, or transactional-memory primitives.
- Expose native thread identity.
- Spawn inside coherent or unitary bodies.
- Treat target jobs as VM tasks.
- Assign numeric opcodes before WIP-0038 allocation.

## Terms and machine state

### Task and TaskId

A task is bounded Wheeler execution state, not an operating-system thread.

```text
Task {
    task_id
    parent_scope_id
    status
    frames
    owned_values
    scoped_shared_capabilities
    join_result
    spawn_ordinal
}

TaskId = Root
       | Child(parent_task_id, scope_ordinal, spawn_ordinal)
```

The parent advances its spawn ordinal in source evaluation order. Rewinding spawn restores the ordinal. Re-execution on the same branch recreates the same TaskId.

### EventId

```text
EventId = (workflow_epoch, task_id, task_local_sequence)
```

Journal position gives total order. EventId gives stable origin, diagnostics, read-from identity, and causal edges. It contains no timestamp or worker identity.

### Task scope and status

A TaskScope owns child tasks, join handles, atomic cells, scoped capabilities, limits, and completion state. It cannot exit with a live or unjoined child.

The initial states are `Created`, `Runnable`, `Running`, `BlockedOnJoin`, `Completed`, `Joined`, and `Failed`. A task trap traps the whole task machine under the first fail-stop profile.

### JoinHandle

`JoinHandle<T>` is affine and scope-owned. One successful join consumes it. Double join, cross-scope join, forged child identity, and scope exit with a live handle fail before mutation.

### Task transfer

A capture may be a copied `Copy` value, a moved owner, a compiler-approved immutable scoped share, a scoped atomic reference, or an admitted moved capability. Ordinary `borrow T` and `borrow mut T` do not cross spawn.

Task transfer is sealed compiler evidence. A normal WIP-0030 instance cannot make a socket copyable or a qubit shared.

### Atomic cells

`AtomicCell<T>` is an affine scope owner. `AtomicRef<T>` is a nonescaping scoped capability for atomic operations only. The first `T` set is signed 64-bit and Boolean.

Atomic cells cannot contain owners, loans, region pointers, foreign handles, I/O operations, provider values, or quantum resources.

### Sequential consistency

Every atomic operation has one place in total event order. A load observes the latest preceding store or read-modify-write to that cell, or the declared initial value. Total order agrees with each task's instruction order.

### Scheduler and SchedulePlan

The scheduler is VM state. The first policies are `CanonicalRoundRobin`, `Replay`, and `Explore`.

Canonical round robin selects the next runnable TaskId after the cursor with canonical wraparound. Replay and exploration consume a bounded SchedulePlan that binds artifact, extension, initial task tree, policy, selections, event bound, and fairness profile.

A disabled selection rejects before mutation.

### Event records and footprints

```text
TaskEventRecord {
    event_id
    global_sequence
    selected_task_id
    event_kind
    instruction_identity
    prior_task_delta
    prior_scheduler_delta
    prior_atomic_delta
    prior_task_tree_delta
    prior_ownership_delta
    prior_allocator_delta
    access_footprint
    causal_predecessors
    prior_machine_status
}
```

Footprints include task-local work, task-tree changes, atomic reads and writes, joins, ownership transfer, allocator changes, and workflow boundaries. A read records both its observed value and exact source write. Equal values do not make two writes the same cause.

The minimum causal relation contains task program order, spawn to first child event, last child event to join, atomic modification order, read-from, ordered conflicts, ownership transfer, and workflow order.

### Complete state and transition law

```text
C = (
    artifact,
    machine_status,
    workflow_epoch,
    task_tree,
    memory_model_state,
    scheduler,
    ownership_state,
    aggregate_store,
    owned_store,
    effect_state,
    global_history,
    causal_metadata,
    local_sequence,
    limits
)

select(C.scheduler, C.task_tree, policy) = task_id
execute(C, task_id) = (C2, event_record)
unstep(C2, event_record) = C
```

Failure publishes no partial state.

## Ownership

WIP-0005 and WIP-0006 own final source syntax. WIP-0028 owns moves, loans, regions, disjointness, and quantum ownership. WIP-0031 owns effect labels and callable kinds. WIP-0032 owns all external operation lifecycle.

The compiler owns capture classification, spawn ordinals, transfer evidence, bounds, footprint classification, and source mapping.

The verifier owns descriptor validity, capture ownership, affine handles, atomic typing, race rejection, effect compatibility, scope completion, and limits.

The VM owns task state, scheduler state, atomic state, global journal order, exact event records, rewind, task traps, join blocking, and diagnostics.

The runtime owns policy selection, plan input, optional host parallel execution, and workflow integration. Hosts own native threads, locks, queues, clocks, and affinity. None becomes portable semantics.

## Design

### Root compatibility

Old artifacts execute as root task zero under canonical scheduling. Their outputs, traps, snapshots, history counts, and rewind behavior remain unchanged unless they require the new extension.

### Scope and spawn

Scope entry validates descriptor and limits before publication. Spawn validates child entry, capacity, captures, and TaskId. It then moves or copies captures, creates the child frame and handle, updates the runnable set, and advances the parent as one event.

Rewind removes the child and handle. It restores captures, spawn ordinal, scheduler state, and parent control.

### Execution, completion, and join

The scheduler chooses one runnable task for each accepted transition. A private instruction touches only that task and its owned stores.

Completion requires returned frames, closed nested scopes, consumed obligations, legal ownership, and a valid result. Joining a live child blocks the parent. Completion wakes a blocked joiner deterministically. Join and wake remain globally ordered events.

Scope exit requires every child completed and joined, every atomic reference ended, every scope owner returned or dropped, and no blocked task.

### Scheduling and exploration

Replay validates task existence and enabledness at each position. It records observations, read-from, modification order, and footprints. Coverage, worker completion, and host timing never select program schedule.

WIP-0015 may use checked DPOR and Mazurkiewicz independence first. Reads-value-from reduction may follow after exact observations work. Every reduced class retains one concrete replayable plan.

### Atomic operations

The semantic family contains load, store, exchange, compare-exchange, fetch-add, fetch-subtract, and fetch-XOR. The first executable subset may be smaller if it still implements bakery.

Every operation validates reference liveness, scope, type, destination, arithmetic, history capacity, and event capacity before mutation.

A load records prior destination state. A store records prior cell value. Exchange and compare-exchange record prior cell, local results, and outcomes. Read-modify-write records enough to restore both cell and returned result.

### Ordinary mutable state

A task mutates locals and owners moved to it. A child cannot access a parent's ordinary mutable place through an alias. Sharing requires an AtomicRef or a later accepted synchronization type.

### Bakery fixture

The first fixture uses fixed `TASKS` and `MAX_TICKET` bounds. Each child owns one immutable process index. Shared cells model `choosing`, `ticket`, `criticalOwner`, and `entryCount`.

Each task publishes a ticket, waits through bounded loads, orders equal tickets by process index, enters one critical section through atomic exchange, increments the entry count, leaves, and clears its ticket.

Ticket arithmetic traps before overflow. The safety assertion is that at most one task owns the critical section at every event. Progress claims name the canonical fairness profile and finite bound.

A repeated-entry successor should use Black-White Bakery. Calling Lamport's unbounded ticket algorithm bounded does not make it so by positive thinking.

### Deadlock

The first core deadlock is a nonempty unfinished task set with no runnable task where every blocked task waits on an unfinished child. The VM emits one canonical bounded wait graph and traps. Busy polling is not deadlock. It may exhaust its loop or event bound.

### Physical parallel execution

A native runtime may serialize, execute proven-disjoint work, or use deterministic validation. First physical completion cannot choose semantic order. The one-thread transition kernel remains the oracle.

## Reversibility and history

The task machine owns one LIFO journal. `rewindOne` consumes only its newest record and restores task frames, task status, scheduler, task tree, handles, atomics, ownership, allocation, machine status, and sequence state.

WIP-0039 defines no complete task-scope inverse. Existing `UNCALL` remains ordinary new execution inside one task. WIP-0040 owns scope inverse witnesses.

`COMMIT` applies to the complete machine. The first profile permits it only when root has no live child scope.

History capacity is global. Exhaustion traps before the next event. No task may discard another task's history.

Causal rollback is not exposed. A successor may consume causal metadata only after it defines checked independence, user-visible branching, storage, and proof rules.

## I/O integration

WIP-0032 remains authoritative for requests, operations, submission, live await, cancellation, completion, selection, lanes, uncertainty, and receipts.

Submission and live await remain barriers. Accepted completion resumes a verified task continuation in a new classical epoch. One-thread task execution does not satisfy required physical I/O concurrency.

## Quantum integration

Task and atomic effects reject inside coherent and unitary bodies. A classical task may move one affine quantum owner to one child or move proven-disjoint views to different children. Every view must return before a cross-view operation.

Static unitary parallelism remains WIP-0037 `DisjointGroup`. Target submission remains a WIP-0003 and WIP-0032 operation. Provider jobs are not VM tasks.

The runtime uses `QuantumSubmission` and reserves Task for this VM model.

## Proof implications

Proof subjects include task-tree well-formedness, spawn and join ownership, schedule enabledness, sequential consistency, read-from, race freedom, event independence, bounded deadlock, mutual exclusion, and exact global rewind.

A passing bakery test is evidence. WIP-0011 owns theorem and certificate forms. WIP-0015 owns bounded universal schedule claims and counterexamples.

## Bytecode, persistence, and compatibility

WIP-0039 requires one standard executable extension under WIP-0038. This proposal names semantics but reserves no numbers.

The extension needs task, scope, capture, result, scheduler, schedule-plan, atomic, footprint, effect, and limit descriptors. Instruction families cover scope entry and exit, spawn, join, and scalar atomic operations.

An old loader rejects the required unknown extension before execution. Existing opcodes and fields do not change meaning.

SchedulePlan is a separate canonical run input bound to exact artifact and scheduler identities. It stores no native thread or timing data.

WIP-0004 owns durable continuation state. The first profile may require all children joined before persistence. No profile persists native stacks or host locks.

Public package identity includes accepted task and shared effects, required extension, memory model, transfer modes, and resource contracts.

## Safety, limits, and failures

Artifacts or policy bound live and total tasks, tree depth, frames, scopes, handles, atomics, schedule entries, events, history records and bytes, footprint entries, blocked edges, diagnostics, and total work.

The compiler or verifier rejects escaping tasks, crossed ordinary loans, shared mutable aliases, forged transfer evidence, copied handles, cross-scope joins, bad atomic types, owner values in atomics, coherent task effects, active-scope commit, and unsupported extensions.

The VM traps before mutation on exhausted bounds, invalid TaskId, a nonrunnable selection, double join, dirty scope exit, arithmetic overflow, bakery ticket overflow, corrupt event metadata, or deterministic join deadlock.

Native worker failure and external uncertainty follow their owning WIPs. They do not become task rewind.

## Migration and deletion

1. Represent the current context as root task zero.
2. Add task-aware snapshots and observer events without changing old results.
3. Replace the single frame-stack owner with a task table.
4. Extend StepRecord into global task event records.
5. Add private-state scope, spawn, completion, join, and exit.
6. Add canonical and replay selection.
7. Add signed and Boolean atomics.
8. Add footprints and WIP-0015 integration.
9. Add ordinary bakery.
10. Integrate ownership, effects, testing, coverage, and workflow horizons.
11. Rename quantum target-submission Task types.
12. Add native parallel execution only after trace parity.
13. Delete task-private rewind, host-thread identity, duplicate schedulers, and unbounded paths.

## Progress

- [x] Quantum target work uses QuantumSubmission. I/O backend work uses IoProviderResult. Task terminology is reserved for this VM model.
- [x] Existing artifacts execute through a canonical task table containing root task zero with stable TaskId and EventId origins.
- [x] The compatibility VM owns typed root-task lifecycle state, a deterministic round-robin selector, and rewindable task and scheduler deltas. Multi-task lifecycle remains open.
- [ ] Task-aware snapshots and complete global task event records exist.
- [ ] Structured spawn, completion, join, and exit execute.
- [ ] Canonical scheduling is deterministic.
- [ ] Replay rejects disabled choices before mutation.
- [ ] One global journal rewinds task lifecycle.
- [ ] Signed and Boolean atomics are sequentially consistent.
- [ ] Atomic transitions rewind exactly.
- [ ] Ordinary mutable cross-task aliases fail verification.
- [ ] WIP-0015 consumes the finite task model.
- [ ] Bakery passes bounded safety, replay, and rewind tests.
- [ ] WIP-0032 resumes task continuations without duplicate lifecycle rules.
- [ ] Coherent and unitary task effects reject.
- [ ] Native execution matches the reference trace.
- [ ] Conflicting prototypes are deleted.

## Testing and acceptance

- [x] Existing single-task outputs, traps, history, and rewind remain unchanged. Snapshots add root task and workflow-epoch identity.
- [ ] Spawn rewind restores captures, ordinal, task table, handle, and scheduler.
- [ ] Completion rewind restores frames, result, blocked joiner, and runnable set.
- [ ] Join and scope-exit rewind restore ownership and tables.
- [ ] A task-private undo cannot bypass a newer foreign-task event.
- [ ] Canonical scheduling matches under one or many host workers.
- [ ] Replay rejects nonexistent, completed, blocked, and forged TaskIds.
- [ ] Schedule, event, and history exhaustion fail before mutation.
- [ ] Atomic operations satisfy generated forward and rewind laws.
- [ ] SC loads observe the latest prior write.
- [ ] Ordinary shared mutable access rejects before execution.
- [ ] Active-scope commit and coherent task effects reject.
- [ ] Join cycles produce one canonical diagnostic.
- [ ] Every admitted complete small bakery schedule preserves mutual exclusion.
- [ ] The canonical fair bakery schedule lets every task enter.
- [ ] Bakery overflow traps before ticket publication.
- [ ] Complete rewind restores the exact bakery initial snapshot.
- [ ] WIP-0015 replays one selected bakery interleaving.
- [ ] Task rewind cannot cross WIP-0032 horizons.
- [ ] Quantum submissions remain external operations.
- [ ] Reference and native runtimes emit equal traces.
- [ ] Reference pages change only after implementation works.

## Alternatives

### Per-task undo stacks

Rejected. Shared observations require one event order.

### Host scheduler semantics

Rejected. Operating-system timing is not a language definition.

### Built-in mutex first

Rejected. It would hide the atomic behavior that bakery must test.

### Weak memory first

Rejected. Sequential consistency is the smaller executable base.

### Canonical schedule only

Rejected. Exploration and replay need explicit alternatives.

### Causal rollback first

Rejected. Exact global LIFO rewind is the smaller trusted contract.

## Deferred successors

Causal-consistent debugger rollback must define EventId selection, dependency closure, reverse-topological undo, workflow horizons, branch behavior, storage, and WIP-0011 certificates.

Reversible channels need paired send and receive identities, communication keys, typed endpoints, bounded queues, checkpoint rules, and reverse deadlock prevention.

Weak memory needs explicit visibility, propagation, buffering, or transactional state. Adding order names to SC opcodes would only make the bug more formally dressed.

Physically parallel deterministic execution remains an implementation profile. It must preserve the reference event order and traces.

## Open questions

- Which WIP-0031 labels express task creation, blocking, and shared access. **Owner:** effect maintainers. **Decide by:** before source syntax.
- Which source form introduces TaskScope without conflicting with IoScope. **Owner:** language and I/O maintainers. **Decide by:** before Review.
- What sealed task-transfer names replace provisional names. **Owner:** ownership maintainers. **Decide by:** before generic APIs.
- Does each instruction remain one permanent schedule turn. **Owner:** VM and model-checking maintainers. **Decide by:** before SchedulePlan freezes.
- Which atomic subset enters the bakery gate. **Owner:** VM maintainers. **Decide by:** before opcode allocation.
- Must the first durable continuation have every child joined. **Owner:** runtime maintainers. **Decide by:** before persisted task checkpoints.

## References

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0002](WIP-0002-unified-classical-quantum-semantics.md)
- [WIP-0003](WIP-0003-quantum-target-and-qiskit-backend.md)
- [WIP-0004](WIP-0004-hybrid-jobs-history-and-replay.md)
- [WIP-0005](WIP-0005-wheeler-source-language.md)
- [WIP-0006](WIP-0006-concrete-syntax-tooling-and-teaching.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0012](WIP-0012-wheeler-standard-library.md)
- [WIP-0013](WIP-0013-typed-frames-control-flow-and-storage.md)
- [WIP-0015](WIP-0015-certified-adversarial-schedule-exploration.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0020](WIP-0020-semantic-coverage-and-evidence-accounting.md)
- [WIP-0025](WIP-0025-native-ffi-and-system-integration.md)
- [WIP-0028](WIP-0028-deterministic-ownership-borrowing-and-regions.md)
- [WIP-0029](WIP-0029-parametric-polymorphism-and-bounded-specialization.md)
- [WIP-0030](WIP-0030-coherent-type-classes-and-associated-types.md)
- [WIP-0031](WIP-0031-reversible-quantum-and-effect-polymorphism.md)
- [WIP-0032](WIP-0032-unified-io-fabric-and-durability-receipts.md)
- [WIP-0036](WIP-0036-symbolic-resource-contracts-and-compositional-cost-evidence.md)
- [WIP-0037](WIP-0037-hierarchical-semantic-routine-graphs.md)
- [WIP-0038](WIP-0038-regular-instruction-forms-and-extension-registry.md)
- Pietro Lami, [*Reversibility for Concurrent Memory Models*](https://doi.org/10.48676/unibo/amsdottorato/12274), 2024.
- Shunya Oguchi and Shoji Yuen, [*CRIL*](https://arxiv.org/abs/2309.07310), 2023.
- James Hoey and Irek Ulidowski, [*Reversing an Imperative Concurrent Programming Language*](https://doi.org/10.1016/j.scico.2022.102873), 2022.
- Pietro Lami et al., [*Reversible Debugging of Concurrent Erlang Programs*](https://doi.org/10.1016/j.jlamp.2024.100944), 2024.
- Ivan Lanese, Iain Phillips, and Irek Ulidowski, [*An Axiomatic Theory for Reversible Computation*](https://arxiv.org/abs/2307.13360), 2023.
- Joseph Devietti et al., [*DMP*](https://llvm.org/pubs/2009-03-ASPLOS-DMP.html), 2009.
- Tom Bergan et al., [*CoreDet*](https://llvm.org/pubs/2010-04-ASPLOS-DeterministicCompiler.html), 2010.
- Heming Cui et al., [*Stable Deterministic Multithreading through Schedule Memoization*](https://llvm.org/pubs/2010-10-OSDI-DeterministicMT.html), 2010.
- Madan Musuvathi et al., [*CHESS*](https://www.microsoft.com/en-us/research/publication/chess-a-systematic-testing-tool-for-concurrent-software/), 2007.
- Madan Musuvathi and Shaz Qadeer, [*Iterative Context Bounding*](https://www.microsoft.com/en-us/research/publication/iterative-context-bounding-for-systematic-testing-of-multithreaded-programs-2/), 2007.
- Pratyush Agarwal et al., [*Stateless Model Checking under a Reads-Value-From Equivalence*](https://arxiv.org/abs/2105.06424), 2021.
- Oguchi, Yuen, and Yoshida, [*RevMiGo*](https://doi.org/10.1007/978-3-031-97063-4_9), 2025.
- Claudio Antares Mezzina et al., [*Checkpoint-Based Rollback Recovery in Session Programming*](https://arxiv.org/abs/2312.02851), 2023.
- Claudio Antares Mezzina et al., [*revTPL*](https://arxiv.org/abs/2212.03687), 2022.
- Simon Gay and Rajagopal Nagarajan, [*Communicating Quantum Processes*](https://arxiv.org/abs/quant-ph/0409052), 2004.
- Ivan Lanese, Ugo Dal Lago, and Vikraman Choudhury, [*Towards Quantum Multiparty Session Types*](https://arxiv.org/abs/2409.11133), 2024.
- Mingsheng Ying, Li Zhou, and Yangjia Li, [*Reasoning about Parallel Quantum Programs*](https://arxiv.org/abs/1810.11334), 2018.
- Thomas Häner et al., [*QParallel*](https://arxiv.org/abs/2210.03680), 2022.
- Leslie Lamport, [bakery algorithm specification and checked proof](https://lamport.azurewebsites.net/tla/boulangerie.html).
- Leslie Lamport, [*On Concurrent Reading and Writing*](https://www.microsoft.com/en-us/research/publication/concurrent-reading-writing/), 1977.
- Gadi Taubenfeld, [*The Black-White Bakery Algorithm*](https://www.disc-conference.org/wp/mirrors/disc2004/abstracts/22.html), 2004.
- Wim H. Hesselink, [*Correctness and Concurrent Complexity of the Black-White Bakery Algorithm*](https://doi.org/10.1007/s00165-016-0364-4), 2016.
