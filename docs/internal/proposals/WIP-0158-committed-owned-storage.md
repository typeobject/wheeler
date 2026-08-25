# WIP-0158: Committed owned storage

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler VM and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Virtual machine, owned storage, committed execution, self-hosting evidence |
| Depends on | WIP-0044, WIP-0115, WIP-0134 |
| Supersedes | Per-write persistent buffer roots during committed execution |
| Superseded by | None |

## Summary

Give one owned buffer a private committed update lifetime when the VM retains no rewind record. The ordinary path remains persistent. Snapshots and a later rewindable transition copy committed state back to a persistent root before exposing or recording it.

The compiler writes large staging products one scalar at a time. Copying a chunk table and one data chunk for every admitted write preserved rewind semantics that committed execution had explicitly discarded. It also allocated a fresh buffer state row for each write.

## Storage modes

`PersistentLongList` keeps one representation and two ownership modes.

A persistent list owns immutable chunk references. `with` and `withThree` return new roots and copy only touched chunks. Rewind records continue to retain those roots directly.

A committed list owns a private outer chunk table and a private ownership bit for each chunk. Its first write to a chunk copies that chunk. Later writes mutate the private chunk. The active buffer state row is replaced once when the persistent list enters committed ownership. Later writes retain that row.

There is no second list implementation and no polymorphic read path. Sparse zero chunks remain unallocated until first write.

## Isolation

Committed ownership is admitted only when `OwnedStore` receives no rewind change. This is the existing `stepWithoutRewindHistory` contract.

Three boundaries restore persistence:

- `buffers()` copies committed chunks before constructing a machine snapshot.
- a rewindable set or map update copies committed chunks before recording the prior buffer.
- a rewindable UTF-8 freeze or buffer drop records a persistent prior buffer.

The active committed list does not share writable chunks with a prior persistent list. A published snapshot therefore remains unchanged after later committed writes. Switching from committed execution to ordinary execution still rewinds to the exact committed boundary.

## Maps and byte buffers

Word and byte writes use one-element committed updates. Long-map insertion and replacement use one three-element update for presence, key, and value. The first and last words may cross a 64-word chunk boundary. Each touched chunk is copied at most once for the committed lifetime.

UTF-8 validation, buffer reads, map probes, host output, region accounting, kind checks, range checks, and live-storage limits retain the same representation and validation order.

## Evidence

The complete core suite covers committed updates, persistent snapshots, map updates, UTF-8 freeze, drop, exact rewind, malformed writes, allocation limits, observations, and task snapshots. The bounded bootstrap-manifest test accepts the current 177,378-byte graph of 379 modules and 1,883 imports in exactly 73,964,287 committed transitions.

A same-worktree alternating comparison used `NativeCompilerResolvedReturnCallKindsPhysicalProductExampleTest`. The committed implementation completed in 230.90 seconds. The immediately following persistent baseline completed in 462.28 seconds. Both produced the exact stage-0 artifact. The host was under sustained load, so the wall-time ratio is evidence of removed allocation pressure, not a portable performance promise.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `9a3fb81e4d75ad52d0ff22deefe636d58d56827ea1de80c1e87a2d96c8c60be9`. The complete run passes in 18 minutes and 34 seconds under the unchanged twenty-minute method deadline.

## Acceptance

- [x] Committed scalar writes copy each touched chunk at most once.
- [x] Committed map writes update three adjacent slots under one ownership decision.
- [x] Repeated committed writes allocate no replacement buffer row.
- [x] Persistent writes retain copy-on-write roots.
- [x] Snapshots do not share writable committed chunks.
- [x] A rewindable mutation records persistent state after committed execution.
- [x] Drops and UTF-8 freezes retain exact rewind state.
- [x] The complete core suite passes.
- [x] Focused physical output remains byte-identical.
- [x] The focused physical route improves in an alternating same-worktree comparison.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The linked physical subset publishes twice with identical bytes.
- [x] The complete closure evidence remains below twenty minutes.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### A second mutable list implementation

Rejected. It makes the dominant read path polymorphic and regressed the physical compiler workload.

### Mutate persistent chunks directly

Rejected. Snapshots and rewind records may retain those chunks.

### Freeze every buffer before every rewindable transition

Rejected. Read-only transitions do not need a storage root. The mutation boundary freezes only the buffer it changes.

### Remove persistent storage

Rejected. Ordinary execution promises exact rewind and immutable prior snapshots.

### Raise the closure deadline

Rejected. Committed writes have no prior state to preserve.

## References

- [WIP-0044](WIP-0044-counted-native-compiler-closure-execution.md)
- [WIP-0115](WIP-0115-root-committed-transition-dispatch.md)
- [WIP-0134](WIP-0134-single-pass-committed-vm-storage.md)
