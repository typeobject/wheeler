# WIP-0445: Retained package-manifest selector-prefix product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-31 |
| Updated | 2026-08-31 |
| Area | Self-hosting, package manifests, UTF-8 traversal |
| Depends on | WIP-0049, WIP-0052, WIP-0443, WIP-0444 |
| Supersedes | Selector-prefix traversal in `PackageManifestSelectors.w` |
| Superseded by | None |

## Summary

Split selector-prefix UTF-8 traversal into `PackageManifestSelectorPrefix.w`. Retain the owner as physical artifact 131 while leaving range completion outside the selected set.

## Prefix traversal

`manifestSelectorPrefixSame` compares a caller-bounded selector with the corresponding root prefix. It projects each scalar through named coordinates, carries a fail-closed Boolean, and traverses at most 4,096 scalar positions. Length classification guarantees the root is at least as long before the range owner calls it.

The prefix owner has no imports or calls. `PackageManifestSelectors.w` imports it beside the scalar state owner. This removes imported calls from the UTF-8 loop. Length and slash-boundary policy remain separate.

The retained module contains one function and 46 forward-plus-inverse instructions.

## Evidence

`NativeCompilerPackageManifestSelectorPrefixPhysicalProductExampleTest` executes equal and mismatched prefixes and compares the complete artifact byte for byte with stage 0. `NativeCompilerPackageManifestSelectorsExampleTest` executes equal, directory-prefix, longer, mismatched, and nonseparator ranges through the split path.

The selected set contains 106 comparable products and 25 callable products. The linked closure retains 111 non-empty module products, 420 functions, and 14,875 forward-plus-inverse instructions. It contains 353,168 code bytes, 11,509 local-type rows, 682 source strings, and 552 unique strings. The 448,432-byte executable closure has SHA-256 `550409cd69cdcbdeb4666b6e77063bb7d489b412c565935fe680e4da46e986f9`.

## Bootstrap identities

The compiler graph contains 409 modules, two externals, and 1,957 imports. Its 188,651-byte canonical manifest has SHA-256 `c0f464a6262b8166bcefd79f85f276dc959e3811f9ae9c877a50c75e4ae423fe`. Native validation halts after 79,336,184 transitions. Wheeler SHA-256 consumes the same bytes in 36,103,580 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,248,909-byte compiler archive has SHA-256 `d70208275efd910c6651061f42add8f6be88a1a9aa9ba495482d6de2747090f5`. Every dependent lock names that archive.

## Failure boundary

Reject a prefix longer than the root before traversal. Reject a mismatched scalar, unnamed coordinate, traversal beyond 4,096 positions, stale identity, archive mismatch, or closure mismatch before publication. Imported range completion remains unselected until its call and conditional-return composition publishes an exact artifact.

## Acceptance

- [x] Selector prefix traversal has one owner.
- [x] The UTF-8 loop contains no imported calls.
- [x] Equal and mismatched prefixes execute.
- [x] The retained artifact matches stage 0 byte for byte.
- [x] The physical set contains 131 products and 420 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Keep state calls inside the loop

The direct product failed closed at imported loop-call composition. Scalar comparisons belong in a call-free traversal owner.

### Merge length and boundary policy into traversal

Length and completion are scalar policy already retained by WIP-0443. Duplicating them would split authority.

### Claim the complete range owner

Stage-0 behavior is not physical publication. Range completion remains separate evidence.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0443](WIP-0443-retained-package-manifest-selector-state-product.md)
- [WIP-0444](WIP-0444-retained-package-manifest-range-product.md)
