# WIP-0032: Unified asynchronous I/O fabric, operation graphs, and durability receipts

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler language, runtime, VM, verifier, standard-library, storage, networking, native, security, workflow, quantum, proof, package, and tooling maintainers |
| Created | 2026-07-19 |
| Updated | 2026-07-19 |
| Area | I/O, asynchronous execution, files, networking, direct I/O, RDMA, tiered storage, durability |
| Depends on | WIP-0001, WIP-0002, WIP-0004, WIP-0005, WIP-0009, WIP-0011, WIP-0013, WIP-0025, WIP-0028, WIP-0031 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler will have one capability-based asynchronous I/O fabric that does not depend on a specific backend. Filesystems, byte channels, messages, datagrams, storage devices, burst tiers, RDMA, and quantum target adapters use the same request lifecycle. Their addressing and durability rules remain distinct.

The base model is not a stream with one mutable cursor. It includes:

- independently addressed byte-range operations;
- message and datagram operations that preserve boundaries;
- pure request construction followed by explicit submission and completion;
- structured scopes and affine operations that must be consumed;
- bounded queues, credits, batches, selection, and dependency graphs;
- owned, borrowed, registered, provided, pinned, and segmented buffers;
- explicit lanes, topology, ordering domains, fences, and storage tiers;
- cancellation races, partial progress, and uncertain outcomes;
- typed visibility and durability receipts with exact evidence.

Sequential readers and writers remain useful adapters. Each owns one affine cursor and serializes only the work that depends on that cursor. Positional devices can still use their independent queues.

The source model has four main parts:

```text
resource operation -> Request<T>
scope executes request
operation owns pending work
result type says what happened
```

One request can be awaited, submitted, batched, placed in a graph, or selected:

```wheeler
within IoScope scope = io.scope(limits) {
  ReadCompleted read = scope.await(
    file.readAt(0, borrow mut buffer)
  );
}
```

```wheeler
Operation<ReadCompleted> read = scope.submit(
  file.readAt(offset, borrow mut buffer)
);

doIndependentWork();
ReadCompleted completed = read.await();
```

The application supplies one `Io` fabric at its root. The fabric schedules work but grants no file, network, device, credential, or target authority.

Live external I/O is a WIP-0001 effect and rewind barrier by default. WIP-0004 may record accepted reads and replay them without new I/O. Writes may use isolation, delayed publication, reconciliation, or declared compensation. None of these is a language-level inverse.

Ordinary host I/O is forbidden in `rev`, `coherent rev`, `unitary`, and proof execution. Quantum target submission uses this lifecycle at a hybrid boundary. Quantum state itself is never a byte stream, file, registered region, or RDMA range.

## Decision

Wheeler adopts these rules:

1. Positional range I/O is foundational for addressable storage.
2. Sequential cursors are explicit affine adapters.
3. Request construction is pure; submission and waiting are effects.
4. Every submitted operation has exactly one terminal completion and is reaped exactly once.
5. A live operation cannot be dropped or detached anonymously.
6. Cancellation races with completion and never means rollback.
7. Submission order gives no completion, visibility, or persistence order without an explicit contract.
8. Buffers remain owned or borrowed until final resource-release completion.
9. Batches expose independent work; graphs expose semantic dependencies.
10. Logical asynchrony and required concurrency are different contracts.
11. Direct, zero-copy, registered, ordered, atomic, visible, and durable are independent axes.
12. Required optimized paths fail when unavailable; preferred paths report fallback.
13. Completion, close, rename, staging, replication acknowledgement, and RDMA placement imply no unnamed durability.
14. Durability receipts identify subject, failure model, atomicity, replication, assumptions, evidence source, and receipt chain.
15. Backends are replaceable implementations of one semantic contract, not separate portable source APIs.

## Semantic ownership

WIP-0032 is the sole owner of Wheeler's portable I/O lifecycle and common operation vocabulary: `Io`, capabilities, requests, scopes, operations, groups, batches, graphs, selection, cancellation, completion, lanes, buffers, backpressure, visibility, and durability receipts.

Other WIPs may define resource-domain facts such as path naming, wire protocols, quantum target commands, package grants, native ABI mappings, or proof rules. They integrate those facts through WIP-0032 and don't invent parallel `Future`, stream, callback, cursor, scheduler, cancellation, or durability APIs. A successor may extend a named resource family only by depending on this WIP and preserving its lifecycle and laws. Method registries remain here; integration notes elsewhere stay deliberately narrow.

If two WIPs appear to define how an I/O request is submitted or completed, this WIP wins and the duplicate text is a bug. Please send a patch instead of naming the second event loop.

## Motivation

WIP-0001 already says external I/O is not physically reversible. WIP-0004 already models acknowledged jobs, pending continuations, cancellation requests, accepted observations, replay, retry, compensation, commit horizons, and uncertain external state. WIP-0013 and WIP-0028 provide bounded regions, affine owners, and loans. WIP-0031 provides effect rows and callable boundaries.

