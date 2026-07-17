# WIP-0004: Hybrid jobs, history, and replay

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler runtime, history, and quantum maintainers |
| Created | 2026-07-17 |
| Updated | 2026-07-17 |
| Area | Hybrid runtime, quantum jobs, transactions, replay |
| Depends on | WIP-0001, WIP-0002, WIP-0003 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler executes hybrid programs as deterministic classical continuations separated by explicit quantum submission and observation events. A `HybridRun` owns classical reversible state, a bounded ordered event log, durable quantum job identities, target provenance, and commit horizons. Local simulators and remote hardware use the same asynchronous lifecycle even when local work completes immediately.

The runtime distinguishes undo from replay and retry. Classical WIP-0001 transitions can be rewound to the latest committed barrier. Recorded measurement and provider results can be replayed to reproduce later classical decisions without rerunning hardware. Retrying creates a new physical preparation and submission lineage. A transaction that has crossed measurement or submission can restore classical state and discard or compensate outputs, but it cannot claim to recreate an unknown prior quantum state.

## Motivation

The hybrid examples are workflows, not single instruction streams. `QuantumOptimizer` and `QuantumNeuralNetwork` repeatedly prepare circuits, wait for sampled results, and update classical parameters. `SurfaceCode` needs target-resident fast feedback for one cycle and host-visible history across cycles. `QuantumCompiler` runs calibration experiments whose results may become stale as hardware changes.

Today's cloud quantum execution is queued, asynchronous, fallible, capability-dependent, and nondeterministic. Future tightly coupled systems may make the same boundary faster, but Wheeler should not define different program semantics based on whether a job takes microseconds or hours.

A reversible language also needs to be precise about external observations. Retaining a measurement outcome permits deterministic replay of the classical suffix; it does not reverse collapse. Cancelling a provider job may race with completion. Cleaning history makes old execution intentionally unavailable. These rules belong to one runtime contract rather than ad hoc `transaction`, `hist`, and `clean` syntax.

## Use cases

### Variational optimization

Each optimizer iteration records parameter state, semantic circuit identity, target plan, submission, measured result, cost, and reversible classical update. Replaying an iteration uses the recorded result. Retrying creates a new submission and may produce a different result distribution.

### Remote suspension and recovery

A process submits a hardware job, persists a continuation, and exits. A later process recovers the provider job by external ID, validates the result identity and bounds, and resumes exactly once.

### Stale calibration

A compilation workflow starts calibration against one target descriptor. Before completion, policy selects a newer calibration epoch. The old result remains attributable but cannot update current compiler state unless an explicit policy accepts it.

### Transaction after measurement

A hybrid transaction updates tentative classical state, submits a circuit, and receives a measurement. If a later check fails, rollback restores the classical checkpoint and discards the observation from the active branch. It does not restore the measured hardware state; a retry must prepare and submit again.

### Target-resident correction cycle

A supported target executes gates, syndrome measurement, reset, bounded decoding, and correction inside one WIP-0002 region. The host event log records the region submission and result rather than pretending every target-internal operation was a local reversible VM step.

## Goals

- Give hybrid source one lifecycle across local simulation, OpenQASM executors, remote hardware, and future targets.
- Persist bounded continuations and recover jobs without duplicate result application.
- Record nondeterministic observations and target provenance for deterministic classical replay.
- Define transaction rollback before and after submission, measurement, reset, and external effects.
- Separate rewind, replay, retry, compensation, cancellation, and branch discard.
- Make history cleanup an explicit commit horizon.
- Support parameterized iterative workflows without retaining live remote qubit handles between jobs.
- Reject stale, mismatched, malformed, duplicate, or oversized results before state mutation.

## Non-goals

- Make measurement or arbitrary external effects physically reversible.
- Guarantee provider cancellation or deterministic hardware samples.
- Keep cloud qubits alive across unrelated submissions unless a target explicitly provides a session capability.
- Define VM shared-memory threads or general distributed transactions.
- Choose optimization algorithms, gradient methods, error mitigation, or retry counts for applications.
- Store credentials or unrestricted provider payloads in history.

## Terms and semantic model

A `HybridRun` is identified execution of one verified artifact and contains:

```text
HybridRun = (
  artifact_id,
  run_id,
  active_branch,
  classical_checkpoint,
  continuation,
  event_log,
  pending_jobs,
  commit_horizon,
  limits,
  status
)
```

