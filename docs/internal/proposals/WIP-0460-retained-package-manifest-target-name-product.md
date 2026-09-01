# WIP-0460: Retained package-manifest target-name product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-31 |
| Updated | 2026-08-31 |
| Area | Self-hosting, package manifests, target rows |
| Depends on | WIP-0049, WIP-0052, WIP-0421, WIP-0459 |
| Supersedes | Target name validation in `PackageManifest.w` |
| Superseded by | None |

## Summary

Split target name-field validation into `PackageManifestTargetName.w`. Retain the owner as physical artifact 146 with three resolved policy calls.

## Target name

`manifestTargetNameValid` checks the cursor-relative `name` key, requires a quoted value, projects its interior range through named locals, and calls canonical workspace-name validation. It fails after the first rejected condition.

The key coordinate and hash and the name-token coordinate bind before imported calls. `PackageManifest.w` composes this owner after retained target-prefix validation and before target root validation.

The retained module contains one function and 74 forward-plus-inverse instructions. Three relocations resolve key, quoted-token, and workspace-name policy.

## Evidence

`NativeCompilerPackageManifestTargetNamePhysicalProductExampleTest` retains the owner, resolves all three call targets, and compares function and instruction counts with stage 0. Manifest behavior and identity examples validate accepted and malformed target names through the split path.

The selected set contains 108 comparable products and 38 callable products. The linked closure retains 126 non-empty module products, 435 functions, and 15,827 forward-plus-inverse instructions. It contains 376,688 code bytes, 12,441 local-type rows, 727 source strings, and 582 unique strings. The 477,952-byte executable closure has SHA-256 `ab1a19bc27ae7826840d5a8683ab2137fbc0c664f38daa4bb016295c5c919db1`.

## Bootstrap identities

The compiler graph contains 423 modules, two externals, and 2,001 imports. Its 194,504-byte canonical manifest has SHA-256 `c63eb8e1428b7f65ab7578093f83d712b73b2308cd46ecf0655899e5785e81d2`. Native validation halts after 82,685,935 transitions. Wheeler SHA-256 consumes the same bytes in 37,230,492 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,261,456-byte compiler archive has SHA-256 `08f21c2fc13f14d78eae6a7d2319d7ed8535f276886e39746630e1ec6617aadb`. Every dependent lock names that archive.

## Failure boundary

Reject the wrong name key, a nonquoted value, or an invalid workspace name. Reject unnamed imported-call operands, unresolved policy targets, stale graph identity, archive mismatch, or closure mismatch before publication.

## Acceptance

- [x] Target name validation has one callable owner.
- [x] Token coordinates and hash bind before imported calls.
- [x] Key, quoted-token, and workspace-name calls resolve.
- [x] Complete target behavior executes through the split path.
- [x] Retained function and instruction counts match stage 0.
- [x] The physical set contains 146 products and 435 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Keep name projection in the nominal parser

The field has a scalar verdict and no need to own the target result record.

### Use package-name validation

Target names use workspace-name grammar. The retained names owner keeps those policies distinct.

### Merge root validation

Name and root fields resolve distinct validators and have independent failure boundaries.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0421](WIP-0421-retained-package-name-product.md)
- [WIP-0459](WIP-0459-retained-package-manifest-target-prefix-product.md)
