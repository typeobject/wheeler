# WIP-0451: Retained package-manifest header-release product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-31 |
| Updated | 2026-08-31 |
| Area | Self-hosting, package manifests, callable products |
| Depends on | WIP-0049, WIP-0052, WIP-0450 |
| Supersedes | Header release validation in `PackageManifest.w` |
| Superseded by | None |

## Summary

Split fixed release header validation into `PackageManifestHeaderRelease.w`. Retain the owner as physical artifact 137 with three resolved policy calls.

## Release validation

`manifestHeaderReleaseValid` checks the fixed `version` key, requires a quoted value, projects the interior range through named locals, and calls canonical semantic-release validation. It fails after the first rejected condition.

The key coordinate, key hash, and release-token coordinate bind before imported calls. The parser composes release validation after retained preamble and name products. Dependency release constraints continue to resolve the same semantic-version facade independently.

The retained module contains one function and 70 forward-plus-inverse instructions. Three relocations resolve to key, quoted-token, and semantic-release policy.

## Evidence

`NativeCompilerPackageManifestHeaderReleasePhysicalProductExampleTest` retains the owner, resolves all three call targets, and compares function and instruction counts with stage 0. Manifest behavior and identity examples validate canonical and malformed releases through the split path.

The selected set contains 108 comparable products and 29 callable products. The linked closure retains 117 non-empty module products, 426 functions, and 15,161 forward-plus-inverse instructions. It contains 360,216 code bytes, 11,789 local-type rows, 700 source strings, and 564 unique strings. The 457,504-byte executable closure has SHA-256 `45534e46c1a1ba82b02033b901ac1073865b5343468f8f4bf79f173681492c2d`.

## Bootstrap identities

The compiler graph contains 414 modules, two externals, and 1,970 imports. Its 190,597-byte canonical manifest has SHA-256 `318d922c405884ccf27e88d941caca3d56b0c235fa28f27ac9052e879f20dcb5`. Native validation halts after 80,416,582 transitions. Wheeler SHA-256 consumes the same bytes in 36,483,510 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,253,725-byte compiler archive has SHA-256 `4f3d31a4611acfc04cc70dbb5052ca43ae58c879ed98d070752a69f05854bf7f`. Every dependent lock names that archive.

## Failure boundary

Reject the wrong version key, a nonquoted value, or an invalid semantic release. Reject unnamed imported-call operands, unresolved policy targets, stale graph identity, archive mismatch, or closure mismatch before publication.

## Acceptance

- [x] Header release validation has one callable owner.
- [x] Token coordinates and hash bind before imported calls.
- [x] All three policy calls resolve.
- [x] Complete manifest behavior executes through the split path.
- [x] Retained function and instruction counts match stage 0.
- [x] The physical set contains 137 products and 426 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Validate release text in the parser

The retained semantic-version facade remains canonical. Header validation supplies only the bounded interior range.

### Reuse package-name coordinates implicitly

Header fields have fixed but distinct token positions. Naming the release coordinate exposes source-order mistakes.

### Merge profile and target keys

Profile quoting and target-map opening form their own smaller call graph and failure boundary.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0450](WIP-0450-retained-package-manifest-header-name-product.md)
