# WIP-0056: Measured source statement local products

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-14 |
| Updated | 2026-08-14 |
| Area | Self-hosting compiler, source products, local types, structured control flow |
| Depends on | WIP-0052, WIP-0055 |
| Supersedes | Inferred statement widths in WIP-0054 |
| Superseded by | None |

## Summary

Publish the logical and physical local extent of every source statement as a first-class product. The callable coordinate planner consumes these extents. Loop code, direct code, local types, value references, and return slots then use the same statement coordinate.

## Problem

`SourceValueProducts.w` measures a statement's local width while it walks the source. It publishes named result locals and the final callable count, but discards each statement's start and width. Later products reconstruct the missing facts in incompatible ways.

`DirectStatementProducts.w` derives assertion and declaration starts through `localBaseAtOrdinal`. `LoopLocalTypeProducts.w` adds five locals for every prior loop. `StructuredSourceModuleCompiler.w` computes loop bases through another ordinal bias. Return slots come from the largest emitted loop type. These calculations happen after source products have already measured the answer.

Sequential roots expose the discrepancy. A simple root loop remains stable. A callable with a nested first root, a declaration between roots, a second root, a trailing assertion, and a value return can produce a one-local hole or a duplicate type row. Syntax-width and encoded-body formulas can disagree for buffer copy statements.

The coordinate planner must not guess around this. The producer that owns a width must publish it.

## Product

`SourceValueProducts.w` publishes two rows for every accepted statement:

- logical first local
- logical local width

The rows use the statement product index. Parameters remain signature products and do not masquerade as statements.

Resolved body products publish the physical width required by their selected instruction form. Direct statement products do the same for declarations, assertions, returns, and calls. Control products publish explicit frame width. A root or nested loop frame is five locals. A result return reserves one local. A control product with no frame publishes zero.

The callable planner joins these rows by statement identity and exact source coordinate. It publishes:

- physical first local
- physical end local
- local-type output start and count
- callable local count

A named value retains its defining statement and offset within that statement. Consumers map the pair through the coordinate product. They do not add a later loop count to a raw local number.

## Invariants

- Every accepted statement has one logical row and one physical-width row.
- Logical statement rows are contiguous in statement ordinal order.
- Physical rows are contiguous in source order.
- Every emitted local type belongs to one physical row.
- Exact emitted local-type counts cover every physical row.
- Parameters keep their signature coordinates.
- A value reference resolves through its defining statement, never through a callable-wide bias.
- A return slot is the physical row owned by the return statement.
- Storage order does not affect coordinates.
- Validation completes before caller rows change.

## Bounds

The product retains WIP-0055 limits:

- 64 callables
- 4,096 statements
- 256 locals per callable
- four nested loop levels
- 4,096 local-type rows

The producer uses fixed caller-provided rows. It does not allocate per statement and does not reopen dependency source.

## Migration

1. Extend source value products with exact per-statement logical starts and widths.
2. Bind resolved body and direct statement widths to the same statement identities.
3. Feed parameter counts and measured statement rows to `CallableCoordinateProducts.w`.
4. Replace `loopFrameBias` and `frameBiasForStatement` with planned physical starts.
5. Map every named operand through its defining statement and local offset.
6. Make return products own their slot.
7. Restore the sequential-root regression and compare the complete artifact with stage 0.
8. Delete ordinal bias helpers and largest-loop-type return inference.

## Progress

