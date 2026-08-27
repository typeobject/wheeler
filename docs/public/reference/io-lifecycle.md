---
title: I/O, Cancellation, and Receipts
description: One portable lifecycle for external work, resource return, placement, and durability evidence.
---

# I/O, Cancellation, and Receipts

External work does not become reversible because a program requests it politely.
Wheeler gives files, sockets, storage tiers, and quantum targets one portable
lifecycle while allowing each resource to state its own physical facts.

The accepted host adapters remain stage-0 scaffolding beneath Wheeler's nominal
source API.

## One lifecycle

```text
prepared -> submitted -> terminal -> reaped
```

`IoRequest<T>` prepares a pure affine host request. Construction validates and
stores identity, work charge, and provider action without invoking that action.
Submission consumes the request once, charges all limits first, and creates one
`IoOperation<T>` identity.

`IoScope` fixes maxima for submissions, work, batches, graphs, terminal
completions, and reap operations. A scope cannot close while any operation remains
live or terminal and unreaped.

`IoCompletion<T>` keeps these facts separate:

- terminal kind.
- relation to cancellation.
- exact known progress.
- resource release.
- backend identity.

Await reaps once. A second await fails. A batch or graph that fails preflight
consumes no member request.

Inline and delayed backends produce the same semantic completion rows. Delivery
speed does not alter meaning.

## Portable backends

| Adapter | Operational shape |
| --- | --- |
| `DeterministicIo` | Inline or explicitly delayed completion. |
| `ThreadedIo` | A fixed worker count and fixed in-flight queue. |
| `CompletionIo` | One or more finite completion lanes driven by await or selection. |
| `ReadinessIo` | Executes only a request whose level signal is ready. |
| `PollingIo` | Requires explicit polling before direct await. |
| `InterruptIo` | Uses a fixed dispatcher for terminal notification. |

None creates an unplanned fallback pool. Closing a backend with admitted work
fails. Admission is reserved before consuming a request.

`ConnectionRegistry` may retain at most one million dormant authorities in
primitive tables. Dormant connections consume no active-work credit, worker,
stack, task, executor, or timer. Activation draws from a separate allowance.
Close requires dormancy and advances the generation.

## Cancellation and uncertainty

Queued cancellation completes before provider work and invokes no provider hook.
A started request may expose one total cancellation hook. The completion records
which outcome won instead of treating interruption as rollback.

`IoDeadline` takes an explicit semantic tick. Expiry requests cancellation once.
It never proves by itself that no effect occurred.

| Cancellation relation | Meaning |
| --- | --- |
| `CANCELED_BEFORE_EFFECT` | Provider action did not run. Progress is zero. |
| `CANCELED_AFTER_PARTIAL_EFFECT` | Known positive progress occurred before cancellation won. |
| `COMPLETED_BEFORE_CANCELLATION` | Success was already terminal. |
| `FAILED_BEFORE_CANCELLATION` | A known failure was already terminal. |
| `UNCERTAIN_WITHOUT_CANCELLATION` | The provider cannot establish the external result. |
| `UNCERTAIN_AFTER_CANCELLATION` | Cancellation raced with an unresolved result. |

Lifecycle encoding assigns terminal rows 1 through 4 to success, failure,
cancellation, and uncertainty. Cancellation relations use rows 0 through 6. The
encoding also carries progress, declared work, and resource release.

Cancellation never reaps and never claims rollback. Malformed provider progress
becomes a known failure before completion publication.

## Effect boundaries and compensation

The accepted source profile grants physical input and output only through an
`entry` signature. Reversible, coherent, unitary, test, and theorem declarations
cannot acquire ambient host resources.

`IoEffectBoundary.acceptLive` accepts one terminal completion and binds its facts
into a content identity. The boundary keeps current VM state and closes the prior
rewind tail.

`IoCompensation` constructs a second request from an effect-bearing completion.
Its action begins only after submission. Successful compensation receives its own
receipt and creates another effect boundary. It neither erases the first effect
nor supplies inverse execution.

## Native lifecycle kernel

