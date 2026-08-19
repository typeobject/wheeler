# WIP-0051: Native aggregate frontend products

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler compiler, aggregate, bytecode, and bootstrap maintainers |
| Created | 2026-08-09 |
| Updated | 2026-08-09 |
| Area | Self-hosting, frontend products, aggregate lowering, bootstrap |
| Depends on | WIP-0045, WIP-0047, WIP-0049, WIP-0050 |
| Supersedes | None |
| Superseded by | None |

## Summary

Publish the primitive frontend values and statement coordinates needed to lower aggregate source without fixture projections. WIP-0050 owns aggregate syntax, descriptors, resolved operands, code products, composition, archival, and final emission. This proposal owns the remaining join between authored source and those products.

The join is temporary compiler evidence. Canonical `.wbc` 1.0 remains the only retained semantic IR.

## Problem

Aggregate source lowering has counted products for declarations, constructors, arguments, fields, indexes, owners, operands, instructions, splice composition, archive ranks, and final linked bytes. Complete callable-owned frontend products now derive local registers before source release. Decoded primitive placeholders derive exact splice coordinates after temporary source compilation. Neither coordinate comes from fixture data.

Inferring registers from emitted byte offsets is not acceptable. It couples semantic lowering to an accidental encoder layout and fails when one source expression creates several temporaries. Re-reading dependency source is also forbidden.

## Frontend value product

Each source-local frontend value row contains:

1. local function row
2. name range
3. source-local register
4. definition source ordinal
5. definition range
6. resolved local type product
7. ownership mode

The name range may be absent for a compiler temporary. A temporary still has one exact definition range. Parameters precede body definitions in source order. Two live values with the same name are legal only when their definition ordinals establish unambiguous shadowing.

The first profile admits 1,024 frontend values per module and 256 registers per function. Validation of every function, register, type, mode, and source range precedes publication.

## Statement product

Each primitive statement row contains:

1. local function row
2. forward or inverse direction
3. source ordinal
4. splice ordinal in the projected primitive body
5. source range

Source ordinal resolves visibility. Splice ordinal orders final instructions. They are not interchangeable. Removing one aggregate statement from the primitive projection changes later splice ordinals but does not change source visibility.

A source expression belongs to exactly one statement row. Nested aggregate expressions additionally carry an evaluation parent and are emitted in postorder. Equal splice ordinals preserve that postorder.

## Primitive projection

Before primitive compilation, the compiler projects aggregate-only statements out of the leased source. It may replace a mixed expression with a typed carrier only when the frontend publishes the carrier's exact value and definition products. The projection preserves newlines and publishes a monotone old-to-new offset map.

Local nominal types use nonretained carrier types during primitive checking. Imported carriers continue to use the exact module, function, and local-type coordinates from WIP-0050. Source-local carriers receive equivalent coordinates. Neither carrier kind enters retained local types, identities, or final code.

The primitive compiler publishes value and statement rows from the projected source in the same transaction as its body artifact. Failure withholds the artifact, rows, aggregate code, archive ranks, and body identity.

## Binding

`AggregateFrontendBindings.w` joins aggregate expression and argument ranges to frontend products. It requires:

- one containing statement per operation
- one exact definition value per operation result
- one latest visible named value or exact temporary per argument
- one latest visible owner for field and indexed projections
- separate source and splice ordinals

The join publishes destination locals, owner locals, argument locals, and placement rows atomically. WIP-0050 then owns descriptor resolution, operand assembly, canonical code generation, composition, and linking.

## Nested expressions

Aggregate operation indexing shall visit nested operands before their consumers. For example, `new Token(new Span(3, 8), true)` emits the `Span` construction before the `Token` construction. The outer argument row names the inner result value.

Field chains follow the same rule. `value.span.end` emits the `span` projection before the `end` projection. A parser that records only the lexical outer operation is incomplete.

## Identity and source release

Frontend source ranges, names, source ordinals, splice ordinals, and carrier registers do not enter callable identity directly. Final local types, canonical instruction bytes, ownership products, relocation identities, and dependency identities already bind the retained semantics.

Source release requires all aggregate values and statement rows to be copied into source-independent products. No later phase may consult a token stream or source allocation.

## Bounds

The first profile admits:

- 64 local functions per module
- 256 locals per function
- 1,024 frontend values per module
- 4,096 primitive statements per module
- 256 aggregate operations per module
- 1,024 aggregate arguments per module
- 4,096 final source-local instructions

A bound breach publishes nothing. No buffer capacity implies another count.

## Implementation status

