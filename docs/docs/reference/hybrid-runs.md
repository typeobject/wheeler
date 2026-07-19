# Hybrid runs and replay

A quantum or hybrid Wheeler workflow runs as a `HybridRun`. The run owns its deterministic classical state, workflow continuation, acknowledged target jobs, accepted observations, active branch, transaction phase, and bounded semantic event log.

A remote queue wait does not block one VM instruction. The runtime advances deterministic workflow edges until it submits a measurement job. It records the acknowledged job identity, enters `WAITING`, and later resumes from the saved continuation after validating the result.

## Lifecycle

A new run starts in `ACTIVE`:

```java
HybridRun run = HybridRun.start(program, target);
RunStatus status = run.advance();
```

`advance()` stops in one of these states:

- `WAITING`: a target acknowledged a quantum job;
- `COMPLETED`: the workflow reached its verified halt;
- `TRAPPED`: a bounded semantic failure stopped the run.

A waiting run accepts a result with a bounded timeout:

```java
status = run.resume(Duration.ofSeconds(30));
```

The local ideal simulator uses the same submit, acknowledge, validate, apply, and resume steps as a delayed target. Fast completion does not skip job or result identity checks.

`runToCompletion()` is only a blocking helper around this state machine. It does not create another execution path.

## Events

Each semantic transition creates an immutable `HybridEvent` with:

- run, branch, sequence, and workflow-edge identity;
- an event kind;
- bounded job and target identity;
- a kind-specific bounded value and detail;
- a SHA-256 content identity.

The first event set covers run start, target selection, transaction start or abort, submission, result application, cancellation request, branch discard or retry, commit, completion, and trap.

`HybridEventReducer` accepts unordered, at-least-once delivery. It sorts events by sequence and removes byte-identical duplicates. It rejects gaps, two different events at one sequence, mixed run identities, changes to an inactive branch, and result applications that lack a matching submission.

Arrival order does not define semantic order. Operational timestamps, polling attempts, queue positions, and log interleaving are not semantic events.

## Result application

Before changing classical state, the run checks:

- job identity;
- target identity;
- task content identity, including the `.wbc` artifact, register, basis state, circuit or adjoint sequence, shot request, and seed policy;
- exact shot count;
- full-register outcome width;
- the active continuation and branch;
- remaining event capacity.

The runtime then applies the accepted observation event and its classical effect once. A second `resume()` fails because the lifecycle has already advanced. A malformed result leaves the continuation, global values, and event stream unchanged.

Measurement outcomes use Wheeler's canonical little-endian integer form; provider display strings never enter semantic event state.

## Persistence and recovery

`HybridRunStore` writes a `HybridRunSnapshot` as one canonical bounded binary record with a trailing SHA-256 integrity digest. A snapshot contains:

- schema, artifact, run, mode, status, branch, and limits;
- the commit horizon;
- typed global values and the exact workflow edge;
- a pending acknowledged job and target identity, when present;
- a transaction checkpoint and phase, when active;
- the complete bounded semantic event stream.

When the host supports it, writes use temporary output and atomic replacement. Decoding rejects bad magic, unknown enums, invalid counts, truncated or extra data, integrity failure, disagreement between the header and reducer, and a mismatched continuation identity.

Recovery starts from the beginning and replays deterministic workflow edges plus accepted observations. It then compares the rebuilt globals with the persisted typed continuation.

At a waiting edge, recovery calls `QuantumTarget.recover(jobId, task)`; it never turns an acknowledged job into a new submission. A target that cannot match the durable identity must fail recovery clearly.

Provider SDK objects, credentials, host pointers, arbitrary object graphs, and raw quantum handles are never persisted.

Atomic replacement can prevent a torn userspace publication on a supporting host. The current store does not return evidence that data, metadata, or the namespace survived a crash. [WIP-0032](../proposals/WIP-0032-unified-io-fabric-and-durability-receipts.md) will place snapshot I/O under the unified operation lifecycle and typed receipt model.

Until then, a successful snapshot write is not a proof of power-loss durability.

## Replay and retry

Replay and retry have different meanings.

```java
ExecutionResult replayed = HybridRun.replay(program, recordedSnapshot);
String newJob = waitingRun.retry();
```

Replay requires a completed event stream with the exact artifact identity. It runs the classical workflow from recorded accepted observations and never calls a target.

Retry asks to cancel the current job, discards that branch, creates a new one, and makes a fresh physical submission. The new job may produce another valid observation. A late result from the discarded branch has no active continuation that can change state.

Cancellation is only a request. Its return value does not prove that remote hardware stopped.

## Transactions

A transaction begins only at an active, clean workflow boundary:

```java
run.beginTransaction();
```

Its phase changes as effects occur:

| Phase | Abort behavior |
| --- | --- |
| `REVERSIBLE` | Restore the typed classical checkpoint. |
| `PREPARED_EXTERNAL` | Restore classical state, request cancellation, and quarantine the acknowledged job branch. |
| `OBSERVED` | Restore classical state and discard the observation branch. The measured physical state is not restored. |
| `COMMITTED` | Reject abort. |

`abortTransaction()` reports whether it requested cancellation and whether it discarded an accepted observation. An abort after an external edge creates a new branch. Running forward again performs a new preparation and submission.

`commitTransaction()` records a commit event, clears local rewind history, and advances the event commit horizon. A workflow `commit()` makes the same horizon change for an active transaction.

Rollback never calls a quantum adjoint on hardware that has already been measured. Restoring a branch is also not physical time reversal.

## Limits and failures

`HybridRunLimits` bounds events, branches, and retries. Program limits still bound workflow and VM steps. Target descriptors cap qubits and shots, while persistence has separate limits for encoded bytes, text fields, events, and globals.

A limit failure occurs before the runtime appends a new semantic event. Retry and transaction abort check event and branch capacity before they request external cancellation.

A trapped, cancelled, or committed path cannot resume through an incompatible API. Failure stays explicit, and the runtime never fetches fresh nondeterminism under an old observation identity.

## Terminology

- Inverse execution runs a verified method inverse.
- Rewind consumes local VM history.
- Uncompute returns coherent temporary state to its required clean value.
- Replay uses recorded observations without target execution.
- Retry creates a fresh target lineage.
- Cancel requests that external work stop.
- Discard prevents a branch from changing active state.
- Compensate is a separate declared external effect. Cancellation does not imply it.
