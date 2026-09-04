# WIP-0115: Root committed-transition dispatch

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler VM and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-09-04 |
| Area | Virtual machine, root task, native closure execution |
| Depends on | WIP-0039, WIP-0044, WIP-0083, WIP-0085 |
| Supersedes | Runnable-set selection during root-only committed transitions |
| Superseded by | None |
| Follow-up | A completed WIP-0039 task-tree scheduler |

## Summary

Dispatch `stepWithoutRewindHistory` through the implemented root-task profile. Avoid the general runnable-set search and selection restoration that can only select `TaskId.ROOT` while Wheeler has no spawn instruction.

Retained-history execution still uses the general scheduler path. Committed execution preserves validation, scheduler cursor commitment, task status, calls, returns, sequence numbers, traps, ownership, effects, and every noncanonical observer event.

## Problem

The VM currently owns one task and exposes no operation that can create another. WIP-0085 removed unreachable task maps, but every committed transition still asked a `TreeSet` to find a task above the root cursor and wrap to the first runnable task.

The answer is always root. The complete native physical closure performs more than 72 million committed transitions. Repeating the set search did not add a schedule choice or evidence.

## Dispatch

`stepRootWithoutRewindHistory` checks halted and trapped states, fetches the current root frame, and validates the instruction before mutation. It then requires the root status to be runnable and commits `TaskId.ROOT` to the scheduler.

Execution receives the same prior machine status, root selection, root scheduler cursor, and root task status as the general path. It creates no `StepRecord`, increments the same sequence, publishes the same completed or runnable task status, and emits the same observation when the observer is not `TransitionObserver.NONE`.

WIP-0125 removes the transient running and runnable writes from successful nonhalting committed transitions. The final published status and every failure state remain unchanged.

A retained rewind tail still rejects committed execution before dispatch. The specialized method cannot run after a noncommitted step until the caller establishes a commit horizon.

## Observable state

The scheduler cursor remains `TaskId.ROOT`. Snapshots retain task-keyed maps and report the same selection, task status, frames, globals, sequence, and machine status.

A focused differential test runs the counter fixture through retained-history and committed paths with real observers. It compares every immutable observation and every observable root-task field after halt. Only the committed path's empty rewind history differs by contract.

## WIP-0039 boundary

This specialization relies on the implemented root-only task profile. A future spawn instruction must not enter through this method piecemeal.

WIP-0039 must replace this dispatch atomically with task publication, runnable-set ordering, ownership transfer, join, global rewind, verifier rules, and schedule evidence. Until then, searching a singleton set on every committed transition is dead machinery.

## Evidence

The core VM conformance suite passes. `CommittedTransitionTest` covers forward and inverse calls, root frame changes, scheduler cursor, statuses, sequence numbers, globals, halt, observations, and empty committed history.

`NativeCompilerPhysicalClosureExampleTest` still compares every selected physical artifact, validates retained products and relocations, and links the exact 96-product container. The complete method fell from 17 minutes and 56 seconds to 16 minutes and 12 seconds on the same builder under the unchanged twenty-minute deadline.

The linked container remains byte-identical with SHA-256 `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] Committed root execution avoids general runnable-set search.
- [x] The scheduler still commits the canonical root cursor.
- [x] Nonrunnable, halted, trapped, and retained-history states fail before execution.
- [x] Instruction validation still precedes mutation.
- [x] Calls, returns, task status, sequence, globals, ownership, and effects remain unchanged.
- [x] Every noncanonical observer receives the complete immutable event stream.
- [x] Snapshots retain the task-keyed public shape.
- [x] Retained-history execution keeps the general scheduler path.
- [x] Core VM conformance passes.
- [x] The complete physical closure passes under its unchanged deadline.
- [x] Documentation, Java compilation, source length, and layout policy pass.

## Rejected alternatives

### Raise the closure deadline

Rejected. Singleton runnable-set search is avoidable work.

### Suppress observers on committed execution

Rejected. Proof and coverage consumers may observe a run without retaining rewind history.

### Remove the scheduler cursor

Rejected. The cursor remains public snapshot state and future task-ordering authority.

### Generalize tasks without spawn semantics

Rejected. Containers alone do not implement WIP-0039 scheduling, ownership, join, or rewind.

## References

- [WIP-0039](WIP-0039-deterministic-structured-task-machine-and-global-rewind.md)
- [WIP-0044](WIP-0044-counted-native-compiler-closure-execution.md)
- [WIP-0083](WIP-0083-zero-allocation-unobserved-transitions.md)
- [WIP-0085](WIP-0085-root-task-state-specialization.md)
- [WIP-0125](WIP-0125-lazy-committed-root-status-publication.md)
