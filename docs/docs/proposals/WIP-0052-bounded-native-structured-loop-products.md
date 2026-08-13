# WIP-0052: Bounded native structured-loop products

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler compiler, bytecode, verification, and bootstrap maintainers |
| Created | 2026-08-11 |
| Updated | 2026-08-11 |
| Area | Self-hosting, structured control flow, callable products, bootstrap |
| Depends on | WIP-0013, WIP-0038, WIP-0047, WIP-0049 |
| Supersedes | None |
| Superseded by | None |

## Summary

Compile bounded multi-statement `while` bodies from source-local callable products. The current native profile lowers one closed local update loop. Physical compiler modules also use loops whose bodies read buffers, write buffers, call helpers, branch, and update several locals. Those loops need counted block products, exact branch targets, and ordinary typed instructions.

The output remains canonical `.wbc` 1.0. A loop product is temporary lowering evidence, not another IR.

## Problem

A source parser that recognizes a loop header but only admits one fixed update body is not a structured-control-flow compiler. It rejects `CoreParsing.w`, `ManifestSyntax.w`, package token utilities, product archives, aggregate linkers, and other physical modules even when every instruction in the body is already supported.

Refactoring each loop into recursion hides the missing compiler feature. It also changes stack use, callable identities, cost evidence, and bytecode shape. Physical source must not be rewritten to fit an incomplete bootstrap parser.

The native compiler needs one bounded representation for nested source blocks. It must preserve source order and emit the same branch layout as stage 0.

## Scope

This proposal owns source-local classical loops with:

- one Boolean loop condition accepted by the bounded scalar profile
- one required static `limit`
- zero through 64 statements in the body
- local declarations, assignments, updates, calls, assertions, and supported intrinsics
- `if` guards whose branches remain inside the loop body
- at most four nested structured blocks

This proposal does not add `break`, `continue`, exceptions, unbounded loops, dynamic limits, reversible loop syntax, or coherent control flow. WIP-0035 owns reversible and coherent control.

## Products

One loop row contains:

1. owner-local function row
2. parent block row
3. source statement ordinal
4. condition product row
5. source range of the static iteration limit
6. first body statement row
7. body statement count
8. nesting depth

Block indexing first publishes the callable-local owner, parent block, depth, source extent, and local ordinal. Loop resolution joins each accepted block to its first child statement and child count. Statement rows retain their existing typed opcode, operand, ownership, call, and aggregate products. A loop does not copy or flatten its body.

Source extents diagnose malformed nesting, overlapping callable bodies, and detached roots. They do not enter final identity. Canonical instructions, limits, types, ownership events, relocation identities, and proof products already bind retained semantics.

## Validation order

For one callable:

1. scan braces and publish no rows
2. validate balanced source blocks and exact loop limits
3. assign function-local block and statement ordinals
4. resolve every condition, body statement, call, and owner product
5. compute forward and inverse instruction extents
6. compute and validate branch targets
7. publish block and loop rows atomically
8. emit canonical instructions

No output byte, artifact rank, relocation row, or identity may publish before step seven succeeds.

## Canonical lowering

Forward code evaluates the condition, checks the static iteration bound, enters the body, and branches back through the canonical loop instruction forms. Body instructions retain source order. Nested blocks use precomputed instruction windows. No emitter searches source text or emitted bytes for a target.

The inverse path exists only when every body instruction and the loop relation have an admitted inverse. Classical irreversible helpers keep ordinary history semantics. An unsupported inverse fails before either direction publishes.

Stage 0 and the native compiler must produce identical function descriptors, local types, instruction order, operands, branch targets, and code padding.

## Bounds

The recovery profile admits per module:

- 64 local functions
- 4,096 source statements
- 1,024 structured blocks
- 256 loops
- 64 direct statements per loop body
- four nested structured blocks
- a loop limit from one through 16,777,216
- 4,096 final source-local instructions

The block and loop bounds are independent. Multiplying a body count by a limit never allocates products or unrolls code.

## Failure behavior

Compilation fails before publication for:

- a missing, zero, negative, nonconstant, or excessive limit
- an unbalanced or overlapping block extent
- a body statement owned by two blocks
- a branch target outside the owning function
- a condition that is not Boolean
- a body local used before definition
- a loan escaping through a back edge
- an ownership state that differs across loop entry and back edge
- unsupported nested control flow
- any statement, block, loop, local, or instruction bound breach

Scratch rows and source coordinates have no identity. Failure leaves artifact bytes, product counts, branch rows, ownership rows, and identities untouched.

## Implementation split

### Block indexing

`SourceStatementProducts.w` publishes balanced callable-local block rows and parent links. Focused fixtures cover an empty body, four nested blocks, a nonzero archive origin, excess depth, stale and overlapping body extents, a detached root block, and atomic failure. Adjacent-loop syntax remains with loop statement indexing.

### Structural loop indexing

`SourceLoopProducts.w` consumes validated block rows while the callable source lease is live. It publishes block-grouped direct statement windows, lexical function ordinals, signed less-than condition ranges, literal or identifier limit ranges, loop parents, body windows, and depths in one transaction. Empty through sixty-four-statement bodies work. Literal bounds fail here. Named bounds remain unresolved until the module-symbol join. A detached or reused child block, forged parent, invalid condition, zero or excessive literal limit, or sixty-fifth body statement leaves every caller row untouched.

