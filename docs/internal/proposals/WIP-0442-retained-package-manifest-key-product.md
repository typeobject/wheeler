# WIP-0442: Retained package-manifest key product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-31 |
| Updated | 2026-08-31 |
| Area | Self-hosting, package manifests, imported call products |
| Depends on | WIP-0049, WIP-0052, WIP-0420, WIP-0441 |
| Supersedes | Private mapping-key composition in `PackageManifest.w` |
| Superseded by | None |

## Summary

Split canonical keyword-and-colon composition into `PackageManifestKeys.w`. Retain the owner as the 128th physical compiler artifact and resolve both calls against the retained token-policy owner.

## Key composition

`manifestKeyAt` accepts source, token rows, token count, keyword coordinate, and expected hash. It names the following colon coordinate and rejects an exhausted token window before hashing.

The function calls `keywordAt` once. A hash mismatch returns false without reading punctuation. A match calls `colonAt` once and returns that named Boolean result. This flat order replaces the parser's nested private helper and gives bounds, hash policy, and colon policy explicit coordinates.

All nineteen package-parser key sites use the new owner. The old private implementation is gone.

## Physical product

The initial nested source shape failed during direct callable composition. Naming the bound, rejecting false states early, and assigning both imported results produces the same semantics with complete source-value products.

The retained owner contains one function and 46 forward-plus-inverse instructions. Its keyword and colon calls produce two imported relocations. Both resolve uniquely to `PackageManifestTokens.w`. No dependency source or signature-only stub enters the product.

## Evidence

`NativeCompilerPackageManifestKeysPhysicalProductExampleTest` executes a valid key, hash mismatch, text mismatch, one-character key, and exhausted coordinate. Its physical case compares the complete owner artifact with stage 0 and requires both relocations to resolve.

Manifest and archive examples parse complete package metadata through all nineteen imported key calls. The selected set contains 103 comparable products and 25 callable products. The linked closure retains 108 non-empty module products, 414 functions, and 14,763 forward-plus-inverse instructions. It contains 350,496 code bytes, 11,410 local-type rows, 670 source strings, and 543 unique strings. The 444,584-byte executable closure has SHA-256 `a7bd0e7d27b878169258f7a70ae274db8b17b51e2ab3ed8e0a095c1409bf4bf0`.

## Bootstrap identities

The compiler graph contains 405 modules, two externals, and 1,953 imports. Its 187,456-byte canonical manifest has SHA-256 `ea6ce09d3a13e872c7b20584acce94aee1ed3942eca0c90707bcd2fe46dd1771`. Native validation halts after 78,858,882 transitions. Wheeler SHA-256 consumes the same bytes in 35,883,489 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,245,047-byte compiler archive has SHA-256 `48233c0cc37644bd8181f0ff6fec6fbacd2bd1014bb9069cdaf390b64a979b07`. Every dependent lock names that archive.

## Failure boundary

Reject an exhausted key, wrong keyword hash, noncolon follower, unresolved token-policy target, stale graph identity, archive mismatch, or linked closure mismatch before publication. A failed key remains Boolean false for the package parser to reject at its exact coordinate.

## Acceptance

- [x] Mapping-key composition has one public owner.
- [x] The package parser contains no private key helper.
- [x] Bounds, hash mismatch, colon mismatch, and success execute.
- [x] The retained artifact matches stage 0 byte for byte.
- [x] Both imported relocations resolve to retained token policy.
- [x] The physical set contains 128 products and 414 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Keep nested imported calls

The nested form obscures call-result coordinates and fails direct source composition. Flat early rejection preserves policy and publishes exact values.

### Hash after reading punctuation

Bounds and keyword identity precede colon policy. Reordering performs unnecessary source reads on malformed keys.

### Duplicate colon checks

`PackageManifestTokens.w` already owns punctuation kind and scalar policy. Resolving that call preserves one canonical authority.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0420](WIP-0420-retained-package-manifest-token-product.md)
- [WIP-0441](WIP-0441-retained-package-manifest-bracket-product.md)
