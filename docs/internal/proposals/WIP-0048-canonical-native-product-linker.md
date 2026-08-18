# WIP-0048: Canonical native product linker

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler compiler, bytecode, bootstrap, and conformance maintainers |
| Created | 2026-08-08 |
| Updated | 2026-08-13 |
| Area | Self-hosting, canonical linking, bytecode emission, bootstrap |
| Depends on | WIP-0038, WIP-0041, WIP-0044, WIP-0045, WIP-0046, WIP-0047 |
| Supersedes | Final artifact emission work in WIP-0047 |
| Superseded by | None |

## Summary

The native linker shall emit one canonical `.wbc` 1.0 artifact from completed semantic products. It shall not read dependency source, preserve a Java `Program`, patch a stage-0 artifact, or infer facts from allocation addresses.

WIP-0047 ends at validated callable products, stable relocations, counted closure windows, and immutable source-local artifacts. This WIP owns final ID assignment, section planning, byte emission, whole-container verification, and identity publication.

## Problem

A closure of valid module products is not yet a deployable artifact. Source-local string IDs, type IDs, function IDs, code offsets, and section offsets overlap. Concatenating sections preserves none of their meanings. Recompiling a flattened source closure would avoid the linker and restore the dependency-source path that WIP-0044 removed.

The output must remain byte-for-byte identical to stage 0. “Equivalent after decoding” is not bootstrap evidence.

## Inputs

The linker consumes only published products:

- canonical package and module order.
- immutable source-local artifact ranks and ranges.
- scalar, callable-signature, aggregate-layout, ownership, and body identities.
- counted aggregate, function, local-type, and instruction windows.
- local, imported-call, and aggregate-operand relocation rows.
- result-slot flags and exact forward and inverse extents.

A missing product is an error. An empty table is valid only when its published count is zero.

## Canonical order

The output assigns IDs in this order:

1. closure modules in deterministic leaf-first order.
2. strings by canonical byte value, with duplicate bytes sharing one ID.
3. records, fixed arrays, slices, and variants by module order and source-local ID.
4. globals by module order and source-local ID.
5. functions by module order and source-local ID.
6. forward code followed immediately by inverse code for each function.
7. optional proof, quantum, workflow, and extension records in their format order.

Dependency rank chooses a product. It never chooses output order.

## Emission pipeline

The linker shall:

1. validate every count, range, rank, identity, and relocation without mutating output.
2. compute exact section counts, lengths, alignments, and output length with checked arithmetic.
3. assign final string, aggregate, global, and function IDs into owned columns.
4. emit local-type and descriptor rows with final type IDs.
5. emit instruction records in closure order and rewrite only typed operands named by relocation products.
6. emit function descriptors from the resulting type and code offsets.
7. emit all remaining canonical sections.
8. emit the header and sorted directory after section facts are final.
9. clear every alignment byte and unused output byte touched by a reused buffer.
10. decode and verify the complete output before setting its length or publishing its identity.

Validation and planning precede the first output mutation. Final verification precedes visibility.

## Bounds

The first implementation admits:

- 512 local modules and 64 direct dependencies per module.
- 16 MiB of immutable source-local artifacts.
- 4,096 closure functions.
- 131,072 closure instructions.
- 4 MiB of linked instruction code.
- 16 MiB for the final canonical artifact.
- the existing WIP-0045, WIP-0046, and WIP-0047 table bounds.

Exceeding a bound traps before output mutation. These are recovery bounds, not language limits.

## Relocation rules

A local call adds the owning module's final function base to a validated source-local target. An imported call uses the exact callable identity selected in dependency rank. Aggregate construction uses the exact aggregate product identity and source-local row. Type operands use final descriptor-kind IDs. Result-slot, owner, loan, direction, and extension facts are verified properties and are not reconstructed from opcode folklore.

Unknown executable opcodes fail. `InstructionForms.w` remains the sole Wheeler-native operand-count owner.

## Evidence

Acceptance requires:

