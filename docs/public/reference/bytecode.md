---
title: Artifacts and Bytecode
description: The canonical Wheeler 1.0 container, its typed sections, and the checks required before execution.
---

# Artifacts and Bytecode

Source can travel in a gray book. Execution requires a more severe object.
Wheeler executables use the `.wbc` container, the closed typed artifact that
carries classical instructions, inverse bodies, workflow records, quantum regions,
and proof certificates.

Native code, OpenQASM, and provider payloads derive from `.wbc`. None replaces its
semantic authority. A `.wbc` file is not a JVM `.class` file.

## Header and directory

Every artifact begins with this 40-byte little-endian header:

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

Each directory row contains section type, flags, offset, length, alignment, and a
zero reserved field. Format 1.0 requires eight-byte alignment, canonical section
order, disjoint extents, and zero-filled padding.

## Sections in format 1.0

| ID | Contents |
| ---: | --- |
| `1` | Manifest: program name, entry, kind, and limits. |
| `2` | Strict UTF-8 string table. |
| `3` | Signed globals, record descriptors, arrays, and slices. |
| `4` | Tagged variants and their cases. |
| `5` | Functions, inverse bodies, signatures, and local types. |
| `6` | Classical instruction records. |
| `7` | Ordered classical and quantum workflow records. |
| `8` | Quantum registers, circuits, parameters, and coherent calls. |
| `10` | Optional proof certificates checked by the finite kernel. |
| `13` | Optional required classical instruction extensions. |

Quantum and hybrid artifacts require sections 7 and 8. Canonical classical
artifacts omit them. Unknown required sections cause rejection.

The manifest kind is `classical`, `quantum`, or `hybrid`. New source uses limits of
4,000,000 transitions and 4,000,000 retained history entries unless the artifact
requests smaller verified values.

## Type identities

Each 40-byte function descriptor carries contiguous signature and local-type windows. Parameter
registers occupy the first local slots. A present result type comes first in its
signature window.

| Type code | Meaning |
| ---: | --- |
| `1` | signed 64-bit integer |
| `2` | Boolean |
| `3` | affine region owner |
| `4` | affine signed-word buffer |
| `5` | affine byte buffer |
| `6` | affine fixed-capacity signed map |
| `7` | affine immutable UTF-8 owner |
| `8` | nonescaping UTF-8 loan |
| `9` | exclusive signed-map loan |
| `10` | exclusive word-buffer loan |
| `11` | exclusive byte-buffer loan |
| `12` | exclusive region loan |
| `13` | immutable binary `byteview` |
| `14` | the one-value `Done` type |

Function flag `4` declares one result type in the signature table.
High-nibble tags `0x1`, `0x2`, `0x3`, and `0x4` identify record, variant,
fixed-array, and borrowed-slice references. Their low 28 bits contain the
descriptor ID.

Unknown types, absent descriptors, malformed type windows, and invalid owner or
loan positions fail verification.

## Aggregate descriptors

Records and variants use canonical nominal IDs and string-table names. Arrays
store element type and a length from 1 through 65,535. A slice stores its element
type and may appear only where its source lifetime remains visible.

Descriptor graphs may refer to records and variants recursively. Runtime values
remain finite constructions from initialized fields. Arrays cannot create a
recursive inline layout.

`Slot<T>` uses the existing variant section. Tag zero is payload-free `Vacant`.
Tag one is `Holding`, with one field named `value`.

Duplicate names, fields, cases, IDs, unknown references, escaped slices, and
recursive array layouts cause rejection before execution.

## Classical instruction records

Each instruction carries its own checked extent:

```text
u16 opcode
u16 operand_count_form
u32 byte_length
u64 operands[operand_count]
```

The opcode selects one registered form and ordered semantic roles such as
destination, source, function, argument window, result, owner, index, or branch
target. The decoder verifies the declared form and length before accepting the
row. Unknown executable opcodes always fail.

Optional section 13 begins with a positive `u32` requirement count. Each row has
a byte length, canonical ASCII extension name, and positive decimal version.
Names are unique, sorted, and no longer than 128 bytes. The current registry
supports no extension. An empty requirement set omits the section.

Instruction families cover:

- checked scalar arithmetic, comparison, and bit operations.
- typed locals, state load and store, affine moves, and expectations.
- branch and loop-limit checks.
- function call, inverse call, result transfer, and return.
- immutable records, variants, arrays, and slices.
- regions, buffers, maps, UTF-8, binary views, loans, and explicit drop.
- `COMMIT` and `HALT`.

