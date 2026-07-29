# WIP-0038: Regular instruction forms and extension registry

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler bytecode, VM, verifier, compiler, runtime, and tooling maintainers |
| Created | 2026-07-27 |
| Updated | 2026-07-28 |
| Area | Bytecode, VM, verifier, compiler, extensions, tooling |
| Depends on | WIP-0001, WIP-0007, WIP-0013, WIP-0017 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler gives every classical opcode one stable identity, one named operand form, one ordered field-role list, and one reversibility class. The design borrows RISC-V's useful habits: a small regular base, stable field positions, explicit extension ownership, and no instruction meaning hidden in a decoder switch. Wheeler keeps its existing canonical variable-length record because typed 64-bit identities, calls, aggregates, ownership, and rewind metadata do not fit honestly into a 32-bit costume.

## Motivation

The `.wbc` instruction record already has a sound framing rule. It carries an opcode, an operand count, an exact byte length, and fixed-width operands. The loader rejects unknown opcodes and noncanonical lengths.

The old registry still wrote operand counts as raw integers beside opcode IDs. A reader had to inspect verifier and VM code to learn whether operand zero meant a destination, global, function, owner, branch target, or something less polite. That is number soup. It encourages compiler, decoder, verifier, disassembler, and VM tables to drift while each table remains locally plausible.

Future extensions make this worse unless Wheeler fixes ownership first. A byte length lets a tool locate the next record. It does not make an unknown executable instruction safe to skip. Skipping a storage write or barrier and continuing execution is not forward compatibility. It is improv comedy with machine state.

RISC-V gets several architectural points right:

- instruction forms have stable field roles.
- base instructions and extensions have explicit ownership.
- decoders reject unsupported required behavior.
- mnemonic families share regular layouts.
- numeric assignments live in a registry rather than scattered call sites.

Wheeler should take those points without copying constraints meant for hardware fetch and decode.

## Use cases

### Compiler emission

The compiler emits a checked local add. It selects `LOCAL_BINARY`, then writes destination, left source, and right source in that order. It does not repeat a bare operand count or invent another order.

### Verification and diagnostics

The verifier reports `right_source local 17 is outside the frame` instead of `operand 2 is invalid`. The stable role name comes from the same opcode registry that supplied the operand count.

### Extension negotiation

A later artifact requires a standard vector or coherent-control extension. The artifact names that requirement. A loader either recognizes the complete extension and verifies every instruction in it, or rejects the artifact before execution.

### Disassembly

The disassembler prints role-labelled fields from registry metadata. New instructions do not need another hand-maintained count table that eventually wanders into traffic.

## Goals

- Give every opcode one named instruction form and ordered field-role list.
- Keep `.wbc` 1.0 instruction bytes canonical and byte-identical.
- Put numeric opcode identities and binary widths behind named constants.
- Keep destination and source positions regular across related instructions.
- Define extension allocation, negotiation, rejection, and version rules.
- Generate or mechanically cross-check compiler, decoder, verifier, VM, and disassembler metadata.
- Reject raw instruction arities and widths in maintained emitter code.

## Non-goals

- Replace `.wbc` with RISC-V machine code.
- Force every Wheeler instruction into 32 bits.
- Make unknown executable opcodes skippable.
- Add dynamic opcode registration or process-local semantics.
- Treat native target instructions as canonical Wheeler IR.
- Change reversibility, ownership, effect, quantum, or proof semantics.

## Terms and semantic model

An **opcode identity** is the stable unsigned 16-bit number assigned to one classical operation.

An **instruction form** is a named ordered list of operand roles. A form determines field count and position. It does not determine the operation on its own.

An **operand role** names the meaning of one 64-bit field, such as `destination`, `source`, `function`, `argument_base`, `argument_count`, `target`, `owner`, `index`, or `immediate`.

An **extension** is a closed registry addition with assigned opcode identities, forms, type rules, transitions, reversibility classes, trap rules, costs, tests, and a required capability identity.

For an opcode `op` with form `F`, canonical decoding requires:

```text
wire_operand_count = length(F.roles)
wire_byte_length = instruction_header_size
                 + wire_operand_count * instruction_operand_size
```

Each role has one position. The verifier interprets the field only through `op` and its form. The VM executes only after structural and semantic verification.

Related register instructions follow this order:

```text
destination, left_source, right_source
```

Calls follow these orders:

```text
call_void:  function, argument_base, argument_count
call_value: function, argument_base, argument_count, result
```

Aggregate and storage forms put the destination first when one exists. They then name the owner or descriptor, followed by index, range, tag, key, capacity, or source fields as the operation requires.

## Ownership and boundaries

The bytecode registry owns opcode identities, forms, roles, reversibility classes, and extension membership.

The compiler chooses an opcode and supplies values for its named roles. It does not supply a free-standing operand count.