- [x] WIP-0055 publishes bounded source-ordered coordinate rows independently of storage order.
- [x] Existing loop and direct producers retain statement identities in their product rows.
- [x] `SourceValueProducts.w` now stages an 8,192-word statement-local table beside named values and callable counts. Each of up to 4,096 statement product rows retains the exact logical first local and width measured by the source walk. Publication copies all three products only after validation. The source-statement fixture pins parameter-relative declaration, return, and second-callable coordinates. Structured, aggregate, and resolved-loop consumers supply bounded rows without changing existing artifacts.
- [x] `ResolvedLoopBodyProducts.w` stages one physical-width row per source statement. Every accepted direct body row records `loopBodyLocalCount`, while nested conditional controls record their exact one- or three-local width. Unsupported rows leave the 4,096-word caller table untouched. Declaration, Boolean, update, buffer, and nested-control fixtures pin the output.
- [x] `DirectStatementProducts.w` preserves resolved-body width rows in private staging, adds exact root declaration, assertion, and return type counts by statement identity, and publishes the merged table only with complete direct code and type products. The physical `CoreParsing.w` fixture verifies every direct row against its emitted type extent while retaining byte equality.
- [x] `SourceLoopProducts.w` atomically joins every loop owner and ordinal back to one structural statement, preserves prior body and direct widths, and assigns the canonical five-local frame width. The physical `CoreParsing.w` fixture validates the complete join before artifact emission.
- [x] `LoopCallProducts.w` publishes one physical local width per call beside code, type, and relocation products. It atomically merges each width into the call's exact statement row while preserving earlier widths. Zero-argument void calls retain width zero. Value calls reserve their result pair, and one- through seven-argument calls include both evaluation and transfer rows. Invalid statements, targets, or argument types leave both call and statement widths untouched.
- [ ] Source-call and ownership products bind exact statement physical widths.
- [x] `SourceCallableCoordinateProducts.w` adapts measured statement rows to WIP-0055's storage-order-independent planner. Structured artifact publication now requires a valid complete coordinate plan, and the physical `CoreParsing.w` fixture retains byte equality. Code, types, and operands do not yet consume the planned starts.
- [x] `StructuredSourceModuleCompiler.w` now seeds logical widths, applies measured body and loop-frame widths, plans physical starts before loop emission, and takes every root and nested loop base from the statement coordinate product. The former callable-wide `loopFrameBias` calculation is deleted. Loop code and loop local types retain byte equality for `CoreParsing.w` and the structured comparison fixture.
- [x] `DirectStatementProducts.w` maps declaration temporaries, prior named sources, assertion opcodes and operands, return sources, return slots, and emitted type rows through planned statement starts. `StructuredSourceModuleCompiler.w` maps every loop-condition local through its defining statement before loop emission. `LoopLocalTypeProducts.w` takes body and nested-control starts directly and no longer counts prior loops. Existing physical artifacts remain byte-identical.
- [x] `LoopInstructionProducts.w` corrects each provisional body window against its planned statement start after structural loop-frame rebasing. The correction covers embedded opcode locals, scalar operands, and every packed buffer operand without moving parameters below the containing loop boundary.
- [x] A nested first root followed by a second root emits the exact stage-0 artifact. The fixture covers second-root conditions, updates, scratch locals, local types, a trailing assertion, and the value return while the existing two-callable `CoreParsing.w` artifact remains byte-identical.
- [ ] Source calls and ownership rows consume planned starts.
- [x] The sequential-root regression matches stage 0 byte for byte.
- [ ] Ordinal frame biases and inferred return maxima are deleted.

## Acceptance

- A nested first root followed by a direct declaration and second root has no local gap or overlap.
- A trailing assertion and value return use planned locals.
- Indexed word, byte, byte-view, and summed-offset statements cover exactly their emitted type rows.
- Reordered loop and statement storage rows do not change bytes.
- Malformed widths leave coordinate, code, type, and artifact outputs untouched.
- The existing `CoreParsing.w` artifact remains byte-identical.

## Rejected alternatives

### Infer widths from named values

Rejected. Assertions, updates, frames, returns, and scratch locals need not define a name.

### Count prior loops in each consumer

Rejected. It duplicates source order and fails when nested and sequential roots interleave with direct statements.

### Fill type holes during composition

Rejected. Composition cannot invent the type, owner, instruction, or provenance of a missing local.

## References

- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0055](WIP-0055-source-ordered-callable-coordinate-products.md)