The missing piece is one I/O lifecycle that joins those contracts without inheriting a cursor-shaped ceiling.

A cursor-only foundation causes accidental coupling:

- independent reads contend on one mutable offset;
- scatter/gather and batch submission become afterthoughts;
- disjoint writes need duplicate handles or seeking games;
- device queues, object ranges, RDMA, and storage tiers fit poorly;
- staging and drain become invisible side effects;
- `write`, `flush`, `sync`, and `close` cannot express the exact promise being requested.

Modern systems expose many queues, cores, lanes, zones, tiers, and failure domains. A server may own millions of dormant connections while admitting only a bounded active set. Zero-copy sends may have separate transport and reuse completions. RDMA can place bytes without proving peer processing or persistence. Crash-safe publication separates file data, file metadata, visible namespace change, and stable namespace change.

Wheeler must represent those distinctions before an API hardens. Wheeler must model these differences before the API becomes a compatibility commitment.

## Goals

- Define one backend-independent request, operation, completion, and scope lifecycle.
- Keep ordinary source in direct `await` style without callback or manual-polling taxes.
- Preserve positional, byte-channel, message, and datagram semantics separately.
- Support groups, batches, multishot operations, selection, and dependency DAGs.
- Make operation, queue, completion, buffer, registration, timer, and total-work limits explicit.
- Make cancellation, partial progress, uncertainty, retry lineage, and reconciliation explicit.
- Keep all buffer and registration lifetimes verifier-visible.
- Support evented, completion, polling, threaded, user-space, device, RDMA, and deterministic backends.
- Support multi-queue and topology-aware storage without a mandatory global lock.
- Support high connection counts without one native thread, stack, timer, or live task per dormant connection.
- Support explicit storage tiers, staging, draining, persistence, and publication.
- Make visibility and durability evidence non-forgeable and domain-specific.
- Integrate read replay, write barriers, compensation, commit horizons, and hybrid target jobs.
- Keep canonical operation metadata in typed `.wbc`, never in provider or native objects.

## Non-goals

- Define complete filesystem, TCP, QUIC, HTTP, DNS, TLS, object-store, or database APIs.
- Guarantee one C10M, IOPS, or latency number on every host.
- Require every backend to implement direct, zero-copy, registered, multishot, polling, RDMA, or durable paths.
- Guarantee submission order is completion or persistence order.
- Hide copying, buffering, fallback, overlap, or durability behind a Boolean option.
- Treat timeout, cancellation, retry, compensation, or transaction abort as proof that no external effect occurred.
- Treat successful send as peer receipt or peer application commit.
- Treat ordinary replication or RDMA completion as persistent quorum evidence.
- Expose raw descriptors, queue pointers, remote keys, physical addresses, provider objects, or native event handles as portable values.
- Introduce ambient event loops, thread pools, filesystems, networks, clocks, credentials, or target sessions.
- Represent quantum state as bytes or use a duplicable global quantum-state monad.

## Semantic axes

The framework keeps these axes independent:

| Axis | Examples |
| --- | --- |
| Addressing | positional range, sequential cursor, byte channel, message, datagram, remote range |
| Execution | await, asynchronous, required-concurrent, batch, multishot, graph |
| Data path | buffered, direct, registered, zero-copy, device-direct, RDMA |
| Ordering | independent, lane-ordered, dependency, fence, atomic unit, version precondition |
| Visibility | local completion, readers, remote memory, peer protocol, namespace, catalog |
| Persistence | none, data stable, metadata stable, namespace stable, quorum stable |
| Observation | live, record, replay, verify-replay, fresh retry |

Consequently:

```text
asynchronous != direct
direct != zero-copy
zero-copy != durable
completion != durability
atomic visibility != stable namespace
remote placement != peer application
remote placement != remote persistence
staged != durable
```

## Core model

### `Io`

`Io` is an explicit application-supplied fabric. It owns scheduling, submission, completion delivery, cancellation translation, lane mapping, registration, backend capability discovery, deadlines, error normalization, and bounded telemetry.

It owns no resource authority. Without a file capability, the scheduler cannot open a file.

### Capabilities

An I/O capability is an affine or scoped authority over one resource domain. Initial families include directory, addressable file/object, listener, connection, datagram endpoint, storage tier, registered local region, advertised remote region, and quantum target adapter.

A capability names rights, resource identity, bounds, and relevant ordering or failure domains. It is not an integer descriptor.

### `Request<T>`

A request is an affine prepared description of one operation with terminal result type `T`.

Construction validates rights, ranges, arithmetic, buffer shape, static alignment, segment count, policy, and limits. It captures owners or loans but performs no external effect and consumes no backend queue credit.

A request can be awaited, submitted, added to a batch, or added to a graph exactly once.

### `IoScope`

A scope owns bounded operation slots, tasks, completion entries, buffers, registrations, deadlines, cancellation state, credits, and trace identity.

