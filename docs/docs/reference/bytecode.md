# Wheeler bytecode format

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

Directory entries contain section type, flags, offset, length, alignment, and a zero reserved field. The first format requires eight-byte alignment, canonical type order, no overlaps, and zero-filled padding.

## Implemented sections

| ID | Section |
| --- | --- |
| 1 | Manifest: program name, entry function, and limits. |
| 2 | Strict UTF-8 string table. |
| 3 | Signed 64-bit global and nominal record descriptors. |
| 4 | Nominal tagged-variant descriptors. |
| 5 | Function, inverse-body, signature, and local-register type descriptors. |
| 6 | Classical code records. |
| 7 | Ordered classical/quantum workflow records. |
| 8 | Quantum-register, circuit, literal or symbolic gate, and coherently lifted call records. |
| 10 | Optional canonical proof certificates checked by the trusted finite kernel. |

Sections 7 and 8 are required for quantum and hybrid artifacts and absent from canonical classical artifacts. Unknown required sections are rejected. WIP-0003 reserves a later section for target requirements; provider executables are derived artifacts, not semantic bytecode.

The manifest records the program kind (`classical`, `quantum`, or `hybrid`) in addition to its name, entry function, history ceiling, and step ceiling.

The type section starts with fixed signed-global descriptors, followed by bounded nominal record and fixed-array tables. A record descriptor carries canonical ID, name, nonempty ordered fields, field names, and field type references. The required variant section carries canonical nominal IDs and an ordered nonempty case table; each case has a name and zero or more ordered typed payload fields. An array descriptor carries canonical ID, element type reference, and a length from 1 through 65,535. A slice descriptor carries canonical ID and element type; slice types are nonescaping and cannot appear as function results or aggregate elements. IDs equal table positions. Record fields may refer only to prior records. Variant payloads may refer to records or prior variants. Recursive, cyclic, and forward inline layouts are therefore unrepresentable. Duplicate names, fields, cases, IDs, forward references, unknown string IDs, unknown type tags, truncation, and trailing bytes fail closed.

## Classical instructions

Each instruction is independently bounded:

```text
u16 opcode
u16 operand_count_form
u32 byte_length
u64 operands[operand_count]
```

The opcode fixes the canonical operand count and semantic rule. Each 40-byte function descriptor declares parameter and local counts, an optional typed result, code ranges, and a canonical offset into the trailing signature-type table. A present result type appears first at that offset, followed by local types; parameter registers are the first locals. Type offsets are contiguous in function order. One little-endian `u32` per register denotes signed 64-bit (`1`), Boolean (`2`), or a tagged aggregate type-table reference. Record references use tag `0x1` in the high nibble, variant references use tag `0x2`, and fixed-array references use tag `0x3`, and borrowed-slice references use tag `0x4`; each carries a 28-bit descriptor ID. Unknown codes, unresolved descriptor IDs, and noncanonical table lengths fail before execution. Parameter registers occupy the first frame slots and carry their declared signed or Boolean type. Result-presence flag `4` denotes one result type in the signature table.

Local instructions cover constants, state load/store, copy or affine move, checked add/subtract/multiply/divide/remainder, typed XOR, structural equality, less-than, conditional/unconditional branch, loop-limit check, static value/void argument calls, value return, nominal aggregate construction, checked payload access, and bounded owned-region storage. `RECORD_NEW` consumes an exact contiguous field window and interns one immutable value; `RECORD_GET` reads one descriptor-checked field. `VARIANT_NEW` adds a verified case tag, `VARIANT_TAG_EQ` tests it, and `VARIANT_GET` requires that exact tag before reading a payload field. `ARRAY_NEW` consumes exactly the descriptor length from a homogeneous local window; `ARRAY_GET` consumes a signed dynamic index and traps before mutation when it is outside the value. `SLICE_NEW` verifies an array origin and signed start/length range; `SLICE_GET` checks a relative index and reads through the retained origin. Scalar type codes 3, 4, and 5 identify affine regions, signed-word buffers, and byte buffers. `OWNED_MOVE` invalidates its source. `REGION_NEW`, the `WORDS_ALLOC`/`WORDS_GET`/`WORDS_SET` and `BYTES_ALLOC`/`BYTES_GET`/`BYTES_SET` families, `BUFFER_DROP`, and `REGION_DROP` expose bounded allocation, kind-checked access, byte-range enforcement, and explicit reclamation. `BUFFER_LENGTH` returns the fixed element count without consuming the owner. `UTF8_VALID` returns a Boolean for strict whole-buffer RFC 3629 validity; `UTF8_COUNT` returns the Unicode scalar count or traps on malformed input. `UTF8_SCALAR` and `UTF8_WIDTH` decode at an exact leading-byte index and trap on malformed or non-boundary access. Type code 6 identifies an affine fixed-capacity signed map. `MAP_ALLOC` charges 24 bytes per slot; `MAP_PUT` inserts or updates; `MAP_HAS` tests membership; and `MAP_GET` traps on an absent key. Map storage uses deterministic slot order and the ordinary owned drop opcode. Type code 7 identifies an affine immutable UTF-8 owner. `UTF8_FREEZE` consumes a mutable byte local only after complete strict validation, changes the owned allocation kind under logged rewind, and initializes the destination; mutation opcodes accept only mutable bytes. Type code 8 is the nonescaping UTF-8 borrow used for immutable function parameters. `UTF8_BORROW` creates a transient call-window handle from an owner or an existing borrow; it grants no drop, move, result, aggregate, or mutation authority. Type code 9 is the nonescaping exclusive signed-map borrow. `MAP_BORROW` creates a transient call window from a map owner or existing borrow; map operations accept that window, but ownership operations do not. Borrow-window verification also rejects passing one storage source to multiple mutable parameters of a call. Type codes 10 and 11 are exclusive signed-word and byte-buffer borrows. `BUFFER_BORROW` derives the verifier-selected kind for one transient call window; ordinary word/byte operations accept the matching borrow while freeze, move, drop, result, and aggregate paths reject it. A function result may carry type code 3 (`region`): `RETURN_VALUE` consumes the callee owner, the caller destination becomes its sole owner, and flow verification requires every other callee owner dead. Buffer, map, UTF-8, and borrowed results remain invalid. `OUTPUT_LENGTH` records a checked publish-prefix length for the external byte output. Verification confines it to the entry and a byte-borrow operand; runtime additionally requires the exact host-output handle and a length within capacity. It mutates no byte, participates in rewind, and cannot publish anything before successful termination. Type code 12 is an exclusive region borrow. `REGION_BORROW` creates a transient call window accepted by allocation opcodes but rejected by region drop and result paths; callee flow must drop every allocation made under the borrowed region before return. Boolean registers contain only `0` or `1`. Equality and ordering produce Boolean values, and branch conditions consume them. The `void` entry has zero parameters, one type-code-8 UTF-8 input borrow, one type-code-11 byte-output borrow, or those input/output borrows in that order. The signature declares required explicit host effects without embedding effect bytes, capacity, or paths in artifact identity. A call identifies a contiguous initialized argument window, exact argument count, and caller result register. Dynamic undo data never appears in an instruction; it belongs to runtime step records.

