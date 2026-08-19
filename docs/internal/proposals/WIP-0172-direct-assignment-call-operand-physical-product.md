# WIP-0172: Direct assignment-call operand physical product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, physical closure, assignment-call operands |
| Depends on | WIP-0049, WIP-0139, WIP-0171 |
| Supersedes | Final signature-stub physical route |
| Superseded by | None |

## Summary

Route `AssignmentCallOperands.w` through direct imported structured products. Two source-local functions retain bounded recursive packed decoding, local calls, one imported arity query, signed source validity, and leading or trailing operand selection without generated signature-stub source.

The physical set remains 97 products. No physical module retains the signature-stub route.

## Packed decoding

`packedSource` decodes one base-256 source digit. It computes the selected distance, returns the current digit when that distance is below the positive minimum gap, or tail-recurses over the scaled operand and next source coordinate.

`assignmentCallSource` calls the imported arity authority, rejects negative and out-of-range sources, decodes both leading and trailing packed operands, and selects the window at source coordinate four.

The positive `ASSIGNMENT_CALL_MINIMUM_SOURCE_GAP` preserves strict source bounds without unsigned arithmetic.

## Calls and relocation

The recursive `packedSource` call and both calls from `assignmentCallSource` remain module-local numeric targets.

One imported call to `assignmentCallArity` publishes a relocation with the source instruction coordinate and stable target identity. The target already belongs to the physical callable set.

No dependency source or generated recursive stub enters this product.

## Arithmetic and types

Packed traversal retains signed subtraction, modulo, division, and addition over a fixed positive radix. Arity, source, gap, selected coordinate, packed values, and decoded values retain signed local types.

Both functions return signed values. Invalid source coordinates return signed minus one.

## Evidence

`NativeCompilerAssignmentCallOperandsPhysicalProductExampleTest` derives two source-local functions and the exact instruction count from stage 0. It requires one callable product, one imported relocation, one resolved target, and successful publication.

`NativeCompilerAssignmentCallOperandsSourceExampleTest` retains generated-source differential evidence for recursion and packed source selection.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. The linked subset retains 233 functions, 8,556 instructions, 5,987 local types, and 200,384 code bytes. Removing the final assignment-call arity stub name reduces source strings to 427, unique strings to 331, and the container to 252,704 bytes. Two runs reproduce SHA-256 `08b5978bc9bc6cdc8c314f5a21375d03369e1a5fa1862a36ba5513fcfe837aac`. Complete evidence passes in 16 minutes and 27 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] `AssignmentCallOperands.w` uses the direct imported structured route.
- [x] Two source-local functions retain exact stage-0 instruction prefixes.
- [x] Recursive packed traversal remains owner local.
- [x] Leading and trailing packed windows retain exact selection.
- [x] One imported arity call publishes and resolves its identity.
- [x] No dependency source or signature stub enters the product.
- [x] No selected physical module retains signature-stub routing.
- [x] Focused physical evidence passes.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The linked physical subset publishes twice with identical bytes.
- [x] Complete evidence remains below twenty minutes.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Unroll seven packed source cases

Rejected. Bounded tail recursion is the canonical compact relation.

### Decode packed sources in Java

Rejected. Wheeler source owns operand semantics.

### Relocate recursive calls

Rejected. Artifact-local function IDs own source-local recursion.

### Keep the final signature stub

Rejected. The direct imported target product closes its sole external call.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0139](WIP-0139-structured-imported-call-product-foundations.md)
- [WIP-0171](WIP-0171-direct-void-call-operand-physical-product.md)
