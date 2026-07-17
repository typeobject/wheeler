# Reversible virtual machine

The implemented VM is a deterministic, single-threaded version-1 transition kernel.

## State

The machine owns:

- one verified immutable program;
- a status (`ready`, `running`, `halted`, or `trapped`);
- a bounded stack of immutable control frames;
- typed signed 64-bit global locations;
- an ordered bounded stack of step records;
- a monotonic transition sequence within the current run.

Raw host pointers and masked segmented addresses are not machine values.

## Forward and reverse laws

A successful step produces a new state and one minimal record:

```text
step(C, instruction) = (C', undo)
unstep(C', undo) = C
```

Intrinsic operations recover data from their inverse operation. Logged operations retain only the value they overwrite. Call and return records retain the control information needed to restore a frame. The VM never restores a whole thread snapshot and then also executes an inverse handler.

## Function inverse versus rewind

`CALL` executes a forward function body. `UNCALL` executes its generated inverse body as new forward work. Both operations add history and can themselves be rewound.

`rewindOne` consumes the newest step record and restores the exact prior machine state. It does not call the function inverse.

## Commit horizons

`COMMIT` clears earlier step records after advancing successfully. The machine cannot rewind before that point even if an implementation happens to retain unrelated cached bytes. A future persistence layer will make checkpoint and replay availability explicit.

## Traps and limits

Invalid expectations, overflow, missing inverses, escaped instruction pointers, exhausted history, and exceeded step limits trap deterministically. A failing instruction does not partially mutate globals or frames.