Arithmetic traps before mutation on overflow, zero division, invalid remainder,
or an out-of-range `rotateRight32` amount. Boolean registers admit only zero and
one.

Dynamic undo data never appears inside an instruction. The VM stores it in a
transition record.

## Calls and reversible results

A call names one initialized argument window and an exact argument count. Value
calls also name the caller's destination register. Owner arguments move. Loans
remain attached to their verified origins.

`CALL` runs a forward zero-argument body. `UNCALL` runs its generated inverse as
new work. The inverse body has its own code offset.

A reversible scalar result uses two adjacent caller-owned registers: a Boolean
presence tag and a signed or Boolean payload. Function flags `0xd` identify this
ABI. `CALL_RESULT_SLOT`, the `RESULT_FILL_*` family,
`RETURN_RESULT_SLOT`, and `UNCALL_RESULT_SLOT` exchange vacancy with one verified
result relation. The inverse checks the held value before restoring vacancy.

Generated inversion never reads the VM's debugger history. Committing between the
forward and inverse calls leaves the relation available.

## Storage and text

Region and buffer instructions check owner state, kind, capacity, byte range, and
loan authority before mutation. `OWNED_MOVE` invalidates its source.

Map allocation charges 24 bytes per slot. UTF-8 freeze consumes mutable bytes only
after complete RFC 3629 validation. Scalar and width operations require a leading
byte position. Binary views perform no text decoding.

An owned result crosses a call boundary without copying its handle. Slices and
loans cannot become results. Flow verification requires every other callee owner
to be dead before return.

The `void` entry accepts no parameters, one text input loan, one binary input view,
one mutable output loan, or either input followed by output. `OUTPUT_LENGTH`
selects a checked prefix of the exact external output owner and becomes visible
only after successful halt.

## Proof certificates

Section 10 begins with a count followed by fixed certificate records containing a
canonical ID, name, trusted rule, subject, and one signed argument.

The accepted rules are:

- `GENERATED_INVERSE`
- `GENERATED_ADJOINT`
- `CIRCUIT_EQUIVALENCE`
- `STATIC_STEP_BOUND`

The kernel rebuilds generated bodies or performs the named finite check. Unknown
rules, missing subjects, changed bodies, malformed arguments, and duplicate names
reject the artifact. Proof metadata cannot weaken ordinary verification.

## Quantum and workflow records

Quantum instructions use a provider-neutral form:

```text
u32 quantum_opcode
u32 field_count
u64 fields[field_count]
```

The accepted quantum opcodes are `APPLY_GATE`, `APPLY_SYMBOLIC_GATE`,
`CALL_UNITARY`, `PREPARE_REGISTER`, `MEASURE_QUBIT`, `RESET_QUBIT`, and
`APPLY_CONDITIONAL_GATE`. Semantic gates are H, X, Z, phase, controlled phase,
CNOT, CZ, and swap.

Preparation contains one complete basis value. Measurement names one qubit and a
target-resident Boolean slot. Conditional application names an earlier slot, an
expected Boolean, and a fixed gate. Preparation, measurement, and reset admit no
inverse construction.

Workflow rows order preparation, circuit or adjoint application, measurement into
classical state, classical calls, assertions, commit, and halt. Task identity also
binds the finite parameter map, requested circuit applications, shot count, and
seed policy.

Provider gate names and QASM never enter the canonical instruction registry.

## Verification before identity

Loading checks:

- size, magic, version, declared length, and complete consumption.
- directory order, arithmetic, alignment, overlap, and padding.
- required sections and strict UTF-8.
- table IDs, references, type windows, body ranges, and instruction extents.
- operand roles, local indexes, Boolean normalization, and branch targets.
- definite assignment, affine movement, equal ownership at joins, and leak-free
  exits.
- typed calls, complete returns, inverse availability, and entry halting.
- proof subjects and quantum result-slot flow.

An instruction either completes and appends one rewind entry or traps without
partial mutation.

Canonical Wheeler 1.0 has one accepted byte representation. Identity encoding
first decodes and verifies the complete artifact, then reproduces those bytes.
SHA-256 can identify accepted bytes. It cannot turn malformed bytes into an
artifact.

## Compatibility

The Reach currently recognizes format `1.0` only. Numeric section, opcode, type,
gate, and proof-rule identities are never silently reused. An incompatible future
format must carry a new version and an explicit migration.

The [virtual machine](virtual-machine.md) describes execution and rewind. The
[package appendix](packages.md) describes the containers that carry source and
artifacts between ports.