The writer derives count and byte length from the form. The reader checks both redundant wire fields before constructing an instruction.

The verifier owns type, initialization, ownership, control-flow, and effect checks for each role. The VM owns the accepted transition and rewind record.

The disassembler consumes registry role names. It does not maintain a parallel operand legend.

Standard extensions require a WIP and a registry change. Target providers may define derived native operations, but those operations never acquire canonical `.wbc` meaning through runtime registration.

## Design

### Existing wire record

Wheeler keeps the current record:

```text
u16 opcode
u16 operand_count_form
u32 byte_length
u64 operands[operand_count_form]
```

All fields use little-endian encoding. The header has a fixed named width. Every operand has a fixed named width. The registry derives the count. The writer stores the count and total length so a decoder can diagnose malformed records without guessing.

The `operand_count_form` field remains the role count in `.wbc` 1.0. The semantic form lives in the opcode registry. A later incompatible wire encoding needs a deliberate format version. It does not reinterpret this field under the same version.

### Regular forms

The first registry includes nullary, function, result, global-immediate, global-pair, local, local-immediate, local-global, global-local, local-source, local-binary, target, local-target, call, aggregate, slice, region, storage, map, and output forms.

Forms may share a field count. `LOCAL_IMMEDIATE` and `LOCAL_SOURCE` both have two fields, but they do not share meaning. This distinction lets diagnostics, verification, and tools stay honest.

The registry stores stable role order. Opcode names do not affect decoding. Numeric ranges may help humans group instructions, but no verifier derives semantics from opcode bits.

### Extension rules

A standard extension must define all of these items in one registry revision:

- an immutable extension name and version.
- unique opcode identities that no prior release assigned.
- one existing or new named form for each opcode.
- type, ownership, effect, trap, cost, and reversibility rules.
- compiler and disassembler spelling.
- malformed-record and semantic conformance tests.
- artifact capability negotiation and bootstrap-feature treatment.

An implementation never reuses a retired opcode identity. Removal leaves a tombstone.

A loader rejects an unknown opcode even when its byte length is valid. An artifact that requires an unsupported extension fails before execution and before publication. Optional non-executable sections may use their own skip rules. Executable instructions may not.

Standard opcode allocation remains centralized. Wheeler does not reserve a canonical vendor range. A vendor operation belongs in a derived target artifact or enters the standard registry through review.

### Named numeric policy

Maintained code may contain a numeric opcode or binary width only at its named constant definition. Emitter call sites use named forms and widths. Tests may use malformed literal bytes only when the test names the violated field and explains the value.

Source token offsets and bounded capacities follow the same rule when their meaning is not obvious from local arithmetic. A comment can name a one-off format fixture. Repeated values require constants. Hexadecimal confetti is not an architecture.

## Reversibility and history

Instruction forms do not change transitions. Each opcode retains its intrinsic, checked, logged, or barrier class. Rewind records continue to name the exact opcode and accepted operands.

An extension must define its forward transition and rewind relation before acceptance. A new form does not grant reversibility. A new opcode cannot infer inverse behavior from matching field positions.

## Concurrency and determinism

This proposal adds no scheduler or shared-memory rule. Registry order, identity assignment, form roles, encoding, diagnostics, and extension negotiation remain deterministic.

Concurrent instructions in a later WIP must still use registered forms and explicit event-order semantics. A tidy field layout does not solve races. Hardware designers have also tried staring harder at the bits.

## Quantum and proof implications

Classical instruction forms do not flatten quantum regions or proof sections into opcodes. Quantum operations and proof rules keep their existing registries and semantic boundaries.

Proof certificates that identify classical bodies continue to bind canonical instruction bytes. The byte-preserving registry refactor does not invalidate them. A future opcode extension must update proof rules only when its semantics need new trusted reasoning.

## Bytecode, persistence, and compatibility

The initial implementation changes no `.wbc` byte. Existing canonical artifacts decode and re-encode identically.

The loader still rejects unknown executable opcodes. Future standard extensions must declare their required capability and use an accepted format-version rule. A minor-compatible extension may add semantics only when old loaders already reject it safely and new loaders verify it completely. Any changed field interpretation requires a new major format.

Persisted history remains artifact-bound. A runtime never resumes history under a registry that assigns different meaning to the artifact's opcode identities.

## Safety, limits, and failures

The reader rejects unknown identities, wrong operand counts, wrong byte lengths, truncation, trailing instruction bytes, and unsupported required extensions.

The verifier reports the opcode and role for an invalid field. It rejects out-of-range registers, IDs, owners, indices, targets, argument windows, and result slots before execution.

Registry duplication fails tests and build checks. Runtime registration does not exist, so process order cannot alter instruction meaning.

## Migration and deletion

