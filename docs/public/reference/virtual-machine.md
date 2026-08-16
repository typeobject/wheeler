---
title: The Ways of Return
description: Deterministic execution, generated inverses, retained-history rewind, commit horizons, and traps.
---

# The Ways of Return

The Common Book uses *return* for several roads. The virtual machine keeps their
costs visible.

Wheeler 1.0 runs a deterministic, single-threaded transition kernel. It accepts
one verified immutable artifact and begins in `ready`. Execution moves through
`running` to `halted` or `trapped`.

## Machine state

A machine owns:

- typed signed and Boolean globals.
- immutable control frames with typed local registers.
- separate tables for records, variants, arrays, and slices.
- affine regions, buffers, UTF-8 owners, signed maps, and active loans.
- the root task frame stack, status, and scheduler cursor.
- an ordered stack of transition records.
- a monotonic transition number.

Raw host pointers and masked addresses never become machine values. Wheeler 1.0
publishes only root task zero. Hierarchical task identities remain reserved until
task creation, joining, ownership transfer, and global rewind enter together.

Newly compiled source normally permits 4,000,000 transitions and 4,000,000 retained
history entries. An artifact or host may choose lower values. `run()` traps before
either limit is exceeded.

The physical bootstrap comparison path may execute without a retained rewind tail
only when history is empty. Each successful transition then advances the rewind
horizon. That path supports large artifact comparisons and makes no claim of
reversible execution or durable storage.

## One transition

A successful instruction produces a new machine state and the information needed
to restore the earlier state:

```text
step(C, instruction) = (C', undo)
unstep(C', undo) = C
```

Intrinsic reversible operations recover information through their inverse.
Logged overwrite stores the value it replaced. Control and local-register work
retain the earlier frame data. Region operations keep the changed bytes,
accounting, drop state, and earlier table lengths required by that transition.

A rewind restores each transition once. The machine never restores an earlier
state and then invokes another inverse handler for the same work.

Persistent frame chunks contain 32 registers. A control-only transition shares
register storage. A local write copies its chunk and shallow index. This keeps the
history charge tied to actual change.

## Inverse execution

`CALL` enters a forward zero-argument function. `UNCALL` enters its generated
inverse body and performs new transitions. Both calls add history.

```wheeler
increment();
reverse increment();
```

Value calls move one initialized argument window into the callee and transfer one
typed result back. Reversible scalar results exchange an adjacent vacant slot for
a checked held value. Their inverse verifies that relation before restoring
vacancy. A commit between the calls removes debugger history and leaves the
generated inverse available.

A unitary call follows the same operational principle at a quantum target: its
adjoint is another physical computation. VM rewind never fires gates on hardware.

## Retained-history rewind

`rewindOne` consumes the newest transition record and restores the exact earlier
machine state. It restores globals, frames, program counter, aggregate table
lengths, storage deltas, ownership, loans, and selected output length.

Rewind never calls a function inverse. It depends on the retained transition
stack, including private data saved for logged overwrite.

An optional observer receives an immutable event only after successful mutation.
Forward, inverse, rewind-forward, and rewind-inverse remain distinct directions.
The observer cannot inspect or alter mutable machine state. The canonical `NONE`
observer constructs no events. Any other observer receives the complete stream,
even when it discards each event.

## Commit horizons

`COMMIT` advances successfully and clears earlier transition records. Rewind
cannot cross that horizon even if an implementation still holds unrelated cached
bytes.

A generated inverse compiled into the artifact remains callable after commit. A
saved external observation may remain replayable. Neither property restores the
history that commit closed.

## Host loans

A classical entry may borrow strict UTF-8 input, immutable binary input, mutable
byte output, or one input followed by output. Each side may contain at most
16 MiB. Total live owned and host storage may contain at most 32 MiB.

The host copies input into external baseline storage and initializes only the
loans declared by the entry. Output begins as a zero-filled fixed-capacity owner.
`OUTPUT_LENGTH` selects a prefix of that exact owner. `hostOutput()` returns a
defensive copy after successful halt.

Missing, extra, malformed, linked, or oversized bindings fail before the first
transition. Binary input is never decoded as text. Input bytes and output capacity
remain runtime data and do not change artifact identity.

Live I/O establishes a rewind barrier when its completion is accepted. Constructing
a request performs no external effect.

## Interpreter recovery slice

The Wheeler-written recovery interpreter accepts the verified self-hosting
profile with these ceilings:

| Resource | Maximum |
| --- | ---: |
| signed globals | 8 |
| interpreted trace rows | 512 |
| frames | 8 |
| functions | 24 |
| locals per frame | 256 |
| instructions per function | 512 |

It supports the accepted scalar, call, loop, aggregate, storage, UTF-8, map,
borrow, result-slot, and halt instructions described in
[artifacts and bytecode](bytecode.md). It rejects missing effect and quantum
opcodes rather than inventing behavior.

The broader compatibility VM admits call depth up to 1,024 frames under the
artifact's transition and history limits.

## Tasks and workflow epoch

Every current artifact enters a canonical task table with `TaskId.ROOT` in
workflow epoch zero. Snapshots retain the selected task, scheduler cursor, epoch,
immutable task statuses, and task-to-frame relation.

Hierarchical task identities and canonical round-robin selection are deterministic.
Spawn, join, replay plans, and atomic task scopes have no accepted artifact form
in the present profile.

## Traps

The machine traps on:

- failed assertions and expectations.
- arithmetic overflow, invalid division, or invalid rotation.
- bad local, global, function, branch, array, slice, map, or storage access.
- type disagreement or a non-Boolean condition.
- absent generated inverse or escaped instruction pointer.
- exhausted loop, frame, transition, or history limits.
- use after move or drop, leaked ownership, and ownership-divergent joins.
- region, buffer, map, UTF-8, or loan violations.

Preflight completes every check before mutation. A failing instruction leaves
globals, frames, region accounting, buffers, and output length unchanged.

## A compact reckoning

| Road | What it spends | What it can restore |
| --- | --- | --- |
| generated inverse | an invertible relation in the artifact | every accepted output of that relation |
| unitary adjoint | coherent target work | a quantum operation before measurement or loss |
| VM rewind | retained transition entries | exact earlier VM state after the rewind horizon |
| uncomputation | a coherent compute path | temporary workspace while preserving an effect elsewhere |
| replay | one accepted observation | later classical decisions only |
| retry | new preparation and target work | nothing. It creates another observation |

The [hybrid-run appendix](hybrid-runs.md) follows observations after they leave a
quantum target.
