# WIP-0459: Retained package-manifest target-prefix product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-31 |
| Updated | 2026-08-31 |
| Area | Self-hosting, package manifests, target rows |
| Depends on | WIP-0049, WIP-0052, WIP-0438, WIP-0442 |
| Supersedes | Target prefix validation in `PackageManifest.w` |
| Superseded by | None |

## Summary

Split target-row bounds, sequence syntax, and kind-field validation into `PackageManifestTargetPrefix.w`. Retain the owner as physical artifact 145 with three resolved policy calls.

## Target prefix

`manifestTargetPrefixKind` proves that the required thirteen-token row prefix is bounded, checks the leading dash and cursor-relative `type` key, and returns the canonical target kind. Zero denotes malformed input.

The key coordinate and hash and the type-token coordinate bind before imported calls. `PackageManifest.w` composes this owner before target name, root, module, selector, and test validation.

The retained module contains one function and 79 forward-plus-inverse instructions. Three relocations resolve dash, key, and target-kind policy.

## Evidence

`NativeCompilerPackageManifestTargetPrefixPhysicalProductExampleTest` retains the owner, resolves all three call targets, and compares function and instruction counts with stage 0. Manifest behavior and identity examples validate accepted and malformed target prefixes through the split path.

The selected set contains 108 comparable products and 37 callable products. The linked closure retains 125 non-empty module products, 434 functions, and 15,753 forward-plus-inverse instructions. It contains 374,840 code bytes, 12,367 local-type rows, 724 source strings, and 580 unique strings. The 475,664-byte executable closure has SHA-256 `0d45c23ddc3d13b08d4fc5fb5bfa922e5706170baf91560332e35c7df12bf660`.

## Bootstrap identities

The compiler graph contains 422 modules, two externals, and 1,997 imports. Its 194,057-byte canonical manifest has SHA-256 `e2bbe731823cd551eb4c1aeb5f7909a5c9adc9d3bea39a955fa62c3ab1a6b052`. Native validation halts after 82,171,671 transitions. The explicit closure budget rises from 82,000,000 to 83,000,000 transitions. Wheeler SHA-256 consumes the same bytes in 37,144,762 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,261,019-byte compiler archive has SHA-256 `d524037218b7c9df1d5a1d07d9eb2e5288394edbb96c065069c8935031f8273c`. Every dependent lock names that archive.

## Failure boundary

Reject a truncated row, missing dash, wrong type key, or unknown target kind. Reject unnamed imported-call operands, unresolved policy targets, stale graph identity, archive mismatch, or closure mismatch before publication.

## Acceptance

- [x] Target prefix validation has one callable owner.
- [x] Token coordinates and key hash bind before imported calls.
- [x] Dash, key, and target-kind calls resolve.
- [x] Complete target behavior executes through the split path.
- [x] Retained function and instruction counts match stage 0.
- [x] The physical set contains 145 products and 434 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Leave row bounds in the nominal parser

Bounds are part of the scalar prefix verdict and permit later owners to address fixed token offsets safely.

### Return a Boolean verdict

The parser needs the canonical kind scalar. Returning it avoids duplicate token decoding.

### Merge name and root validation

Those fields resolve distinct validators and retain independent failure boundaries.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0438](WIP-0438-retained-package-manifest-kind-product.md)
- [WIP-0442](WIP-0442-retained-package-manifest-key-product.md)
