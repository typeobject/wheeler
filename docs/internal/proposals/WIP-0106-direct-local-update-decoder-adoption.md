# WIP-0106: Direct local-update decoder adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, update decoding |
| Depends on | WIP-0049, WIP-0054, WIP-0075, WIP-0078, WIP-0087 |
| Supersedes | Parser projection for `ResolvedLocalUpdates.w` |
| Superseded by | None |

## Summary

Route `ResolvedLocalUpdates.w` through direct source products. Its three functions and 99 instructions produce a 3,304-byte artifact that matches stage 0 byte for byte.

The module classifies resolved checked local updates, identifies updates whose right operand is a prior local, and decodes the exact target local across add, subtract, and XOR regions.

## Product path

`resolvedLocalUpdate` uses one lower-bound condition with a `false` child followed by one final upper-bound comparison.

`resolvedLocalUpdateNamed` uses five source-ordered range conditions. Its children alternate `false`, `true`, `false`, `true`, and `false` before the final upper-bound comparison. Exact local range ends retain module-local constant products.

`resolvedLocalUpdateTarget` uses five source-ordered conditions. Each child subtracts the corresponding literal or local operation base. The final return subtracts `STATEMENT_LOCAL_UPDATE_XOR_LOCAL_BASE`.

The classifier contributes 11 instructions, the named-source predicate contributes 39, and the target decoder contributes 49. The complete module contains 99 instructions.

## Semantic boundaries

The decoder preserves six distinct update regions:

1. add literal,
2. add local,
3. subtract literal,
4. subtract local,
5. XOR literal, and
6. XOR local.

It does not infer the operation, source kind, or target from host masks. It does not load operands, check arithmetic overflow, mutate a local, or emit inverse code.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module after `ResolvedLocalReturns.w`. The list remains the sole callable-bearing direct-route authority in Java evidence.

No production source or package lock changes belong to this migration. The route consumes existing direct condition, Boolean literal, constant, subtraction, and comparison products only after complete-artifact parity passes.

## Evidence

`NativeCompilerResolvedLocalUpdatesPhysicalProductExampleTest` compiles the module with stage 0 and its native product program. It requires atomic publication and compares all 3,304 bytes. Focused physical evidence passes in 4 minutes and 52 seconds.

`NativeCompilerPhysicalClosureExampleTest` compares every selected artifact, validates retained functions and imported relocations, links the exact 96-product subset, repeats publication, and rejects malformed footer and relocation products. It passes in 16 minutes and 8 seconds under the unchanged twenty-minute deadline.

The linked container remains byte-identical with SHA-256 `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] `ResolvedLocalUpdates.w` uses direct source products.
- [x] Its three functions and 99 instructions match the 3,304-byte stage-0 artifact.
- [x] Update classification retains exact lower and upper bounds.
- [x] Named-source classification retains exact add, subtract, and XOR local ranges.
- [x] Target decoding retains all six source-ordered base products.
- [x] Each arithmetic child retains exact block and return ownership.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Merge literal and local update regions

Rejected. Source kind controls operand binding and remains a distinct statement product.

### Decode update targets with masks

Rejected. The statement registry defines explicit bases and ranges, not a host bitfield contract.

### Execute checked arithmetic here

Rejected. This module classifies statement identities. Lowering and the VM own overflow and mutation semantics.

### Keep the decoder on parser projection

Rejected. Existing direct condition, constant, subtraction, and return products close the artifact.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0075](WIP-0075-exact-computed-conditional-return-products.md)
- [WIP-0078](WIP-0078-bounded-direct-conditional-lookups.md)
- [WIP-0087](WIP-0087-bounded-direct-product-publication.md)
