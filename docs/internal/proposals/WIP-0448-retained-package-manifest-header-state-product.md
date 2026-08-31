# WIP-0448: Retained package-manifest header-state product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-31 |
| Updated | 2026-08-31 |
| Area | Self-hosting, package manifests, header validation |
| Depends on | WIP-0049, WIP-0052, WIP-0447 |
| Supersedes | Private header-count and format-version literals in `PackageManifest.w` |
| Superseded by | None |

## Summary

Split fixed package-header token capacity and format-version policy into `PackageManifestHeaderState.w`. Retain the owner as physical artifact 134.

## Header state

`manifestHeaderTokenCount` rejects fewer than 35 tokens, the minimum fixed header plus one collection row. It uses local-left comparison and literal conditional returns so its physical result does not depend on unsupported literal-left source comparison.

`manifestFormatVersion` accepts only token hash 49, the canonical scalar `1`. The parser computes that hash through the retained token owner and passes the named result to header state. Header key order, quoting, package name, release, and profile validation remain in the parser.

The retained module contains two functions and 13 forward-plus-inverse instructions. It has no imports, loops, calls, or relocations.

## Evidence

`NativeCompilerPackageManifestHeaderStatePhysicalProductExampleTest` executes the final short count, first accepted count, adjacent format hash, and accepted format hash. Its physical case compares the complete artifact byte for byte with stage 0. Manifest examples parse and identify the complete header through the split path.

The selected set contains 108 comparable products and 26 callable products. The linked closure retains 114 non-empty module products, 423 functions, and 14,938 forward-plus-inverse instructions. It contains 354,704 code bytes, 11,572 local-type rows, 691 source strings, and 558 unique strings. The 450,680-byte executable closure has SHA-256 `4ee0a0eb3b07b5f8938a658c4f1ab3400a0b0a3c1e2cd48a16a6eb148ad675ac`.

## Bootstrap identities

The compiler graph contains 411 modules, two externals, and 1,959 imports. Its 189,276-byte canonical manifest has SHA-256 `31b4890850ab911a9c4072a3c8efe5bda3aa03acde6f452befbbf5e40bba2f1e`. Native validation halts after 79,688,593 transitions. Wheeler SHA-256 consumes the same bytes in 36,226,160 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,250,078-byte compiler archive has SHA-256 `026c79713068bb02fd206801c564c2e26514c4f73c38eef501234f3ff657ff17`. Every dependent lock names that archive.

## Failure boundary

Reject fewer than 35 tokens or any format hash other than 49. Reject literal-left physical comparison, stale graph identity, archive mismatch, or closure mismatch before publication.

## Acceptance

- [x] Header capacity and format-version policy have one scalar owner.
- [x] Boundary and adjacent format cases execute.
- [x] Complete manifests parse through the split path.
- [x] The retained artifact matches stage 0 byte for byte.
- [x] The physical set contains 134 products and 423 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Retain literal-left comparison

`34 < count` executes under stage 0 but failed direct physical publication. The equivalent local-left conditional has exact evidence.

### Move all header validation at once

Key, token, package-name, release, and profile checks cross several callable owners. Scalar state is independently retainable and keeps the next composition bounded.

### Duplicate format hashing

The token owner already computes the stable hash. Header state owns only accepted format policy.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0447](WIP-0447-retained-package-manifest-selector-product.md)
