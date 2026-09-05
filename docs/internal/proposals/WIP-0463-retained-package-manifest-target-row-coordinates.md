# WIP-0463: Retained package-manifest target-row coordinates

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-01 |
| Updated | 2026-09-05 |
| Area | Self-hosting, package manifests, target rows |
| Depends on | WIP-0049, WIP-0462 |
| Supersedes | Inline module, selector, and test coordinates in `PackageManifest.w` |
| Superseded by | None |

## Summary

Complete the retained target-coordinate owner. Module metadata, source selectors, and the trailing test field now use named projections from `PackageManifestTargetCoordinates.w`. The parser no longer advances a target row with unexplained literals.

## Target-row coordinates

The owner projects ten coordinates:

- quoted target name and root values.
- optional module key and value.
- source-selector key and first row.
- one row's selector and successor.
- test value and target-row successor.

Fixed fields take the target cursor. Repeated source rows take the current row
cursor. Test projections take the test-key cursor because modular targets have
variable source counts. Each of these ten projections performs one signed addition.

Target admission, source collection, and publication name their coordinates
before calls or table reads. Selector order, root coverage, and target construction
consume those same projections. No coordinate helper reads parser state or widens
a buffer authority.

## Evidence

`NativeCompilerPackageManifestCoordinatesExampleTest` executes the token and
value projections. [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md#manifest-composition)
owns the combined pass that compares the coordinate artifact byte for byte.
Manifest tests retain modular, nonmodular, malformed, ordered, and root-covering
rows. The identities below describe the ten-projection milestone.

The selected set remains 109 comparable products and 39 callable products. It retains 128 non-empty module products, 446 functions, and 15,941 forward-plus-inverse instructions. The linked closure contains 379,496 code bytes, 12,565 local-type rows, 742 source strings, and 595 unique strings. Its 482,688-byte executable has SHA-256 `48029988769a1fee26f5e085e15f08d884cab31d0f3b2515a776b1871fe9b4d2`.

## Bootstrap identities

The compiler graph remains 425 modules, two externals, and 2,006 imports. Its 195,278-byte canonical manifest has SHA-256 `10d89def342497f9ebadfbf5af17af7137285efc7486b9312370cb4a4753bb0a`. Native validation halts after 82,893,647 transitions. Wheeler SHA-256 consumes the same bytes in 37,377,396 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,264,515-byte compiler archive has SHA-256 `4777e7b4f93cfe8e883e5c31d7a2958748e37b3ad573c0d7b12046f4e347410b`. Every dependent lock names that archive.

## Failure boundary

Reject an invalid module, source selector, source order, root coverage, or test field before target publication. Reject coordinate drift, a stage-0 product mismatch, stale graph identity, archive mismatch, or linked-closure mismatch before bootstrap publication.

## Acceptance

- [x] Every target-row coordinate has one retained owner.
- [x] Fixed and repeated coordinates take the narrowest useful cursor.
- [x] The parser names coordinates before calls and table reads.
- [x] All ten projections execute independently.
- [x] The retained library matches stage 0 byte for byte.
- [x] The linked closure contains 148 products and 446 functions.
- [x] Manifest, archive, executable, SHA-256, and locks name the completed owner.

## Rejected alternatives

### Keep cursor arithmetic in the parser

Repeated `+ 1`, `+ 2`, and `+ 3` expressions obscure whether a cursor names a key, value, row, or successor. The retained owner makes that distinction executable.

### Store absolute selector coordinates

A modular target has a bounded but variable selector count. Row-relative projections preserve one loop cursor and avoid a second mutable coordinate table.

### Move buffer reads into the coordinate owner

Coordinates are scalar layout policy. Token kinds, lengths, ordering, and path validity remain with their existing authorities.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0462](WIP-0462-retained-package-manifest-target-coordinate-product.md)