`wheeler.runtime.io.portable` defines source-level request, scope, operation,
completion, queue, reap, and effect-boundary forms. Wheeler's `Lifecycle.w` owns
caller-provided columns for state, declared work, progress, terminal kind,
cancellation relation, resource release, and reap state.

The kernel accepts at most 64 rows. It rejects second completion, completion before
resource release, progress beyond declared work, inconsistent terminal and
cancellation rows, second reap, and scope close with unreaped work.

Late cancellation may strengthen a matching relation: success becomes
completion-won, known failure becomes failure-won, and independent uncertainty
becomes uncertainty-after-cancellation. It cannot rewrite an earlier effect into
cancellation-before-effect.

## Positional files

`MemoryAddressableFile` is the positional contract oracle. `readAt` and `writeAt`
validate complete ranges before capturing an owner. They report exact progress and
use no shared cursor.

`NativePositionalFile` opens one final physical component without following a
symbolic link. Authority is fixed as read-only or read-write, with extent from one
byte through 16 MiB. Close rejects any unreaped request resource.

A required direct path uses `openDirect`. It requires host support, one
power-of-two alignment no greater than 4,096 bytes, and aligned file position,
owner offset, length, and native buffer address. Unsupported or unaligned work
fails before capture. There is no silent buffered fallback.

A successful write yields `WriteCompleted`. `force(false)` may promote that exact
subject to `DataStable`. `force(true)` may promote it to `FileStable`. The present
native issuer admits only a one-replica `PROCESS_CRASH` profile naming the
FileChannel force contract. A `POWER_LOSS` profile is rejected.

`SequentialFileCursor` lends one cursor to one live request. Read completion
returns consumed and examined coordinates. `advance` moves only within that
completed window. Writes require a settled cursor where consumed equals examined.
Cancellation before effect releases the cursor without changing position.

## Buffer pools and direct profiles

`IoBufferPool` registers at most 4,096 fixed owners under a combined 16 MiB
ceiling. Acquisition returns the lowest free generation-checked lease. A lease is
unavailable during provider work and returns to the pool only after terminal
resource release and explicit `recycle`.

`OwnedIoBuffer` is inaccessible from request construction until terminal release.
Cancellation-before-effect returns it unchanged.

`DirectFile` binds one power-of-two alignment through 4,096 bytes. A required path
rejects unsupported or unaligned work. A preferred path either rejects fallback
or records `direct = false` under an explicit buffered-tail policy. Direct and
ordinary views share one synchronized byte authority in the positional oracle.
That agreement establishes semantic coherence, rather than host-device behavior.

## Native completion and readiness

`NativeCompletionFile` uses one no-follow asynchronous positional-file capability,
a fixed worker count, and a finite executor queue. Request construction captures
the owner and starts no operation. Progress begins through the selected completion
lane. Queued cancellation starts no file work.

`NativeReadinessSocket` acquires one connected nonblocking capability before
request construction. Read and write expose a level predicate backed by
`Selector.selectNow` and perform at most one channel operation after selection.
Polling forms require `pollOne` first.

The socket adapter supplies a byte stream. It defines no framing, retry, security,
congestion, or application protocol.

The declared host floor opens 256 simultaneous loopback channels with one service
worker and performs 64 positional writes across four file queues. This floor
checks adapter drift. It makes no throughput, latency, device, filesystem, crash,
or durability guarantee.

## Placement across tiers

`StagedData` binds content and byte count to a named tier, failure domain, and
optional parent placement. It is placement evidence and has no conversion to a
durability receipt.

`NativeTieredStorage` hashes source bytes before initial placement. Drain verifies
the source identity, writes the target range, and keeps source ancestry. A known
short transfer returns exact prefix placement evidence.

`RemoteMemory` uses an epoch-scoped advertisement naming range, rights, and
revocation epoch. Writes produce placement only. Peer acknowledgement, peer
application, and persistence remain distinct stages. Reconnection advances the
epoch and restores no earlier authority.