A **continuation** names a verified resume point and typed live classical values. Quantum resources may be included only through a target session handle whose capability explicitly permits persistence; ordinary remote qubit identities never cross the boundary.

An **event** is an immutable, sequence-numbered transition envelope. An event may contain bounded semantic data or a content-addressed reference. Initial event kinds are:

- classical checkpoint and commit;
- effect request, receipt, compensation, and barrier;
- target descriptor selection and lowering-plan identity;
- quantum submission request and provider acknowledgement;
- job state observation and cancellation request;
- quantum result receipt, rejection, and application;
- branch creation, activation, discard, retry, and completion;
- structured trap and recovery decision.

The active state is a deterministic reduction of the checkpoint and accepted events. Duplicate delivery of the same event identity is idempotent.

### Distinct operations

- **Rewind** consumes WIP-0001 classical step records down to the commit horizon.
- **Replay** re-applies recorded accepted events and observations to reproduce classical state.
- **Retry** creates a new child lineage with a new submission identity.
- **Compensate** invokes an effect-specific external operation and records its result.
- **Cancel** asks a target to stop work; it may not succeed.
- **Discard** prevents an event or branch from affecting active state while retaining provenance according to policy.

These terms appear in APIs, diagnostics, and documentation.

## Ownership and boundaries

`wheeler-core` owns deterministic WIP-0001 checkpoints and rewind within a classical continuation.

`wheeler-runtime` owns `HybridRun`, event reduction, continuation validation, job correlation, result application, retry lineages, commit horizons, and policy hooks.

WIP-0003 target adapters own provider lifecycle translation and job recovery. They do not apply results to program state.

Applications own algorithm policy: target choice within host grants, shot count within limits, retry conditions, optimizer convergence, stale-result acceptance where permitted, and which outputs become externally committed.

Hosts own persistence, clocks used for operational deadlines, credentials, user approval, and network reachability. Host storage cannot edit semantic events without integrity failure.

## Design

### Continuation boundaries

The compiler emits suspension points at every target submission or host effect that may not complete immediately. A continuation includes exact artifact and function identities, resume PC or region edge, typed classical live values, expected result schema, branch identity, and bounds.

Continuation serialization rejects raw Java object graphs, host pointers, provider objects, and ordinary quantum handles. Values use canonical `.wbc` type schemas or content-addressed bounded artifacts.

Local simulation still travels through submission, completion, validation, and resume states. An implementation may execute them in one process turn but cannot bypass identity or result checks.

### Submission identity

A quantum submission identity covers:

- artifact and semantic-region hashes;
- source run, branch, and sequence;
- target descriptor and derived-executable fingerprints;
- parameter schema and canonical bindings;
- result request, shot count, seed policy, and execution options;
- lowering and mitigation policy identities;
- declared cost and result ceilings.

Provider acknowledgement adds a redacted external job identity. Resubmitting after an ambiguous failure requires reconciliation or a new retry lineage; the runtime never assumes “no acknowledgement” means “not submitted.”

### Result application

Before applying a result, the runtime checks job state, submission identity, expected schema, target provenance, bit/register order, result bounds, branch activity, continuation state, and duplicate application.

Application is one atomic classical transition: either the validated typed result and completion event become visible together, or active state remains unchanged. Late results for cancelled, discarded, or superseded branches are retained or dropped by bounded audit policy but never mutate active state.

### Replay modes

A run declares one of these observation policies:

- `record`: execute targets and retain accepted observations;
- `replay`: prohibit target submission and require matching recorded observations;
- `verify-replay`: replay classical state while optionally submitting comparison jobs whose results cannot affect it;
- `fresh`: deliberately create new lineages and observations.

Replay validates artifact, semantic region, parameter, schema, and policy identity. It does not substitute an approximately similar circuit or target result.

### Transactions

A transaction tracks its current effect phase:

1. **Reversible phase:** only WIP-0001 reversible classical operations and live WIP-0002 unitary operations. Abort applies inverse/uncompute and rewinds classical state.
2. **Prepared external phase:** a submission or effect request exists but has not produced an accepted observation. Abort restores classical state and requests cancellation; the external job may continue and is quarantined from the active branch.
3. **Observed phase:** measurement or another external receipt has been accepted. Abort restores the classical checkpoint, discards the active observation branch, and performs declared compensation where possible. Unknown physical state is not restored.
4. **Committed phase:** external outputs and history before the horizon are no longer reversible by this transaction.