### Loop resolution

`ResolvedLoopProducts.w` consumes structural conditions, callable values, and counted module symbols. It resolves signed literal or uniquely named prior-local operands, then binds each limit to a positive literal or one unique resolved signed constant owned by the current module. Archive-relative symbol names are rebased before comparison. Missing, ambiguous, unresolved, Boolean, zero, negative, or excessive named bounds fail before publication. The resolver preserves parent and body windows and publishes source-independent condition and loop rows atomically.

`ResolvedLoopBodyProducts.w` resolves direct signed declarations, assignments, literal equality and less-than assertions, and checked local updates from the block-grouped statement window. Named operands bind one visible callable value. Body scratch locals form one monotonic window; later statements cannot reuse an earlier statement's temporaries. It records exact local bases, closed opcodes, operand forms, and operand values in one transaction. Unsupported statements and ambiguous names publish nothing. Calls, ownership, nested blocks, and back-edge joins remain separate.

### Canonical emission

`LoopInstructionProducts.w` consumes resolved loop and direct-body products. It emits canonical limit, iteration, comparison, branch, body, and back-edge instructions after a complete extent pass. Body-local and named-operand coordinates rebase into a private staging table; published rows stay immutable. `LoopLocalTypeProducts.w` publishes the corresponding signed and Boolean local suffix. `InstructionForms.w` remains the operand-count owner. Forward branch targets match stage 0 byte for byte for the admitted declaration, literal-assertion, assignment, and update body profile. `LoopCodegen.w` still owns the older fixed one-update parser path.

### Physical closure adoption

Adoption starts with `CoreParsing.w`, whose two loops compact and shift token columns. It then covers `ManifestSyntax.w`, `CompiledBodyArchive.w`, package token utilities, and the remaining physical modules in dependency order.

## Implementation status

- [x] Closed single-update local loops have canonical source identities, resolution, local types, instruction forms, and code generation.
- [x] Physical closure probes identify multi-statement loop bodies as a repeated source-product boundary.
- [x] `SourceStatementProducts.w` publishes source-independent function owners, parent rows, depths, extents, and local ordinals atomically for empty through four-level nested blocks. Excess depth, stale or overlapping callable extents, and detached root blocks preserve caller rows.
- [x] `SourceLoopProducts.w` publishes exact structural statement, signed condition range, literal or named limit range, body window, parent, and depth rows. Empty, adjacent, and sixty-four-statement bodies pass. Invalid literal bounds and forged block graphs publish nothing.
- [x] `ResolvedLoopProducts.w` joins signed literal and unique prior-local condition operands to exact local rows and rejects use before definition, ambiguity, wrong type spelling, invalid reversals, and forged windows without publication.
- [x] Resolved loop products join named compile-time limits from counted module symbols. Literal and named bounds publish the same source-independent value. Malformed symbol products publish nothing.
- [x] `ResolvedLoopBodyProducts.w` publishes direct signed declaration, assignment, literal equality and less-than assertion, and checked local-update flow with exact monotonic local bases. Named sources require one visible prior value. Unsupported or ambiguous body rows publish nothing.
- [ ] Resolved loop products join calls, ownership state, nested blocks, and back edges.
- [x] `LoopLocalTypeProducts.w` publishes exact signed and Boolean loop-frame and direct-body local types. The admitted suffix matches stage 0.
- [ ] Ownership, loan, call, and relocation joins validate loop back edges.
- [x] `LoopInstructionProducts.w` emits canonical forward instruction windows and exact branch targets for direct signed declarations, literal assertions, assignments, and checked local updates without mutating resolved products. The admitted fixture matches stage 0 byte for byte.
- [ ] Canonical call, ownership, nested-block, and inverse instruction windows match stage 0.
- [ ] `CoreParsing.w` compiles byte for byte from its immutable archive range.
- [ ] Every physical multi-statement loop module compiles without dependency source.

## Acceptance

- Empty through 64-statement loop bodies match stage 0 byte for byte.
- Four nested structured blocks match stage 0 byte for byte.
- Calls, buffer reads, buffer writes, assertions, and local updates work in one loop body.
- Invalid limits, blocks, types, ownership states, and branch extents publish nothing.
- Loop products survive source release and contain no dependency source.
- `CoreParsing.w` enters the retained physical product set.
- No compatibility parser or recursive source rewrite remains.

## Rejected alternatives

### Rewrite physical loops as recursion

Rejected. It changes semantics and hides an incomplete compiler behind source churn.

### Unroll to the static limit

Rejected. The limit is a runtime guard, not a code-size multiplier.

### Recover blocks from emitted jumps

Rejected. Byte offsets are output, not semantic source products.

### Retain a second control-flow IR

Rejected. Block rows are temporary lowering evidence. Canonical `.wbc` remains the sole semantic IR.

## References

- [WIP-0047: Counted native callable bytecode products](WIP-0047-counted-native-callable-bytecode-products.md)
- [WIP-0049: Bounded native source-product compilation](WIP-0049-bounded-native-source-product-compilation.md)
- [Bootstrap evidence](../reference/bootstrap.md)
