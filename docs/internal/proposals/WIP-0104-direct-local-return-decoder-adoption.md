# WIP-0104: Direct local-return decoder adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, return decoding |
| Depends on | WIP-0049, WIP-0054, WIP-0075, WIP-0078, WIP-0099 |
| Supersedes | Parser projection for `ResolvedLocalReturns.w` |
| Superseded by | None |

## Summary

Route `ResolvedLocalReturns.w` through direct source products. Its three functions and 44 instructions produce a 1,880-byte artifact that matches stage 0 byte for byte.

The module classifies resolved scalar local returns, distinguishes signed returns, and decodes the exact source local from signed and Boolean opcode regions.

## Product path

`resolvedLocalReturn` and `resolvedSignedLocalReturn` each use one exact lower-bound condition whose child returns `false`, followed by one final upper-bound comparison.

`resolvedLocalReturnSource` has two source-ordered lower-bound conditions. Each exact child subtracts the corresponding signed or Boolean base. The final return subtracts the Boolean base.

The two predicates contribute 11 instructions each. The source decoder contributes two nine-instruction arithmetic child windows plus one four-instruction final subtraction, for 22 instructions. The complete module contains 44 instructions.

The public signed and Boolean base constants remain module products. The private Boolean end product derives from the Boolean base and exact source count. No decoder masks an opcode or collapses the two return types.

## Boundaries

The module classifies and decodes resolved local-return statement identities. It does not read a local value, type-check a callable result, emit `RETURN_VALUE`, or allocate a result slot.

Signed and Boolean regions retain distinct source constants even though source-local decoding produces one numeric index.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module after `ResolvedLocalPairAssertions.w`. The list remains the sole callable-bearing direct-route authority in Java evidence.

No production source or package lock changes belong to this migration. The route consumes existing direct conditional, Boolean literal, comparison, subtraction, and return products only after complete-artifact parity passes.

## Evidence

`NativeCompilerResolvedLocalReturnsPhysicalProductExampleTest` compiles the module with stage 0 and its native product program. It requires atomic publication and compares all 1,880 bytes. Focused physical evidence passes in 4 minutes and 37 seconds.

`NativeCompilerPhysicalClosureExampleTest` compares every selected artifact, validates retained functions and imported relocations, links the exact 96-product subset, repeats publication, and rejects malformed footer and relocation products. It passes in 16 minutes and 43 seconds under the unchanged twenty-minute deadline.

The linked container remains byte-identical with SHA-256 `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] `ResolvedLocalReturns.w` uses direct source products.
- [x] Its three functions and 44 instructions match the 1,880-byte stage-0 artifact.
- [x] Signed and Boolean predicate bounds retain exact constant identities.
- [x] Source decoding retains source-ordered signed and Boolean regions.
- [x] Arithmetic children retain exact base subtraction products.
- [x] The final subtraction retains the Boolean base product.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Merge signed and Boolean return regions

Rejected. Their statement identities and result types remain distinct semantic products.

### Decode the local with a mask

Rejected. The source names explicit bases and a bounded source count, not a host bitfield.

### Execute return semantics in the decoder

Rejected. This module owns statement identity only. Lowering owns local reads and return bytecode.

### Keep the decoder on parser projection

Rejected. Existing direct conditions, constants, subtraction, and returns close the artifact.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0075](WIP-0075-exact-computed-conditional-return-products.md)
- [WIP-0078](WIP-0078-bounded-direct-conditional-lookups.md)
- [WIP-0099](WIP-0099-exact-boolean-literal-return-products.md)
