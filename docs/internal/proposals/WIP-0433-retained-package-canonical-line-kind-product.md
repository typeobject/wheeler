# WIP-0433: Retained package-canonical line-kind product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-29 |
| Updated | 2026-08-29 |
| Area | Self-hosting, package manifests, canonical lines |
| Depends on | WIP-0049, WIP-0432 |
| Supersedes | Nested token-count checks in `PackageCanonical.w` |
| Superseded by | None |

## Summary

Split canonical line grammar from `PackageCanonical.w`. Retain the closed token-count and final-coordinate owner `PackageCanonicalLineKinds.w` as the 121st physical compiler product. Keep punctuation and spacing policy in `PackageCanonicalLines.w` for the next physical step.

## Problem

After WIP-0432, canonical layout still mixed plain lines, dashed lines, indentation, token count, and final-token selection in one owner. The original methods took nine arguments, above the seven-source physical call boundary. Their nested optional branches also coupled token-count dispatch to array and UTF-8 reads.

A first `PackageCanonicalLines.w` extraction remained too broad. Conditional Boolean assignments failed nested-body resolution. A second form flattened those assignments but still failed direct conditional-return materialization at the first array-backed line check.

The closed scalar surface should not wait on array-backed punctuation policy.

## Line kinds

`canonicalPlainLineTokenCount` accepts exactly two, three, or four tokens. `canonicalDashedLineTokenCount` accepts exactly two or four. Every other signed value fails.

`canonicalFinalLineToken` converts a nonempty half-open token window to its final coordinate. The canonical line owner checks nonemptiness before calling it.

The retained owner has no imports, buffers, UTF-8 projection, loops, or mutable state. It retains three functions and 47 forward-plus-inverse instructions.

## Line grammar split

`PackageCanonicalLines.w` now owns plain base punctuation, value spacing, split-value adjacency, dashed base spacing, dashed field spacing, line-shape dispatch, and final-end equality. Helpers take at most six arguments. Plain and dashed count checks call the retained line-kind owner.

`PackageCanonical.w` deletes its three private line-shape functions. Its root loop now calls indentation, line shape, and final-end products separately. This source split preserves canonical behavior while leaving the array-backed owner outside the retained set until its direct conditional-return boundary is closed.

## Evidence

`NativeCompilerPackageCanonicalLineKindsPhysicalProductExampleTest` compares the complete line-kind artifact byte for byte with stage 0. Its executable fixture covers every admitted count, adjacent rejected counts, and a nonzero final-token coordinate.

`NativeCompilerPackageCanonicalLinesExampleTest` executes plain key-value and dashed key-value lines, exact final ends, an invalid count, and an invalid final end through the split line owner.

The selected set contains 98 comparable products and 23 callable products. The linked closure retains 101 non-empty module products, 397 functions, and 14,272 forward-plus-inverse instructions. It contains 338,824 code bytes, 10,978 local-type rows, 639 source strings, and 519 unique strings. The 429,128-byte executable closure has SHA-256 `f76cc6a95bb90a6a33096d6ad5eed26f0b4798becab890d5f27310509a917298`.

## Bootstrap identities

The compiler graph contains 397 modules, two externals, and 1,943 imports. Its 185,040-byte canonical manifest has SHA-256 `d813daec5c0cda619b9b3f1a353b75879f04f74ba0e13c9c32fa0fe28e00a799`. Native validation halts after 77,448,173 transitions. Wheeler SHA-256 consumes the same bytes in 35,418,020 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,233,728-byte compiler archive has SHA-256 `e5e8b3344078d6ba358bd18f263cb23d3385b84864244acce9df1e56a7aff122`. Every dependent lock names that archive.

## Failure boundary

Reject a plain count outside two through four, dashed count other than two or four, empty final-token window at the line owner, invalid final coordinate, unresolved line-kind call, invalid artifact, or stale graph identity before publication. Array-backed punctuation and spacing remain fail-closed outside the physical set.

## Acceptance

- [x] Plain and dashed token counts have one closed owner.
- [x] Final-token coordinate has one closed owner.
- [x] The owner has no imports or mutable state.
- [x] Every positive and adjacent negative count executes.
- [x] The native artifact matches stage 0 byte for byte.
- [x] Line punctuation behavior survives the source split.
- [x] The physical set contains 121 products and 397 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Keep nine-argument line methods

The physical call product admits at most seven source arguments. The API mixed independent checks.

### Claim the array-backed line owner is retained

Its focused physical attempt failed before artifact publication. Stage execution is not physical closure evidence.

### Duplicate count checks in plain and dashed helpers

The count sets are small closed policy and deserve one scalar authority.

### Widen the call boundary

Splitting line coordinates, kinds, and punctuation yields clearer ownership without changing global limits.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0432](WIP-0432-retained-package-canonical-coordinate-product.md)
