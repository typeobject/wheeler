# WIP-0067: Exact physical loop-value products

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-15 |
| Updated | 2026-08-15 |
| Area | Self-hosting compiler, loop products, local coordinates, bootstrap closure |
| Depends on | WIP-0052, WIP-0055, WIP-0056 |
| Supersedes | Inferred nested-loop local rebasing in the physical source-product path |
| Superseded by | None |

## Summary

Publish loop-body operands, nested conditions, and nested scratch windows in exact physical coordinates before code emission. The production emitter consumes those products without applying source-order bias guesses. Logical-coordinate mode remains only for isolated loop-product fixtures.

This split closes one part of WIP-0054. It does not own adoption of the remaining physical compiler modules.

## Problem

Resolved loop products originally carried callable-logical locals. `LoopInstructionProducts.w` then added five locals for every earlier loop frame and applied a second correction from a provisional statement start. The arithmetic worked for small fixtures. It failed when a callable mixed sequential root loops, indexed reads, nested controls, and values declared outside the current loop.

Storage order cannot answer which physical local defines a value. A later root loop may precede a low-numbered local. A nested condition may use a value produced by a body instruction whose private width differs from its logical width. Reapplying frame bias can move an already physical coordinate.

## Contract

`PhysicalLoopBodyProducts.w` receives closed statement, value, body, and nested-control products plus planned statement starts. It publishes one atomic coordinate view with these rules:

1. A parameter keeps its parameter local.
2. A root value uses its exact planned statement start and logical result offset.
3. A loop-body value uses the defining body's planned physical start and measured instruction-local width.
4. A packed buffer operand maps every owner, index, base, and value independently.
5. A nested condition names the exact defining physical value.
6. A nested scratch window starts after every earlier physical body extent for the callable.
7. Code emission applies no frame or source-order rebasing to a physical view.

The mapper admits at most 1,024 values, 4,096 statements, 4,096 body rows, 4,096 nested controls, and 256 locals in packed operand fields. It leaves body and nested rows unchanged on failure.

## Implementation

`StructuredSourceModuleCompiler.w` invokes the mapper after statement and callable coordinate planning. The mapper stages complete body and nested tables, derives exact defining-value starts, maps ordinary and packed operands, and publishes only after every row validates.

`LoopInstructionProducts.w` marks production rows as physical. `LoopNestedLoopProducts.w` passes physical nested conditions and scratch bases through unchanged. Its logical mode retains the old frame adjustment only for focused fixtures that construct logical rows directly.

`ResolvedLoopProducts.w`, `DirectStatementProducts.w`, and the physical mapper retain bounded failure coordinates. Production orchestration asserts those coordinates before the general validity bit. A failed closure run therefore identifies the first loop, statement, body row, or nested row without weakening atomic publication.

## Aggregate adoption

`AggregateSourceProjection.w` now uses direct-profile forms:

- root `bufferLength` products bind lengths before assertions
- named loop limits become bounded literals
- one preflight loop proves every source index before output mutation
- outer-loop cursors are declared outside nested loops
- indexed writes consume signed source locals
- a final bounded pass restores declaration newlines

The physical closure routes the module through `compileStructuredArchiveModuleProduct`. Its 8,096-byte artifact verifies natively and matches stage 0 byte for byte.

## Failure behavior

Reject before publication when:

- one logical local lacks one exact defining value
- a body result width is zero, malformed, or excessive
- one packed operand exceeds its eight-bit local field
- one body or nested statement has no unique owner
- one nested control lacks an earlier physical scratch extent
- one mapped opcode or operand names an unsupported relation
- physical code emission attempts to rebase a closed coordinate

Failure publishes no body rows, nested rows, artifact bytes, or identity.

## Acceptance

- [x] Parameters, root values, and loop-defined values map independently.
- [x] Word, byte, and byte-view packed operands preserve every component.
- [x] Physical nested conditions bypass inferred frame rebasing.
- [x] Logical loop fixtures retain their isolated input contract.
- [x] `AggregateSourceProjection.w` compiles through direct products.
- [x] The native aggregate artifact verifies and matches stage 0 byte for byte.
- [x] Malformed mappings retain bounded failure coordinates and publish nothing.
- [x] Wheeler sources remain below 32,768 bytes and authored files remain below 1,000 lines.

## Rejected alternatives

### Add another post-emission correction

Rejected. A correction cannot distinguish a logical local from an already physical local.

### Infer values from packed storage order

Rejected. Packed order is not source identity and changes when statement widths change.

### Reparse the projected module

Rejected. Parser retry restores a second frontend and discards the closed products.

## References

- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0055](WIP-0055-source-ordered-callable-coordinate-products.md)
- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
