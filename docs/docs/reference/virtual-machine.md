# Reversible virtual machine

The current VM is Wheeler's deterministic, single-threaded transition kernel for bytecode format 1.0.

## State

The machine owns:

- one verified, immutable program;
- a status of `ready`, `running`, `halted`, or `trapped`;
- a bounded stack of immutable control frames;
- descriptor-typed signed and Boolean local registers in each frame;
- typed signed 64-bit global locations;
- separate bounded tables for immutable records, tagged variants, fixed arrays, and nonescaping slices;
- bounded owned regions and mutable signed-word or byte buffers;
- immutable frozen UTF-8 owners and fixed-capacity signed maps;
- explicit live or dropped state with byte and object accounting;
- an ordered bounded stack of step records;
- a monotonic transition number for the current run.

Raw host pointers and masked segmented addresses are not machine values.

Source compilation currently writes limits of 1,000,000 steps and 250,000 retained history records. The VM traps before another mutation when either limit is exhausted. These defaults allow bounded compiler and package work without adding a commit horizon. An artifact or embedding host may choose lower verified limits.

A classical entry may borrow one strict UTF-8 input, one immutable binary `byteview`, one mutable byte output, or one input followed by the output. VM construction requires the exact declared effects and an explicit text or binary binding API.

Each input or output is capped at 16 MiB. The VM copies input into external baseline storage and initializes only the declared borrow registers. Output has a fixed capacity and starts filled with zero bytes.

`OUTPUT_LENGTH` selects a prefix only from the entry's output borrow. A wrong handle or a length outside `0..capacity` traps before mutation. The chosen length is part of snapshots and exact rewind, while `hostOutput()` returns a defensive copy of that prefix.

Missing, extra, mismatched, malformed UTF-8, or oversized effects fail before the first step. Binary input is never decoded as text. Effect bytes and output capacity are runtime data, so they do not change `.wbc` identity.

These entry loans are the narrow host boundary that exists today. They are not the planned asynchronous I/O API. [WIP-0032](../proposals/WIP-0032-unified-io-fabric-and-durability-receipts.md) will lower submitted I/O through typed effects and continuations while keeping the same ownership and fail-closed rules.

Live I/O remains a rewind barrier. Building a request doesn't submit it.

## Wheeler-written bounded interpreter

`NativeVm.w` imports `runtime/Interpreter.w` plus the Wheeler-written framing, payload, and instruction verifiers. It accepts immutable binary `.wbc` and verifies the bounded self-hosted compiler profile.

The interpreter supports:

- up to eight signed globals;
- up to 512 interpreted instructions;
- eight bounded frames;
- up to eight functions;
- sixty-four typed locals per frame;
- up to 128 instructions per function.

Only the active function's local window is cleared. `compiler/ir/Opcodes.w`, `compiler/ir/TypeCodes.w`, and `compiler/ir/ProofRules.w` define the names used at this boundary.

`compiler/verification/FunctionVerifier.w` checks descriptor, type, and code windows. `compiler/verification/AggregateVerifier.w` checks immutable aggregate metadata. `compiler/verification/StorageVerifier.w` checks regions, buffers, maps, loans, and UTF-8 operands. `compiler/verification/ProofVerifier.w` verifies generated-inverse records and straight-line step bounds.

The current opcode set includes:

- reversible global add, subtract, and XOR;
- local constants, state load or store, and moves;
- checked arithmetic, including `LOCAL_AND` and `LOCAL_ROTR32`;
- signed and Boolean equality or comparison;
- bounded loop checks;
- immutable records, finite variants, fixed arrays, and slices;
- bounded owned regions and mutable word or byte buffers;
- strict UTF-8 validation, count, scalar, width, and freeze operations;
- read-only UTF-8 and byte loans;
- mutable region, word, byte, and map loans;
- owner-returning primitive-storage calls;
- deterministic fixed-capacity signed maps;
- instruction-index branches and global expectations;
- zero-argument `CALL` and `UNCALL`;
- typed `CALL_VALUE`, `CALL_VOID`, `RETURN`, and `RETURN_VALUE`;
- `HALT`.

