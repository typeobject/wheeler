# WIP-0001: Reversible bytecode and machine-state contract

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler maintainers |
| Created | 2026-07-17 |
| Updated | 2026-07-17 |
| Area | VM, reversible bytecode, artifacts, history |
| Depends on | None |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler's first executable contract has two parts: a versioned Wheeler Bytecode Container (`.wbc`) and a deterministic, single-threaded reversible machine. Each successful instruction step creates a bounded undo record for its declared reversibility class. A reverse step consumes that record and restores the exact earlier machine state.

Instructions use one of four classes. Intrinsic instructions are bijective and need no saved value. Checked instructions depend on verified preconditions. Logged instructions save only the data they destroy. Barrier instructions mark the point beyond which execution cannot rewind.

Wheeler bytecode is a closed, typed IR built around slots and regions. It is neither JVM bytecode nor an untyped host-address machine. The container reserves versioned sections for quantum regions, generic library bodies, target requirements, proofs, and debug data. This WIP defines and tests the classical reversible core first.

## Motivation

Wheeler once had several bytecode sketches that did not agree. `Instruction` used a fixed 128-bit format with a static `history` field. `ClassWriter` wrote those bytes with a JVM `.class` suffix, while the runner expected `.wb`, the README named `.wc`, and the sample `.wb` was annotated text. The VM also started outside the code segment. Only `INC` had a handler, and its mix of full-thread snapshots and local undo data could not reverse correctly.

Those paths are gone. The acceptance checklist tracks the remaining work.

Reversibility has to shape the machine from the start. The design must define the full state, the data each instruction may destroy, the location and limits of undo records, effect barriers, and malformed-program handling. The binary format must also support the classical and quantum region model without treating a remote quantum device as normal mutable memory.

## Use cases

### Reversible counter

A compiled `Counter.increment` adds one to a typed integer location. Calling it twice and then invoking the language-level inverse twice restores the count to zero without retaining both previous integer values.

### Logged tree update

A tree mutation overwrites links and allocates a node. The generated operations retain the old links and deterministic allocation receipt required for reversal. Committing or cleaning that history creates an explicit rewind horizon.

### VM debugger rewind

A debugger steps through ordinary forward bytecode and then consumes step records in reverse order. Each reverse step restores the prior frame, program counter, regions, status, and reversible effect state exactly.

### Invalid artifact

A loader rejects overlapping sections, noncanonical instruction lengths, invalid branch targets, unsupported required sections, out-of-range slot references, malformed inverse metadata, and a declared reversible body containing an unacknowledged barrier.

### Future quantum region

The loader can identify a function or region as quantum or hybrid and report an unsupported required capability without interpreting provider-specific payloads as classical instructions.

## Goals

- Define one canonical `.wbc` container, loader, verifier, and disassembler contract.
- Define exact machine state, typed locations, program-counter behavior, calls, traps, and halting.
- Give every core opcode a stable operand schema and reversibility class.
- Make dynamic undo data a runtime record instead of an instruction field.
- Distinguish language-level inverse invocation from debugger or runtime rewind.
- Bound code, regions, stack depth, step count, history bytes, and undo payloads.
- Test forward and reverse laws over both example fixtures and generated states.
- Reserve explicit artifact extension points for WIP-0002 quantum regions and future proof certificates.

## Non-goals

- Define quantum gates, measurement, coherent lifting, or target execution; WIP-0002 and WIP-0003 do that.
- Define concurrent scheduling or shared-memory reversal.
- Preserve the current 128-bit instruction shape, raw segmented addresses, or `.class` output.
- Implement the full current Java-like grammar before the bytecode is executable.
- Make external I/O physically reversible.
- Standardize an optimizing in-memory compiler IR; bytecode is the verified execution boundary.

## Terms and semantic model

A classical machine state is:

```text
C = (artifact, status, frames, regions, allocator, effects)
```

- `artifact` is the immutable verified `.wbc` image and its identity.
- `status` is `ready`, `running`, `halted`, or `trapped` with a structured reason.
- `frames` is the bounded call stack. A frame owns a function ID, instruction-boundary PC, typed slots, and return continuation.
- `regions` maps unforgeable region IDs to typed, bounded storage.
- `allocator` is deterministic machine state, not a host pointer allocator.
- `effects` is an ordered ledger of externally visible receipts and rewind barriers.

