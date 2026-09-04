# WIP-0125: Lazy committed root-status publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler VM and bootstrap maintainers |
| Created | 2026-08-17 |
| Updated | 2026-09-04 |
| Area | Virtual machine, root task, native closure execution |
| Depends on | WIP-0039, WIP-0044, WIP-0085, WIP-0115 |
| Supersedes | Transient root task-status writes during successful committed transitions |
| Superseded by | None |
| Follow-up | A completed WIP-0039 task-tree scheduler |

## Summary

Keep the root task's published status `RUNNABLE` while one successful committed transition executes. Publish `COMPLETED` only when that transition halts. A transition that traps during execution still publishes `RUNNING` before it rethrows, preserving the existing failed-transition snapshot.

This removes two task-status writes from every nonhalting `stepWithoutRewindHistory` transition. Retained-history execution and future multitask scheduling keep their existing status protocol.

## Rule

`stepRootWithoutRewindHistory` already requires the root task to be runnable before instruction execution. The VM is single threaded, and no instruction reads task status. A successful transition therefore has no observer between the old `RUNNING` write and the old return to `RUNNABLE`.

The committed path now:

1. requires `RUNNABLE`
2. commits the root scheduler cursor
3. validates and executes the instruction
4. restores the historical `RUNNING` trap state if execution throws
5. increments the sequence
6. publishes `COMPLETED` on halt
7. emits the unchanged observation

A nonhalting success leaves the already published `RUNNABLE` value untouched.

## Observable state

Snapshots before and after every successful transition remain identical to the previous protocol. Selection remains root, the scheduler cursor remains root, and status remains runnable until halt.

A real observer still receives one immutable event after each successful transition. The observer sees the same frame, instruction, sequence, task identity, direction, and final machine state.

Preflight failures occur before task execution and retain their previous runnable task status. Exceptions from execution set the task to running before they leave the VM, matching the prior failed-transition state.

## WIP-0039 boundary

The optimization applies only to `stepWithoutRewindHistory` under the implemented root-only profile. `step()` still uses the general scheduler and explicit running publication because rewind records retain prior task state.

A future task tree must replace this specialization atomically. Spawn, join, scheduler interleaving, task-visible status, ownership transfer, and global rewind may create observable intervals where a running status matters.

## Evidence

The complete core VM suite passes. It covers observed committed execution, retained history rejection, calls, inverse calls, results, traps, ownership, effects, task snapshots, scheduler state, and exact rewind.

`NativeCompilerPhysicalClosureExampleTest` compares all selected physical artifacts, validates retained products and relocations, links the exact 96-product subset, repeats publication, and rejects malformed footer and relocation products. With 60 callable-bearing direct routes, it falls from 18 minutes and 22 seconds to 17 minutes and 35 seconds under the unchanged twenty-minute deadline.

Artifact bytes and the linked identity remain unchanged at `5fc2ddaec2835c516d52d1e8b1254aeaf50789c72d7b42cd0060b026b880ec25`.

## Acceptance

- [x] Successful nonhalting committed transitions perform no root task-status write.
- [x] Halting committed transitions publish `COMPLETED`.
- [x] Preflight failures retain the previous task status.
- [x] Execution failures retain the previous running trap state.
- [x] Scheduler cursor, task identity, frames, sequence, and observations remain unchanged.
- [x] Retained-history execution keeps the general status protocol.
- [x] The complete core VM suite passes.
- [x] The complete physical closure passes under its unchanged deadline.
- [x] Artifact and linked-container bytes remain exact.
- [x] Documentation, Java compilation, source length, and layout policy pass.

## Rejected alternatives

### Remove task status from snapshots

Rejected. Public task-keyed snapshots remain stable and WIP-0039 needs status authority.

### Skip failed-transition status restoration

Rejected. Trap snapshots must preserve the existing running task state after execution begins.

### Apply the shortcut to retained-history steps

Rejected. Rewind records preserve explicit prior task status and scheduler transitions.

### Raise the closure deadline

Rejected. Transient writes with no successful observation boundary are avoidable work.

## References

- [WIP-0039](WIP-0039-deterministic-structured-task-machine-and-global-rewind.md)
- [WIP-0044](WIP-0044-counted-native-compiler-closure-execution.md)
- [WIP-0085](WIP-0085-root-task-state-specialization.md)
- [WIP-0115](WIP-0115-root-committed-transition-dispatch.md)
