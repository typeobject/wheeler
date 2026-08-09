# WIP-0050: Native aggregate source lowering

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler compiler, aggregate, ownership, bytecode, and bootstrap maintainers |
| Created | 2026-08-09 |
| Updated | 2026-08-09 |
| Area | Self-hosting, aggregate lowering, ownership, relocation, compiler products |
| Depends on | WIP-0013, WIP-0028, WIP-0046, WIP-0047, WIP-0049 |
| Supersedes | None |
| Superseded by | None |

## Summary

Lower record, variant, fixed-array, and slice source into source-local semantic products without importing dependency source. Resolve local and imported nominal references to WIP-0046 aggregate identities. Compile aggregate instructions into WIP-0047 body products, then discard all source ranges and generated scaffolding.

This work is split from WIP-0049 because aggregate parsing, descriptor construction, ownership projection, and temporary nominal declarations have different failure boundaries. WIP-0049 still owns module compilation. This proposal owns aggregate semantic products and canonical emission. [WIP-0051](WIP-0051-native-aggregate-frontend-products.md) owns publication of primitive-frontend values and splice coordinates.

## Source boundary

A module may read its own source while its `ActiveSourceSlots.w` lease is live. It may also read counted public products from direct dependencies. It may not read a dependency source range, body, token stream, or host `Program` object.

Source-local ranges are temporary parse evidence. They do not cross an import edge and do not enter aggregate, callable-body, graph, or artifact identity.

## Source aggregate products

`SourceAggregateProducts.w` scans canonical source with the native Wheeler scanner. Comments and documentation are removed before declaration matching. The aggregate product has these fixed columns:

1. kind
2. name start
3. name length
4. first case
5. case count
6. first member
7. member count
8. visibility
9. declaration start
10. structural element kind
11. structural element type
12. fixed-array length
13. declaration end

Variant cases carry their aggregate owner, name range, first member, and member count. Members carry their aggregate owner, optional case owner, name range, type range, resolved type kind, and primitive code or source-local aggregate row.

The first profile admits sixty-four aggregate declarations, 128 variant cases, and 256 members per module. Duplicate aggregate, case, or member names, malformed members, unterminated declarations, unresolved types, and a bound breach fail before one caller row changes.

Fixed arrays and slices shall publish structural descriptor products rather than invented declarations.

## Type resolution

Each source-local type range resolves to one of:

- a primitive type code
- a source-local aggregate row
- one public aggregate product from a direct dependency
- one locked external aggregate product

Unqualified matching follows local shadowing and direct-import ambiguity rules. Qualified matching binds the written dependency rank before name and kind matching. Equal identities do not cure ambiguity.

Resolution publishes a stable aggregate identity and kind. No final numeric descriptor ID is available at this phase.

## Imported nominal scaffolding

The temporary compiler source may need a declaration so the source-local type checker can admit an imported nominal signature. Such declarations use the grammar-valid reserved name `WheelerNominal<product-row>`. The internal `__wheeler_nominal_` namespace is also unavailable to authored declarations. Generated declarations carry only the shape needed for type checking.

Each generated descriptor publishes a projection from its temporary owner, kind, and source-local ID to the imported aggregate identity. WIP-0048 resolves that identity to the final descriptor row. Temporary descriptors, members, cases, strings, functions, and instructions are excluded before body archival.

Generated names and allocation offsets do not enter an identity. A local use of the reserved prefix fails before source or output mutation.

## Instruction lowering

The native compiler core shall lower:

- record construction and field projection
- fixed-array construction and indexing
- slice construction and indexing
- variant construction, case tests, and payload projection
- ownership move, loan, release, and drop events for aggregate values

Instruction operands retain source-local aggregate references until `AggregateOperandRelocations.w` publishes stable target identities. Code rewriting remains atomic under `IdentityRelocationEmitter.w`.

`InstructionForms.w` remains the sole operand-count owner. Unknown aggregate opcodes fail rather than passing through as opaque instructions.

## Ownership

Aggregate ownership products name the aggregate projection behind each owner-bearing local. Shared and mutable loans are nonescaping. Moves consume the source owner. Releases close the exact loan. Function exit requires every owned aggregate local to be moved, returned, or dropped.

`AggregateLoanVerifier.w` checks the counted event stream before body identity publication. A generated scaffolding owner cannot appear in the retained stream.

## Bounds

The first profile retains existing limits:

