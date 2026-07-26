# I/O lifecycle

Wheeler's portable I/O contract is specified by [WIP-0032](../proposals/WIP-0032-unified-io-fabric-and-durability-receipts.md). There is one request lifecycle. Files, sockets, storage tiers, RDMA, and quantum target adapters may define resource facts, but they do not get private futures, cancellation folklore, or a second event loop hidden behind the curtains.

## Executable stage-0 slice

The quarantined runtime now carries a deterministic executable slice under `bootstrap/runtime/src/main/java/com/typeobject/wheeler/runtime/io/`:

- `IoRequest<T>` prepares one pure, affine request;
- `IoScope` bounds submission, work, batches, graphs, terminal completions, and reaping;
- `IoOperation<T>` is a live must-reap handle;
- `IoCompletion<T>` separates terminal kind, cancellation relation, known progress, resource release, and backend identity;
- `IoGraph<T>` is an explicitly bounded terminal-dependency DAG;
- `DeterministicIo` offers inline and delayed delivery with identical completion meaning.

The implementation is stage-0 scaffolding. Its Java API is replaceable and is not a source-language compatibility promise. The lifecycle and distinctions are the contract.

## Lifecycle

A request constructor stores a validated identity, work charge, and provider action. It does not invoke that action. Submission consumes the request once, charges all limits before publication, and creates one operation identity.

```text
prepared -> submitted -> terminal -> reaped
```

A scope cannot close while an operation is live or terminal-but-unreaped. Awaiting reaps exactly once. A second await fails. Batch and graph preflight failures consume no requests, which avoids the charming recovery protocol known as “guess which half ran.”

Inline submission may produce terminal completion before `submit` returns. Delayed submission produces the same semantic completion when driven by `await` or selection. Tests compare the complete records, not merely result values.

## Cancellation and uncertainty

Terminal kind and cancellation relation are separate closed enums. The executable model distinguishes:

| Result | Meaning |
| --- | --- |
| `CANCELED_BEFORE_EFFECT` | Provider action did not run; progress is zero. |
| `CANCELED_AFTER_PARTIAL_EFFECT` | Known positive progress occurred before cancellation won. |
| `COMPLETED_BEFORE_CANCELLATION` | Success was already terminal when cancellation arrived. |
| `FAILED_BEFORE_CANCELLATION` | A known failure was already terminal. |
| `UNCERTAIN_WITHOUT_CANCELLATION` | The provider cannot establish the external outcome. |
| `UNCERTAIN_AFTER_CANCELLATION` | Cancellation raced with an outcome that still needs reconciliation. |

Cancellation does not reap an operation and never claims rollback. Malformed provider progress is normalized to a known failure before completion publication.

## Batches, selection, and graphs

A batch is independent work and adds no ordering edges. Selection reaps one canonical terminal operation and returns every nonselected operation to the caller. Nothing is detached merely because it lost a race.

A graph names terminal predecessors. Independent roots are admitted together; a dependent node is not submitted until all named predecessors are terminal and reaped into the graph result table. Nodes and edges have constructor bounds as well as scope bounds. Graph execution returns completions in stable node order, regardless of physical delivery order.

## Deliberate nonclaims

This slice performs synthetic provider actions. It does not yet implement positional files, threaded delivery, clocks, replay, borrowed buffers, native completion queues, direct I/O, network protocols, persistence evidence, or durability receipts. A successful completion therefore proves no crash survival, namespace stability, peer application, quorum, or remote persistence.

The conformance tests live at `bootstrap/runtime/src/test/java/com/typeobject/wheeler/runtime/io/DeterministicIoTest.java`. Native source types, effect lowering, positional resources, buffer loans, and the portable threaded backend remain required before WIP-0032 can leave Draft.
