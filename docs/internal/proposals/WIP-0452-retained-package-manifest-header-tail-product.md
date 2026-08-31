# WIP-0452: Retained package-manifest header-tail product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-31 |
| Updated | 2026-08-31 |
| Area | Self-hosting, package manifests, callable products |
| Depends on | WIP-0049, WIP-0052, WIP-0451 |
| Supersedes | Header profile and target-opener validation in `PackageManifest.w` |
| Superseded by | None |

## Summary

Split profile quoting and target-sequence opening into `PackageManifestHeaderTail.w`. Retain the owner as physical artifact 138 with three resolved token-policy calls.

## Header tail

`manifestHeaderTailValid` checks the fixed `profile` key, requires its value token to be quoted, and checks the fixed `targets` key. Profile value interpretation remains a consumer concern. Manifest parsing retains its exact quoted range.

Both key coordinates, both key hashes, and the profile-token coordinate bind before imported calls. The parser composes the tail after retained preamble, name, and release products. No fixed header token check remains duplicated in the parser.

The retained module contains one function and 66 forward-plus-inverse instructions. Three relocations resolve two key checks and quoted-token policy.

## Evidence

`NativeCompilerPackageManifestHeaderTailPhysicalProductExampleTest` retains the owner, resolves all three call targets, and compares function and instruction counts with stage 0. Manifest behavior and identity examples validate complete header ordering and profile quoting through the split path.

The selected set contains 108 comparable products and 30 callable products. The linked closure retains 118 non-empty module products, 427 functions, and 15,227 forward-plus-inverse instructions. It contains 361,824 code bytes, 11,854 local-type rows, 703 source strings, and 566 unique strings. The 459,520-byte executable closure has SHA-256 `b6bfa43493f71e1669d3f2c08f2cc1121a1654f671a93edb1bc53e0e49dd6693`.

## Bootstrap identities

The compiler graph contains 415 modules, two externals, and 1,973 imports. Its 191,002-byte canonical manifest has SHA-256 `ec4db91d669c6d3e9154cfa46d4ab525e70de257635a70d2143f67a80f104b10`. Native validation halts after 80,464,120 transitions. Wheeler SHA-256 consumes the same bytes in 36,556,818 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,254,929-byte compiler archive has SHA-256 `6140bfe05f736094746e5ca1effa8f93a58772b203968cbf4b92aa1232a6b07e`. Every dependent lock names that archive.

## Failure boundary

Reject the wrong profile key, a nonquoted profile, or the wrong targets opener. Reject unnamed imported-call operands, unresolved token-policy targets, stale graph identity, archive mismatch, or closure mismatch before publication.

## Acceptance

- [x] Profile and target-opener validation have one callable owner.
- [x] Token coordinates and hashes bind before imported calls.
- [x] All three token-policy calls resolve.
- [x] Complete manifest behavior executes through the split path.
- [x] Retained function and instruction counts match stage 0.
- [x] The physical set contains 138 products and 427 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Interpret profile text in the parser

The parser's contract is to retain the quoted range. Consumers own profile semantics.

### Leave the targets key in the collection loop

The fixed opener belongs to header validation. Collection parsing starts at the first target row.

### Merge all header owners immediately

The facade is a separate callable product with four imports. Keeping exact leaves first makes its relocation evidence mechanical.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0451](WIP-0451-retained-package-manifest-header-release-product.md)