A successful forward step is:

```text
step(C, instruction) = (C', U)
```

`U` is a bounded `StepRecord` containing instruction identity, the before and after PCs, frame identity, a reversibility class, and the opcode-specific undo payload. A reverse step satisfies:

```text
unstep(C', U) = C
```

for every successful transition that has not crossed a committed barrier. A failed instruction makes no partial machine-state change. It produces a deterministic trap and either no step record or one trap record whose reversal semantics are explicitly declared.

There are two different reverse operations:

1. Language-level inverse invocation executes a verified inverse body, such as `UNCALL increment`. It is new forward execution and may itself be rewound.
2. Machine rewind consumes existing `StepRecord` values to return to an earlier execution state. It does not execute the inverse body after restoring a snapshot.

Implementations must not combine whole-state restoration and inverse-handler execution for one reverse step.

## Ownership and boundaries

`wheeler-core` owns the abstract machine state, core opcode semantics, step records, bounds, traps, and forward/reverse law suite.

`wheeler-runtime` owns `.wbc` loading, section validation, capability resolution, effect adapters, and execution policy. It may reject a valid artifact when required target capabilities are unavailable, but it does not reinterpret opcodes.

`wheeler-compiler` owns lowering typed source or IR into verified bytecode and emitting inverse bodies and effect metadata.

`wheeler-tools` owns assembler, disassembler, verifier CLI, debugger, and human-readable traces. The disassembler is never an alternate executable format.

Hosts own filesystem, console, clock, random, network, and provider integration. Host values enter the machine only through declared effect operations and receipts.

## Design

### Bytecode container

All integers in the container are unsigned little-endian unless an operand schema says otherwise. The first format begins with a 40-byte header:

```text
byte[8] magic             = "WHEELBC\0"
u16     major_version     = 1
u16     minor_version     = 0
u32     flags
u64     file_length
u32     section_count
u32     directory_entry_size = 32
u64     directory_offset
```

A directory entry is:

```text
u32 section_type
u32 section_flags
u64 offset
u64 length
u32 alignment
u32 reserved = 0
```

Sections do not overlap, offsets and lengths fit within `file_length`, padding is zero, and directory entries use canonical `(section_type, offset)` order. Required unknown sections cause rejection. Optional unknown sections may be ignored only when no known section refers to them.

The first format reserves these section types:

| ID | Section | Requirement |
| --- | --- | --- |
| 1 | Manifest and entry points | Required |
| 2 | UTF-8 string table | Required |
| 3 | Type and effect descriptors | Required |
| 4 | Nominal tagged-variant descriptors | Required |
| 5 | Function descriptors | Required |
| 6 | Classical code bodies | Required for a classical entry point |
| 7 | Ordered classical/quantum workflow | Required for quantum and hybrid artifacts |
| 8 | Quantum registers and circuit bodies | Required for quantum and hybrid artifacts |
| 9 | Target requirements | Reserved for WIP-0003 |
| 10 | Proof certificates | Optional; initial generated-inverse rule from WIP-0011 |
| 11 | Source and debug maps | Optional and non-semantic |
| 12 | Generic typed library bodies | Reserved for WIP-0029; non-executable |

The manifest declares artifact identity inputs, minimum runtime version, entry points, required section features, and global resource ceilings. A function descriptor declares its stable function ID, type signature, effect set, computation domain, frame-slot schema, forward body range, inverse body range when present, and declared bounds.

Only format `1.0` exists. The decoder accepts that exact pair and carries no compatibility path for an unreleased predecessor; any future versioning policy must preserve canonical rejection and may not silently reuse numeric IDs.

### Instruction encoding

Classical code is a sequence of independently bounded records:

```text
u16 opcode
u16 form
u32 byte_length
byte[byte_length - 8] operands_and_zero_padding
```

`byte_length` is at least 8, is a multiple of 8, and cannot exceed the artifact limit. Each `(opcode, form)` has one canonical operand schema. Slot IDs, region IDs, function IDs, constant IDs, and branch targets use fixed-width integers specified by that form. Branch targets are byte offsets within the current body and must name verified instruction boundaries.

This record shape permits deterministic skipping and diagnostics but does not permit execution of unknown opcodes. It replaces the current static `history` field: undo information depends on runtime values and belongs in `StepRecord`.