Scope exit requires every operation terminal and reaped, every held loan released, every group joined or transferred, and every uncertain result reconciled, persisted as a WIP-0004 continuation, or returned as an owned result.

### `Operation<T>`

An operation is an affine must-consume handle for submitted work; it has one terminal result; dropping it live is invalid. Cancellation does not consume it; terminal completion and reaping do.

### Completion

A completion records operation identity, result/error, exact progress, cancellation relation, buffer-release state, backend receipt, and uncertainty/provenance. Completion is a local lifecycle fact, not an unnamed persistence claim.

### Multishot, batch, and graph

A multishot operation yields a bounded item sequence followed by one terminal completion.

A batch is a bounded set of independent requests submitted together. It gives no implicit order.

An I/O graph is a bounded DAG. Dependency edges may require predecessor terminal completion, success, visibility, persistence, quorum, or an explicit fence. Backends may fuse or pipeline nodes but cannot weaken edge requirements or result types.

### Lanes and ordering domains

A lane is a logical sharding domain that may map to a CPU, event shard, device queue, poll group, receive queue, storage channel, NUMA node, or remote queue pair.

Lane choice is ordinarily policy. Any semantic ordering or affinity guarantee is named explicitly. There is no process-global I/O order.

## Core laws

### Terminal completion

```text
submitted(operation) -> exactly one terminal completion -> exactly one reap
```

Multishot item completions do not replace the terminal completion.

### Resource lifetime

```text
request resources remain valid
until final resource-release completion
```

A zero-copy transport completion may precede source-buffer reuse permission.

### Cancellation

A cancellation race terminates as one of:

```text
CanceledBeforeEffect
CanceledAfterPartialEffect(progress)
CompletedBeforeCancellation(result)
FailedBeforeCancellation(error)
UncertainAfterCancellation(correlation, knownProgress)
```

No branch forgets the operation or invents rollback.

### No implicit order

```text
submit(a) before submit(b)
```

does not imply:

```text
complete(a) before complete(b)
visible(a) before visible(b)
persist(a) before persist(b)
```

### Range independence

Proven-disjoint ranges may proceed independently. Overlapping read/write or write/write operations require explicit order, snapshot/version semantics, atomicity, compare/exchange, merge, or a deliberately named unsafe race profile.

### Receipt monotonicity

A stronger receipt comes only from a declared operation, a runtime-accepted backend evidence transformation, or a checked protocol over prior receipts. Casts, comments, and optimistic method names have no promotion rights.

### Replay

Replay matches exact request/resource/profile identity, returns the recorded accepted observation, and performs no live external operation.

### Quantum separation

```text
quantum state is not an I/O byte resource
```

Classical circuit descriptions, parameters, target envelopes, and observations may use the fabric. Coherent state transformations remain WIP-0002 quantum IR.

## Structured concurrency

The source distinction is normative:

- Asynchronous work is independent and may execute inline on a conforming single-threaded backend.
- Concurrent work requires actual overlapping progress and fails before use when the backend cannot provide it.

A scope may own groups with `awaitAll`, `firstFailure`, cancellation, and canonical result reduction. Selection policies include first terminal, first success, all, all successful, quorum, deadline-or-result, and ordered prefix.

Selecting one operation does not orphan the others. Nonselected operations remain owned until canceled/reaped or transferred.

Deadlines require an explicit clock capability and request cancellation. Expiry doesn't prove the effect did not occur.

A persisted continuation contains canonical owned request state, capability reference, external operation identity, expected result schema, correlation/idempotency data, and event history. It contains no process borrow, native descriptor, registered address, or remote key.

## Buffers and memory

WIP-0028 owns memory semantics.

- Reads hold exclusive destination loans until final release.
- Writes hold shared source loans until final release.
- A caller may move a buffer into an operation and recover it from the terminal result.
- Segments carry origin, range, mutability, alignment, and registration state; forbidden overlap fails verification.
- Buffer-pool leases are affine and explicitly returned.
- Provided-buffer completion transfers one lease to the application.
- Registered regions consume bounded pin/map credit and cannot move, deallocate, or deregister while referenced.
- Reused untrusted buffers follow explicit initialization and zeroing policy.
- Backend completions cannot claim more bytes than supplied storage.

The portable core requires no tracing collector or one allocation per operation. Scope slots, ring entries, slabs, arenas, continuations, inline completions, and hardware trackers are permitted bounded representations.

## Backpressure and scheduling

Every queue is bounded. Credits cover pending work, completions, buffers, pinned bytes, connections, timers, task frames, queue depth, RDMA work requests, tier capacity, transfer bytes, and CPU service.

`trySubmit` returns unavailable credit immediately. `submit` may wait under scope cancellation/deadline; `reserve` acquires bounded graph capacity before construction.

Backends reserve enough control capacity for cancellation, completion, scope close, deregistration, shutdown, and error reporting. Saturating the data plane cannot permanently prevent cleanup.

