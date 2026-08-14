# WIP-0055: Source-ordered callable coordinate products

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler compiler, bytecode, and bootstrap maintainers |
| Created | 2026-08-14 |
| Updated | 2026-08-14 |
| Area | Self-hosting compiler, callable layout, local types, structured control flow |
| Depends on | WIP-0047, WIP-0052 |
| Supersedes | Distributed callable-local rebasing in WIP-0054 |
| Superseded by | None |

## Summary

Publish one source-ordered coordinate plan for every callable before code or local types are emitted. Direct statements, root loops, nested loops, calls, returns, and generated scratch locals consume that plan. Code and type emission must not derive physical local coordinates independently.

This is the next bounded step in WIP-0054. It is not a new frontend.

## Problem

The structured product path has exact products for one root loop and its nested descendants. It also composes direct statements before and after that root. Physical coordinates are still adjusted in several consumers:

- `StructuredSourceModuleCompiler.w` chooses loop frame bases and instruction starts.
- `LoopInstructionProducts.w` rebases body and condition operands.
- `LoopLocalTypeProducts.w` reconstructs frame and body local positions.
- `DirectStatementProducts.w` emits declaration, assertion, and return locals.
- `CallableSourceComposition.w` detects the resulting type window after emission.

That split is tolerable for one root loop. It is not an authority for sequential root loops. A later direct declaration can observe logical statement temporaries but not the physical frame inserted by an earlier loop. A later loop can then receive a different adjustment from its code, body types, direct assertions, or return slot. Loop table order cannot stand in for source order because child blocks need not be stored beside root statements.

Patching each consumer with another frame bias would preserve the bug class. The callable needs one measured layout product.

## Requirements

### Input products

The planner consumes only validated products:

- callable signature local types
- callable root block and source extent
- source-ordered statement rows
- resolved root and nested loop rows
- direct-statement local widths
- resolved body, call, aggregate, and ownership local widths
- exact instruction counts and byte extents

It does not reopen source and does not encode instructions.

### Source order

The planner orders products by callable owner and exact statement source coordinate. Local ordinals remain validation evidence. They are not a substitute for source coordinates.

For each callable, the planner walks the root statement stream. A root loop recursively walks its child statements before the next root statement. Sibling blocks retain source order. The planner visits a nested loop at its written position even when its loop row lives after a later root row.

### Local coordinates

The plan publishes, for every product:

- physical first local
- physical local count
- ordered local-type start and count
- callable-local maximum after the product

A loop frame contributes its exact five locals. Body and call products contribute their measured widths. Logical placeholder width, if any, is an explicit input field and is subtracted once. No consumer uses a private four-versus-five adjustment.

Parameters and locals allocated before a loop retain their coordinates. Products after a completed loop begin after every frame and body local retained by that loop. A trailing assertion begins at the exact prior maximum. A value return slot follows every retained direct, loop, call, and ownership local.

No callable may exceed 256 locals. No plan may exceed 64 callables, 4,096 statements, 256 loops, or four nested loop levels.

### Instruction coordinates

The same walk publishes callable-local instruction starts. Direct instruction widths, root-loop recursive widths, calls, implicit returns, and inverse windows enter one prefix sum. Branch targets and relocation instruction rows refer to these coordinates.

Code emission may validate the prefix. It may not recompute it.

### Atomicity

The planner validates complete coverage before copying one row to caller storage. It rejects:

- duplicate, detached, or overlapping statements
- loop rows not attached at their exact source statement
- a child visited twice or not visited
- a local overlap, gap, or type disagreement
- an instruction overlap, gap, or out-of-range target
- an unsupported result or product kind
- any bound violation

Failure leaves coordinate, code, type, relocation, and artifact outputs untouched.

## Migration

1. Add `CallableCoordinateProducts.w` with private staging rows.
2. Differentially plan the existing `CoreParsing.w` artifact without changing bytes.
3. Complete WIP-0056 so every statement supplies its measured logical and physical local extent.
4. Add a fixture with two sequential root loops, a nested loop in the first root, direct declarations between roots, a trailing assertion, and a value return.
5. Make loop code, loop types, direct statements, and callable composition consume the plan.
6. Add void and Boolean result slots plus implicit void returns.
7. Add call and relocation widths.
8. Remove private frame-bias and instruction-bias calculations.
9. Resume physical-module adoption in WIP-0054.

## Progress

- [x] WIP-0052 publishes exact root and nested loop code and type extents.
- [x] WIP-0054 composes one root structured window into a byte-identical `CoreParsing.w` artifact.
- [x] Root assertions contribute their exact four instructions to later loop targets.
- [x] `CallableCoordinateProducts.w` accepts up to 64 callables and 4,096 product rows, validates owners, exact source extents, strict parent containment, explicit logical and physical widths, product kinds, instruction counts, code lengths, and 256-local, 32,768-instruction, 262,144-byte, and 4,096-type ceilings before publication. It orders each callable by source coordinate rather than storage row. One private pass publishes physical local starts and ends, callable-local instruction starts, global code and type starts, exact extents, and callable totals. A deliberately shuffled two-root fixture includes a nested first root, direct work between roots, a trailing assertion, and a return. It publishes 30 contiguous locals, 31 instructions, and 736 code bytes. A logical gap or overlapping root extent leaves sentinel coordinate and callable rows untouched.
- [x] WIP-0056 now feeds parameter counts, exact logical statement rows, merged body, direct, and loop-frame widths, statement identities, source extents, and structural parents into `SourceCallableCoordinateProducts.w`. `StructuredSourceModuleCompiler.w` requires the shared plan before composition and publication. The physical `CoreParsing.w` product remains byte-identical to stage 0.
- [x] WIP-0056's sequential-root and nested-first fixture matches stage 0 byte for byte. It includes direct work between roots, a second-root update, a trailing assertion, and a value return. The existing two-callable `CoreParsing.w` product remains byte-identical.
- [x] Direct signed and Boolean returns publish the planned return slot and exact result type through the function descriptor. Unsupported direct return types fail before artifact publication.
- [ ] Void and inverse products consume the same plan. WIP-0057 owns call, relocation, and ownership coordinate products.
- [ ] Private frame and instruction bias calculations are deleted.

## Acceptance

- Code and local types consume one coordinate product.
- Two sequential root loops with a nested first loop have contiguous code and local-type windows.
- Direct statements between and after loops retain exact source order and physical locals.
- Parameters and pre-loop locals are never shifted.
- Trailing assertion and return slots follow the exact prior maximum.
- Reordered loop storage rows do not change the artifact.
- The complete fixture matches stage 0 byte for byte.
- Malformed input publishes no partial plan or artifact.
- Every maintained Wheeler source remains below the physical source and line limits.

## Rejected alternatives

### Add another consumer-local frame bias

Rejected. Code, types, assertions, and returns would still own different coordinate rules.

### Sort loop rows once and mutate them

Rejected. Loop storage order is an input detail. Child structure and source statement order are the semantic products.

### Reparse the callable

Rejected. WIP-0054 exists to remove source projection and parser retry from artifact construction.

## References

- [WIP-0047](WIP-0047-counted-native-callable-bytecode-products.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0057](WIP-0057-source-call-relocation-and-ownership-coordinate-products.md)
