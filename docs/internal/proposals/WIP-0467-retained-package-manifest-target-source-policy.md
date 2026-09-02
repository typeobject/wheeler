# WIP-0467: Retained package-manifest target-source policy

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-01 |
| Updated | 2026-09-01 |
| Area | Self-hosting, package manifests, target rows |
| Depends on | WIP-0049, WIP-0447, WIP-0466 |
| Supersedes | Inline target source ordering and root coverage in `PackageManifest.w` |
| Superseded by | None |

## Summary

Complete the retained target-source owner. `PackageManifestTargetSource.w` now owns path validity, strict adjacent order, and root coverage. The parser retains only source-row iteration, capacity, and publication.

## Source policy

`manifestTargetSourcesOrdered` compares two quoted selector tokens through canonical token-text order and accepts only a negative result. Equal and descending rows reject.

`manifestTargetSourceCoversRoot` projects the quoted interiors of one selector and the target root through named scalar locals, then applies the retained selector-range policy. It neither copies source text nor records coverage state.

Together with WIP-0466, the owner has three functions and four imported calls: quoted-token grammar, logical-path grammar, token-text comparison, and selector-range coverage. `PackageManifest.w` no longer imports selector composition directly. The parser accumulates the coverage Boolean and publishes a row only after all three policy checks and capacity succeed.

## Evidence

`NativeCompilerPackageManifestTargetSourcePhysicalProductExampleTest` compiles the enlarged owner through the direct imported structured-source route, compares retained function and instruction counts with stage 0, and closes all four relocations. `NativeManifestExampleTest` executes ordered selector rows and rejects path escape, reversed order, and missing root coverage.

The selected set remains 110 comparable products and 41 callable products. It retains 131 non-empty module products, 451 functions, and 16,098 forward-plus-inverse instructions. The linked closure contains 383,440 code bytes, 12,735 local-type rows, 753 source strings, and 603 unique strings. Its 488,008-byte executable has SHA-256 `490778282833e293e5f97d54855eb2f9aba3a24becc25ab54f2ae2f4e002b624`.

## Bootstrap identities

The compiler graph remains 428 modules, two externals, and 2,011 imports. Its 196,306-byte canonical manifest has SHA-256 `a921a52366317efc8c8201abac746f2069ce62e568968af7db755226867c3d08`. Native validation halts after 83,467,594 transitions under the 84,000,000-transition evidence ceiling. Wheeler SHA-256 consumes the same bytes in 37,573,300 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,267,532-byte compiler archive has SHA-256 `291d9f14b03199d2d44b9c40ea20dc5394b7a18458b7c70a4dd29b2dd09c4844`. Every dependent lock names that archive.

## Failure boundary

Reject an invalid path, equal or descending selector, uncovered root, exhausted row table, unresolved policy call, stage-0 mismatch, stale graph identity, archive mismatch, or linked-closure mismatch before publication.

## Acceptance

- [x] Path, order, and coverage policy share one target-source owner.
- [x] Token interiors use named scalar projections.
- [x] The parser retains iteration, capacity, state, and publication only.
- [x] All four imported calls resolve exactly.
- [x] Valid and malformed selector lists execute through the retained policy.
- [x] The retained library matches stage 0 byte for byte.
- [x] The linked closure contains 151 products and 451 functions.
- [x] Manifest, archive, executable, SHA-256, and locks name the completed owner.

## Rejected alternatives

### Return comparison ordinals

The parser needs strict-order policy, not a general sorter. A Boolean verdict prevents callers from accepting equality accidentally.

### Copy selector and root text

The token tables already bind immutable source ranges. Copying bytes would add storage and another identity surface without strengthening validation.

### Move row publication into policy

Publication owns caller storage and aggregate counts. Keeping it in the parser preserves one mutation boundary.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0447](WIP-0447-retained-package-manifest-selector-product.md)
- [WIP-0466](WIP-0466-retained-package-manifest-target-source-product.md)
