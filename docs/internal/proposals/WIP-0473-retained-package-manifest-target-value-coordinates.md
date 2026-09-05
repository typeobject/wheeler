# WIP-0473: Retained package-manifest target-value coordinates

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-02 |
| Updated | 2026-09-05 |
| Area | Self-hosting, package manifests, target rows |
| Depends on | WIP-0049, WIP-0444, WIP-0463, WIP-0471 |
| Supersedes | Inline target name, root, and module range arithmetic in `PackageManifest.w` |
| Superseded by | None |

## Summary

Complete the retained target-coordinate owner with quoted value projections. `PackageManifestTargetCoordinates.w` now owns the interior start and length used for target names, roots, and optional module names.

## Value coordinates

`manifestTargetValueStart` reads one token start and advances over the opening quote. `manifestTargetValueLength` reads one token length and removes both quotes. Each operation uses named scalar locals. The functions do not validate token grammar, allocate text, mutate a target row, or choose a field.

Target name, root, and optional module policy establish quoted-token validity before publication. `parseManifest` requests the retained coordinates, writes the ten-word target row, and leaves zeroes in the absent module range.

## Physical route

The coordinate product gained two functions while staying in the comparable
prefix. WIP-0049 now routes the complete owner through direct structured products,
including its conditional target-tail projections.

## Evidence

[WIP-0049](WIP-0049-bounded-native-source-product-compilation.md#manifest-composition)
owns the combined pass that compares the complete coordinate artifact.
`NativeCompilerPackageManifestCoordinatesExampleTest` executes its token and
value projections against caller-owned tables. `NativeManifestExampleTest`
executes modular and nonmodular publication. The receipts below record the
twelve-function milestone.

The selected set contains 112 comparable products and 42 callable products. It retains 134 non-empty module products, 472 functions, and 16,324 forward-plus-inverse instructions. The linked closure contains 389,008 code bytes, 13,021 local-type rows, 780 source strings, and 627 unique strings. Its 497,512-byte executable has SHA-256 `c8a3edc93bcdee19c824e12506b05ce3d95f0f1c70931597414f1ac04320ac30`.

## Bootstrap identities

The compiler graph contains 431 modules, two externals, and 2,017 imports. Its 197,486-byte canonical manifest has SHA-256 `24f915709b834838e6ff73ffdc7634d5c42a8ea0dd81eb03883f0cbef34001f5`. Native validation halts after 83,741,378 transitions under the 84,000,000-transition evidence ceiling. Wheeler SHA-256 consumes the same bytes in 37,793,504 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,276,737-byte compiler archive has SHA-256 `a1d591515d8fc76fb1067187de2179d9c1e035c65ee810de5f08f68f6c5841fd`. Every dependent lock names that archive.

## Failure boundary

Reject malformed target values before coordinate projection and exhausted row storage before publication. Reject a stage-0 mismatch, stale graph identity, archive mismatch, linked-closure mismatch, or lock mismatch before bootstrap publication.

## Acceptance

- [x] Target token and quoted-value coordinates have one owner.
- [x] Quoted start and length use named scalar projections.
- [x] The parser carries no target value quote arithmetic.
- [x] Modular and nonmodular target rows execute through the completed owner.
- [x] The retained library matches stage 0 byte for byte.
- [x] The linked closure contains 154 products and 472 functions.
- [x] Manifest, archive, executable, SHA-256, and locks name the completed owner.

## Rejected alternatives

### Add field-specific start and length pairs

Name, root, and module values have identical quoted framing after field validation. Six wrappers would repeat one invariant and widen the physical product without adding policy.

### Return a range record

The parser writes independent scalar columns. A record would add construction and field projection without strengthening validity.

### Move target-row publication into the owner

The parser owns capacity, ordering, optional-field state, counts, and storage. Coordinate projection should not create a second mutation boundary.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0444](WIP-0444-retained-package-manifest-range-product.md)
- [WIP-0463](WIP-0463-retained-package-manifest-target-row-coordinates.md)
- [WIP-0471](WIP-0471-retained-package-manifest-capability-coordinates.md)
