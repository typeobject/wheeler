# Reversible virtual machine

The implemented VM is the deterministic, single-threaded transition kernel for Wheeler's first bytecode format.

## State

The machine owns:

- one verified immutable program;
- a status (`ready`, `running`, `halted`, or `trapped`);
- a bounded stack of immutable control frames with descriptor-typed signed and Boolean local registers;
- typed signed 64-bit global locations;
- separate deterministic bounded tables of immutable nominal records, tagged variants, fixed arrays, and nonescaping slices;
- bounded owned regions and mutable signed-word/byte buffers, immutable frozen UTF-8 owners, and fixed-capacity signed maps with explicit live/dropped state and byte/object accounting;
- an ordered bounded stack of step records;
- a monotonic transition sequence within the current run.

Raw host pointers and masked segmented addresses are not machine values. Source compilation currently records ceilings of 1,000,000 steps and 250,000 retained history records; exhaustion traps before another mutation. The history default admits bounded compiler/package passes without sneaking in a commit horizon, while artifact and embedding policy may choose lower verified limits.

A classical entry may borrow one strict UTF-8 input or immutable binary `byteview`, one mutable byte output, or one input followed by the output. VM construction requires the exact declared effects and an explicit text/binary binding API, caps each at 16 MiB, defensively copies input into externally owned baseline storage, and initializes only borrow registers. Output has a fixed maximum capacity and is zero-initialized. `OUTPUT_LENGTH` may select a prefix only from the entry output borrow; wrong handles and lengths outside `0..capacity` trap before mutation. The selected length participates in snapshots and exact rewind, and `hostOutput()` returns a defensive copy of that prefix. Missing, unexpected, kind-mismatched, malformed UTF-8, or oversized effects fail before stepping; arbitrary binary input is never decoded as text. Effect bytes and output capacity are runtime data and never alter `.wbc` identity.

## Wheeler-written bounded interpreter

`NativeVm.w` imports `compiler/Interpreter.w` and the split Wheeler-native framing/payload and instruction verifiers. It accepts an immutable binary `.wbc`, verifies the bounded self-hosted compiler profile, initializes its zero-or-one signed global from the type section, and executes up to 512 interpreted instructions with eight bounded frames and sixteen signed/Boolean locals per frame. `compiler/Opcodes.w` and `compiler/TypeCodes.w` own the names at that boundary. The current opcode surface covers direct reversible global add/subtract/XOR, local constants and state load/store/move, checked arithmetic including `LOCAL_AND` and `LOCAL_ROTR32`, signed/Boolean equality and comparison, bounded loop checks, instruction-index branches, global expectations, zero-argument `CALL`/`UNCALL`, typed signed/Boolean `CALL_VALUE`/`CALL_VOID`, `RETURN`/`RETURN_VALUE`, and `HALT`.

The direct checked-update fixture produces the same final global as the stage-0 VM and the outer Wheeler execution rewinds exactly. The Wheeler-written compiler emits the checked-in proof-bearing `Counter.w` artifact byte-for-byte with stage 0; the Wheeler-written interpreter then exercises its repeated forward and inverse calls and finishes at zero. Conditional branches, a three-iteration bounded loop, a two-argument signed value call, and a signed void call differentially agree with stage 0 and rewind exactly; a forged branch target fails Wheeler verification before execution. This remains an interpreter vertical slice, not yet the authoritative transition kernel: early value returns, aggregates, owned storage, arguments/results, effects, workflows, and interpreter-level step history remain stage-0 behavior. An interpreter with six opcodes missing is a test fixture; calling it a runtime does not make the opcodes less missing.

## Forward and reverse laws

A successful step produces a new state and one minimal record:

```text
step(C, instruction) = (C', undo)
unstep(C', undo) = C
```

Intrinsic operations recover data from their inverse operation. Logged operations retain the value they overwrite. Local register and control operations retain the prior immutable frame needed to restore program counter and locals. Frames use persistent 32-register chunks: control-only steps share all register storage, while a local write copies only its chunk and the shallow chunk index. Snapshots still expose ordinary immutable lists, and equality remains structural. This keeps a declared history budget from quietly becoming `records × every local × boxed object`, an allocator policy best left unpublished. Aggregate construction interns by nominal type, variant tag where present, and ordered field values; rewind restores prior record-, variant-, array-, and slice-table lengths as well as the frame. Region operations retain bounded deltas for changed region accounting, changed buffer contents/drop state, and prior table lengths. Call and return records retain the control information needed to restore frame depth. The VM never restores state and then also executes an inverse handler.

## Function inverse versus rewind

`CALL` executes a zero-argument void function body. `UNCALL` executes its generated inverse body as new forward work. `CALL_VALUE` transfers an exact initialized, type-compatible argument window—including transient verified borrows—into callee parameter registers and names one caller register matching the declared result; `RETURN_VALUE` checks and moves that result back. Every call and return adds history and can itself be rewound, including the caller result write.

`rewindOne` consumes the newest step record and restores the exact prior machine state. It does not call the function inverse.

## Commit horizons

`COMMIT` clears earlier step records after advancing successfully. The machine cannot rewind before that point even if an implementation happens to retain unrelated cached bytes. A future persistence layer will make checkpoint and replay availability explicit.

## Traps and limits

Invalid expectations, overflow, missing inverses, invalid local or branch access, register type mismatches, non-Boolean conditions, exceeded source loop limits, call depth above 1,024 frames, escaped instruction pointers, exhausted history, and exceeded step limits trap deterministically. Owned moves, region/buffer exhaustion, use after move or drop, buffer kind/range/bounds, UTF-8 freeze validity, immutable borrow kind/owner state, exclusive region/buffer/map-borrow kind and aliasing, map capacity/absence, malformed UTF-8 counting, dropping an owner with live buffers, ownership-divergent joins, and leaked owned locals are also checked. A failing instruction does not partially mutate globals, frames, region accounting, or buffer contents.
