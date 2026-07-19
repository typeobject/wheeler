# Hybrid runs and replay

A quantum or hybrid Wheeler workflow executes as a `HybridRun`. The run owns deterministic classical state, its workflow continuation, acknowledged target jobs, accepted observations, active branch, transaction phase, and a bounded semantic event log.

The runtime does not represent a remote queue wait as a blocked VM instruction. It advances deterministic workflow edges until a measurement submission, records the acknowledged job identity, and enters `WAITING`. A later call resumes from that continuation after validating the result.

## Lifecycle

A new run starts in `ACTIVE`:

```java
HybridRun run = HybridRun.start(program, target);
RunStatus status = run.advance();
```

`advance()` stops at one of these states:

- `WAITING`: a target acknowledged a quantum job;
- `COMPLETED`: the workflow reached its verified halt;
- `TRAPPED`: a bounded semantic failure stopped execution.

A waiting run accepts a result with a bounded timeout:

```java
status = run.resume(Duration.ofSeconds(30));
```

Local ideal simulation uses the same submit, acknowledge, validate, apply, and resume transitions as a delayed target. Fast completion does not bypass job or result identity.

`runToCompletion()` is a blocking convenience around the same state machine. It does not define a separate execution path.

## Events

Every semantic transition is an immutable `HybridEvent` with:

- run, branch, sequence, and workflow-edge identity;
- event kind;
- bounded job and target identity;
- a kind-specific bounded value and detail;
- a SHA-256 content identity.

The initial vocabulary records run start, target selection, transaction start or abort, submission, result application, cancellation request, branch discard or retry, commit, completion, and trap.

`HybridEventReducer` accepts unordered at-least-once delivery. It sorts by sequence, removes identical duplicate deliveries, and rejects gaps, conflicting sequence occupants, mixed run identities, inactive-branch mutation, and result applications without a matching submission. Arrival order is not semantic order.

Operational timestamps, polling attempts, queue position, and log interleaving are not semantic events.

## Result application

Before mutating classical state, the run checks:

- job identity;
- target identity;
- task content identity covering the `.wbc` artifact, register, basis state, circuit or adjoint sequence, shot request, and seed policy;
- exact shot count;
- full-register outcome width;
- active continuation and branch;
- event capacity.

The accepted observation event and classical effect boundary are then applied once. A second `resume()` is rejected by lifecycle state. A malformed result leaves the continuation, global values, and event stream unchanged.

Measurement outcomes use Wheeler's canonical little-endian integer representation. Provider display strings do not enter event state.

## Persistence and recovery

`HybridRunStore` encodes a `HybridRunSnapshot` as a canonical bounded binary record with a trailing SHA-256 integrity digest. A snapshot contains:

- schema, artifact, run, mode, status, branch, and limits;
- commit horizon;
- typed global values and exact workflow edge;
- pending acknowledged job and target identity, if any;
- transaction checkpoint and phase, if active;
- the complete bounded semantic event stream.

Writes use temporary output and atomic replacement when the host supports it. Decoding rejects bad magic, unknown enums, invalid counts, truncation, trailing payload, integrity failure, header/reducer disagreement, and continuation identity mismatch.

Recovery replays deterministic workflow edges and accepted observations from the start, then compares the reconstructed globals with the persisted typed continuation. At a waiting edge it calls `QuantumTarget.recover(jobId, task)`. Recovery never turns an acknowledged job into a new submission. A target that cannot reconcile that identity fails recovery explicitly.

Provider SDK objects, credentials, host pointers, arbitrary object graphs, and raw quantum handles are not persisted.

Atomic replacement protects publication from a torn userspace write when the host supports it; the current store does not return data, metadata, or namespace durability evidence. [WIP-0032](../proposals/WIP-0032-unified-io-fabric-and-durability-receipts.md) will place snapshot I/O under the unified operation lifecycle and typed receipt model. Until then, “snapshot written” is not a power-loss theorem.

## Replay and retry

Replay and retry are different operations.

```java
ExecutionResult replayed = HybridRun.replay(program, recordedSnapshot);
String newJob = waitingRun.retry();
```

Replay requires a completed event stream with the exact artifact identity. It executes the classical workflow using recorded accepted observations and never calls a target.

Retry requests cancellation of the current job, discards that branch, creates a new branch, and performs a fresh physical submission. The new job may return another valid observation. A late result from the discarded lineage has no active continuation through which to mutate state.

Cancellation is only a request. Its return value does not prove that remote hardware stopped.

## Transactions

A transaction begins only at an active clean workflow boundary:

```java
run.beginTransaction();
```

Its phase changes according to observed effects:

| Phase | Abort behavior |
| --- | --- |
| `REVERSIBLE` | Restore the typed classical checkpoint. |
| `PREPARED_EXTERNAL` | Restore classical state, request cancellation, and quarantine the acknowledged job branch. |
| `OBSERVED` | Restore classical state and discard the observation branch. The measured physical state is not restored. |
| `COMMITTED` | Reject abort. |

`abortTransaction()` reports whether cancellation was requested and whether an accepted observation was discarded. An abort after an external edge creates a new branch. Running forward again performs a new preparation and submission.

`commitTransaction()` records a commit event, clears local rewind history, and advances the event commit horizon. A workflow `commit()` performs the same horizon transition for an active transaction.

Transaction rollback never calls a quantum adjoint on hardware that has already been measured, and it never describes branch restoration as physical time reversal.

## Limits and failures

`HybridRunLimits` bounds events, branches, and retries. Program limits continue to bound workflow and VM steps. Target descriptors bound qubits and shots. Persistence separately bounds encoded bytes, text fields, events, and globals.

Limit failure occurs before a new semantic event is appended. Retry and transaction abort preflight the event and branch capacity before requesting external cancellation.

A trapped, cancelled, or committed path cannot be resumed through an incompatible API. Failure is explicit; the runtime does not fetch fresh nondeterminism under an old observation identity.

## Terminology

- **Inverse execution** performs a verified method inverse.
- **Rewind** consumes local VM history.
- **Uncompute** returns coherent temporary state to its required clean value.
- **Replay** uses recorded observations without target execution.
- **Retry** creates a fresh target lineage.
- **Cancel** requests that external work stop.
- **Discard** prevents a branch from affecting active state.
- **Compensate** is a separate declared external effect; it is not yet implied by cancellation.
