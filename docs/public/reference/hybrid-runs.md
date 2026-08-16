---
title: Observations, Replay, and Retry
description: The lifecycle of a hybrid run from deterministic work through target observation and recovery.
---

# Observations, Replay, and Retry

A quantum result can cross the Reach in less time than the machinery that made it.
A hybrid run keeps the resulting identities in order.

`HybridRun` owns deterministic classical state, a workflow continuation,
acknowledged target jobs, accepted observations, the active branch, transaction
phase, and a finite semantic event log.

## Lifecycle

A new run begins in `ACTIVE`:

```java
HybridRun run = HybridRun.start(program, target);
RunStatus status = run.advance();
```

`advance()` stops at:

| Status | Meaning |
| --- | --- |
| `WAITING` | A target acknowledged a quantum job. |
| `COMPLETED` | The verified workflow halted. |
| `TRAPPED` | A deterministic semantic failure stopped the run. |

A waiting run resumes through a declared timeout:

```java
status = run.resume(Duration.ofSeconds(30));
```

The ideal local target follows the same submit, acknowledge, validate, apply, and
resume sequence as a distant queue. Fast work receives no shorter identity path.
`runToCompletion()` is a blocking convenience around this lifecycle.

## Events

Every semantic transition creates an immutable `HybridEvent` carrying run,
branch, sequence, workflow edge, event kind, relevant job and target identity,
kind-specific value, and SHA-256 content identity.

The event set includes run start, target selection, transaction start or abort,
submission, result application, cancellation request, branch discard, retry,
commit, completion, and trap.

`HybridEventReducer` accepts unordered delivery and byte-identical duplicates. It
sorts by sequence, removes duplicate bytes, and rejects gaps, conflicts at one
sequence, mixed runs, changes to inactive branches, and result application without
a matching submission.

Operational timestamps, polls, queue positions, and log arrival order never define
semantic order.

## Applying an observation

Before classical state changes, Wheeler checks:

- job and target identity.
- task identity, including artifact, register, preparation, circuit or adjoint,
  shots, and seed policy.
- exact shot count and outcome width.
- active workflow continuation and branch.
- remaining event capacity.

One accepted observation changes classical state once. A second resume through
the same continuation fails. A malformed result leaves globals, continuation, and
events unchanged.

Measurement outcomes use canonical little-endian integers. Provider display text
never enters semantic state.

## Snapshots and recovery

`HybridRunStore` encodes one canonical binary snapshot with a trailing SHA-256
digest. It contains schema, artifact, run, mode, status, branch, limits, commit
horizon, typed globals, workflow edge, pending acknowledged job, transaction
checkpoint, phase, and the complete event stream.

Decoding rejects malformed magic, unknown rows, invalid counts, truncation,
trailing bytes, digest failure, reducer disagreement, and continuation mismatch.

Recovery starts from the beginning, repeats deterministic workflow edges, and
applies the accepted observations. It then compares rebuilt globals with the
persisted continuation.

At a waiting edge, recovery calls `QuantumTarget.recover(jobId, task)`. It never
turns an acknowledged job into another submission. Unknown or mismatched provider
identity stops recovery.

Snapshots contain no provider SDK objects, credentials, host pointers, arbitrary
object graphs, or raw quantum handles. Atomic replacement can prevent a torn
userspace file on a supporting host. The current snapshot store issues no
power-loss durability receipt.

## Replay and retry

```java
ExecutionResult replayed = HybridRun.replay(program, recordedSnapshot);
String newJob = waitingRun.retry();
```

Replay requires a completed event stream and the exact artifact identity. It runs
the classical workflow using recorded accepted observations and never contacts a
target.

Retry requests cancellation of the current job, discards that branch, creates a
new branch, and makes a fresh physical submission. Its systems, job identity, and
observation lineage are new. A late result from the discarded branch has no active
continuation capable of changing state.

Cancellation remains a request. Its return does not prove that remote hardware
stopped.

## Transactions

A transaction begins at an active clean workflow boundary:

```java
run.beginTransaction();
```

| Phase | Abort behavior |
| --- | --- |
| `REVERSIBLE` | Restore the typed classical checkpoint. |
| `PREPARED_EXTERNAL` | Restore classical state, request cancellation, and quarantine the acknowledged job branch. |
| `OBSERVED` | Restore classical state and discard the observation branch. The measured physical state remains spent. |
| `COMMITTED` | Reject abort. |

An abort after an external edge creates another branch. Running forward again
performs another preparation and submission.

Commit appends a commit event, clears local rewind history, and advances the event
horizon. Rollback never invokes an adjoint on hardware already measured.

## Limits and failures

`HybridRunLimits` fixes event, branch, and retry maxima. Program limits govern VM
and workflow transitions. Target descriptors govern logical qubits and shots.
Snapshot encoding has separate maxima for bytes, text, events, and globals.

A limit failure occurs before appending an event or requesting external
cancellation. Trapped, cancelled, and committed paths reject incompatible resume
operations. Wheeler never obtains fresh nondeterminism under an earlier
observation identity.

## Terms kept apart

| Term | Meaning |
| --- | --- |
| inverse | Run a verified method inverse. |
| rewind | Consume retained VM history. |
| uncompute | Clean coherent temporary state through inverse work. |
| replay | Reuse accepted observations without target execution. |
| retry | Create a fresh target lineage. |
| cancel | Request that external work stop. |
| discard | Prevent one branch from changing active state. |
| compensate | Perform a separate declared external effect. |

The [target appendix](quantum-targets.md) describes the physical job beneath a
waiting edge. The [I/O appendix](io-lifecycle.md) gives cancellation and resource
release their portable rows.