The initial registry contains these semantic groups:

- control: `NOP`, `HALT`, `JUMP`, `BRANCH`, `CALL`, `UNCALL`, `RETURN`;
- checked initialization: `INIT`, `CLEAR_EXPECT`, `REGION_ALLOC`, `REGION_FREE_EXPECT`;
- intrinsic reversible data: `SWAP`, `XOR`, `ADD`, `SUB`, `NEGATE`, rotations, and width-specific variants;
- typed memory: checked load/copy forms and logged load/store forms;
- history: `CHECKPOINT`, `COMMIT`, and bounded history assertions;
- effects: typed `EFFECT_CALL` with a declared policy and receipt schema.

The normative opcode registry added during implementation records numeric ID, form, operands, type rule, forward transition, inverse relation, reversibility class, undo schema, trap conditions, and cost model. Acceptance of this WIP freezes the first-slice numeric assignments in that registry.

### Typed slots and regions

Frames expose verifier-typed slots. Instructions cannot reinterpret a floating value as an integer, forge a region reference, or read an uninitialized slot. Integer widths and overflow behavior are explicit. The first slice uses checked arithmetic by default; wrapping operations have distinct opcodes.

Memory references are `(region_id, typed_offset)` capabilities. Valid addresses are bounded by one region, never inferred from host pointers, and never alias by masking high address bits. Allocation returns deterministic region IDs. Deallocation requires an expected clean shape or retains the state needed to restore the region.

Classical values may be copied. Quantum resources are not classical region values; WIP-0002 introduces affine resource references in separate verified region bodies.

### Reversibility classes

Every opcode form has exactly one class:

- Intrinsic operations determine their inverse from the current operands and state. `SWAP` and `XOR` are self-inverse; `ADD` and `SUB` are paired.
- Checked operations are reversible under a verified or runtime-checked precondition. `INIT(dst, value)` requires an uninitialized or canonical-zero destination; its inverse checks the expected value before clearing it.
- Logged operations destroy information and emit a typed undo payload, such as an overwritten field value.
- Barrier operations create an external observation that the machine cannot undo. They produce a receipt and stop rewind unless the effect contract supplies a compensator and runs it successfully.

A `rev` function may use intrinsic, checked, or bounded logged operations according to its declared history effect. It may not hide a barrier. A stronger `coherent` eligibility check in WIP-0002 permits only operations that lower to a unitary without a runtime undo log.

### Calls and inverses

A reversible function has either:

- a compiler-generated inverse body validated against the forward body;
- a declared inverse function validated for compatible signature and effects; or
- an intrinsic body from the normative registry.

`CALL` selects the forward body; `UNCALL` selects the inverse body. Call and return continuations remain ordinary reversible machine state. Runtime rewind uses step records and is independent of `UNCALL`.

### Effects and output

`EFFECT_CALL` names a versioned effect capability and policy:

- `replayable`: the recorded result may be reused during deterministic replay;
- `compensatable`: a declared compensator may reverse the external effect;
- `barrier`: execution cannot rewind across the committed receipt.

Console output is a barrier by default. Therefore the `Counter` example may invoke the inverse of `increment` after printing, but debugger rewind cannot erase text that a user has already observed.

### Verification

The verifier performs structural decoding before semantic verification. It checks section layout, canonical encoding, IDs, signatures, slot initialization, types, branch targets, frame bounds, region bounds, call compatibility, inverse metadata, effect declarations, history ceilings, and reachable halt or declared nontermination.

Verification does not prove arbitrary source theorems. It establishes that execution cannot escape the abstract machine and that declared reversible bodies use only allowed reversibility classes. Optional proof certificates may discharge stronger obligations later.

## Reversibility and history

`StepRecord` is the only authority for machine rewind. Records are ordered, artifact-bound, and integrity-checked in memory or persistence. Each record contains no more than the opcode's declared maximum undo bytes.

History has explicit limits in records and bytes. Before exceeding either limit, execution traps without applying the next instruction unless policy has created a checkpoint and committed an older prefix. `COMMIT` establishes a new rewind horizon and makes discarded history semantically unavailable. `clean history` in source must lower to a visible commit policy; it cannot claim that old states remain reversible.

