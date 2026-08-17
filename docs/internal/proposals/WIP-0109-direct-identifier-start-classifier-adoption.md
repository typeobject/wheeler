# WIP-0109: Direct identifier-start classifier adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, lexical products |
| Depends on | WIP-0049, WIP-0054, WIP-0073, WIP-0099 |
| Supersedes | Parser projection for `IdentifierStarts.w` |
| Superseded by | None |

## Summary

Route `IdentifierStarts.w` through direct source products. Its one function and 39 instructions produce a 1,464-byte artifact that matches stage 0 byte for byte.

The classifier accepts bounded ASCII uppercase letters, underscore, and lowercase letters as source identifier starts.

## Product path

`identifierStart` owns one preserved signed `scalar` parameter. Five source-ordered conditions classify the ASCII intervals and underscore point.

1. Values below `ASCII_UPPER_START` return `false`.
2. Values below `ASCII_UPPER_END` return `true`.
3. Values below `ASCII_UNDERSCORE` return `false`.
4. Exact underscore returns `true`.
5. Values below `ASCII_LOWER_START` return `false`.

The final return checks `scalar < ASCII_LOWER_END`.

Each conditional window contributes seven instructions. The final less-than relation contributes four, for 39 instructions. Every boundary remains a named module-local signed constant product.

## Boundaries

The module classifies one source scalar. It does not decode UTF-8, scan the remainder of an identifier, accept digits after the first scalar, normalize Unicode, or calculate token hashes.

The ASCII profile remains explicit. Direct adoption does not broaden source syntax.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module after `FourArgumentCalls.w`. The list remains the sole callable-bearing direct-route authority in Java evidence.

No production source or package lock changes belong to this migration. The route consumes existing direct less-than, equality, Boolean literal, and terminal return products only after complete-artifact parity passes.

## Evidence

`NativeCompilerIdentifierStartsPhysicalProductExampleTest` compiles the module with stage 0 and its native product program. It requires atomic publication and compares all 1,464 bytes. Focused physical evidence passes in 4 minutes and 34 seconds.

`NativeCompilerPhysicalClosureExampleTest` compares every selected artifact, validates retained functions and imported relocations, links the exact 96-product subset, repeats publication, and rejects malformed footer and relocation products. It passes in 16 minutes and 36 seconds under the unchanged twenty-minute deadline.

The linked container remains byte-identical with SHA-256 `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] `IdentifierStarts.w` uses direct source products.
- [x] Its one function and 39 instructions match the 1,464-byte stage-0 artifact.
- [x] Uppercase, underscore, and lowercase boundaries retain exact constant identities.
- [x] Gap values retain exact false-child ownership.
- [x] Underscore uses exact equality rather than a widened interval.
- [x] The final lowercase upper bound remains exclusive.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Use host character predicates

Rejected. Host locale and Unicode libraries are outside the bounded source profile.

### Merge ASCII gaps into broad ranges

Rejected. Punctuation between the accepted ranges must remain invalid.

### Accept digits as identifier starts

Rejected. Digits belong only to later identifier positions under the source grammar.

### Keep the lexical leaf on parser projection

Rejected. Existing direct comparison and Boolean return products close the artifact.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0099](WIP-0099-exact-boolean-literal-return-products.md)