Admission policy may include active/queued limits, tenant quotas, token buckets, weighted fairness, priority, load shedding, and queue-delay bounds. Completion queues never silently drop terminal events; backpressure begins before overflow.

Backend profiles name lane count, concurrency, polling, preemption/yield budget, batch size, fairness, memory per operation/connection, timer strategy, migration, and NUMA policy.

## Addressing families

### Positional storage

Initial request families include `readAt`, `writeAt`, `readMany`, `writeMany`, `copyRanges`, `append`, zone append, exact atomic writes when supported, and versioned compare/exchange.

A request names object, range, buffers, path policy, ordering domain, atomicity/version requirements, lane/topology hint, deadline, cancellation, and observation policy. Addressable resources have no shared cursor.

Range capabilities may split one object into disjoint affine authorities and later join them after origin/range checks.

### Sequential adapters

A sequential adapter owns one affine cursor over an addressable object or inherently ordered byte channel. It may provide buffering, `peek`, `consume`, delimiter scans, parsing helpers, exact limits, and `flushBuffer`.

`flushBuffer` submits userspace-buffered bytes. It returns no persistence receipt. Two tasks cannot mutate one cursor without an explicit shared sequential protocol.

Segmented parsers distinguish consumed bytes, examined-but-retained bytes, configured limits, and end-of-input.

### Byte channels, messages, and datagrams

Byte channels preserve byte order, not message boundaries; message and datagram endpoints preserve boundaries and metadata. Framing a byte channel is a protocol adapter; flattening messages requires an explicit framing rule.

Send completion says only what the local transport/backend contract says. Peer receipt, peer application, peer persistence, and exactly-once processing require stronger protocol results.

## Batches, graphs, and selection

Independent batch members may reorder, shard, coalesce, and complete out of order. Aggregate results retain request identity and reduce in canonical order when semantics require it.

Graph failure policy is explicit: cancel descendants, continue independent branches, execute fallback, accept degraded quorum, return partial manifest, or invoke declared compensation.

Example durable publication graph:

```wheeler
IoGraph graph = scope.graph();

Node<WriteCompleted> data = graph.add(
  temporary.writeAllAt(0, borrow bytes)
);
Node<DataStable> stableData = graph.after(data, temporary.persistData());
Node<NamespaceVisible> visible = graph.after(
  stableData,
  directory.replaceName(temporary, finalName)
);
Node<NamespaceStable> stableName = graph.after(
  visible,
  directory.persistNamespace(finalName)
);

NamespaceStable published = graph.submit(stableName).await();
```

The graph orders what must be ordered and leaves unrelated work alone.

## Direct and zero-copy paths

Asynchrony, direct access, zero-copy, and durability are orthogonal.

A direct capability publishes memory/offset/length alignment, segment and transfer limits, and cache-coherence policy. `DirectRequired` rejects fallback; `DirectPreferred` reports the actual path. Zero-copy uses the same required/preferred distinction.

Unaligned tails use an explicit bounce buffer, buffered tail, read-modify-write protocol, or rejection. Mixing overlapping buffered and direct access is rejected without a coherence contract.

Direct write completion does not imply persistence. A device path may be fast enough to outrun a bad assumption, which remains a bad assumption.

Transfer metadata may report copied, kernel zero-copy, device-direct, RDMA one-sided, storage offload, or unknown optimization. It is informational unless the request made the path semantic.

## Multi-queue storage and topology

`IoTopology` may describe controller/namespace identity, NUMA placement, queue count/depth, channels/zones, alignment, polling, registration, bandwidth/latency class, failure domain, and endurance.

Backends may distribute disjoint ranges over controller queues, flash channels, dies, zones, device heads, or stripes. Portable algorithms may prefer topology; only specialized capabilities may require it.

Interrupt, worker, busy-poll, adaptive-poll, centralized-poll, and device-notification backends implement the same lifecycle. Polling policy includes CPU budgets and bounded turns.

Zoned resources expose range, capacity, write pointer, append, reset, finish, active/open limits, and ordering requirements. Random write is absent when the device does not provide it.

## High-scale networking

C10M is a conformance profile, not a portable numerical promise.

The semantic model requires no native thread, native stack, active task, or operating-system timer per dormant connection. Backends may keep compact generation-checked connection state in slabs, use shared multishot accept/receive, provided buffers, lane ownership, batched notifications, and shared timer wheels.

Connection migration is explicit and may require quiescence. Pool exhaustion rejects, waits, or sheds under declared admission policy before unsafe allocation.

Performance reports name bytes per dormant connection, bytes per active operation, timer memory, stack/task policy, handle limits, churn, completion throughput, mixed-load tail latency, overload behavior, and cancellation/reap correctness.

## Storage tiers and burst buffers

A tier descriptor names capacity, allocation unit, volatility, failure domain, persistence support, locality, performance class, endurance, eviction, sharing, and supported paths.

