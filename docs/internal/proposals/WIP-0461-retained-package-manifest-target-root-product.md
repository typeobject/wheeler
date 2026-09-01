# WIP-0461: Retained package-manifest target-root product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-31 |
| Updated | 2026-08-31 |
| Area | Self-hosting, package manifests, target rows |
| Depends on | WIP-0049, WIP-0052, WIP-0422, WIP-0460 |
| Supersedes | Target root validation in `PackageManifest.w` |
| Superseded by | None |

## Summary

Split target root-field validation into `PackageManifestTargetRoot.w`. Retain the owner as physical artifact 147 with three resolved policy calls.

## Target root

`manifestTargetRootValid` checks the cursor-relative `root` key, requires a quoted value, projects its interior range through named locals, and calls canonical logical-path validation. It fails after the first rejected condition.

The key coordinate and hash and the root-token coordinate bind before imported calls. `PackageManifest.w` composes this owner after retained target-name validation and before optional module and selector validation.

The retained module contains one function and 74 forward-plus-inverse instructions. Three relocations resolve key, quoted-token, and logical-path policy.

## Evidence

`NativeCompilerPackageManifestTargetRootPhysicalProductExampleTest` retains the owner, resolves all three call targets, and compares function and instruction counts with stage 0. Manifest behavior and identity examples validate accepted and malformed target roots through the split path.

The selected set contains 108 comparable products and 39 callable products. The linked closure retains 127 non-empty module products, 436 functions, and 15,901 forward-plus-inverse instructions. It contains 378,536 code bytes, 12,515 local-type rows, 730 source strings, and 584 unique strings. The 480,240-byte executable closure has SHA-256 `1a87c430ab0f40240e28ffced2312db44f4507005b73051516956a21addde8bc`.

## Bootstrap identities

The compiler graph contains 424 modules, two externals, and 2,005 imports. Its 194,951-byte canonical manifest has SHA-256 `77e63d9e4e7146d5d6a076af39bffd586e275c5a526e8681ba4182503588a517`. Native validation halts after 82,856,453 transitions. Wheeler SHA-256 consumes the same bytes in 37,316,222 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,262,051-byte compiler archive has SHA-256 `97c89f01d732b8cbdc99a0071471050e1b413b946be76db5f0b1cd3ae6719e91`. Every dependent lock names that archive.

## Failure boundary

Reject the wrong root key, a nonquoted value, or an invalid logical path. Reject unnamed imported-call operands, unresolved policy targets, stale graph identity, archive mismatch, or closure mismatch before publication.

## Acceptance

- [x] Target root validation has one callable owner.
- [x] Token coordinates and hash bind before imported calls.
- [x] Key, quoted-token, and logical-path calls resolve.
- [x] Complete target behavior executes through the split path.
- [x] Retained function and instruction counts match stage 0.
- [x] The physical set contains 147 products and 436 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Keep root projection in the nominal parser

The field has a scalar verdict and no need to own the target result record.

### Accept host paths

Target roots use package logical-path grammar and remain independent of host path syntax.

### Merge optional module validation

Module metadata has distinct presence and name semantics and an independent failure boundary.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0422](WIP-0422-retained-package-path-product.md)
- [WIP-0460](WIP-0460-retained-package-manifest-target-name-product.md)
