# WIP-0085: Root task state specialization

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler VM and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-09-04 |
| Area | Virtual machine, task state, native closure execution |
| Depends on | WIP-0039, WIP-0044, WIP-0083 |
| Supersedes | Map-backed storage for the current root-only task profile |
| Superseded by | None |
| Follow-up | A completed WIP-0039 task-tree store |

## Summary

Store the current VM's one root frame stack and status directly. Remove map-backed task state that had no spawn, join, child publication, or child lookup path.

The scheduler, snapshots, observations, event identities, status transitions, calls, returns, rewind, and public root task identity remain unchanged. WIP-0039 still owns a future task-tree store together with the instructions and evidence needed to populate it.

## Problem

`TaskTable` used two `TreeMap` instances keyed by `TaskId`. Every transition performed repeated map lookups and two status writes. Calls, returns, snapshots, and rewind also selected a stack through the map.

The implementation exposed no operation that could add a second task. `runnableTaskIds` returned one static root set or an empty set, regardless of map contents. `select` could therefore select only `TaskId.ROOT`. The maps represented unreachable structure rather than implemented task semantics.

Native compiler closure executes more than 72 million transitions. Paying tree-map dispatch for one fixed key consumed evidence time without adding a schedule choice.

## Current profile

The current VM owns exactly:

- `TaskId.ROOT`
- one bounded root frame stack
- one root `TaskStatus`
- one canonical scheduler cursor
- one global rewind history

`TaskTable.selected()` returns `TaskId.ROOT`. `select` accepts only that identity and traps for any other identity. `runnableTaskIds` continues to return the immutable root set only while the root status is runnable.

Snapshots still publish maps. `snapshotFrames` returns one immutable root entry whose value is an immutable frame list. `snapshotStatuses` returns one immutable root status entry. Public snapshot shape and equality remain unchanged.

## Calls and rewind

A call appends one frame to the root stack. A return removes it. A result return updates the caller frame after removing the callee. Rewind restores the same stack operations from the retained `StepRecord`.

The specialization does not change frame immutability, local register persistence, scheduler cursor restoration, event identity, history limits, or commit horizons.

## WIP-0039 boundary

Hierarchical `TaskId` and deterministic `TaskScheduler` remain as stable semantic types. WIP-0039 is a draft and no bytecode instruction can create a task tree today.

A WIP-0039 implementation must replace the root specialization atomically with a bounded task-tree store. That change must also provide spawn and join instructions, ownership transfer, runnable-set publication, global journal records, verifier rules, exact rewind, finite schedule evidence, and the bakery-mutex acceptance program. Retaining empty maps before those semantics exist does not advance that work.

WIP-0115 extends the same boundary to committed transition dispatch. It avoids searching the singleton runnable set but keeps the root scheduler cursor and full observation stream.

## Evidence

All core tests pass. They cover root task and event identities, scheduler wraparound, snapshots, observations, calls, returns, result transfer, traps, commits, ownership, aggregate state, and exact rewind.

The focused `NamedComparisonKinds.w` product evidence fell from 6 minutes and 35 seconds after WIP-0083 to 4 minutes and 57 seconds on the same builder. Artifact bytes and transition semantics remained exact.

The complete physical product closure compiles all selected products and links the exact retained subset under the unchanged deadline. It passed in 13 minutes and 31 seconds on the same builder. The preceding map-backed run took 18 minutes and 47 seconds.

## Acceptance

- [x] Root frame storage uses one direct bounded stack.
- [x] Root status storage uses one direct value.
- [x] Non-root selection fails closed.
- [x] Runnable-set, snapshot, observation, event, call, return, and rewind semantics remain unchanged.
- [x] No implemented task publication path is removed.
- [x] Core VM tests pass.
- [x] Focused native artifact evidence matches stage 0 byte for byte.
- [x] The complete native physical closure passes under its unchanged deadline.
- [x] Documentation, Java compilation, line, and style policy pass.

## Rejected alternatives

### Keep unreachable maps for future tasks

Rejected. Future task semantics require more than containers and must enter atomically with verification and rewind evidence.

### Bypass the scheduler

Rejected. Canonical root selection and cursor state remain observable machine semantics.

### Change snapshots to root-only records

Rejected. Existing tooling consumes task-keyed immutable maps. The specialization stays private.

### Merge WIP-0039 into this change

Rejected. Task creation, ownership transfer, shared atomics, schedule plans, and global rewind form a separate large protocol.

## References

- [WIP-0039](WIP-0039-deterministic-structured-task-machine-and-global-rewind.md)
- [WIP-0044](WIP-0044-counted-native-compiler-closure-execution.md)
- [WIP-0083](WIP-0083-zero-allocation-unobserved-transitions.md)
- [WIP-0115](WIP-0115-root-committed-transition-dispatch.md)
