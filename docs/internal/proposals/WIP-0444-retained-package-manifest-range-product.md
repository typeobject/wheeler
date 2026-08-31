# WIP-0444: Retained package-manifest range product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-31 |
| Updated | 2026-08-31 |
| Area | Self-hosting, package manifests, token coordinates |
| Depends on | WIP-0049, WIP-0052, WIP-0443 |
| Supersedes | Compound quoted-range projections in `PackageManifest.w` |
| Superseded by | None |

## Summary

Split quoted-token start and length projection into `PackageManifestRanges.w`. Retain the owner as the 130th physical compiler artifact and keep nominal `QuotedRange` construction in the public parser.

## Range coordinates

`manifestQuotedStart` reads one token start into a named local and advances past the opening quote. `manifestQuotedLength` reads one token length and removes both quotes. Neither function reads source bytes or infers whether a token is quoted. Syntax validation remains with the parser and token owner.

`PackageManifest.w` calls both functions before constructing the package name, version, and profile ranges in `ManifestModel`. Its private nominal wrapper now owns only record construction. Array projection and arithmetic policy have one scalar owner.

The retained module contains two functions and 16 forward-plus-inverse instructions. It has no imports, loops, calls, or relocations.

## Evidence

`NativeCompilerPackageManifestRangesPhysicalProductExampleTest` executes both projections over distinct rows and compares the complete artifact byte for byte with stage 0. Manifest identity tests carry all three resulting ranges through native parsing and hashing.

The selected set contains 105 comparable products and 25 callable products. The linked closure retains 110 non-empty module products, 419 functions, and 14,829 forward-plus-inverse instructions. It contains 352,032 code bytes, 11,469 local-type rows, 679 source strings, and 550 unique strings. The 446,976-byte executable closure has SHA-256 `c1002443583a1234f4a02ae517333a5b3f25f832c8da87f945f49090136aed6e`.

## Bootstrap identities

The compiler graph contains 408 modules, two externals, and 1,956 imports. Its 188,340-byte canonical manifest has SHA-256 `eb99be31c4c710f4d80c09fc187264aed8edbff37efc9d9989bf398b6744cd67`. Native validation halts after 79,080,495 transitions. Wheeler SHA-256 consumes the same bytes in 36,042,278 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,248,147-byte compiler archive has SHA-256 `2e8b423704b54d2abe57e4b0feeb111af55f5fce9adc0f0ad02a48c0c2667893`. Every dependent lock names that archive.

## Failure boundary

Reject a nonquoted token before range construction. Reject unnamed row projection, compound range arithmetic, stale graph identity, archive mismatch, or closure mismatch before physical publication.

## Acceptance

- [x] Interior start and length arithmetic have one scalar owner.
- [x] Nominal record construction remains in the public parser.
- [x] Both coordinate projections execute.
- [x] The retained artifact matches stage 0 byte for byte.
- [x] The physical set contains 130 products and 419 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Move the nominal record into the scalar owner

The record is part of the parser's public result model. Moving it would couple a coordinate product to nominal package API ownership.

### Keep compound array expressions

Named row reads provide exact source-value products and keep arithmetic independently testable.

### Revalidate quotes in both functions

Quoted syntax is already checked before model construction. Duplicating token-kind policy would split authority.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0443](WIP-0443-retained-package-manifest-selector-state-product.md)