The compiler rejects transaction code whose declared rollback guarantee is stronger than its effects permit. `rollback` after measurement means branch rollback, not physical inverse.

### History and commit horizons

Three records remain conceptually separate even if stored together:

- step history for local machine rewind;
- observation/event history for replay and provenance;
- optional debug traces with no semantic authority.

`commit` advances the active rewind horizon only after required event and state persistence succeeds. `clean history before ...` requests retention policy and cannot remove records still referenced by an active continuation, retry lineage, proof, or audit requirement.

Deletion may preserve a cryptographic or content identity without preserving replayable payloads. After payload deletion, the runtime reports that replay is unavailable rather than fetching fresh nondeterminism under the old identity.

### Iterative hybrid workflows

Loops such as `QuantumOptimizer.optimize` compile into repeated classical continuation and quantum region stages. Circuit templates and target executables may be cached; bindings, result requests, and observations remain iteration-specific.

A QNN gradient computation may submit parameter-shift or other explicitly selected batches. The language does not pretend a measured training register survives into the next iteration. State that persists is classical parameter/history state or an explicit target session capability.

### Target-resident workflows

A WIP-0003 target may execute a bounded hybrid subgraph internally. Wheeler records it as one target submission with declared internal effects, resource bounds, and returned observations. The adapter supplies an execution report; the host does not fabricate per-gate local history.

Surface-code decoding that cannot meet latency through host round trips must be target-resident or rejected. A host-split emulation is a distinct plan with explicit semantics and performance expectations.

## Reversibility and history

WIP-0001 reverse laws apply only to local classical state and reversible effect contracts. WIP-0002 adjoints apply only while the relevant coherent resources remain available. Event replay reproduces classical decisions from recorded observations but does not recreate the quantum state that generated them.

A `QuantumResult` is immutable evidence, not an undo payload. Retrying from the same preparation may yield another valid but different result. Both lineages retain distinct identities.

After a commit horizon, Wheeler makes no promise to rewind earlier state even if an implementation still has bytes in a cache. History availability is semantic and policy-controlled, not inferred from storage accidents.

## Concurrency and determinism

Each `HybridRun` has one total semantic event order. Jobs may execute and complete concurrently, but completion arrival does not determine application order. A continuation declares which results it awaits and the deterministic reduction order for batches.

Event producers use idempotency keys and bounded queues. Polling schedules, provider queue times, wall-clock timestamps, and log ordering are operational metadata unless the program explicitly requests a time effect.

General parallel branches require a later structured-concurrency WIP. This proposal permits independent target jobs but does not allow unsynchronized shared classical mutation.

## Quantum and proof implications

Replay logs can support empirical reproducibility and later proof checking, but sampled evidence does not prove a theorem. A future proof system may reference semantic region hashes, target-independent certificates, or bounded empirical claims with explicit confidence.

A proof about a unitary region is independent from a particular noisy run. A claim about hardware fidelity identifies target, calibration, shots, estimator, and uncertainty through event provenance.

## Bytecode, persistence, and compatibility

Hybrid continuation descriptors and expected event/result schemas are semantic `.wbc` data. Run checkpoints, events, provider acknowledgements, and results are mutable runtime records in a separate versioned persistence format.

Every persisted record identifies schema version and artifact hash. Migrations are pure, bounded transformations that preserve event identities or create an explicitly linked new run. Unknown required events stop recovery.

Provider metadata is filtered into a bounded stable envelope plus optional content-addressed attachments. Runtime persistence never relies on deserializing arbitrary provider SDK objects.

## Safety, limits, and failures

A run has limits for events, history bytes, branches, pending jobs, submissions, retries, shots, result bytes, attachment bytes, elapsed policy budget, and provider cost where available. Limit exhaustion traps or requests a policy decision before new work is submitted.

Persistence uses integrity checks and atomic checkpoint/event commits. Recovery treats truncated, reordered, duplicated, mismatched, or forged records as structured failures.

Retries are never infinite by default. Compensation and cancellation failures are recorded and surfaced. A user can see whether a run is active, waiting, uncertain, partially compensated, completed, trapped, or unrecoverable.

## Migration and deletion

1. Implement in-memory `HybridRun`, canonical event identities, and deterministic reduction over a mock target.
2. Add compiler-generated suspension points and typed continuations for one optimizer iteration.
3. Add atomic result validation/application and duplicate/late-result handling.
4. Add persisted checkpoints, event recovery, and provider job reconciliation.
5. Implement replay, fresh retry lineages, and transaction effect phases.
6. Run the optimizer and QNN fixtures through local simulation and a queued mock target.
7. Add dynamic surface-code fixture planning and target-resident event reporting.
8. Replace ad hoc `hist`, transaction, rollback, and cleanup behavior in examples with accepted semantics.
9. Delete any runtime path that stores provider objects or treats measurement results as reversible thread snapshots.

