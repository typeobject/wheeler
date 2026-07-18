# Reversible virtual machine

The implemented VM is a deterministic, single-threaded version-2 transition kernel.

## State

The machine owns:

- one verified immutable program;
- a status (`ready`, `running`, `halted`, or `trapped`);
- a bounded stack of immutable control frames with descriptor-typed signed and Boolean local registers;
- typed signed 64-bit global locations;
- a deterministic bounded table of immutable nominal record values;
- an ordered bounded stack of step records;
- a monotonic transition sequence within the current run.

Raw host pointers and masked segmented addresses are not machine values.

## Forward and reverse laws

A successful step produces a new state and one minimal record:

```text
step(C, instruction) = (C', undo)
unstep(C', undo) = C
```

Intrinsic operations recover data from their inverse operation. Logged operations retain the value they overwrite. Local register and control operations retain the prior immutable frame needed to restore program counter and locals. Record construction interns by nominal type and ordered field values; rewind restores the prior record-table length as well as the frame. Call and return records retain the control information needed to restore frame depth. The VM never restores state and then also executes an inverse handler.

## Function inverse versus rewind

`CALL` executes a zero-argument void function body. `UNCALL` executes its generated inverse body as new forward work. `CALL_VALUE` moves an exact initialized, type-compatible argument window into callee parameter registers and names one caller register matching the declared signed or Boolean result; `RETURN_VALUE` checks and moves that result back. Every call and return adds history and can itself be rewound, including the caller result write.

`rewindOne` consumes the newest step record and restores the exact prior machine state. It does not call the function inverse.

## Commit horizons

`COMMIT` clears earlier step records after advancing successfully. The machine cannot rewind before that point even if an implementation happens to retain unrelated cached bytes. A future persistence layer will make checkpoint and replay availability explicit.

## Traps and limits

Invalid expectations, overflow, missing inverses, invalid local or branch access, register type mismatches, non-Boolean conditions, exceeded source loop limits, call depth above 1,024 frames, escaped instruction pointers, exhausted history, and exceeded step limits trap deterministically. A failing instruction does not partially mutate globals or frames.
