# WIP-0462: Retained package-manifest target-coordinate product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-01 |
| Updated | 2026-09-05 |
| Area | Self-hosting, package manifests, target rows |
| Depends on | WIP-0049, WIP-0459, WIP-0461 |
| Supersedes | Fixed target coordinates in `PackageManifest.w` |
| Superseded by | None |

## Summary

Retain fixed target name and root token projections in `PackageManifestTargetCoordinates.w`. The parser consumes those coordinates for selector coverage and nominal target construction.

## Coordinates

`manifestTargetNameToken` projects `cursor + 6`. `manifestTargetRootToken` projects `cursor + 9`. Keeping both values in one call-free owner removes repeated literals without coupling coordinate policy to nominal result construction.

Attempts to retain optional module syntax and target test policy were rejected. Optional module owners failed structured archive publication at `compileStructuredArchiveModuleWithTargetView`. A call-free nested target-test owner failed minimal-program publication. The coordinate owner is the next exact physically supported boundary.

## Evidence

`NativeCompilerPackageManifestTargetSourceCollectionPhysicalProductExampleTest`
compares the coordinate library byte for byte with stage 0 in the combined target
pass. `NativeCompilerPackageManifestCoordinatesExampleTest` executes the
projections against caller-owned tables. The standalone coordinate pass is gone.

The selected set contains 109 comparable products and 39 callable products. The linked closure retains 128 non-empty module products, 438 functions, and 15,909 forward-plus-inverse instructions. It contains 378,728 code bytes, 12,525 local-type rows, 734 source strings, and 587 unique strings. The 480,752-byte executable closure has SHA-256 `30987305ab15b9f58787c05611ae40d02be0f9ca580fd462d69ff3e122d85697`.

## Bootstrap identities

The compiler graph contains 425 modules, two externals, and 2,006 imports. Its 195,278-byte canonical manifest has SHA-256 `3fd0dd89ba49e5fb75929ddd7011f5dca475ada3b22bae79552317fac791c63d`. Native validation halts after 82,893,665 transitions. Wheeler SHA-256 consumes the same bytes in 37,377,396 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,262,747-byte compiler archive has SHA-256 `3668f53cfcdacb6806f87f66f14083030b6cc23cafc68e77ae589f5e00fad19a`. Every dependent lock names that archive.

## Failure boundary

Reject coordinate drift, a stage-0 product mismatch, stale graph identity, archive mismatch, or closure mismatch before publication.

## Acceptance

- [x] Target name and root coordinates have one call-free owner.
- [x] Selector coverage and target construction consume retained coordinates.
- [x] Both coordinate projections execute independently.
- [x] The retained library matches stage 0 byte for byte.
- [x] The physical set contains 148 products and 438 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Retain optional module validation

Signed state, split presence and name, key-plus-name, and quoted-only variants failed physical publication. Stage-0 behavior alone is insufficient evidence.

### Retain target test policy

Nested and simplified conditional-return variants failed minimal-program publication.

### Repeat coordinate literals

The parser uses root coordinates in selector coverage and result construction. One retained owner prevents drift.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0459](WIP-0459-retained-package-manifest-target-prefix-product.md)
- [WIP-0461](WIP-0461-retained-package-manifest-target-root-product.md)
