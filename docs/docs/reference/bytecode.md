# Wheeler bytecode version 1

Wheeler executables use the `.wbc` Wheeler Bytecode Container. They are not JVM `.class` files.

## Header

Every artifact starts with this 40-byte little-endian header:

```text
byte[8] magic                 "WHEELBC\0"
u16     major_version         1
u16     minor_version         0
u32     flags                 0
u64     file_length
u32     section_count
u32     directory_entry_size  32
u64     directory_offset
```

Directory entries contain section type, flags, offset, length, alignment, and a zero reserved field. Version 1 requires eight-byte alignment, canonical type order, no overlaps, and zero-filled padding.

## Implemented sections

| ID | Section |
| --- | --- |
| 1 | Manifest: program name, entry function, and limits. |
| 2 | Strict UTF-8 string table. |
| 3 | Signed 64-bit global descriptors. |
| 5 | Function and inverse-body descriptors. |
| 6 | Classical code records. |
| 7 | Ordered classical/quantum workflow records. |
| 8 | Quantum-register, circuit, literal or symbolic gate, and coherently lifted call records. |

Sections 7 and 8 are required for quantum and hybrid artifacts and absent from canonical classical artifacts. Unknown required sections are rejected. WIP-0003 reserves a later section for target requirements; provider executables are derived artifacts, not semantic bytecode.

The manifest records the program kind (`classical`, `quantum`, or `hybrid`) in addition to its name, entry function, history ceiling, and step ceiling.

## Classical instructions

Each instruction is independently bounded:

```text
u16 opcode
u16 operand_count_form
u32 byte_length
u64 operands[operand_count]
```

The opcode fixes the canonical operand count and semantic rule. Branches and variable records are not in the first slice. Dynamic undo data never appears in an instruction; it belongs to runtime step records.

## Quantum and workflow records

Quantum bodies declare affine logical registers, unitary circuits, semantic gates, symbolic phase parameters with finite scale, and references to compiler-validated coherent functions. Symbol names are canonical string-table entries. Runtime tasks provide an exact finite binding map whose identity covers schema, values, circuit applications, request, and seed policy. Workflow records describe preparation, circuit/adjoint application, measurement into classical state, classical call/inverse, assertion, commit, and halt.

Quantum operations do not masquerade as mutable classical addresses. The decoder preserves their domain so runtime target selection cannot reinterpret an ordinary opcode as a provider gate.

## Verification

Loading checks artifact size, magic, version, file length, directory arithmetic, canonical ordering, overlap, alignment, required sections, UTF-8, table IDs, body ranges, instruction lengths, operand counts, global references, function references, inverse availability, and entry halting.

An instruction either completes and adds one rewind record or traps before data mutation. Arithmetic is checked. Limits in an artifact may reduce runtime budgets but cannot evade host ceilings.

## Compatibility

Major versions change incompatible structure or semantics. Minor versions add optional records or capabilities that old runtimes reject canonically. Numeric opcode and section IDs are never silently reused.
