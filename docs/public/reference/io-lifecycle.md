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
- `IoBufferPool` owns bounded registered buffers, provider leases, and explicit reuse permission.
- `DirectFile` enforces one declared alignment, tail, fallback, and coherence profile.
- `QuantumIo` adapts a complete target call to the same request and completion contract.
- `DeterministicIo` offers inline and delayed delivery with identical completion meaning.
- `ThreadedIo` supplies an explicitly bounded portable worker backend.
- `CompletionIo` supplies bounded one-lane and many-lane completion queues. The awaiting scope thread drives them.

The implementation is stage-0 scaffolding. Its Java API is replaceable and is not a source-language compatibility promise. The lifecycle and distinctions are the contract.

## Lifecycle

A request constructor stores a validated identity, work charge, and provider action. It does not invoke that action. Submission consumes the request once, charges all limits before publication, and creates one operation identity. A started request may define one total provider-cancellation hook. Queued cancellation still completes before provider work and never invokes that hook.

```text
prepared -> submitted -> terminal -> reaped
```

A scope cannot close while an operation is live or terminal-but-unreaped. Awaiting reaps exactly once. A second await fails. Batch and graph preflight failures consume no requests, which avoids the charming recovery protocol known as “guess which half ran.”

Inline submission may produce terminal completion before `submit` returns. Delayed submission produces the same semantic completion when driven by `await` or selection. Tests compare the complete records, not merely result values.

`ThreadedIo(workers, maxInFlight)` adds actual overlap without changing request or completion types. Admission is reserved before request consumption. The executor has a fixed worker count, a bounded queue, and no fallback pool. Closing it with admitted work fails. Cancellation of queued work releases resources without invoking the provider. Cancellation racing with started work records which terminal result won instead of interrupting an external effect and hoping for the best.

`CompletionIo(queueCount, queueDepth)` models one or more bounded completion lanes without allocating a worker, stack, task, or timer for each queued operation. The scope operation limit must fit the declared queue capacity. Submission queues work without running the provider. Await and selection drive the selected operation, preserve canonical reduction order, and release the queue slot before provider execution. Queued cancellation removes the slot and releases resources without running provider code. This stage-0 profile establishes portable queue semantics. It does not claim a native readiness or kernel completion adapter.

`ConnectionRegistry` keeps up to one million dormant connection authorities in primitive state, generation, and free-slot tables. Dormant connections hold no active-work credit and allocate no worker, stack, task, executor, or timer. Activation draws from a separate bound and fails without changing a dormant authority when that credit is exhausted. Close requires dormancy and invalidates the prior generation. This is an admission and ownership profile, not a socket stack or throughput claim.

## Cancellation and uncertainty

`IoDeadline` takes an explicit semantic tick rather than reading wall time. Expiry requests cancellation once. It may establish cancellation before effect, completion winning the race, known partial effect, or uncertainty. Expiry alone never proves that no effect occurred.

The accepted source profile grants physical host input and output only to `entry`. `setOutputLength` requires the exact entry output owner. An entry cannot also be `rev`, `coherent rev`, `unitary`, or `test`, and theorem declarations contain no executable body. The compiler rejects helper and reversible or quantum method attempts before bytecode publication. Stage-0 `IoRequest` is host scaffolding, not an ambient Wheeler source API.

`IoEffectBoundary.acceptLive` accepts one terminal live-I/O completion at an explicit workflow boundary. It binds the completion facts into a content identity and cuts the VM rewind tail while retaining current machine state. `IoCompensation` prepares a second request from one effect-bearing completion. Its action does not run during construction. Successful evidence receives a distinct compensation receipt, and acceptance establishes another `COMPENSATION` boundary. Failed compensation cannot establish that boundary. Neither operation claims inverse execution or removes the original external effect.

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

`IoBufferPool` pre-registers up to 4,096 fixed owners under a 16 MiB aggregate ceiling. Acquisition returns the lowest available generation-checked lease or explicit absence when data-plane credit is exhausted. Provided reads and registered writes submit that owner directly, return the exact lease in the terminal result, and expose no second staging owner. The lease remains unavailable during provider work and cannot return to the pool until terminal resource release. `recycle` is the explicit final reuse permission and invalidates stale generations. Saturation cannot consume the cancellation, terminal-release, recycle, or close path.

