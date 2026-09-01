# WIP-0457: Retained package-manifest capability-prefix product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-31 |
| Updated | 2026-08-31 |
| Area | Self-hosting, package manifests, capability rows |
| Depends on | WIP-0049, WIP-0052, WIP-0438, WIP-0442 |
| Supersedes | Capability prefix validation in `PackageManifest.w` |
| Superseded by | None |

## Summary

Split capability-row bounds, sequence syntax, and name-field validation into `PackageManifestCapabilityPrefix.w`. Retain the owner as physical artifact 143 with three resolved policy calls.

## Capability prefix

`manifestCapabilityPrefixValid` proves that the complete seven-token row is bounded, checks the leading dash, checks the cursor-relative `name` key, and requires a quoted name value. It fails after the first rejected condition.

The key coordinate and hash and the name-token coordinate bind before imported calls. `PackageManifest.w` composes this owner before capability path validation and nominal result construction.

The retained module contains one function and 75 forward-plus-inverse instructions. Three relocations resolve dash, key, and quoted-token policy.

## Evidence

`NativeCompilerPackageManifestCapabilityPrefixPhysicalProductExampleTest` retains the owner, resolves all three call targets, and compares function and instruction counts with stage 0. Manifest behavior and identity examples validate accepted and malformed capability prefixes through the split path.

The selected set contains 108 comparable products and 35 callable products. The linked closure retains 123 non-empty module products, 432 functions, and 15,600 forward-plus-inverse instructions. It contains 371,048 code bytes, 12,217 local-type rows, 718 source strings, and 576 unique strings. The 470,968-byte executable closure has SHA-256 `66530482dcc346ac3f9f84ae5a202de1e38fb0cf10a843ea341010c486c720dd`.

## Bootstrap identities

The compiler graph contains 420 modules, two externals, and 1,989 imports. Its 193,132-byte canonical manifest has SHA-256 `7b7f458a6a963f2319308cf56d677b5d092513c447f8c363564f441f3adf2749`. Native validation halts after 81,581,849 transitions. Wheeler SHA-256 consumes the same bytes in 36,960,792 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,259,879-byte compiler archive has SHA-256 `6ae07a1a3979a5360c8b0d26f89d01280f11f4b48b9d4c62f6e2c6e2f7b4bd9e`. Every dependent lock names that archive.

## Failure boundary

Reject a truncated row, missing dash, wrong name key, or nonquoted name. Reject unnamed imported-call operands, unresolved policy targets, stale graph identity, archive mismatch, or closure mismatch before publication.

## Acceptance

- [x] Capability prefix validation has one callable owner.
- [x] Token coordinates and key hash bind before imported calls.
- [x] Dash, key, and quoted-token calls resolve.
- [x] Complete capability behavior executes through the split path.
- [x] Retained function and instruction counts match stage 0.
- [x] The physical set contains 143 products and 432 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Leave capability bounds in the nominal parser

Bounds are part of the scalar prefix verdict and allow later owners to address fixed token offsets safely.

### Validate the quoted name as a package name

Capability names are opaque manifest strings. Existing policy requires quoting, not package-name grammar.

### Merge path validation

The path field resolves a distinct canonical validator and has an independent failure boundary.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0438](WIP-0438-retained-package-manifest-kind-product.md)
- [WIP-0442](WIP-0442-retained-package-manifest-key-product.md)