- sixty-four source-local aggregates per module
- 128 variant cases per module
- 256 members per module
- 4,096 closure aggregates
- 8,192 closure cases
- 16,384 closure members
- 256 locals per source-local function
- 4,096 instructions per source-local module

Scratch token, declaration, descriptor, and projection windows are independently bounded. No limit is inferred from another buffer's capacity.

## Implementation status

- [x] `SourceAggregateProducts.w` publishes atomic record, variant, case, and member source products. `SourceAggregateSyntax.w` owns shared bounded declaration, member, range, and structural-type parsing in a separate source-layout directory.
- [x] Native evidence covers public and private records, variants, empty and populated cases, mutually recursive record and variant types, exact source ranges, and malformed-member nonpublication. `projectSourceAggregateLayouts` converts validated source products into descriptor-compatible local aggregate, case, member, structural-array, and source-string rows. Recursive member codes use per-kind local descriptor IDs. `appendProjectedAggregateLayouts` validates and rebases those rows directly into counted closure windows without a temporary artifact. `SourceAggregateStrings.w` validates every ASCII name range, copies the bytes into bounded immutable string storage, and publishes counted ranks and extents before the local source is released.
- [x] Primitive and recursive local nominal member types resolve before source release. `LocalNominalReferences.w` also indexes local nominal uses in callable signatures, parameters, bodies, and constructors while excluding aggregate declarations. `LocalNominalCarriers.w` rewrites those ranges to compact signed carriers and retains old-to-new coordinates. `LocalNominalCarrierProjections.w` separates value, constructor, and signature uses and binds value carriers to exact function-local coordinates. `CountedLocalNominalCarriers.w` carries value projections into closure coordinates for final local-type rewriting. `AggregateExpressionProjection.w` replaces outer aggregate expressions with offset-stable scalar placeholders before primitive compilation. Nested expressions share one placeholder statement. `AggregatePlaceholderPlacements.w` derives exact splice ordinals from compiled zero-local placeholders. `PrimitivePlaceholderProjection.w` then validates and removes those instructions before aggregate composition and adjusts function lengths and subsequent splice ordinals. `AggregateExpressionTemporaries.w` gives nested operations source-ordered locals while retaining each named outer destination. `SourceCallableTypeProducts.w` freezes primitive and local nominal signature types before temporary carrier source is discarded. Duplicate cases and unresolved types publish nothing.
- [x] Scalar fixed-array member types publish deduplicated structural descriptors in encounter order. Invalid lengths, nonscalar elements, and nonescaping slice members publish nothing.
- [x] `AggregateSourceProjection.w` blanks validated local record and variant declarations at stable offsets before primitive body compilation. Newlines remain in place, call offsets do not move, and invalid ranges publish nothing.
- [ ] Source products cover nonescaping slice use outside aggregate storage.
- [x] `ImportedNominalProducts.w` resolves qualified or unqualified nominal names from public WIP-0046 aggregate rows and counted artifact-string products. Qualification binds dependency rank. Equal unqualified matches remain ambiguous, and malformed string products fail closed.
- [ ] The native compiler core derives aggregate locals and splice coordinates from primitive-frontend products as specified by WIP-0051.
- [x] Source-projected recursive records, variants, and fixed arrays pass through counted layout and string products into `LinkedAggregateSections.w`. Native evidence checks final record fields, recursive descriptor codes, variant cases and payloads, and structural-array descriptors without a temporary aggregate artifact.
- [x] `SourceAggregateOperations.w` indexes nominal and variant constructors, field and indexed projections, and slice constructors in source order. It publishes bounded expression, type, selector, index, and top-level argument ranges only after every aggregate expression is framed. Nested calls and indexes do not split arguments. Nested operations are normalized into evaluation postorder before publication. Fixed-array type brackets are not mistaken for projections.
- [x] `AggregateConstructorTargets.w` resolves local record, variant-case, and fixed-array constructor ranges against counted source products. Exact name and kind matches publish descriptor and case coordinates atomically.
- [x] `AggregateProjectionTargets.w` validates explicit owner aggregate and variant-case rows before resolving record fields, variant payloads, or fixed-array indexes. Member names resolve only inside the selected owner window.
- [x] `AggregateResolvedOperands.w` joins ordered argument locals, destination locals, owner locals, descriptor rows, case rows, and member rows. Constructor arguments must occupy contiguous evaluated locals. Indexed and slice forms require exact arity. Failure leaves resolved rows untouched.
- [x] `AggregateInstructionComposition.w` merges primitive and aggregate instructions at counted function, direction, and ordinal splice points. It publishes adjusted function lengths, source-artifact selectors, and one canonical instruction order only after both artifacts and every placement validate. `appendSupplementalBodyArtifact` retains one aggregate code product beside the module artifact. `appendComposedFunctionProduct` carries both ranks into closure instruction rows, and `LinkedInstructionCode.w` emits their merged bytes.
- [x] `ResolvedAggregateOperations.w` joins each source syntax row to an exact resolved opcode and operand row. The source kind constrains the admitted opcode before canonical rows or output bytes are allocated.
- [x] `AggregateCodegen.w` emits canonical record, variant, fixed-array, and slice construction and projection forms. `AggregateInstructionProducts.w` validates a complete counted operation window and lowers it to canonical bytes. Native evidence drives indexed source expressions through resolved products and every canonical form. Record construction and field projection match stage 0. Invalid operands or unknown aggregate opcodes fail before a header byte is written.
- [x] `compileAggregateSourceModuleProductWithImports` projects declarations and aggregate expressions, rewrites classified local nominal carriers, validates imported nominal scaffolding and projections, then compiles primitive body portions through nonretained signed carriers. It withholds nominal and exact function-local carrier projections until compilation succeeds. The carrier artifact contains no generated descriptor. Resolved aggregate instructions now compose with primitive instruction rows through source-artifact selectors. The archive retains both products, counted closure rows retain both ranks, and final linked code emits their canonical order. Complete source-product compilation must derive local and splice products from the primitive frontend rather than fixture projections.
- [x] `ImportedNominalStubs.w` emits collision-checked record and variant declarations in target-row order and publishes owner-scoped temporary source-code projections. Input arrival order cannot change names, descriptor order, or projections.
- [x] `ImportedNominalReferences.w` rewrites sorted resolved type ranges after imported-call rewriting, accounts for every prior call-name width change, and inserts declarations before their first use. Its bounded-core projection uses nonretained signed carriers for primitive body compilation. An overlap, stale transformed range, kind mismatch, duplicate namespace, or capacity failure publishes nothing.
- [x] `AggregateOwnerProjections.w` maps create, move, loan, release, and drop event locals to unique aggregate and member rows. A move requires identical source and destination projections, and failure leaves caller rows untouched.
- [x] `LinkedLocalTypes.w` consumes temporary owner, source-code, and aggregate-row projections before final descriptor emission. `ImportedNominalCarrierProjections.w` adds exact module, local-function, and local-type coordinates for nonretained signed carriers. The linker validates every coordinate and signed source slot before replacing it with the target record or variant descriptor. Missing, duplicate, or kind-inconsistent projections fail before publication.
- [x] `AggregateOperandProjections.w` maps temporary owner, kind, and type IDs to aggregate rows and stable product identities. Duplicate projections leave relocation rows and identities untouched.
- [x] Counted aggregate archival accepts exact generated suffix counts, validates every retained case and member range before mutation, and excludes the generated aggregate, case, and member suffixes. Native evidence covers successful prefix retention and failure before publication.
- [ ] Aggregate-aware source-local artifacts match stage 0 byte for byte under the WIP-0051 acceptance suite.

## Acceptance

- Recursive records and mutually recursive record and variant graphs compile.
- Imported nominal signatures compile without dependency source.
- Local and imported aggregate instructions relocate through stable identities.
- Aggregate owner, move, loan, release, and drop products match stage 0.
- Invalid syntax, ambiguity, privacy, kind, ownership, or capacity leaves publication untouched.
- No retained row names a temporary descriptor or generated source range.
- No authored file reaches 1,000 lines.
- No Wheeler source directory exceeds ten files.

[WIP-0051](WIP-0051-native-aggregate-frontend-products.md) specifies frontend value publication, primitive source projection, and nested-expression postorder.

## Rejected alternatives

### Copy dependency declarations

Rejected. Dependency source is not a semantic product, even when only the header is copied.

### Retain temporary descriptors

Rejected. Scaffolding exists to satisfy a source-local checker. It has no package identity and cannot survive final ID assignment.

### Patch descriptor IDs after emission

Rejected. Stable identities resolve before canonical emission. Numeric patching would make allocation order observable.

### Treat every nominal as a record

Rejected. Record, variant, array, and slice kinds have distinct bytecode descriptors and ownership behavior.
