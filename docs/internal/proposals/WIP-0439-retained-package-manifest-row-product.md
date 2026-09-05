# WIP-0439: Retained package-manifest row product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-30 |
| Updated | 2026-09-04 |
| Area | Self-hosting, package manifests, bounded row layout |
| Depends on | WIP-0049, WIP-0052, WIP-0438 |
| Supersedes | Generic private row-capacity arithmetic in `PackageManifest.w` |
| Superseded by | None |

## Summary

Split target, target-source, dependency, and capability row-capacity checks into `PackageManifestRows.w`. Give each canonical row width one function and retain the owner as the 126th physical compiler artifact.

## Fixed row products

`manifestTargetRowCapacity` admits one complete ten-column target row. `manifestSourceRowCapacity` admits one complete two-column target-source row. Dependency and capability checks do the same for five- and four-column rows.

The original functions multiplied the row ordinal by its format width and checked the final column. That assumed a nonnegative, bounded ordinal. WIP-0049 now rejects negative indexes and divides capacity by the fixed width before comparing row counts. No unchecked multiplication remains.

`PackageManifest.w` initially called the matching function at all four publication sites. WIP-0049 now delegates dependency and capability checks to their complete entry products. The generic width parameter and its private arithmetic are gone. Width constants still define public row layout and storage offsets. Capacity policy now has one closed owner.

## Physical shape

The first split kept a generic `(rows, row, width)` function. Stage 0 executed it, but physical source compilation rejected its local-by-local multiplication before artifact publication. Retaining that form would have overstated evidence.

The format admits only four widths. Specializing them turns every multiplication into a local-by-literal product already covered by the physical source path. The original owner retained four functions and 60 forward-plus-inverse instructions without imports or relocations.

## Evidence

`NativeCompilerPackageManifestEntryPhysicalProductExampleTest` now compares the capacity and coordinate artifacts with stage 0 in one archive pass. `NativeCompilerPackageManifestRowsExampleTest` covers partial and complete rows, negative indexes, and signed multiplication overflow for all four layouts. It verifies unchanged storage and complete rewind.

The manifest and archive examples parse complete package metadata through the split owner. The selected set contains 102 comparable products and 24 callable products. The linked closure retains 106 non-empty module products, 411 functions, and 14,625 forward-plus-inverse instructions. It contains 347,192 code bytes, 11,287 local-type rows, 663 source strings, and 538 unique strings. The 440,416-byte executable closure has SHA-256 `bbb6496215bcd38ee32ad9cf8fd6dd0d9274eb7369bd6767d398513af2c3cacc`.

## Bootstrap identities

The compiler graph contains 403 modules, two externals, and 1,950 imports. Its 186,837-byte canonical manifest has SHA-256 `3407d67f46714e8d2e14194f0854bbb4dde45a3703199c8e96d71b661103a9dc`. Native validation halts after 78,614,152 transitions. Wheeler SHA-256 consumes the same bytes in 35,760,868 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,241,365-byte compiler archive has SHA-256 `23d9d7f765cc4973da828ac3c7f0af08fed01de609301c312f46143112d7a099`. Every dependent lock names that archive.

## Failure boundary

Reject an incomplete target, source, dependency, or capability row before parser publication. Reject local-by-local width arithmetic, stale graph evidence, archive mismatch, or closure identity mismatch before physical publication.

## Acceptance

- [x] Every package-manifest row width has one named capacity function.
- [x] The parser contains no generic private row-capacity helper.
- [x] First, final, and overflowing rows execute for every layout.
- [x] The retained artifact matches stage 0 byte for byte.
- [x] The physical set contains 126 products and 411 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Keep a runtime width parameter

The package format has four fixed layouts. A runtime width weakens the format boundary and requires a local-by-local multiplication that the physical source path does not publish.

### Check only the row start

A start coordinate can fit while later columns overflow. Publication requires the complete row.

### Duplicate arithmetic at call sites

That couples parser control flow to storage bounds and gives four sites room to diverge.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0438](WIP-0438-retained-package-manifest-kind-product.md)
