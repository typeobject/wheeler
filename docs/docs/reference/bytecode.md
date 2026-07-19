# Wheeler bytecode format

Wheeler executables use the `.wbc` Wheeler Bytecode Container. It is the closed, typed, reversible IR and the only semantic artifact.

Classical instructions keep inverse, logging, and barrier rules. Workflow records keep irreversible boundaries visible, while quantum regions keep semantic operations and adjoints. Native code, OpenQASM, and provider payloads are derived from this form.

A `.wbc` file is not a JVM `.class` file.

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

Each directory entry stores the section type, flags, offset, length, alignment, and a zero reserved field. Format 1.0 requires eight-byte alignment, canonical section order, no overlaps, and zero-filled padding.

## Implemented sections

| ID | Section |
| --- | --- |
| 1 | Manifest: program name, entry function, and limits. |
| 2 | Strict UTF-8 string table. |
| 3 | Signed 64-bit global and nominal record descriptors. |
| 4 | Nominal tagged-variant descriptors. |
| 5 | Function, inverse-body, signature, and local-register type descriptors. |
| 6 | Classical code records. |
| 7 | Ordered classical and quantum workflow records. |
| 8 | Quantum registers, circuits, literal or symbolic gates, and coherently lifted calls. |
| 10 | Optional canonical proof certificates checked by the trusted finite kernel. |

Quantum and hybrid artifacts require sections 7 and 8. Canonical classical artifacts omit both. The decoder rejects unknown required sections.

WIP-0003 reserves a later section for target requirements. Provider-specific executables remain derived artifacts instead of semantic bytecode.

The manifest records the program kind as `classical`, `quantum`, or `hybrid`. It also stores the name, entry function, history limit, and step limit.

New source builds default to 250,000 history records and 1,000,000 transitions. These values are encoded, verifier-bounded policy inputs instead of fixed rules of the container format.

## Type and aggregate descriptors

The type section starts with fixed signed-global descriptors; bounded tables for records and fixed arrays follow.

A record descriptor contains a canonical ID, name, and a nonempty ordered field list. Each field has a name and type reference.

The required variant section has canonical nominal IDs and ordered, nonempty case tables. A case has a name and zero or more ordered payload fields.

An array descriptor stores a canonical ID, element type, and a length from 1 through 65,535. A slice descriptor stores a canonical ID and element type. Slices cannot escape, appear as function results, or become aggregate elements.

Every descriptor ID must equal its table position. Record fields may refer only to earlier record descriptors; variant payloads may refer to records or earlier variants.

This layout cannot represent recursive, cyclic, or forward inline values. Duplicate names, fields, cases, or IDs fail closed. The decoder also rejects forward references, unknown string IDs, unknown type tags, truncation, and trailing bytes.

## Classical instruction records

Each instruction is independently bounded:

```text
u16 opcode
u16 operand_count_form
u32 byte_length
u64 operands[operand_count]
```

The opcode determines one canonical operand count and one semantic rule. Dynamic undo data never appears in an instruction. The runtime stores it in step records.

### Function signatures and local types

Each 40-byte function descriptor declares parameter and local counts, an optional result, code ranges, and a canonical offset into the trailing signature-type table.

When a result exists, its type appears first at that offset; local types follow, and parameter registers occupy the first local slots. Type windows are contiguous in function order.

One little-endian `u32` per register stores its type:

- `1`: signed 64-bit integer;
- `2`: Boolean;
- high-nibble tag `0x1`: record reference;
- high-nibble tag `0x2`: variant reference;
- high-nibble tag `0x3`: fixed-array reference;
- high-nibble tag `0x4`: borrowed-slice reference.

Aggregate references carry a 28-bit descriptor ID. The result-presence flag `4` means that one result type is present in the signature table.

Unknown type codes, missing descriptor IDs, and noncanonical type-table lengths fail before execution. Parameter registers may carry any value, affine owner, or nonescaping loan accepted by the source profile.

