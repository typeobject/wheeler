# WIP-0417: UTF-8 loop projection products

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-28 |
| Updated | 2026-08-28 |
| Area | Self-hosting, structured loops, UTF-8 projections, local types |
| Depends on | WIP-0049, WIP-0052, WIP-0188, WIP-0416 |
| Supersedes | Rejection of UTF-8 scalar and width declarations inside structured loops |
| Superseded by | None |

## Summary

Lower `utf8Scalar` and `utf8Width` declarations inside direct structured loop bodies. Preserve exact source and index ownership through logical planning, loop rebasing, physical projection, local typing, instruction measurement, and byte emission.

## Problem

The root direct-product path already lowered:

```wheeler
long scalar = utf8Scalar(source, index);
```

The same declaration inside a `while` body reached `ResolvedLoopBodyProducts.w` without a loop-body opcode. Resolution failed before physical locals or code publication. `utf8Width` had the same gap.

Moving these reads outside a loop changes evaluation order and can read an index that the loop never reaches. Treating a UTF-8 loan as bytes would discard scalar-boundary validation. A loop product needs its own exact coordinates.

## Design

`LoopBodyOpcodes.w` assigns two closed identities:

- `BODY_UTF8_SCALAR = 35074`.
- `BODY_UTF8_WIDTH = 35075`.

`DirectLoopBodyProducts.w` recognizes only the exact two-argument call syntax. It resolves a shared UTF-8 source and one prior signed index, rejects every other source type or index form, and packs the two logical local coordinates into one bounded operand.

`PhysicalLoopBodyProducts.w` maps both logical coordinates after loop-frame insertion. `LoopInstructionProducts.w` rebases both coordinates when an earlier loop shifts locals. No packed logical index reaches final code.

Each product uses four locals:

1. shared UTF-8 source.
2. signed byte index.
3. intrinsic result.
4. declared signed value.

`LoopLocalTypeProducts.w` publishes one `TYPE_UTF8_BORROW` row followed by three signed rows. `LoopBodyInstructionEncoding.w` emits two moves, `UTF8_SCALAR` or `UTF8_WIDTH`, and the final result move. The exact extent is four instructions and 104 bytes.

## Evidence

`NativeCompilerStructuredComparisonSourceProductExampleTest` compiles one loop containing both declarations, signed assertions over both results, a following byte write, and the ordinary loop update. The complete source-local artifact matches stage 0 byte for byte.

The negative fixture changes the source loan to `byteview`, then changes the width index to a literal. Both forms trap before artifact length, identity, code, or publication changes.

The existing word, byte, byte-view, offset, copy, assertion, assignment, and update loop products retain their opcode and operand paths.

## Bootstrap identities

The compiler graph remains at 385 modules and grows to 1,921 imports. Its 180,888-byte canonical manifest has SHA-256 `2855e73e79fc98858939f8f1d7f089a9d41292522775e8d190823b3b681cb375`. Native validation halts after 75,439,422 transitions. Wheeler SHA-256 consumes the same bytes in 34,621,966 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,188,284-byte compiler archive has SHA-256 `0257d54f7dad0b79362d2acdd96ef56345de343816ce44c4e8e1036e68e1c429`. Every dependent lock names the new archive.

The selected physical product set remains at the WIP-0416 boundary. This WIP adds a source-product capability, not another retained module.

## Failure boundary

Reject an unshared UTF-8 source, non-UTF-8 source, literal or non-signed index, malformed punctuation, unknown logical local, coordinate above 255, failed physical mapping, over-bound local window, or exhausted code buffer before publication. A runtime index that does not start one encoded scalar still traps through the canonical UTF-8 instruction.

## Acceptance

- [x] Scalar and width loop declarations have distinct closed body opcodes.
- [x] Logical source and index coordinates map and rebase independently.
- [x] Local types preserve the UTF-8 loan and signed result.
- [x] Instruction counts and code lengths use exact production measurements.
- [x] A mixed positive fixture matches stage 0 byte for byte.
- [x] Wrong source and literal-index fixtures publish no artifact.
- [x] Compiler manifest, SHA-256, archive, and dependent locks name the new source.
- [x] Every authored code file remains below 1,000 lines.

## Rejected alternatives

### Cast UTF-8 to bytes

That removes scalar-boundary validation and changes the source type.

### Hoist the projection

A hoisted read executes even when the loop does not and cannot follow a changing index.

### Store raw logical locals in code

Loop frame insertion rebases locals. Final instructions consume physical coordinates only.

### Share one opcode

Scalar value and encoded width are distinct VM operations. An operand flag would duplicate an existing instruction distinction.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0188](WIP-0188-sparse-loop-instruction-staging.md)
- [WIP-0416](WIP-0416-boolean-source-conditional-return-products.md)
