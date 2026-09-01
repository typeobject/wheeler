# WIP-0458: Retained package-manifest capability-path product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-31 |
| Updated | 2026-08-31 |
| Area | Self-hosting, package manifests, capability rows |
| Depends on | WIP-0049, WIP-0052, WIP-0422, WIP-0457 |
| Supersedes | Capability path validation in `PackageManifest.w` |
| Superseded by | None |

## Summary

Split capability path-field validation into `PackageManifestCapabilityPath.w`. Retain the owner as physical artifact 144 with three resolved policy calls.

## Capability path

`manifestCapabilityPathValid` checks the cursor-relative `path` key, requires a quoted value, projects its interior range through named locals, and calls canonical logical-path validation. It fails after the first rejected condition.

The key coordinate and hash and the path-token coordinate bind before imported calls. `PackageManifest.w` composes this owner after retained capability-prefix validation, then constructs the nominal capability result.

The retained module contains one function and 74 forward-plus-inverse instructions. Three relocations resolve key, quoted-token, and logical-path policy.

## Evidence

`NativeCompilerPackageManifestCapabilityPathPhysicalProductExampleTest` retains the owner, resolves all three call targets, and compares function and instruction counts with stage 0. Manifest behavior and identity examples validate accepted and malformed capability paths through the split path.

The selected set contains 108 comparable products and 36 callable products. The linked closure retains 124 non-empty module products, 433 functions, and 15,674 forward-plus-inverse instructions. It contains 372,896 code bytes, 12,291 local-type rows, 721 source strings, and 578 unique strings. The 473,264-byte executable closure has SHA-256 `8afaa144deed528d4771e53b109011dea4242b44d15dc1f741f17cd030234932`.

## Bootstrap identities

The compiler graph contains 421 modules, two externals, and 1,993 imports. Its 193,595-byte canonical manifest has SHA-256 `7ab4d7eb103393dab3d68f0b7af51ec4025d64cd614e63049a98580450d8e931`. Native validation halts after 81,765,233 transitions. Wheeler SHA-256 consumes the same bytes in 37,060,214 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,261,111-byte compiler archive has SHA-256 `11b6beb79e5434f4e0cf513f8c8f83d386857f0d87d55fbb0ba081f6bcbe921e`. Every dependent lock names that archive.

## Failure boundary

Reject the wrong path key, a nonquoted value, or an invalid logical path. Reject unnamed imported-call operands, unresolved policy targets, stale graph identity, archive mismatch, or closure mismatch before publication.

## Acceptance

- [x] Capability path validation has one callable owner.
- [x] Token coordinates and hash bind before imported calls.
- [x] Key, quoted-token, and logical-path calls resolve.
- [x] Complete capability behavior executes through the split path.
- [x] Retained function and instruction counts match stage 0.
- [x] The physical set contains 144 products and 433 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Keep path projection in the nominal parser

The field has a scalar verdict and no need to own the capability result record.

### Duplicate path validation

The retained paths owner remains canonical. Capability validation supplies its bounded interior range.

### Admit file-system paths

Package capability paths use the logical-path grammar and remain independent of host path syntax.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0422](WIP-0422-retained-package-path-product.md)
- [WIP-0457](WIP-0457-retained-package-manifest-capability-prefix-product.md)