A tier allocation is an affine capacity lease. `stage` returns `Staged`, which identifies content, tier, placement, failure domain, retention, eviction, and any actual persistence evidence. `Staged` alone is not `DataStable`.

`drainTo` is an owned asynchronous operation. It may combine, reorder, stripe, throttle, or offload independent data, but cannot claim destination durability before the required persistence receipt exists.

A full tier waits, rejects, or spills under explicit policy. It never silently evicts uncommitted data. Background drain belongs to a caller/service scope or persisted continuation; a source lease cannot expire while a live drain depends on it.

Checkpoint staging, drain, persistence, and catalog publication are separate graph phases and receipts.

## RDMA and remote regions

Local registration binds a bounded range, backend/device, protection domain, rights, epoch, credit, and required affinity; remote advertisement binds session, protected range, rights, remote epoch, expiration/revocation, ordering domain, and protocol identity.

Raw addresses and keys are not portable values.

One-sided read/write/atomic and two-sided send/receive remain distinct. Requests name local/remote registered ranges, rights, queue/lane, ordering domain, fences, completion level, cancellation, and any remote-persistence protocol.

The receipt ladder is explicit:

```text
LocalSourceReleased
TransportCompleted
RemoteVisible
PeerAcknowledged
PeerApplied
RemoteDataStable
RemoteQuorumStable
```

Ordinary RDMA completion does not establish peer processing or remote persistence. Remote persistence depends on exact memory, DMA/cache path, power protection, remote CPU/flush involvement, ordering, hardware, software, and replication profile.

Connection loss or revocation may produce `Uncertain` with operation identity, range, known progress, remote epoch, and reconciliation key. Re-registration changes epochs and invalidates stale advertisements.

## Visibility and durability receipts

A durability guarantee is not a Boolean. It records:

- protected resource/object, generation, ranges/records, content identity, metadata, namespace/catalog relation, and replica set;
- visibility domain;
- named failure model;
- exact atomicity;
- replication/quorum rule and independence assumptions;
- backend/profile/operation/protocol evidence;
- assumptions and receipt chain.

Public nominal types include `WriteCompleted`, `RemotePlaced`, `PeerApplied`, `Staged`, `DataStable`, `FileStable`, `NamespaceVisible`, `NamespaceStable`, `QuorumStable`, and `Published`.

Receipt values are compiler/runtime-owned evidence. Applications cannot construct, cast, or deserialize stronger guarantees from weaker ones.

Persistence may return persisted evidence, failure before persistence, known partial receipts, uncertain persistence, or unsupported requirement. A failed call does not prove that no prior state became stable.

For files, the stages are separate:

```text
WriteCompleted
DataStable
FileStable
NamespaceVisible
NamespaceStable
```

Canonical replacement writes a new generation, persists data, persists required metadata, atomically changes the visible name, persists the namespace, and optionally publishes a higher catalog. Atomic rename is one stage, not the entire bedtime story.

Release-grade durability profiles require crash injection, qualified failure/power testing, exact filesystem/device configuration, failed-persistence behavior, namespace tests, cache tests, remote protocol tests, and evidence-chain verification.

## Rewind, replay, retry, and compensation

Submitting or awaiting live I/O is an effect barrier. Machine rewind restores Wheeler state above the horizon; it does not reread, unsend, or unwrite external state.

A live read may become a WIP-0004 observation. Replay validates exact identity and returns recorded bytes/results without live I/O.

Retry creates a new operation/event lineage. Idempotency keys, expected generations, compare/exchange, deduplication, and reconciliation are explicit protocol tools; the fabric does not infer exactly-once execution.

Compensation is a second external effect with its own failure and uncertainty. Isolation and write-new-generation protocols may prevent publication before commit without claiming inverse execution.

A commit horizon advances only after required receipt and continuation/event persistence policy succeeds.

## Quantum I/O

Classical source, parameters, circuit artifacts, target descriptors, credentials, submission envelopes, logs, and observed result bytes use ordinary I/O capabilities.

A quantum target adapter exposes typed requests such as session preparation, region submission, job observation, cancellation, result receipt, and session close. These use `IoScope`, WIP-0004 identities, cancellation races, continuations, replay/fresh policy, validation, and resource/cost limits.

Coherent state transformation remains unitary/coherent WIP-0002 IR. A `Qreg` cannot be opened as a file, mapped, registered for RDMA, hashed as unknown state, or sent as bytes. Measurement explicitly transitions quantum ownership and produces a classical observation, which may then be recorded or persisted.

Target session survival requires an explicit resumable capability and persisted continuation. Future entanglement distribution returns affine quantum resources and provenance, not ordinary byte buffers.

## Composition model

Direct style is primary. Optional combinators may include `mapResult`, `thenRequest`, `zip`, `all`, `firstSuccess`, and `recover`.

Dependent work uses sequencing. Independent work uses applicative batch/graph composition instead of an artificial `bind` chain.

After WIP-0030 and WIP-0031, a library may expose:

```text
IoAction<Effects, Result>
QuantumAction<InputState, OutputState, Effects, Result>
```

Effect and resource-state indices remain visible. A conventional duplicable `State<QuantumState, A>` is rejected. Optional sequencing sugar must transparently desugar to request chaining, explicit suspension, effects, and resource transitions.

## Backend contract

Initial backend classes include deterministic inline, bounded threaded, readiness-driven, completion-driven, polling, io_uring, IOCP/RIO, kqueue/event-port, user-space NVMe/SPDK, packet path, RDMA, tiered storage, and hybrid routing.

Capability discovery names positional I/O, batch, graph, multishot, provided/registered buffers, direct, zero-copy, polling, RDMA, zoned storage, and exact durability profiles.

A portable threaded backend is required before optimized backends may claim equivalence. Readiness is translated into operation progress; readiness itself is not completion. Completion backends validate native results; polling backends declare CPU budgets. Routing backends cannot change result meaning.

## Bytecode, packages, and security

Canonical `.wbc` remains the sole semantic artifact. Typed operation metadata includes schema ID, capability type, request/result type, buffer ownership, scope relation, WIP-0031 effect row, cancellation/deadline policy, bounds, replay identity inputs, and receipt requirements.

The first lowering may use WIP-0001 `EFFECT_CALL` and WIP-0004 continuations instead of multiplying low-level opcodes. Bytecode contains no descriptors, pointers, native queues, addresses, remote keys, provider objects, or credentials.

Package manifests request exact target/phase-scoped capabilities such as file read/write, network connect/listen, direct storage, persistence evidence, RDMA registration/remote access, and target submission. Build programs retain WIP-0023 sealed declared inputs/outputs; runtime I/O support does not hand them the network keys.

Runtime and verifier limits cover scopes, operations, tasks, groups, batches, graph nodes/edges, lanes, completions, segments, pinned bytes, connections, timers, multishot items, transfers, tiers, RDMA resources, evidence bytes, cancellation/reconciliation, and total work.

Untrusted backends cannot forge lengths, identities, rights, receipt strength, or quantum state; privileged direct/user-space/RDMA adapters require declared trust and may require isolation.

## Ownership and boundaries

The language owns request/result types, effects, suspension syntax, scopes, operations, cancellation semantics, and receipt types.

The verifier owns lifecycle, loans, scope nonescape, effect legality, receipt provenance, bounds, and quantum/I/O separation.

The runtime owns scheduling, dispatch, completion, cancellation translation, replay integration, limits, and evidence validation.

Backend adapters own native translation, topology, native error mapping, evidence acquisition, performance paths, and conformance profiles.

WIP-0032 owns the common I/O method registry and lifecycle. Resource-specific WIPs own their domain data and rules, including paths, namespace transitions, wire protocols, TLS, object semantics, distributed transactions, and target commands. Every operation still goes through this fabric. Those WIPs cannot introduce a second request, future, stream, callback, cancellation, completion, or receipt authority. Applications own admission, durability requirements, retry, reconciliation, compensation, publication, and granted performance policy.

## Migration and deletion

1. Freeze request, operation, scope, completion, cancellation, and result schemas.
2. Implement deterministic inline and bounded threaded backends.
3. Implement positional file I/O and sequential adapters.
4. Add groups, batches, selection, and graph dependencies.
5. Add channels, messages, datagrams, listeners, and lane ownership.
6. Add event/completion backends.
7. Add pools, registered/provided buffers, and zero-copy release tracking.
8. Add explicit direct-file constraints and coherence.
9. Add receipts and crash-tested atomic publication.
10. Add high-scale network, multi-queue storage, tier, RDMA, and quantum-target profiles in independent reviewable slices owned by this WIP.
11. Add deterministic failure, replay, and schedule exploration.
12. Delete ambient I/O globals, cursor-only foundations, hidden unbounded pools, callback-only APIs, bare ambiguous `flush`, and dishonest durability claims.

Filesystem, networking, tier, RDMA, durability-profile, and quantum-network details may receive dependent successor WIPs before WIP-0032 leaves Draft. Such a successor owns domain semantics only and amends this WIP's method registry; it cannot fork the lifecycle. Device-specific details may live in dependent proposals, but they must use the same event lifecycle.

## Progress

- [x] Proposal index, dependent WIPs, current references, and future documentation name WIP-0032 as the sole I/O lifecycle and method-registry owner; no competing portable method family remains in another WIP.
- [ ] Unified request/scope/result model is accepted.
- [ ] Async versus required-concurrent behavior is accepted.
- [ ] Terminal completion, cancellation, uncertainty, and reap laws are accepted.
- [ ] Positional storage and sequential adapters execute.
- [ ] Groups, batches, graphs, selection, and multishot operations execute.
- [ ] Deterministic inline and bounded threaded backends pass.
- [ ] Event/completion backend passes.
- [ ] Registered/provided/zero-copy buffer safety passes.
- [ ] Direct I/O and coherence profile passes.
- [ ] Durability receipts pass crash-injection conformance.
- [ ] High-scale network and multi-queue storage profiles pass on declared hardware.
- [ ] Tiered storage and RDMA profiles pass.
- [ ] Quantum target lifecycle uses the fabric.
- [ ] Ambient, cursor-only, callback-only, and ambiguous-flush paths are deleted.