- local-call code bytes matching stage 0 after nonzero function-base rebasing.
- imported, qualified, ambiguous, and private-call fixtures.
- reversible forward/inverse and WIP-0041 result-slot fixtures.
- recursive nominal, aggregate-construction, ownership, and loan fixtures.
- two independently emitted artifacts comparing byte for byte.
- the complete physical compiler closure emitted from products alone.
- stage 1 compiling byte-identical stage 2.

The first six facts establish a linker. The final two establish self-hosting.

## Recovery consequences

A linked native artifact does not set the bootstrap bit. Promotion still requires fixed-point and diverse-compilation evidence with provenance. No `wheeler.bootstrap.yaml` may be checked in before those facts exist.

## Implementation status

- [x] `CompiledBodyArchive.w` retains validated source-local artifacts under stable ranks.
- [x] `CountedFunctionProducts.w` publishes closure-wide function and instruction windows.
- [x] `LinkedInstructionCode.w` emits closure-ordered code and rebases validated local call targets by module function base.
- [x] Validated imported-target rows rewrite final function IDs atomically after local emission.
- [x] `CallableFunctionRows.w` maps callable and imported signature identities to unique final function rows with bounded open addressing. Duplicate or missing identities publish nothing.
- [x] `AggregateDescriptorRows.w` assigns per-kind final IDs in closure order and resolves stable module identity, kind, and source-type triples. Duplicate or missing products publish nothing.
- [x] `LinkedLocalTypes.w` emits exact closure function type windows and rewrites nominal codes through owner-scoped final descriptor rows.
- [x] `LinkedFunctionSection.w` emits exact function descriptors and final local-type rows after code and type extent validation.
- [x] `LinkedStringSection.w` sorts and deduplicates counted ASCII bootstrap names, emits canonical bytes, and publishes every source-to-final ID.
- [x] `CompiledStringProducts.w` validates source-local string directories, sorted ASCII names, exact extents, and appends counted artifact ranges for linked emission.
- [x] `CompiledGlobalProducts.w` appends source-local global rows with split 64-bit initial values. `LinkedAggregateSections.w` emits final globals, records, arrays, slices, variants, cases, and fields. Descriptor-compatible source products and copied source-string products feed the same emitter without a temporary aggregate artifact.
- [x] `CompiledFunctionNames.w` retains closure string references and resolves final function-name IDs.
- [x] `LinkedManifestSection.w` resolves the root program name and rebases its entry through counted module function windows.
- [x] `LinkedContainer.w` emits format 1.0 headers, sorted directories, eight-byte alignment, zero padding, and bounded optional section types.
- [x] The assembled container verifies its header, directory, extents, and padding before the caller publishes output length or identity.
- [x] `CanonicalProductEmitter.w` emits final semantic sections, returns an immutable section plan, and publishes a verified container in a separate lifetime after callers may drop large source and product windows.
- [x] The complete product-linked fixture uses that production emitter, passes `verifyArtifact` before output-length publication, and then passes the independent stage-0 reader.
- [x] A local-call, global, and aggregate fixture flows through counted strings, globals, layouts, functions, types, code, manifest, and container emission and matches stage 0 byte for byte.
- [x] `CompiledProofProducts.w` rebases counted certificate names and subjects. `LinkedProofSection.w` emits canonical split arguments.
- [x] The complete reversible result-slot and optional proof product fixture matches stage 0 byte for byte.
- [x] A complete mixed-owner fixture applies validated imported relocation rows and matches stage 0 byte for byte.
- [x] `IdentityRelocationEmitter.w` resolves all relocation identities to final rows before changing one code operand.
- [x] The complete mixed-owner fixture uses that production boundary. numeric source targets select fixture identities but never final rows.
- [x] Physical callable signature identities feed the same complete pipeline.
- [ ] WIP-0049 publishes one source-local artifact for every physical compiler module. Seventy-nine physical scalar-dependent modules now pass the counted archive-to-artifact path. The dependency-free loop-body opcode and layout authorities are part of that prefix. Fifty-five consume direct imported scalar products after imports are removed from the retained module source. Each artifact is retained under its module owner in the immutable body archive before the ordered prefix matches stage 0 byte for byte. Thirteen more physical modules compile against copied callable names, frozen primitive types, and packed dependency rows. Six retain signature-only stubs. WIP-0141 routes three assignment-call width products directly. WIP-0142 routes three void-call form and width products directly. WIP-0143 routes `EarlyComparisonForms.w` directly. The eleventh compiles `VoidCallOperands.w` after source validity becomes an explicit gap and packed digits become prior locals. The twelfth compiles `HelperResultKinds.w` after signed and nonsigned local-return tests become disjoint call guards. The thirteenth compiles `AssignmentCallOperands.w` after bounded packed traversal becomes tail recursion and call results bind before branch returns. Those intermediate products enter the same archive after the comparable prefix. `VoidCallSyntax.w` adds one direct imported structured product, yielding 97 framed artifacts. `CoreParsing.w` is the first artifact in that archive built directly from structured source products instead of projected source or signature stubs. The reversible `ReversibleTokenCoordinates.w` follows with its exact effect and proof products. `EarlyReturnKinds.w` now follows the same direct route after WIP-0135 carries signed constant children through an exact value column. WIP-0136 then routes `InstructionForms.w` with a signed literal child and later direct conditions. WIP-0137 routes `HelperSignatures.w` from exact helper-ABI constants. WIP-0138 routes `BorrowedIntrinsicShapes.w` and completes the comparable set without parser projection. WIP-0139 then separates local calls from imported structured relocations and preserves imported loan types. WIP-0140 uses that path for `VoidCallSyntax.w` and appends one imported relocation frame. WIP-0141 moves the three assignment-call width products to the same direct imported boundary. WIP-0142 follows with three void-call form and width products. WIP-0143 follows with the early-comparison form product. Decoded calls publish cross-owner relocation rows carrying the target WIP-0045 signature identity while recursive stub calls remain local. Every physical relocation identity resolves uniquely through the complete callable identity hash back to its callable product row. Every selected artifact is also decoded through `CompiledFunctionProducts.w`. Exact source-local function and instruction prefixes pass `retainLocalFunctionProduct`, excluding signature stubs and compiler-added library entries. A second bounded lifetime reads the immutable archive. An eight-byte `WPF1` footer binds the version, product count, and relocation count before it revalidates owner, length, and local-function framing, then appends every nonempty prefix through `CountedFunctionProducts.w`. The resulting closure function and instruction extents match stage 0 exactly. Six-byte relocation frames identify the source product, local instruction, target owner, and target-local function. The second lifetime validates every frame and call opcode before publishing numeric closure function rows. `emitResolvedLinkedInstructionCodeAt` then copies closure-ordered instructions from the immutable artifacts and writes only validated final call operands. The current physical subset emits 200,384 code bytes across 233 functions and 8,556 instructions. Its 5,987 primitive local-type rows then pass `LinkedLocalTypes.w`. `CompiledStringProducts.w` validates 443 source-local strings, `LinkedStringSection.w` sorts and deduplicates them to 347 final rows, and retained function-name prefixes resolve to those rows. `LinkedFunctionSection.w` emits exact descriptors, names, code ranges, parameter counts, local counts, and type windows. One retained synthetic library entry gives the subset a valid root. `AtomicLinkedContainer.w` stages and verifies a 253,664-byte classical artifact with canonical manifest, string, empty global, empty aggregate, function, and code sections. The second lifetime drops its source and product windows before it hashes and publishes the verified container natively. Two independent runs produce identical bytes and the same SHA-256 identity is `2d078ef722d6cc916a7a8649492f9f0871efeb507d96abd32e1bf971497268ca`. The independent stage-0 reader accepts all 233 functions, and the synthetic library entry executes to `HALT`. A malformed relocation owner traps before numeric targets, code, or publication. This is a complete executable container for the physical subset, not final-artifact equality for the compiler closure. Publication still needs to cover the remaining closure.
- [ ] The complete physical compiler closure emits without dependency source.

## Rejected alternatives

**Concatenate canonical sections.** Source-local IDs and offsets overlap. Canonical fragments do not compose by byte concatenation.

**Patch stage-0 output.** That retains stage 0 as the linker and provides no native construction evidence.

**Decode into host objects.** Java objects are replaceable infrastructure and allocation order is not identity.

**Flatten source before emission.** That discards the product boundary and fails the purpose of WIP-0044.
