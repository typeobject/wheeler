# WIP-0121: Direct assignment-call column adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, call assignment |
| Depends on | WIP-0049, WIP-0054, WIP-0056, WIP-0073, WIP-0077, WIP-0079 |
| Supersedes | Parser projection for `AssignmentCallColumns.w` |
| Superseded by | None |

## Summary

Route `AssignmentCallColumns.w` through direct source products. Its two functions and 116 instructions produce a 3,496-byte artifact that matches stage 0 byte for byte.

The module maps each bounded call-assignment arity to one unresolved source identity and one resolved target-column base.

## Product path

`sourceKind` checks arities zero through six in seven one-arm conditions and returns the seven-argument identity when the arity equals the public maximum. An invalid arity returns signed minus one. The function uses 58 instructions.

`resolvedBase` mirrors that shape for the eight resolved target-column bases and also uses 58 instructions.

Every arity remains an exact signed literal product. Every mapped identity remains an imported or module-local constant product. Direct compilation does not infer a stride between columns or derive one table from the other.

## Boundaries

The module maps bounded arities only. It does not classify statement identities, count source arguments, decode packed target indexes, validate callable signatures, bind arguments, or emit call instructions.

Negative values and values above seven return minus one. Source identities and resolved column bases remain separate outputs.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module first in lexical order. The list remains the sole callable-bearing direct-route authority in Java evidence.

No production source or package lock changes belong to this migration. The route consumes existing direct equality, conditional, constant return, literal return, and final return products only after complete-artifact parity passes.

## Evidence

`NativeCompilerAssignmentCallColumnsPhysicalProductExampleTest` compiles the module with stage 0 and its native product program. It requires atomic publication and compares all 3,496 bytes. Focused physical evidence passes in 4 minutes and 17 seconds.

`NativeCompilerPhysicalClosureExampleTest` compares every selected artifact, validates retained functions and imported relocations, links the exact 96-product subset, repeats publication, and rejects malformed footer and relocation products. It passes in 17 minutes and 33 seconds under the unchanged twenty-minute deadline.

The linked container remains byte-identical with SHA-256 `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] `AssignmentCallColumns.w` uses direct source products.
- [x] Its two functions and 116 instructions match the 3,496-byte stage-0 artifact.
- [x] Arity zero through seven retains exact source-identity mapping.
- [x] Arity zero through seven retains exact resolved-base mapping.
- [x] Source identities and resolved bases remain separate products.
- [x] Out-of-range arities return exact signed minus one.
- [x] No column stride or host lookup table becomes semantic authority.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Derive resolved bases from source identities

Rejected. Source and resolved registries have separate stable identities.

### Infer one constant column stride

Rejected. The module owns explicit bases and no host arithmetic contract.

### Combine arity measurement with mapping

Rejected. Syntax measurement and identity selection remain separate products.

### Keep the mapper on parser projection

Rejected. Existing direct equality and scalar return products close the artifact.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0077](WIP-0077-exact-constant-return-products.md)
- [WIP-0079](WIP-0079-exact-signed-literal-return-products.md)