## Progress

- [x] Hybrid run and deterministic event reducer exist in memory.
- [x] Typed continuations suspend, persist, recover, and resume one acknowledged quantum job.
- [x] Result identity and exactly-once application are enforced before classical mutation.
- [ ] Recovery handles every provider lifecycle and ambiguous acknowledgement state.
- [x] Replay and fresh retry lineages are distinct and tested.
- [x] Reversible, prepared-external, observed, and committed transaction phases are implemented.
- [ ] Optimizer, QNN, cleanup, compensation, and dynamic-circuit fixtures satisfy acceptance tests.

## Testing and acceptance

- [x] Event reduction is deterministic under reordered and duplicated delivery.
- [ ] Local immediate completion and remote delayed completion produce identical semantic event sequences modulo operational metadata.
- [ ] Recovery resumes queued, running, succeeded, failed, cancelled, and unknown provider states without double submission or result application.
- [ ] Result validation rejects wrong artifacts, regions, targets, bindings, schemas, branches, shot counts, and oversized payloads; content-identified tasks cover artifacts, regions, requests, targets, branches, shots, seeds, and outcome widths, while symbolic bindings remain.
- [x] Replay reproduces recorded classical state without calling a target; optimizer execution remains.
- [x] Fresh retry creates a distinct submission lineage.
- [x] Rollback before submission, after acknowledgement, and after measurement follows the declared transaction phase without claiming physical reversal.
- [x] Late results from cancelled or discarded branches cannot mutate active state.
- [ ] Commit and cleanup make earlier rewind/replay availability explicit and respect live references.
- [ ] Optimizer and QNN fixtures do not retain quantum handles across ordinary remote job boundaries.
- [ ] Surface-code fixtures require target-resident capabilities when host latency would violate the plan.
- [ ] Persistence corruption, truncation, unknown required events, and target restarts have bounded failure tests; corruption, truncation, and unknown enums are covered.
- [x] Credentials and unrestricted provider payloads never enter persistence.
- [x] Current runtime documentation explains rewind, inverse, uncompute, replay, retry, cancel, compensate, and discard.

## Alternatives

### Block the VM thread until a quantum job completes

Rejected. It cannot survive remote queueing, process restart, mobile suspension, or long hardware jobs, and it obscures cancellation and result identity.

### Treat quantum jobs as reversible instructions

Rejected. A submission and measurement are external effects. Classical rollback and recorded replay do not restore unknown physical state.

### Rerun hardware during replay

Rejected. That is retry or comparison, not replay, and can produce different observations, costs, and target conditions.

### Keep quantum registers alive as provider handles in objects

Rejected as the portable baseline. Most current cloud jobs do not provide that lifetime, provider objects are not serializable language values, and future sessions require explicit capabilities.

### Store one full VM snapshot around every job

Rejected as the semantic model. Typed continuations plus WIP-0001 checkpoints and ordered events define smaller, verifiable ownership and bounded recovery.

## Open questions

- Which event-log persistence encoding and integrity mechanism should be standardized first? — **Owner:** runtime maintainers — **Decide by:** before durable recovery implementation
- Which stale-result policies are generic runtime choices versus application-supplied decisions? — **Owner:** runtime and language maintainers — **Decide by:** before this WIP enters Review
- What minimum target-session lifecycle is needed before a quantum handle may legally appear in a persisted continuation? — **Owner:** quantum runtime maintainers — **Decide by:** before session support is implemented

## References

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0002](WIP-0002-unified-classical-quantum-semantics.md)
- [WIP-0003](WIP-0003-quantum-target-and-qiskit-backend.md)
- [`QuantumOptimizer.w`](../../../wheeler-examples/src/main/wheeler/QuantumOptimizer.w)
- [`QuantumNeuralNetwork.w`](../../../wheeler-examples/src/main/wheeler/QuantumNeuralNetwork.w)
- [`SurfaceCode.w`](../../../wheeler-examples/src/main/wheeler/SurfaceCode.w)
- [`QuantumCompiler.w`](../../../wheeler-examples/src/main/wheeler/QuantumCompiler.w)
