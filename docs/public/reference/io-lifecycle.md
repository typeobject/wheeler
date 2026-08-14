# I/O lifecycle

WIP-0032 specifies Wheeler's portable I/O contract. There is one request lifecycle. Files, sockets, storage tiers, RDMA, and quantum target adapters may define resource facts, but they do not get private futures, cancellation folklore, or a second event loop hidden behind the curtains.

## Executable stage-0 slice

The quarantined runtime now carries a deterministic executable slice under `bootstrap/runtime/src/main/java/com/typeobject/wheeler/runtime/io/`:

- `IoRequest<T>` prepares one pure, affine request.
- `IoScope` bounds submission, work, batches, graphs, terminal completions, and reaping.
- `IoOperation<T>` is a live must-reap handle.
- `IoCompletion<T>` separates terminal kind, cancellation relation, known progress, resource release, and backend identity.
- `IoGraph<T>` is an explicitly bounded terminal-dependency DAG.
- `OwnedIoBuffer` is inaccessible while captured and returns through a terminal result.
- `MemoryAddressableFile` is the bounded positional-semantics oracle.
- `SequentialFileCursor` is the single-owner adapter for work that depends on one cursor.
- `DeterministicIo` offers inline and delayed delivery with identical completion meaning.
- `ThreadedIo` supplies an explicitly bounded portable worker backend.

The implementation is stage-0 scaffolding. Its Java API is replaceable and is not a source-language compatibility promise. The lifecycle and distinctions are the contract.

## Lifecycle

A request constructor stores a validated identity, work charge, and provider action. It does not invoke that action. Submission consumes the request once, charges all limits before publication, and creates one operation identity.

```text
prepared -> submitted -> terminal -> reaped
```

A scope cannot close while an operation is live or terminal-but-unreaped. Awaiting reaps exactly once. A second await fails. Batch and graph preflight failures consume no requests, which avoids the charming recovery protocol known as “guess which half ran.”

Inline submission may produce terminal completion before `submit` returns. Delayed submission produces the same semantic completion when driven by `await` or selection. Tests compare the complete records, not merely result values.

`ThreadedIo(workers, maxInFlight)` adds actual overlap without changing request or completion types. Admission is reserved before request consumption. The executor has a fixed worker count, a bounded queue, and no fallback pool. Closing it with admitted work fails. Cancellation of queued work releases resources without invoking the provider. Cancellation racing with started work records which terminal result won instead of interrupting an external effect and hoping for the best.

## Cancellation and uncertainty

`IoDeadline` takes an explicit semantic tick rather than reading wall time. Expiry requests cancellation once. It may establish cancellation before effect, completion winning the race, known partial effect, or uncertainty. Expiry alone never proves that no effect occurred.

Terminal kind and cancellation relation are separate closed enums. The executable model distinguishes:

| Result | Meaning |
| --- | --- |
| `CANCELED_BEFORE_EFFECT` | Provider action did not run. Progress is zero. |
| `CANCELED_AFTER_PARTIAL_EFFECT` | Known positive progress occurred before cancellation won. |
| `COMPLETED_BEFORE_CANCELLATION` | Success was already terminal when cancellation arrived. |
| `FAILED_BEFORE_CANCELLATION` | A known failure was already terminal. |
| `UNCERTAIN_WITHOUT_CANCELLATION` | The provider cannot establish the external outcome. |
| `UNCERTAIN_AFTER_CANCELLATION` | Cancellation raced with an outcome that still needs reconciliation. |

Cancellation does not reap an operation and never claims rollback. Malformed provider progress is normalized to a known failure before completion publication.

## Wheeler-native lifecycle kernel

`wheeler-runtime/src/main/wheeler/runtime/io/Lifecycle.w` moves the lifecycle laws out of Java prose and into executable Wheeler. The kernel uses caller-owned fixed columns for state, declared work, exact progress, terminal kind, cancellation relation, resource release, and reap state. It accepts at most 64 rows and publishes no row until every capacity and arithmetic check succeeds.