## Testing and acceptance

### Lifecycle and ergonomics

- [x] Repository documentation contains one portable I/O lifecycle owner and links integration clauses back here instead of copying method contracts.
- [ ] One request type can be awaited, submitted, batched, graphed, or selected.
- [ ] Request construction performs no external I/O.
- [ ] Every submitted operation has one terminal completion and one reap.
- [ ] Dropping a live operation or leaving a scope with live work is rejected.
- [ ] Inline and delayed completion have equal semantic results.
- [ ] `async` may execute inline; `concurrent` fails when overlap is unavailable.
- [ ] Common examples require no backend vocabulary or manual polling.

### Cancellation and replay

- [ ] Cancellation-before-effect, partial effect, completion-won, failure, and uncertainty are distinguishable.
- [ ] Deadline expiry requests cancellation and never proves no effect.
- [ ] Every uncertain result carries reconciliation identity and known progress.
- [ ] Replay performs no live I/O and validates exact request/resource/profile identity.
- [ ] Retry creates a new lineage; no generic API claims exactly-once execution.

### Buffers and pressure

- [ ] Reads hold exclusive destination loans and writes hold shared source loans until release.
- [ ] Moved buffers return through terminal results.
- [ ] Segment overlap/range arithmetic and backend result lengths are checked.
- [ ] Registration, pool, queue, completion, timer, and total-work limits fail closed.
- [ ] Data-plane saturation preserves cleanup/control credit.
- [ ] Zero-copy does not release a source before final reuse permission.

### Ordering and addressing

- [ ] Independent batch operations complete in every permitted order.
- [ ] Graph dependencies serialize only dependent branches.
- [ ] Submission order creates no implicit completion or persistence order.
- [ ] Disjoint ranges run independently; unsafe overlap is rejected or explicitly named.
- [ ] Sequential adapters own exactly one cursor and preserve consumed/examined positions.
- [ ] Canonical aggregate reduction is independent of physical completion order.

### Direct, topology, and scale

- [ ] Required direct/zero-copy paths reject fallback; preferred paths report it.
- [ ] Alignment, tail handling, and buffered/direct coherence are explicit.
- [ ] Direct completion produces no persistence receipt by itself.
- [ ] One-queue, many-queue, interrupt, worker, and polling backends pass one semantic suite.
- [ ] Connection scale requires no native thread, stack, task, or timer per dormant connection.
- [ ] Admission, batching, migration, fairness, and overload remain bounded and measurable.

### Tier and RDMA honesty

- [ ] `Staged` names its tier and failure domain and cannot be treated as durable.
- [ ] Drains retain source leases and preserve known partial receipts on failure.
- [ ] Remote advertisements are unforgeable, bounded, right-checked, and epoch-checked.
- [ ] One-sided placement, peer acknowledgement, peer application, and persistence remain distinct.
- [ ] RDMA completion cannot be cast to remote persistence.
- [ ] Connection/revocation races can return uncertainty.

### Durability

- [ ] `WriteCompleted`, `DataStable`, `FileStable`, `NamespaceVisible`, `NamespaceStable`, and `QuorumStable` cannot be confused or forged.
- [ ] Requirements name protected subject, failure model, atomicity, and replication.
- [ ] Unsupported requirements fail instead of silently degrade.
- [ ] Data, metadata, namespace, catalog, and quorum stages test separately.
- [ ] Persistence failures report known, partial, or uncertain state accurately.
- [ ] Crash/power/profile evidence binds exact backend assumptions.
- [ ] Documentation uses the word durable for close, rename, staging, direct completion, transport completion, or ordinary replication only when exact evidence supports it.

### Reversibility, quantum, and backends

- [ ] Live I/O is rejected from `rev`, `coherent rev`, `unitary`, and proof bodies.
- [ ] Compensation is a new effect and rewind cannot cross an I/O barrier.
- [ ] Quantum registers cannot become files, bytes, mapped regions, or RDMA registrations.
- [ ] Target submission/cancellation/result handling uses WIP-0004 identities and this lifecycle.
- [ ] Measurement remains a quantum effect; replay reuses only its classical observation.
- [ ] Deterministic, threaded, readiness, completion, polling, native, and VM implementations agree on lifecycle and encodings.

## Alternatives

A universal sequential stream is rejected because it serializes storage and remote ranges that have no semantic cursor.

Blocking APIs over an invisible thread pool are rejected as the model. They hide queue capacity, cancellation, memory use, and required concurrency.

A future alone is insufficient: it does not define scope ownership, cancellation races, multishot items, buffer release, batching, graph order, or durability.