## Proof certificates

Section 10 is present only when a program carries proof evidence. It begins with a bounded count followed by fixed records containing canonical proof ID, proof-name string ID, trusted rule code, rule-domain subject ID, and one signed 64-bit rule argument. Unary generation rules require argument `-1`; binary circuit rules use a second circuit ID; resource rules use a positive bound. The initial rules are `GENERATED_INVERSE`, `GENERATED_ADJOINT`, `CIRCUIT_EQUIVALENCE`, and `STATIC_STEP_BOUND`. The kernel reconstructs an inverse body from the exact forward instruction sequence and accepts only the checked reversible opcode subset. For an adjoint certificate it reverses the exact circuit operation list, inverts each semantic operation, and checks involution against the original body. Circuit equivalence requires two circuits on one register and compares the canonical bodies after stack-like cancellation of adjacent inverse operation pairs. A static step-bound certificate rejects calls and branches, then compares the complete forward instruction count with its positive bound and the program ceiling. Unknown rules, unresolved subjects, noncanonical IDs, nonreversible functions, malformed lengths, duplicate names, or changed inverse bodies reject the artifact.

Proof metadata cannot weaken ordinary bytecode verification or change execution. Omitting the section makes no theorem claim.

## Quantum and workflow records

Quantum bodies declare affine logical registers, unitary circuits, semantic gates, symbolic phase parameters with finite scale, and references to compiler-validated coherent functions. Symbol names are canonical string-table entries. Runtime tasks provide an exact finite binding map whose identity covers schema, values, circuit applications, request, and seed policy. Workflow records describe preparation, circuit/adjoint application, measurement into classical state, classical call/inverse, assertion, commit, and halt.

Quantum operations do not masquerade as mutable classical addresses. The decoder preserves their domain so runtime target selection cannot reinterpret an ordinary opcode as a provider gate.

## Verification

Loading checks artifact size, magic, version, file length, directory arithmetic, canonical ordering, overlap, alignment, required sections, UTF-8, table IDs, body ranges, instruction lengths, operand counts, global and local references, local type codes and operand compatibility, Boolean normalization, control-flow targets, definite local assignment, affine move/drop state and join equality, leak-free exits, fallthrough, typed function signatures and references, argument initialization, result compatibility, return completeness, inverse availability, and entry halting.

`MinimalCompiler.w` exercises the compiler/writer contract without asking Java to hold the pen: Wheeler scans and parses a bounded minimal source file, extracts its class and global IR, and emits a complete artifact containing one signed global and one `HALT` entry with derived strings, aligned offsets, and final size. For `LongClass` with `state long value = 7`, CI compares all 392 bytes with stage 0, decodes it through the strict reader, requires byte-identical re-encoding, and executes it through both direct VM and `wheeler run` publication paths. This proves a complete source-to-artifact path for a narrow grammar with global IR; general declarations and instructions are not yet IR-driven.

An instruction either completes and adds one rewind record or traps before data mutation. Arithmetic is checked. Limits in an artifact may reduce runtime budgets but cannot evade host ceilings.

## Compatibility

The repository defines only format `1.0`. The decoder accepts exactly that pair and contains no compatibility branch for an earlier artifact. Future incompatible work must replace the format deliberately rather than retain an unreleased legacy path. Numeric opcode and section IDs are never silently reused.
