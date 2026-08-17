# WIP-0119: Direct early-return source-decoder adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, guard returns |
| Depends on | WIP-0049, WIP-0054, WIP-0056, WIP-0069, WIP-0073, WIP-0075 |
| Supersedes | Parser projection for `EarlyReturnSources.w` |
| Superseded by | None |

## Summary

Route `EarlyReturnSources.w` through direct source products. Its two functions and 107 instructions produce a 3,464-byte artifact that matches stage 0 byte for byte.

The module decodes source-local indexes from resolved helper-call and comparison guard-return columns.

## Product path

`earlyHelperReturnSource` selects three helper-guard columns. Two less-than conditional windows return the opcode minus the corresponding base. The final return decodes the helper-call-result column. The function uses 22 instructions.

`earlyComparisonReturnSource` selects ten comparison-guard columns. Nine less-than conditional windows return an exact base-relative source, followed by one final subtraction return. The function uses 85 instructions.

Each computed child owns two signed operand locals and one result local. Its parent owns a separate signed comparison and absolute branch targets. Direct composition preserves every physical local and all source-ordered column boundaries.

## Boundaries

The module decodes one packed prior-local source. It does not classify result type, decode right operands, resolve helper targets, validate local types, execute arithmetic results, or emit control flow.

Every column boundary remains a named imported statement product. No host table or numeric range synthesis replaces those identities.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module after `EarlyReturnResultKinds.w`. The list remains the sole callable-bearing direct-route authority in Java evidence.

No production source or package lock changes belong to this migration. The route consumes existing direct ordering, computed conditional child, arithmetic return, and final return products only after complete-artifact parity passes.

## Evidence

`NativeCompilerEarlyReturnSourcesPhysicalProductExampleTest` compiles the module with stage 0 and its native product program. It requires atomic publication and compares all 3,464 bytes. Focused physical evidence passes in 4 minutes and 26 seconds.

`NativeCompilerPhysicalClosureExampleTest` compares every selected artifact, validates retained functions and imported relocations, links the exact 96-product subset, repeats publication, and rejects malformed footer and relocation products. It passes in 17 minutes and 24 seconds under the unchanged twenty-minute deadline.

The linked container remains byte-identical with SHA-256 `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] `EarlyReturnSources.w` uses direct source products.
- [x] Its two functions and 107 instructions match the 3,464-byte stage-0 artifact.
- [x] All three helper-guard columns retain exact base-relative decoding.
- [x] All ten comparison-guard columns retain exact base-relative decoding.
- [x] Computed conditional children retain exact local and instruction widths.
- [x] Column boundaries remain imported statement products.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Decode through one host range table

Rejected. Imported statement products remain the source-ordered boundary authority.

### Merge source decoding with result classification

Rejected. Result type and source-local position are independent products.

### Infer a fixed stride across every column

Rejected. The accepted family includes distinct helper, equality, ordering, local-right, and computed-result columns.

### Keep the decoder on parser projection

Rejected. Existing direct computed-child and arithmetic-return products close the artifact.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0069](WIP-0069-exact-scalar-return-expression-products.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0075](WIP-0075-exact-computed-conditional-return-products.md)