Dropping a future as cancellation is rejected because external work may have completed, partially completed, or become uncertain.

Callbacks, actors, CSP channels, and monadic bind remain useful implementation/library techniques; none alone covers positional buffers, device queues, graphs, and receipts. Direct style plus explicit independent composition is primary.

Exposing io_uring, IOCP, kqueue, SPDK, or RDMA verbs directly is rejected as the portable API. They are backends with different lifetime and feature rules.

Automatic unreported direct/zero-copy fallback, bare `flush()`, close-as-persistence, rename-as-durable-publication, transparent retry, generic rollback, universal polling, task-per-connection requirements, transparent tier eviction, and RDMA-as-local-memory are rejected.

## Open questions

- Is `scope.await(request)`, `await request`, or exact sugar for both the final surface (owner: language/tooling; decision point: parser implementation)?
- Are `async` and `concurrent` keywords, scope operations, or WIP-0031 callable characteristics (owner: language/runtime; decision point: structured-concurrency syntax)?
- Are `Request<T>` and receipt families explicit source types or commonly inferred (owner: language/library; decision point: API stabilization)?
- Which operation/result names form the first public vocabulary (owner: library/documentation; decision point: first implementation)?
- Are durability receipts nominal types, `Receipt<Guarantee>`, or both (owner: storage/types/proof; decision point: schema freeze)?
- What portable failure-domain algebra accurately covers devices and distributed stores (owner: storage/distributed systems; decision point: durability profile)?
- Which cancellation outcomes share a common variant and which remain effect-specific (owner: runtime/API; decision point: lifecycle freeze)?
- Which backend features and numerical scale profiles are tier-one requirements (owner: runtime/platform/performance; decision point: native conformance)?
- Which filesystem, network, tier, durability, RDMA, and quantum-network domain rules need dependent successor WIPs while this WIP retains the method registry and lifecycle (owner: proposal maintainers; decision point: before Review)?

## References

### Wheeler proposals

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0002](WIP-0002-unified-classical-quantum-semantics.md)
- [WIP-0003](WIP-0003-quantum-target-and-qiskit-backend.md)
- [WIP-0004](WIP-0004-hybrid-jobs-history-and-replay.md)
- [WIP-0005](WIP-0005-wheeler-source-language.md)
- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0012](WIP-0012-wheeler-standard-library.md)
- [WIP-0013](WIP-0013-typed-frames-control-flow-and-storage.md)
- [WIP-0022](WIP-0022-package-instances-and-resolution.md)
- [WIP-0023](WIP-0023-recipe-repositories-and-reproducible-builds.md)
- [WIP-0025](WIP-0025-native-ffi-and-system-integration.md)
- [WIP-0028](WIP-0028-deterministic-ownership-borrowing-and-regions.md)
- [WIP-0030](WIP-0030-coherent-type-classes-and-associated-types.md)
- [WIP-0031](WIP-0031-reversible-quantum-and-effect-polymorphism.md)

### Systems and language design

- [Zig `std.Io`](https://github.com/ziglang/zig/blob/master/lib/std/Io.zig)
- [Go `io.ReaderAt` and `io.WriterAt`](https://pkg.go.dev/io)
- [.NET pipelines](https://learn.microsoft.com/dotnet/standard/io/pipelines)
- [Linux io_uring](https://docs.kernel.org/io_uring/)
- [Windows I/O completion ports](https://learn.microsoft.com/windows/win32/fileio/i-o-completion-ports)
- [MegaPipe](https://www.usenix.org/conference/osdi12/technical-sessions/presentation/han)
- [mTCP](https://www.usenix.org/conference/nsdi14/technical-sessions/presentation/jeong)
- [IX](https://www.usenix.org/conference/osdi14/technical-sessions/presentation/belay)
- [Shenango](https://www.usenix.org/conference/nsdi19/presentation/ousterhout)
- [Shinjuku](https://www.usenix.org/conference/nsdi19/presentation/kaffes)
- [Demikernel](https://dl.acm.org/doi/10.1145/3477132.3483561)
- [SPDK](https://spdk.io/doc/about.html)
- [NVM Express specifications](https://nvmexpress.org/specifications/)
- [Linux zoned storage](https://zonedstorage.io/docs/)
- [Hermes tiered buffering](https://doi.org/10.1145/3208040.3208059)
- [UnifyFS](https://doi.org/10.1109/IPDPS54959.2023.00037)
- [rdma-core](https://github.com/linux-rdma/rdma-core)
- [Correct, Fast Remote Persistence](https://arxiv.org/abs/1909.02092)
- [CrashMonkey and ACE](https://doi.org/10.1145/3132747.3132777)
- [Can Applications Recover from `fsync` Failures?](https://www.usenix.org/conference/atc20/presentation/rebello)
- [The Quantum IO Monad](https://doi.org/10.1017/CBO9781139193313.006)
- [Proto-Quipper-M abstract machine](https://arxiv.org/abs/2105.03522)