The native transition table rejects second completion, completion before resource release, progress beyond declared work, mismatched terminal/cancellation pairs, second reap, and scope closure with any unreaped row. Late cancellation may strengthen only the matching relation: success becomes completion-won, known failure becomes failure-won, and independent uncertainty becomes uncertainty-after-cancellation. It does not rewrite history into cancellation-before-effect because that would be lying with extra steps.

[`NativeIoLifecycle.w`](../../wheeler-conformance/src/main/wheeler/io/NativeIoLifecycle.w) executes success, cancellation-before-effect, partial cancellation, uncertainty, late cancellation, capacity failure, exact reaping, closure, and complete VM rewind.

## Positional memory-file oracle

`MemoryAddressableFile` is not a filesystem API. It is a bounded oracle for the positional contract. `readAt` validates the destination range and position before capture, then returns the destination owner with exact bytes-read progress. `writeAt` requires a write capability, validates the complete source and file ranges before capture, and returns the source owner with exact bytes-written progress.

`SequentialFileCursor` lends its sole cursor to one live request. A read starts at the examined position and returns exact consumed and examined coordinates. `advance` moves those coordinates only inside the completed window. A write requires a settled cursor, where consumed equals examined, and advances both only after successful provider work. Cancellation before effect releases the cursor and buffer without changing either position. Independent positional work still uses `MemoryAddressableFile` directly instead of sharing this serialization point.

`OwnedIoBuffer` rejects access from request construction until terminal resource release. Cancellation-before-effect releases it without touching file bytes. The memory file has no cursor, so unrelated ranges acquire no accidental seek order. It is capped at 16 MiB and performs no growth, truncation, namespace, metadata, or persistence operation.

A `WriteCompleted` value proves only that the in-memory copy completed. Calling it durable would be like calling a register assignment a successful fsync: energetic, but not useful.

## Batches, selection, and graphs

A batch is independent work and adds no ordering edges. Selection reaps one canonical terminal operation and returns every nonselected operation to the caller. Nothing is detached merely because it lost a race.

A graph names terminal predecessors. Independent roots are admitted together. A dependent node is not submitted until all named predecessors are terminal and reaped into the graph result table. Nodes and edges have constructor bounds as well as scope bounds. Graph execution returns completions in stable node order, regardless of physical delivery order.

## Receipt schema and monotonicity gate

Stage 0 now has a runtime-owned file-publication receipt chain:

```text
WriteCompleted
  -> DataStable
  -> FileStable
  -> NamespaceVisible
  -> NamespaceStable
  -> QuorumStable
```

`DurabilityReceipt` has no public constructor. The package-private issuer accepts only the next transition and its matching evidence source: operation completion, data flush, metadata flush, atomic rename, namespace flush, then quorum protocol. A promotion binds one immutable subject, failure model, atomicity, replica/quorum rule, backend-profile identity, sorted assumptions, new evidence identity, parent receipt, and chain depth. Subject and profile records receive their own canonical SHA-256 identities. Receipt bytes then bind the SHA-256 domain separator, kind, evidence source, depth, subject, profile, evidence, and parent in a fixed 163-byte form. Stage 0 and Wheeler reproduce every stage byte for byte. The full chain ends at `1d4fb3a8521eaa451dd37734c7fa0017e44bb7a684c004026c7c1c90c3f4d8b5`.

Skipping a stage, replaying evidence, claiming namespace visibility without a namespace subject, or claiming quorum stability with one replica fails. These checks establish schema monotonicity. They do not establish that the supplied evidence is true. Release-grade issuance still needs the crash, power, hardware, filesystem, protocol, and configuration conformance demanded by WIP-0032.

## Deliberate nonclaims

This slice performs synthetic provider actions and bounded in-memory positional operations. It has a typed receipt schema but no release-grade evidence issuer. It does not yet implement host files, clocks, replay, source-language loans, native completion queues, direct I/O, network protocols, or crash-qualified persistence evidence. A successful completion therefore proves no crash survival, namespace stability, peer application, quorum, or remote persistence.

The deterministic and threaded conformance tests live under `bootstrap/runtime/src/test/java/com/typeobject/wheeler/runtime/io/`. Native source request types, effect lowering, host positional resources, source-language buffer loans, and crash-tested receipts remain required before WIP-0032 can leave Draft.
