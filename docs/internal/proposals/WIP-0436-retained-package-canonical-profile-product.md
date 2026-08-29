# WIP-0436: Retained package-canonical profile product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-29 |
| Updated | 2026-08-29 |
| Area | Self-hosting, package manifests, canonical profile |
| Depends on | WIP-0049, WIP-0432, WIP-0435 |
| Supersedes | Outer bounds and completion checks in `PackageCanonical.w` |
| Superseded by | None |

## Summary

Split canonical source bounds and terminal completion into `PackageCanonicalProfile.w`. Retain it as the 123rd physical compiler product and reduce `PackageCanonical.w` to bounded line traversal plus calls to focused owners.

## Source bounds

`canonicalManifestBounds` rejects empty input and input at or above the 262,145-byte exclusive limit. It projects the final scalar and requires newline.

The prior-coordinate helper names constant one, subtraction, and result before return. The exclusive limit is a direct constant. No arithmetic expression falls through to copy lowering.

## Completion

`canonicalManifestComplete` requires exact token consumption and terminal section three. Both checks use signed scalar inputs and one Boolean declaration. Extra tokens, missing tokens, and earlier sections fail.

`PackageCanonical.w` calls the bounds product before reading source length. After traversal it delegates token and section completion. It no longer owns final-scalar arithmetic or terminal policy.

## Evidence

`NativeCompilerPackageCanonicalProfilePhysicalProductExampleTest` compares the complete artifact byte for byte with stage 0. Its executable fixture covers valid newline input, missing newline, empty input, exact completion, token mismatch, and section mismatch.

The owner retains three functions and 68 forward-plus-inverse instructions. It has no imports, loops, arrays, or mutable state.

The selected set contains 100 comparable products and 23 callable products. The linked closure retains 103 non-empty module products, 402 functions, and 14,425 forward-plus-inverse instructions. It contains 342,384 code bytes, 11,095 local-type rows, 648 source strings, and 526 unique strings. The 433,760-byte executable closure has SHA-256 `118702c5e80b0159adbe206b1def9572c12084a25d95099f5ebb3fd54c23584a`.

## Bootstrap identities

The compiler graph contains 399 modules, two externals, and 1,945 imports. Its 185,621-byte canonical manifest has SHA-256 `80247cc7aea34659f9824197a3a419c3f63d49a9c50ac05d63b92c69aa4beed4`. Native validation halts after 77,705,584 transitions. Wheeler SHA-256 consumes the same bytes in 35,528,194 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,237,385-byte compiler archive has SHA-256 `daf65d96a2ae758ad9a542bed5a554739ede7c3b734340e9e7ba76e9ba4750c6`. Every dependent lock names that archive.

## Failure boundary

Reject empty input, input above the package-manifest byte bound, missing final newline, token-count mismatch, nonterminal section, unresolved profile call, invalid artifact, stale graph identity, or archive mismatch before publication.

## Acceptance

- [x] Outer source bounds have one owner.
- [x] Terminal token and section policy have one owner.
- [x] Prior-coordinate arithmetic uses named declarations.
- [x] Positive and negative bounds execute.
- [x] Positive and negative completion states execute.
- [x] The native artifact matches stage 0 byte for byte.
- [x] The physical set contains 123 products and 402 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Keep final-scalar checks in the root loop owner

Source framing is profile policy and is independently testable before token traversal.

### Admit the exclusive limit

The package parser's bound is 262,144 bytes. The exclusive comparison keeps the accepted maximum unchanged.

### Return completion from the traversal loop

Token consumption and terminal section are postconditions. Keeping them outside the loop avoids another early return.

### Pack bounds and completion into one function

They consume different domains and run at opposite sides of traversal.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0432](WIP-0432-retained-package-canonical-coordinate-product.md)
- [WIP-0435](WIP-0435-retained-package-canonical-indent-product.md)
