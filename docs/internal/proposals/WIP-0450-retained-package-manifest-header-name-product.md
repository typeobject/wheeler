# WIP-0450: Retained package-manifest header-name product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-31 |
| Updated | 2026-08-31 |
| Area | Self-hosting, package manifests, callable products |
| Depends on | WIP-0049, WIP-0052, WIP-0449 |
| Supersedes | Header name validation in `PackageManifest.w` |
| Superseded by | None |

## Summary

Split fixed package-name header validation into `PackageManifestHeaderName.w`. Retain the owner as physical artifact 136 with three resolved policy calls.

## Name validation

`manifestHeaderNameValid` checks the fixed `name` key, requires the value token to be quoted, projects its interior range through named locals, and calls canonical package-name validation. It fails after the first rejected condition.

The key coordinate, key hash, and value-token coordinate bind before their calls. This follows the imported-call source profile established by WIP-0449 and keeps token projection out of call operands. The parser composes name validation after the retained format preamble.

The retained module contains one function and 70 forward-plus-inverse instructions. Three relocations resolve to key, quoted-token, and package-name policy.

## Evidence

`NativeCompilerPackageManifestHeaderNamePhysicalProductExampleTest` retains the owner, resolves all three call targets, and compares its function and instruction counts with stage 0. Manifest behavior and identity examples validate canonical and malformed headers through the split path.

The selected set contains 108 comparable products and 28 callable products. The linked closure retains 116 non-empty module products, 425 functions, and 15,091 forward-plus-inverse instructions. It contains 358,480 code bytes, 11,720 local-type rows, 697 source strings, and 562 unique strings. The 455,344-byte executable closure has SHA-256 `ab393df133dcf7f0871146b1517979043639ebb84542f01207245fbae49bf348`.

## Bootstrap identities

The compiler graph contains 413 modules, two externals, and 1,966 imports. Its 190,140-byte canonical manifest has SHA-256 `d39a5920aaca5da2be0abd8f9da41df9e1be69722eefc87511aed112606b5f93`. Native validation halts after 80,473,365 transitions. Wheeler SHA-256 consumes the same bytes in 36,398,922 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,252,460-byte compiler archive has SHA-256 `2217087d6769852f5144eadd0725dcb17e3f06a18896b5f04a678ad729cee67f`. Every dependent lock names that archive.

## Failure boundary

Reject the wrong name key, a nonquoted value, or an invalid package name. Reject unnamed imported-call operands, unresolved policy targets, stale graph identity, archive mismatch, or closure mismatch before publication.

## Acceptance

- [x] Header name validation has one callable owner.
- [x] Token coordinates and hash bind before imported calls.
- [x] All three policy calls resolve.
- [x] Complete manifest behavior executes through the split path.
- [x] Retained function and instruction counts match stage 0.
- [x] The physical set contains 136 products and 425 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Leave interior projection in call operands

Named projection locals are part of the exact physical source profile and expose independent coordinate failures.

### Duplicate package-name validation

The retained name owner remains canonical. Header validation resolves it instead of copying its state machine.

### Merge release and profile validation

Each fixed field has a separate call graph and failure boundary. Small products produce sharper evidence.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0449](WIP-0449-retained-package-manifest-header-preamble-product.md)