Checkpoint snapshots are an optimization and persistence mechanism, not an additional reverse semantics. Restoring a checkpoint and replaying records must produce the same state as uninterrupted execution.

## Concurrency and determinism

This machine contract is single-threaded. All decoding, allocation, arithmetic, traps, effects, history accounting, and step ordering are deterministic for the same artifact and effect receipts.

A later concurrency WIP must define a global event order for shared state and may not infer correct reversal from independent per-thread stacks. The artifact reserves computation and capability metadata without assigning thread opcodes in the first format.

## Quantum and proof implications

The container records computation domains and reserves region, quantum, target, and proof sections. Classical machine code does not store amplitudes in ordinary memory or treat a remote qubit as an address.

WIP-0002 may mark a classical reversible body as coherently liftable only when it needs no logged undo, barrier, exception path, dynamic allocation leak, or other non-unitary behavior. The same source function can still use ordinary WIP-0001 bytecode on a CPU.

Proof metadata is optional and cannot change opcode semantics. A verifier must remain sound when all optional proof sections are absent.

## Bytecode, persistence, and compatibility

`.wbc` is the only executable artifact extension standardized here. `.class`, `.wb`, and `.wc` are not compatibility aliases. Textual assembly uses a separate `.wba` extension and always passes through the same encoder and verifier.

Persisted checkpoints and history identify the exact artifact hash, major/minor bytecode version, runtime semantic version, and effect schema versions. A runtime rejects mismatches instead of replaying records under different opcode semantics.

Canonical re-encoding of a decoded artifact produces byte-identical output except for explicitly non-semantic debug sections. Debug stripping never changes semantic section offsets referenced internally; the writer rebuilds and revalidates the directory.

## Safety, limits, and failures

Loaders enforce configurable ceilings before allocation. The manifest cannot raise host policy limits. Integer overflow, division errors, invalid initialization, dirty deallocation, unavailable effects, history exhaustion, and limit exhaustion produce structured traps.

An instruction either completes and appends one valid step record or leaves pre-step state intact. Host adapter failure during an effect follows that effect's declared atomicity contract and never fabricates a successful receipt.

Artifact bytes, assembly, debug names, effect payloads, and persisted history are untrusted input; verification has bounded time and memory proportional to declared and host-capped artifact limits.

## Unified I/O effects

WIP-0032 owns structured asynchronous I/O requests, operation scopes, cancellation races, completion, visibility and durability receipts, and external-operation uncertainty.

Submitting or awaiting external I/O remains a typed `EFFECT_CALL` barrier unless an effect-specific compensation contract applies. Pure request construction is not submission, and completion is not durability. WIP-0004 may replay a recorded read observation, but machine rewind never rereads or unwrites an external resource.

## Migration and deletion

1. Add immutable container models, canonical encoder/decoder, and malformed corpus tests.
2. Add the normative opcode registry and generated constants, disassembly, and verification tables.
3. Implement a pure transition kernel for the first instruction slice and property-test `unstep(step(C)) = C`.
4. Implement bounded step history, checkpoints, commits, traps, and effect barriers.
5. Assemble and execute a bytecode-level counter fixture, including `CALL` and `UNCALL`.
6. Lower one source-level counter through the real AST and compiler into the same verified artifact.
7. Replace `Instruction`, `InstructionSet`, raw `MemoryManager` segment addressing, and snapshot-plus-handler reversal.
8. Replace `ClassWriter` with the `.wbc` writer and make the `wheeler` compiler, runtime, and disassembler commands consume the canonical format.
9. Delete the annotated `Counter.wb` pseudo-binary or move it to non-executable design history.

## Progress

- [x] Container header, directory, and section schemas are implemented.
- [x] The initial opcode registry is shared by compiler, VM, verifier, and tools.
- [x] The transition kernel and bounded undo records exist.
- [x] The verifier rejects malformed structure and semantic violations.
- [x] Major version 1 stores canonical typed local and aggregate references; the decoder has no alternate or legacy format path.
- [x] Signed and Boolean frame parameters, results, locals, typed value calls, branch targets, definite assignment, and bounded-loop checks execute and verify.
- [x] Bytecode and source counter fixtures run forward and inverse.
- [x] Existing incompatible bytecode and memory paths are deleted.
- [x] Checked `LOCAL_AND` and low-32-bit `LOCAL_ROTR32` execute, verify, rewind, and provide bounded cryptographic word operations without relying on hidden host arithmetic in SHA-256. Source artifacts now default to one million steps and 250,000 history records; both remain explicit manifest limits, and exhaustion still wins before mutation. Immutable frames use persistent 32-register chunks so control steps share storage and local writes copy one chunk instead of a boxed full frame. Memory use remains explicitly bounded.
- [x] A Wheeler-written compiler slice parses one bounded source file and emits its full canonical artifact. It derives the aligned layout instead of copying a template. Stage 0 produces the same bytes, the strict decoder accepts them, canonical re-encoding matches, and the VM runs the result.