### Scalar and control instructions

Local instructions include constants, state load or store, copy or affine move, checked arithmetic, bit operations, comparison, branches, loop-limit checks, calls, returns, aggregate construction, payload access, and bounded storage operations.

Checked arithmetic covers add, subtract, multiply, divide, and remainder. `LOCAL_AND` performs signed bitwise AND. `LOCAL_ROTR32` rotates the low unsigned 32 bits and requires an amount in the exact `0..31` range.

Equality and ordering produce Boolean values. Boolean registers contain only `0` or `1`, and branch conditions consume those values.

`EXPECT_TRUE` consumes one assigned Boolean local and traps when it is false. `EXPECT_EQ` remains the compact form for direct signed-global and literal equality.

### Records, variants, arrays, and slices

`RECORD_NEW` consumes an exact, contiguous field window and interns one immutable record. `RECORD_GET` reads a field checked against the descriptor.

`VARIANT_NEW` adds a verified case tag. `VARIANT_TAG_EQ` tests that tag, while `VARIANT_GET` requires the exact tag before it reads a payload field.

`ARRAY_NEW` consumes exactly the descriptor length from a homogeneous local window. `ARRAY_GET` takes a signed dynamic index and traps before mutation when the index is outside the value.

`SLICE_NEW` verifies the array origin plus a signed start and length; `SLICE_GET` checks a relative index and reads through the retained origin.

### Owned storage

Type code `3` identifies an affine region. Codes `4` and `5` identify affine signed-word and byte buffers. `OWNED_MOVE` invalidates its source.

Owner types may also appear in parameters. Passing an owner consumes the caller's argument and initializes exactly one owner in the callee. Before exit, the callee must consume, forward, drop, or return that value.

`REGION_NEW` creates bounded region storage. The `WORDS_ALLOC`, `WORDS_GET`, and `WORDS_SET` family manages signed-word buffers; `BYTES_ALLOC`, `BYTES_GET`, and `BYTES_SET` does the same for bytes.

`BUFFER_DROP` and `REGION_DROP` reclaim storage explicitly. Each operation checks allocation bounds, storage kind, byte range, and ownership state.

`BUFFER_LENGTH` returns the fixed element count without consuming an owner. It also accepts the immutable UTF-8 loan used by core text functions.

Type code `6` is an affine, fixed-capacity signed map. `MAP_ALLOC` charges 24 bytes for each slot. `MAP_PUT` inserts or updates, `MAP_HAS` checks membership, and `MAP_GET` traps on a missing key. Map slots use deterministic order and the normal owned-drop opcode.

Type code `7` is an affine immutable UTF-8 owner; `UTF8_FREEZE` consumes mutable bytes only after full strict validation. It changes the allocation kind under logged rewind and initializes the destination. Mutation opcodes continue to accept only mutable byte storage.

A function result may return any owned storage type. `RETURN_VALUE` consumes the callee local, then makes the caller destination the sole owner. Flow verification requires every other callee owner to be dead.

A returned buffer, map, or UTF-8 value must live in a caller region reached through a nonescaping region loan. A callee cannot return storage while abandoning its owning region. Slices, loans, and `byteview` values cannot be results.

Crossing a frame boundary does not copy an affine handle.

### UTF-8 operations

`UTF8_VALID` checks full-buffer RFC 3629 validity and returns a Boolean. `UTF8_COUNT` returns the Unicode scalar count or traps on malformed input.

`UTF8_SCALAR` and `UTF8_WIDTH` decode one scalar at an exact leading-byte position. They trap on malformed input, continuation-byte access, truncation, or a position outside the buffer.

Type code `8` is the nonescaping UTF-8 loan used for immutable function parameters. `UTF8_BORROW` creates a transient call-window handle from an owner or another loan.

This loan cannot be dropped, moved, returned, placed in an aggregate, or used for mutation.