`DirectFile` binds one power-of-two alignment up to 4,096 bytes. A required direct path rejects an unsupported backend or any unaligned position, buffer offset, or length before capture. A preferred path either rejects fallback or reports `direct = false` in the terminal result under an explicit buffered-tail policy. Direct and ordinary positional requests share one synchronized byte authority, so each view immediately observes completed writes from the other. This is a semantic profile over the in-memory oracle, not evidence for a host kernel, device, cache, or power-loss contract.

`QuantumIo.request` performs target submission, bounded waiting, result-identity validation, cancellation propagation, terminal completion, and reap as one ordinary I/O operation. Request construction allocates no provider job. Queued cancellation therefore allocates nothing. Cancellation after target allocation either records acknowledged partial cancellation or remains uncertain under the normal completion vocabulary. `QuantumJob` remains the provider adapter beneath this boundary until hybrid recovery also moves to the common fabric.

The accepted source profile gives a qreg no classical declaration, local-storage, buffer-intrinsic, file, mapping, or remote-advertisement path. Classical classes cannot declare qregs. Unitary bodies accept only gate syntax, and quantum entry bodies cannot reinterpret qregs as local storage. Stage-0 I/O and remote-memory adapters accept `OwnedIoBuffer`, not quantum register or state objects. Circuit descriptions and measured classical results may cross the I/O fabric. Coherent state cannot.

`OwnedIoBuffer` rejects access from request construction until terminal resource release. Cancellation-before-effect releases it without touching file bytes. The memory file has no cursor, so unrelated ranges acquire no accidental seek order. It is capped at 16 MiB and performs no growth, truncation, namespace, metadata, or persistence operation.

A `WriteCompleted` value proves only that the in-memory copy completed. Calling it durable would be like calling a register assignment a successful fsync: energetic, but not useful.

`StagedData` is likewise placement evidence, not durability. It binds exact content and byte count to one named tier, one named failure domain, and an optional prior placement identity. Restaging forms a content-identified ancestry chain. A known partial transfer binds the placed prefix identity and byte count to its complete source placement. The type has no conversion or promotion path to `DurabilityReceipt`. A caller still needs the exact evidence sequence below before making stability claims.

`TieredStorage` supplies a bounded placement and drain oracle. A drain captures its source placement until terminal resource release and never consumes it. Complete transfer returns a complete restaging record. A provider's shorter known transfer limit returns `PARTIAL_FAILURE` with exact prefix evidence and source ancestry. The request itself completes because it obtained the typed drain outcome. That outcome does not claim complete transfer or durability.

`RemoteMemory` supplies an epoch-scoped one-sided placement oracle. Only the region can issue an `Advertisement`, and each advertisement binds the exact range, rights, and revocation epoch. A write captures its source owner and produces only a `Placement`. Region-issued `PeerAcknowledgement`, `PeerApplication`, and `Persistence` records form distinct evidence stages. None implements or converts to `DurabilityReceipt`. Disconnection or revocation before queued provider work returns explicit uncertainty, releases the source, and performs no observed placement. Reconnection advances the epoch and restores no old authority. This profile proves the type and lifecycle boundaries. It does not claim an RNIC, transport, peer, or persistent-memory implementation.

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

This slice performs synthetic provider actions and bounded in-memory positional, tier, and remote-memory operations. It has typed placement and receipt schemas but no release-grade evidence issuer. It does not yet implement host files, clocks, replay, source-language loans, native completion queues, host direct I/O, network protocols, RNIC access, or crash-qualified persistence evidence. A successful completion therefore proves no crash survival, namespace stability, peer application, quorum, or remote persistence beyond the explicit synthetic evidence type that its oracle returns.

The I/O conformance tests live under `bootstrap/runtime/src/test/java/com/typeobject/wheeler/runtime/io/`. Native source request types, effect lowering, host positional resources, source-language buffer loans, and crash-tested receipts remain required before WIP-0032 can leave Draft.