The direct checked-update fixture matches the final global value produced by the stage-0 VM, and the outer Wheeler run rewinds exactly. The Wheeler compiler also emits the proof-bearing `Counter.w` artifact byte for byte with stage 0. The Wheeler interpreter runs its repeated forward and inverse calls, then finishes at zero.

Differential tests also cover branches, a three-iteration bounded loop, signed calls, and Boolean logic in `FunctionValues.w`. Six-level recursion runs through `RecursiveValue.w`, while `LoopControl.w` covers early return, `break`, and `continue`.

Data fixtures include nested `Records.w` values, payload-free `FiniteEnums.w`, payload-carrying `Variants.w`, arrays, slices, owned storage, valid and invalid UTF-8, `FrozenUtf8.w`, and signed maps. Every declared global, up to eight, must match stage 0 before exact rewind.

Negative tests forge record-field, variant-tag, array-index-local, slice-index-local, word-index-local, byte-index-local, UTF-8-index-local, and map-key-local operands. They also forge step bounds, branch targets, and generated inverses. The Wheeler verifier must reject each case before interpretation.

This remains a bounded interpreter slice. It is not yet the final transition kernel because host effects, workflows, and interpreter-level history still use stage-0 behavior. Missing effect, loan, or quantum opcodes remain real limits even when the surrounding types already exist.

## Forward and reverse laws

A successful step creates one new state and one minimal undo record:

```text
step(C, instruction) = (C', undo)
unstep(C', undo) = C
```

Intrinsic operations recover information through their inverse; logged operations save the value they overwrite. Local-register and control operations retain the earlier immutable frame needed to restore the program counter and local values.

Frames use persistent chunks of 32 registers; a control-only step shares all register storage. A local write copies only its chunk and the shallow chunk index.

Snapshots still expose ordinary immutable lists, and equality stays structural. This keeps the declared history budget tied to actual changes instead of charging `records × every local × boxed object`.

Aggregate construction interns values by nominal type, variant tag when present, and ordered fields; rewind restores earlier record, variant, array, and slice table lengths along with the frame.

Region operations save bounded deltas for accounting, changed buffer contents, drop state, and earlier table lengths. Call and return records keep the control data needed to restore frame depth.

A reverse step restores state once. The VM never restores an earlier state and then also runs an inverse handler for the same step.

## Function inverse versus rewind

`CALL` runs the forward body of a zero-argument void function; `UNCALL` runs its generated inverse body as new forward work.

`CALL_VALUE` moves an exact initialized argument window into the callee's parameter registers. The window may include transient verified loans. It also names one caller register whose type matches the declared result.

`RETURN_VALUE` checks the result and moves it back to the caller. Every call and return adds history, including the write to the caller's result register, so each transition can be rewound.

`rewindOne` consumes the newest step record and restores the exact earlier machine state. It does not call a function inverse.

## Commit horizons

`COMMIT` advances successfully, then clears older step records. The VM cannot rewind before that point, even when an implementation still holds unrelated cached bytes.

A future persistence layer will make checkpoint and replay availability explicit.

## Traps and limits

An optional transition observer receives an immutable function, instruction, and opcode observation only after a successful mutation. It reports forward, inverse, rewind-forward, and rewind-inverse transitions separately. The observer receives no mutable machine state.

The stage-0 semantic coverage reducer in [semantic coverage](coverage.md) uses this boundary without changing artifacts or history.

The VM traps deterministically on invalid expectations, overflow, or missing inverses. It also traps on bad local or branch access, register type mismatches, and non-Boolean conditions. Other failures include exhausted loop limits, call depth above 1,024 frames, escaped instruction pointers, full history, and an exceeded step limit.

Ownership checks cover moves, use after move or drop, and leaked owned locals. Storage checks cover region or buffer exhaustion, buffer kind and range, and live buffers during region drop. The VM also checks UTF-8 validity, malformed decoding, immutable-loan state, exclusive-loan aliasing, map capacity or missing keys, and ownership-divergent joins.

A failing instruction makes no partial change to globals, frames, region accounting, or buffer contents.