### Mutable and immutable loans

Type code `9` is a nonescaping exclusive map loan. `MAP_BORROW` creates a transient call window from a map owner or an existing loan. Map operations accept the window, but ownership operations do not.

Type codes `10` and `11` are exclusive signed-word and byte-buffer loans. `BUFFER_BORROW` derives the verifier-selected kind for one transient call window. Normal word and byte operations accept a matching loan, while freeze, move, drop, return, and aggregate paths reject it.

Type code `12` is an exclusive region loan. `REGION_BORROW` creates a transient call window accepted by allocation opcodes. Region drop and result paths reject it. A callee must drop every allocation made through that region before returning.

Borrow verification rejects a call that passes one storage source into more than one mutable parameter.

Type code `13` is immutable `byteview`; `BYTES_GET` and `BUFFER_LENGTH` may inspect it. Byte writes, owner operations, function results, and aggregate storage reject it.

`BUFFER_BORROW` may derive a temporary immutable view from byte storage for a call. Unlike a mutable byte loan, this view does not join the exclusive-writer alias set.

### Calls and host effects

A call names a contiguous, initialized argument window, an exact argument count, and one caller result register when needed.

Verification consumes owner and transient-loan argument slots at the call boundary. A borrowed source owner remains live, while an owner moved into the argument window doesn't. Runtime frame binding follows the same rule, and rewind restores both frames and ownership state exactly.

The `void` entry accepts one of these signatures:

- no parameters;
- one type-code-8 UTF-8 input loan;
- one type-code-13 binary input view;
- one type-code-11 byte-output loan;
- either input form followed by the output loan.

The signature declares the required host effects. It does not place effect bytes, capacities, or paths in artifact identity.

`OUTPUT_LENGTH` records a checked prefix length for external byte output. Verification limits it to the entry function and a byte-loan operand. At runtime, the handle must be the exact host-output loan and the length must fit within capacity.

The instruction changes no byte. Its state participates in rewind, and no output becomes visible before successful termination.

## Proof certificates

Section 10 appears only when a program carries proof evidence. It begins with a bounded count, followed by fixed records with:

- canonical proof ID;
- proof-name string ID;
- trusted rule code;
- rule-domain subject ID;
- one signed 64-bit rule argument.

Unary generation rules require argument `-1`. Binary circuit rules use a second circuit ID, and resource rules use a positive bound.

The first trusted rules are `GENERATED_INVERSE`, `GENERATED_ADJOINT`, `CIRCUIT_EQUIVALENCE`, and `STATIC_STEP_BOUND`.

For `GENERATED_INVERSE`, the kernel rebuilds the inverse from the exact forward instruction sequence. It accepts only the checked reversible opcode set.

For `GENERATED_ADJOINT`, the kernel reverses the exact circuit operation list, inverts every semantic operation, and checks that applying the process twice returns the original body.

`CIRCUIT_EQUIVALENCE` requires two circuits over one register. The kernel compares their canonical bodies after cancelling adjacent inverse pairs with a stack-like pass.

`STATIC_STEP_BOUND` rejects calls and branches, then compares the full forward instruction count with both its positive proof bound and the program limit.

Unknown rules, missing subjects, noncanonical IDs, nonreversible functions, malformed lengths, duplicate names, and changed inverse bodies all reject the artifact.

Proof metadata cannot weaken normal verification or change execution. Omitting section 10 makes no theorem claim.

## Quantum and workflow records

Quantum bodies declare affine logical registers, unitary circuits, semantic gates, symbolic phase parameters with finite scale, and references to compiler-checked coherent functions. Symbol names are canonical string-table entries.

Runtime tasks provide an exact finite binding map. Task identity covers its schema, values, circuit applications, request, and seed policy.

Workflow records describe preparation, circuit or adjoint application, measurement into classical state, classical call or inverse, assertion, commit, and halt.

