# WIP-0454: Retained package-manifest dependency-prefix product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-31 |
| Updated | 2026-08-31 |
| Area | Self-hosting, package manifests, dependency rows |
| Depends on | WIP-0049, WIP-0052, WIP-0438, WIP-0453 |
| Supersedes | Dependency row bounds, dash, type-key, and kind prefix in `PackageManifest.w` |
| Superseded by | None |

## Summary

Split bounded dependency-row prefix validation into `PackageManifestDependencyPrefix.w`. Retain the owner as physical artifact 140 with three resolved token-policy calls.

## Dependency prefix

`manifestDependencyPrefix` proves the final fixed row token is present, requires a sequence dash, checks the fixed `type` key, and decodes the dependency kind. It returns zero after the first invalid condition or the canonical positive kind.

The final coordinate, type-key coordinate and hash, and kind-token coordinate bind before imported calls. `PackageManifest.w` consumes the returned kind before validating name and version fields. This removes four nested prefix conditions from its nominal row parser.

The retained module contains one function and 79 forward-plus-inverse instructions. Three relocations resolve dash, key, and dependency-kind policy.

## Evidence

`NativeCompilerPackageManifestDependencyPrefixPhysicalProductExampleTest` retains the owner, resolves all three call targets, and compares function and instruction counts with stage 0. Manifest behavior and identity examples validate accepted and malformed dependency rows through the split path.

The selected set contains 108 comparable products and 32 callable products. The linked closure retains 120 non-empty module products, 429 functions, and 15,377 forward-plus-inverse instructions. It contains 365,504 code bytes, 11,997 local-type rows, 709 source strings, and 570 unique strings. The 464,056-byte executable closure has SHA-256 `3647c5cc5cef76379a2fce774addb1b73b44d97ba579e988aa4f171c4bce2de0`.

## Bootstrap identities

The compiler graph contains 417 modules, two externals, and 1,978 imports. Its 191,769-byte canonical manifest has SHA-256 `45182c429c7b8b6bf5c48119a2d764b9773e8cdcbb92f5f6067ba02e4d845d45`. Native validation halts after 80,814,252 transitions. Wheeler SHA-256 consumes the same bytes in 36,703,778 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,256,147-byte compiler archive has SHA-256 `59e071ce37fc2a23d7efa0a521c236f12149210606358235beaa781f778b6430`. Every dependent lock names that archive.

## Failure boundary

Reject a truncated row, missing dash, wrong type key, or unknown dependency kind. Reject unnamed imported-call operands, unresolved policy targets, stale graph identity, archive mismatch, or closure mismatch before publication.

## Acceptance

- [x] Dependency row prefix validation has one callable owner.
- [x] Bounds, coordinates, and key hash bind before imported calls.
- [x] Dash, key, and kind calls resolve.
- [x] Complete dependency behavior executes through the split path.
- [x] Retained function and instruction counts match stage 0.
- [x] The physical set contains 140 products and 429 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Move the nominal parse record with the prefix

The prefix has a scalar verdict and no need to own parser result types. Name and version products can close independently.

### Keep compound cursor call operands

The physical imported-call source profile requires named coordinates and exposes row-layout mistakes directly.

### Decode unknown kinds as parser errors locally

The retained kind owner already returns zero for unknown values. The prefix preserves that closed contract.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0438](WIP-0438-retained-package-manifest-kind-product.md)
- [WIP-0453](WIP-0453-retained-package-manifest-header-product.md)
