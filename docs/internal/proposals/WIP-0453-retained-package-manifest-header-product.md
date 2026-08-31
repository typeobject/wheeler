# WIP-0453: Retained package-manifest header product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-31 |
| Updated | 2026-08-31 |
| Area | Self-hosting, package manifests, callable products |
| Depends on | WIP-0049, WIP-0052, WIP-0449, WIP-0450, WIP-0451, WIP-0452 |
| Supersedes | Private header facade in `PackageManifest.w` |
| Superseded by | None |

## Summary

Split complete fixed header composition into `PackageManifestHeader.w`. Retain the facade as physical artifact 139 with four resolved field-owner calls.

## Header composition

`manifestHeaderValid` calls the format preamble, package name, semantic release, and profile-target tail in canonical order. Each call binds before its fail-closed check. The function returns the final tail result directly from a named local.

`PackageManifest.w` now imports one header facade instead of four field owners. Fixed header token coordinates, key hashes, token syntax, and value validation no longer live in the collection parser.

The retained module contains one function and 71 forward-plus-inverse instructions. Four relocations resolve to the retained header field products.

## Evidence

`NativeCompilerPackageManifestHeaderPhysicalProductExampleTest` retains the facade, resolves all four field targets, and compares function and instruction counts with stage 0. Manifest behavior and identity examples validate complete canonical and malformed headers through the retained facade.

The selected set contains 108 comparable products and 31 callable products. The linked closure retains 119 non-empty module products, 428 functions, and 15,298 forward-plus-inverse instructions. It contains 363,560 code bytes, 11,921 local-type rows, 706 source strings, and 568 unique strings. The 461,656-byte executable closure has SHA-256 `71073c18867dc2f298fe54b2fc835b0dd2133f772df37be3bae6a658011e9323`.

## Bootstrap identities

The compiler graph contains 416 modules, two externals, and 1,974 imports. Its 191,291-byte canonical manifest has SHA-256 `3eacb93c2c66bc0c1546ebd8962b8874fd1b9625d973c8ee8b17ad1bd519f1f0`. Native validation halts after 80,624,517 transitions. Wheeler SHA-256 consumes the same bytes in 36,619,358 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,255,477-byte compiler archive has SHA-256 `bb665b9ed035de882f80989f8ddda3a7a75af288d557b1d482aa527692d0f499`. Every dependent lock names that archive.

## Failure boundary

Reject the first invalid field owner result. Reject a reordered or unresolved field call, stale graph identity, archive mismatch, or closure mismatch before publication.

## Acceptance

- [x] Fixed header composition has one callable facade.
- [x] The collection parser imports only that facade for header validation.
- [x] All four field-owner calls resolve.
- [x] Complete manifest behavior executes through the retained path.
- [x] Retained function and instruction counts match stage 0.
- [x] The physical set contains 139 products and 428 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the facade.

## Rejected alternatives

### Keep the private parser helper

A private facade would remain inseparable from collection loops and nominal results. One public owner gives header composition exact relocation evidence.

### Inline field owners

The four retained products have independent boundaries and tests. The facade composes rather than duplicates them.

### Evaluate all fields after failure

Fail-fast order preserves parser behavior and avoids projecting later malformed tokens.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0449](WIP-0449-retained-package-manifest-header-preamble-product.md)
- [WIP-0450](WIP-0450-retained-package-manifest-header-name-product.md)
- [WIP-0451](WIP-0451-retained-package-manifest-header-release-product.md)
- [WIP-0452](WIP-0452-retained-package-manifest-header-tail-product.md)