Quantum operations remain in their own domain. The decoder does not let a runtime target reinterpret a classical opcode as a provider gate.

## Verification

Loading checks the artifact size, magic, version, file length, directory arithmetic, section order, overlap, alignment, required sections, UTF-8, table IDs, body ranges, instruction lengths, and operand counts.

It also checks references, type codes, operands, Boolean normalization, and control-flow targets. Data-flow checks cover definite assignment, affine moves and drops, equal ownership at joins, and leak-free exits. Call checks cover fallthrough, typed calls, initialized arguments, result types, complete returns, inverse availability, and entry halting.

An instruction either completes and adds one rewind record, or it traps before changing data. Arithmetic is checked. Artifact limits may reduce runtime budgets, but they cannot exceed host ceilings.

### Wheeler-written compiler and verifier slice

`MinimalCompiler.w` and its IR, token, parser, code-generation, and encoding modules exercise a complete but bounded writer path. Wheeler scans one small source file, builds class and global IR, and emits a canonical artifact.

The accepted grammar supports zero or one signed global, an optional classical or reversible helper with one through five statements, and one entry. The entry may contain zero through five signed-local, assignment, checked update, or global-expectation statements before `HALT`.

Identifiers from source are sorted into the canonical string table. Offsets, type windows, local counts, code lengths, and final artifact size are derived from the parsed program.

The `LongClass` fixture contains `state long value = 7` and a checked update. CI compares all 504 output bytes with stage 0, decodes them strictly, requires byte-identical re-encoding, and runs both direct VM and `wheeler run` CLI publication paths.

`compiler/verification/Verifier.w` and its focused verifier modules independently read the emitted bytes. They check the header, contiguous directory, payload rules, function and local windows, manifest bounds, every supported instruction form, call and register domains, proof subjects and arguments, and terminal-only `HALT`.

A binary corpus accepts canonical stage-0 artifacts and rejects forged local or global indexes, type codes, call targets, proof subjects, and proof arguments. `NativeVerifier.w` applies the same verifier to immutable binary `byteview`, so verification does not need a text envelope.

This verifier covers the bounded compiler profile. It is not yet the full production verifier.

Differential fixtures include these exact artifacts and lowering paths:

- the 568-byte two-function `Calls` artifact;
- the 528-byte inverse-bearing `ReversibleCalls` artifact;
- post-call local and assertion forms;
- the proof-bearing `Certified` artifact;
- the 360-byte no-global `Bare` artifact;
- alternate identifier orders and the checked-in commented `Counter.w` source.

Classical helper fixtures use two descriptors, end with `RETURN`, and exercise one or two repeated `CALL` sites. Reversible helpers lower checked `+=` and `-=` to opposite bodies and XOR through `^=` to a self-inverse body. Entry code relies on `CALL` and `UNCALL`, while local declarations use `LOCAL_CONST` and `LOCAL_MOVE`. An optional inverse theorem adds a 28-byte `GENERATED_INVERSE` proof section.

Plain assignment inside a `rev` helper and duplicate names fail before output publication.

`compiler/ir/Opcodes.w`, `compiler/ir/TypeCodes.w`, and `compiler/ir/ProofRules.w` are the Wheeler-side authorities for the current opcode, type, and proof identities. Their public `const long` declarations fold at compile time and add no globals or startup work.

`InstructionVerifier.w`, `Verifier.w`, and `Interpreter.w` dispatch through those names instead of repeating integer tables. The focused verifier set also includes `compiler/{FunctionVerifier,InstructionVerifier,ProofVerifier}.w`. The stage-0 `Opcode` table remains the differential reference until compiler promotion; it does not authorize a third source of truth.

## Compatibility

The repository defines only format `1.0`. The decoder accepts that exact version and has no compatibility path for an earlier artifact.

Future incompatible work must replace the format on purpose; numeric section and opcode IDs are never silently reused.
