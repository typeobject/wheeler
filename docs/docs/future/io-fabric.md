# Unified I/O fabric

WIP-0032 specifies Wheeler's planned asynchronous I/O foundation. It is a **Draft**, not an implemented source API. The current stage-0 host bindings and `QuantumJob` classes are migration fixtures; they must not be mistaken for a second I/O design merely because they currently answer the phone.

The proposal keeps the common model small:

```text
resource operation -> Request<T>
scope executes request
operation owns pending work
result type says what happened
```

One request may be awaited directly, submitted for overlap, placed in an independent batch, connected in a dependency graph, or selected under an explicit race, quorum, deadline, or all-results policy.

## Fixed semantic rules

- The application supplies `Io`; the fabric grants scheduling but no resource authority.
- Positional ranges are foundational for addressable storage. Sequential cursors are affine adapters.
- Every submitted operation has one terminal completion and is reaped exactly once.
- Cancellation races with completion and never means rollback.
- Buffers remain owned or borrowed through final resource-release completion.
- Queues, completions, registrations, timers, transfers, and total work are bounded.
- Asynchronous, required-concurrent, direct, registered, zero-copy, ordered, visible, and durable are separate properties.
- Completion, close, rename, direct mode, staging, replication acknowledgement, and RDMA placement do not imply durability.
- Durability receipts identify the protected subject, failure model, atomicity, replication rule, assumptions, and evidence.
- Live external I/O is an irreversible effect. Replay may reuse an accepted recorded read; rewind cannot reread or unwrite the world.
- Quantum target lifecycle may use the fabric, but coherent quantum state never becomes bytes, a file, or an RDMA region.

## Current implementation boundary

Today Wheeler implements explicit bounded entry input/output loans, canonical hybrid job events, target submission and recovery, atomic host publication where supported, package capability requests, and native FFI ownership checks. Those pieces establish useful constraints but do not yet implement `IoScope`, `Request<T>`, operation graphs, buffer registration, direct I/O, RDMA, storage tiers, or durability receipts.

Until typed receipts execute, an atomic replacement is only an atomic publication attempt under the host contract. It is not evidence that data, metadata, or namespace survived a crash or power loss. `fsync` folklore has been asked to wait outside.

The complete contract, migration order, acceptance suite, and research references live in [WIP-0032](../proposals/WIP-0032-unified-io-fabric-and-durability-receipts.md).