## Testing and acceptance

- [x] A golden artifact digest and length lock the header, directory, section, and instruction byte encoding.
- [x] Decoder/encoder round trips are byte-identical for canonical artifacts.
- [x] Deterministic mutation and fuzz corpora reject every truncated prefix plus overlap, arithmetic overflow, invalid IDs/types/targets, invalid UTF-8, oversized artifacts, bad flags, bad alignment, and unknown opcodes through one checked failure boundary.
- [ ] Every initial opcode has forward, inverse, trap, bound, and disassembly tests generated from the registry.
- [x] Property tests establish `unstep(step(C).state, step(C).undo) == C` over valid generated arithmetic states.
- [x] Paired instruction and `CALL`/`UNCALL` tests restore exact typed globals and frames.
- [x] Logged writes restore destroyed values and history exhaustion traps before mutation.
- [x] Commit barriers prevent earlier rewind while later language-level inverse calls remain executable and independently rewindable.
- [x] Checkpoint, complete rewind, and fresh execution agree exactly with uninterrupted machine state.
- [x] A compiled `Counter.w` produces a verified `.wbc`, reaches `2`, invokes inverse increments, and reaches `0`.
- [x] The VM never reads outside a verified body or aliases out-of-range global locations.
- [x] Current bytecode and VM reference documentation describes the implemented contract.

## Alternatives

### Preserve the 128-bit instruction

Rejected. Its static history field cannot represent dynamic undo data, its operand layout is too narrow for typed and region-aware extensions, and fixed decoding does not solve artifact versioning or verification.

### Snapshot the entire VM before every step

Rejected as the semantic model. It is simple but unbounded, obscures which operations destroy information, and cannot define external effects or quantum resources correctly. Implementations may use checkpoints as an optimization behind the step-record contract.

### Require every instruction to be intrinsically bijective

Rejected for the complete language. Strict reversible kernels are useful and required for coherent lifting, but practical classical programs also need bounded logged mutation and explicit barriers.

### Emit JVM class files

Rejected. Wheeler's reversible, region, effect, quantum, and history semantics are not JVM bytecode semantics. A future JVM execution backend can lower verified Wheeler IR without making `.class` the language artifact.

### Put provider-specific quantum instructions in the core stream

Rejected. Quantum regions have different ownership, linearity, execution, and capability rules. WIP-0002 gives them a backend-neutral region representation.

## Open questions

- Which numeric opcode ranges and first-slice operand forms should be frozen in the normative registry (owner: VM and compiler maintainers; decision point: before this WIP enters Review)?
- Should semantic section hashing be embedded in a dedicated manifest record or remain an artifact identity computed over canonical bytes (owner: runtime maintainers; decision point: before persisted checkpoints are implemented)?

## References

- [WIP-0002](WIP-0002-unified-classical-quantum-semantics.md)
- [WIP-0029](WIP-0029-parametric-polymorphism-and-bounded-specialization.md)
- [WIP-0031](WIP-0031-reversible-quantum-and-effect-polymorphism.md)
- [WIP-0032](WIP-0032-unified-io-fabric-and-durability-receipts.md)
- [Proposal process](README.md)
- [Bytecode reference](../reference/bytecode.md)
- [Virtual-machine reference](../reference/virtual-machine.md)
- [`Instruction`](../../../bootstrap/core/src/main/java/com/typeobject/wheeler/core/bytecode/Instruction.java)
- [`VirtualMachine`](../../../bootstrap/core/src/main/java/com/typeobject/wheeler/core/vm/VirtualMachine.java)
- [`Counter.w`](../../../wheeler-examples/src/main/wheeler/classical/control/Counter.w)