- [x] `AggregateFrontendBindings.w` validates counted frontend value and statement rows, distinguishes source order from splice order, and publishes destination, owner, argument, and placement products atomically.
- [x] WIP-0050 composes, archives, and links primitive and aggregate code from two immutable artifact ranks.
- [x] `SourceStatementProducts.w` scans complete callable ranges into named parameter, statement-result, statement-range, and local-count rows atomically. It replaced the incremental primitive-frontend fixture once aggregate-aware compilation consumed the complete product directly. Exact splice ordinals are derived later from decoded placeholder instructions.
- [x] `compileAggregateSourceModuleProductWithImports` consumes counted aggregate operations, local references, and carrier projections while producing its primitive body artifact.
- [x] `AggregateExpressionTemporaries.w` appends source-ordered locals for nested operations while retaining the primitive frontend's named outer destination.
- [x] `AggregateFrontendBindings.w` derives operation functions from exact destination value products rather than trusting statement fixtures.
- [x] `AggregatePlaceholderPlacements.w` derives splice ordinals from exact compiled zero-local placeholders instead of accepting fixture ordinals.
- [x] `SourceStatementProducts.w` derives callable-owned source ranges and ordinals in the aggregate-aware compilation transaction, including nominal declarations that the primitive grammar cannot parse before projection. It also publishes the source-independent block owner, parent, depth, extent, and local ordinal rows consumed by WIP-0052, rejecting intersecting callable ranges and malformed block roots before publication.
- [x] Aggregate-aware compilation publishes parameter, statement-result, nested-expression, and function-local-count products before classifying local nominal carriers. It derives destination, owner, argument, function, direction, and provisional placement rows in the same transaction. Local constructor descriptor and variant-case targets are resolved in the same transaction. Record and variant projection owners are joined from callable-local nominal products, then field and payload targets are resolved from counted member windows. Resolved operands and the exact supplemental instruction extent publish only after those joins pass. Primitive assignment lowering may place a zero in a temporary and move it into the named destination. Placeholder validation removes that exact pair, derives the true splice ordinal from decoded primitive instructions, and rejects any other bridge. The compiler then publishes the selector-driven composition only after staging and validating both artifacts. `AggregateCompiledCallableBodies.w` owns this transaction. The primitive compiler remains a small independent module and exposes only the exact-source compilation boundary. The complete source-product fixture covers record and variant construction, record fields, and variant payloads through that path. `AggregateIndexedOwners.w` joins fixed-array field results and directly typed callable values to exact structural descriptors before indexed projection. Duplicate structural descriptors fail before owner or value-row publication. Slice constructor destinations bind exact callable structural descriptors, and indexed slices select `SLICE_GET` through the same projection path. Missing or wrong-kind descriptors publish nothing. Caller-supplied carrier, local-coordinate, constructor-target, owner, projection-target, and resolved-operand fixtures no longer participate.
- [x] `LocalNominalReferences.w` indexes callable signature, parameter, local, and constructor uses of source-local record and variant names while excluding declaration bodies.
- [x] `LocalNominalCarriers.w` rewrites sorted local nominal ranges to compact signed carriers and publishes exact old-to-new coordinates without partial source mutation.
- [x] `LocalNominalCarrierProjections.w` classifies source-local carriers as value, constructor, or signature uses and binds value carriers to exact function-local coordinates atomically.
- [x] `CountedLocalNominalCarriers.w` converts value projections to closure coordinates, and `LinkedLocalTypes.w` rewrites the exact signed local slots to final descriptors.
- [x] Carrier classification now precedes rewriting, and constructor names inside projected aggregate expressions remain untouched.
- [x] `AggregateExpressionProjection.w` replaces each outer aggregate expression with one offset-stable scalar placeholder while suppressing nested expressions as one primitive statement.
- [x] `PrimitivePlaceholderProjection.w` removes one validated zero-local placeholder per aggregate statement, adjusts later splice ordinals and function lengths, and handles nested operations as one placeholder.
- [x] `SourceCallableTypeProducts.w` freezes primitive, local-record, and local-variant signature types before signed source carriers are compiled or discarded.
- [x] `AggregateSourceProjection.w` removes aggregate-only declarations from primitive compilation without moving newlines or following source offsets. Native evidence compares every projected byte and traps on overlapping declaration ranges before mutation.
- [x] `SourceAggregateOperations.w` normalizes nested constructors, field chains, and postfix slice indexes into evaluation postorder and remaps their argument owners.
- [x] Product and linker fixtures reproduce the complete stage-0 record-bearing artifact and its canonical aggregate sections byte for byte. Focused native fixtures cover variant construction and payloads, fixed-array construction and indexing, slice construction and indexing, field chains, and instruction ownership. Whole-artifact equality for every focused form remains part of physical-closure publication.
- [x] WIP-0173 publishes parsed and descriptor-compatible aggregate, case, member, and string rows through exact counts. WIP-0174 carries measured projected rows into counted closure staging.
- [x] WIP-0175 publishes normalized source operations, arguments, and resolved canonical operands through exact operation and argument counts.
- [ ] Every physical compiler module publishes frontend products without dependency source.

## Acceptance

- No test supplies destination, owner, argument, or splice rows by hand.
- Nested aggregate expressions lower in evaluation order.
- Primitive and aggregate products compose into one canonical function order.
- Final local types contain no carrier.
- Invalid ranges, shadowing, types, ownership, or placement publish nothing.
- Stage 0 and the native compiler emit byte-identical artifacts for the aggregate example set.
- The physical compiler closure compiles without dependency source.

## Rejected alternatives

### Recover registers from bytecode

Rejected. Encoder offsets are not semantic frontend products and do not identify removed expressions.

### Keep fixture projections in the compiler path

Rejected. Fixtures can test a join but cannot publish a physical module.

### Flatten aggregate source into primitive source

Rejected. Flattening discards nominal, ownership, and relocation semantics and reintroduces source concatenation.

### Retain source coordinates in `.wbc`

Rejected. Coordinates are temporary evidence and are unstable under canonical formatting and generated scaffolding.

## References

- [WIP-0049: Bounded native source-product compilation](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0050: Native aggregate source lowering](WIP-0050-native-aggregate-source-lowering.md)
- [WIP-0173: Sparse source-aggregate publication](WIP-0173-sparse-source-aggregate-publication.md)
- [WIP-0174: Sparse counted-aggregate projection](WIP-0174-sparse-counted-aggregate-projection.md)
- [WIP-0175: Sparse aggregate-operation publication](WIP-0175-sparse-aggregate-operation-publication.md)
- [Bootstrap evidence](../../public/reference/bootstrap.md)