1. Split stable numeric identities from Java opcode semantics.
2. Replace raw Java operand counts with named forms and roles.
3. Add named native instruction arities and operand widths.
4. Replace raw emitter arities and widths with those names.
5. Make verifier and disassembler diagnostics consume role metadata.
6. Add artifact extension declarations before assigning the first extension opcode.
7. Delete every parallel operand-count table after generated registry consumers replace it.

## Progress

- [x] Java opcode identities live in one constants owner.
- [x] Java opcodes name forms with ordered semantic roles.
- [x] Instruction count and byte length derive from form and format constants.
- [x] Wheeler-native emitters use named instruction arities and operand widths.
- [x] Registry tests reject duplicate identities and field-order drift.
- [x] Stage 0 mechanically cross-checks every opcode identity and operand count consumed by the native compiler.
- [x] The Wheeler-native verifier reads operand counts from one instruction-form registry instead of carrying a private switch.
- [x] Verifier diagnostics name the opcode and canonical role for local types, references, windows, descriptors, tags, indices, limits, and storage checks.
- [x] VM execution, preflight, aggregate checks, borrow-window checks, argument binding, transition observation, storage preflight, and disassembly consume semantic roles instead of private operand positions.
- [x] Disassembly labels fields from registry metadata.
- [x] Optional required section 13 declares unique sorted instruction-extension names and versions.
- [ ] Stage 1 generates the mechanically cross-checked Java and Wheeler registry views from one promoted source.

## Testing and acceptance

- [x] Every opcode identity is unique and round-trips through lookup.
- [x] Every opcode has one immutable form and exact role count.
- [x] Representative arithmetic and call forms lock field order.
- [x] Existing bytecode codec, verifier, VM, rewind, compiler, and example suites pass unchanged.
- [x] Wheeler-native compiler output remains byte-identical to stage 0.
- [x] Malformed extension declarations fail before instruction decoding.
- [x] Unsupported required extensions fail before execution.
- [x] Verifier diagnostics and tests name every invalid operand role.
- [x] Disassembler tests assert role-labelled output.
- [x] Current reference docs describe extension negotiation and the empty supported registry.

## Alternatives

### Copy RISC-V 32-bit encodings

Rejected. Wheeler instructions carry 64-bit semantic IDs and register windows, typed aggregate fields, calls, ownership operations, and explicit variable arity. Compressing those values would add side tables or arbitrary limits. Wheeler needs regular semantics more than it needs hardware fetch density.

### Keep only operand counts

Rejected. Equal counts do not imply equal roles. The verifier and disassembler would keep private schemas, which recreates drift.

### Skip unknown instructions using byte length

Rejected. Structural skipping cannot preserve executable meaning, effects, barriers, ownership, or control flow.

### Allow runtime vendor opcode registration

Rejected. Artifact meaning would depend on process configuration and load order. That breaks identity, replay, proofs, and bootstrap trust in one impressively small API.

## Open questions

- Which artifact section should carry required standard extension identities. **Owner:** bytecode and package maintainers. **Decide by:** before the first post-base opcode enters Review.
- Should generated registry data originate from Wheeler source after stage-1 promotion. **Owner:** compiler and bootstrap maintainers. **Decide by:** before deleting the Java differential registry.

## Integration with reversible concurrency

### Structured-task standard extension

After WIP-0039 acceptance, the registry adds one required standard extension with a stable name and version. It owns task-scope, spawn, join, scheduler, and scalar-atomic instruction families.

Numeric identities land only with compiler, decoder, verifier, VM, disassembler, malformed-artifact, rewind, and bakery coverage. WIP-0039 names semantic families but reserves no numbers.

Extension metadata names task descriptors, memory model, schedule plan, event record, and effects. Old loaders reject the requirement before execution. New operand roles land only with their opcodes.

## Integration with reversible result slots

WIP-0041 requires regular forms for result slot, source place, constant, result type, ownership mode, and inverse relation operands. This proposal assigns identities only when compiler, verifier, VM, disassembler, rewind, generated inverse, and malformed-artifact handling land together. Existing `RETURN_VALUE` keeps its current ordinary meaning. A new inverse contract does not arrive disguised as an old opcode.

## References
- [WIP-0041](WIP-0041-reversible-result-slots-and-explicit-presence-values.md)
- [WIP-0039](WIP-0039-deterministic-structured-task-machine-and-global-rewind.md)
- [WIP-0040](WIP-0040-explicit-schedule-witnesses-for-reversible-task-scopes.md)

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0013](WIP-0013-typed-frames-control-flow-and-storage.md)
- [WIP-0017](WIP-0017-compile-time-constants-and-finite-enums.md)
- [Bytecode reference](../reference/bytecode.md)
- [RISC-V instruction set manual](https://riscv.org/technical/specifications/)