`NativeRnicRegistry` owns the host RNIC registration boundary. It binds a held
buffer range, remote rights, a monotonic generation, and backend-issued address
and keys into one private-constructor authority. Revocation removes authority
before native teardown. Disconnect revokes every registration in generation
order and releases every owner even when a backend reports failure.

Native one-sided reads and writes enter through ordinary `IoRequest` and
`IoScope`. Request construction holds the exact source or destination range but
performs no backend work. Completion requires matching generation, registered
range, byte count, provider progress, content identity, and backend evidence. A
read hashes received bytes before returning the destination owner. A write hashes
source bytes before capture. A revocation race or malformed provider success
returns uncertainty. Aligned 64-bit compare-and-swap additionally requires
read-write rights and reports the exact observed value. Exchange success derives
from equality with the requested expected value. Native completion establishes
no peer acknowledgement, application, persistence, or durability evidence.

Every prepared native RNIC operation receives a monotonic operation identity.
The backend receives that identity for execution and started-work cancellation.
Queued cancellation invokes neither hook and returns captured owners. A
cancellation request does not determine the outcome. Provider completion keeps
success, partial cancellation, failure, and uncertainty distinct.

Native peer acknowledgement consumes one exact write completion. Peer application
consumes that acknowledgement. Remote persistence consumes the application and a
SHA-256 profile identity naming backend assumptions. Each stage runs as another
request and validates generation, predecessor, progress, and backend evidence.
Remote persistence has no conversion to a durability receipt. Concrete hardware
and power-interruption qualification remains a release requirement.

## Batches, selection, and graphs

A batch contains independent work and creates no ordering edge. Selection reaps
one canonical terminal operation and returns every nonselected operation to the
caller.

An `IoGraph` names terminal predecessors. Independent roots enter together. A
dependent node is submitted only after all predecessors are terminal and reaped
into the graph table. Results return in stable node order regardless of delivery
order.

## Quantum work through I/O

`QuantumIo.request` performs target submission, waiting, result-identity checks,
cancellation propagation, completion, and reap as one I/O operation. Construction
allocates no provider job. Queued cancellation therefore allocates none.

After target allocation, one cancellation attempt owns the provider verdict.
Completion waits for that attempt to return before recording acknowledged partial
cancellation or uncertainty. Observing the target's cancellation effect does not
race ahead of its acknowledgement. Circuit descriptions and measured classical
results may cross the I/O fabric. A `qreg` has no path into classical buffers,
files, maps, or remote advertisements.

## Receipt chain

The stage-0 publication chain is monotonic:

```text
WriteCompleted
  -> DataStable
  -> FileStable
  -> NamespaceVisible
  -> NamespaceStable
  -> QuorumStable
```

`DurabilityReceipt` has no public constructor. Each promotion requires the exact
preceding receipt and matching evidence: operation completion, data flush,
metadata flush, atomic rename, namespace flush, then quorum protocol.

A receipt binds subject, failure model, atomicity, replica and quorum rule, backend
profile, sorted assumptions, evidence identity, parent, and depth. Canonical bytes
use a fixed 163-byte form. Stage 0 and Wheeler reproduce the full chain byte for
byte. Its terminal identity is:

```text
1d4fb3a8521eaa451dd37734c7fa0017e44bb7a684c004026c7c1c90c3f4d8b5
```

Skipping a stage, replaying evidence, asserting namespace visibility for a
non-namespace subject, or asserting quorum with one replica fails. These rules
prove schema order. They cannot prove that a provider's evidence is physically
true.

`NativeNamespacePublication` accepts one matching file-stable subject, performs a
no-replacement atomic move, and emits `NamespaceVisible`. Forcing the containing
directory may then emit `NamespaceStable`. The current qualification covers its
named process-crash FileChannel and atomic-move profile.

## Present physical boundary

Current adapters cover deterministic and threaded execution, finite completion
lanes, readiness and polling, positional files, one connected byte stream,
placement tiers, a remote-memory oracle, quantum target calls, and one native
process-crash publication profile.

They do not establish power-loss survival, public network protocols, RNIC
behavior, peer application, remote persistence, quorum behavior, or release-grade
hardware qualification. A successful write deserves only the receipt its evidence
can support.
