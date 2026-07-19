# Unified I/O fabric

WIP-0032 defines Wheeler's planned asynchronous I/O foundation. It is still a **Draft**, so the source API does not exist yet. The current stage-0 host bindings and `QuantumJob` classes are migration tools, not a second I/O model.

The shared model has four parts:

```text
resource operation -> Request<T>
scope executes request
operation owns pending work
result type says what happened
```

A caller may await one request directly or submit it for overlapping work. Requests may also join a batch or dependency graph; selection policies cover races, quorums, deadlines, and all-results waits.

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

Today Wheeler has bounded entry input and output loans, canonical hybrid job events, target submission and recovery, atomic host publication where the platform supports it, package capability requests, and native FFI ownership checks. These pieces set useful rules. They do not yet provide `IoScope`, `Request<T>`, operation graphs, buffer registration, direct I/O, RDMA, storage tiers, or durability receipts.

Until typed receipts exist, an atomic replacement proves only that the host attempted atomic publication. It does not prove that data, metadata, or the namespace survived a crash or power loss. Durability needs its own evidence. An `fsync` call by itself is not a durability receipt.

The complete contract, migration order, acceptance suite, and research references live in [WIP-0032](../proposals/WIP-0032-unified-io-fabric-and-durability-receipts.md).
