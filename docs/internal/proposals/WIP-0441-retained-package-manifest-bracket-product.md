# WIP-0441: Retained package-manifest bracket product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-30 |
| Updated | 2026-08-30 |
| Area | Self-hosting, package manifests, structured source products |
| Depends on | WIP-0049, WIP-0052, WIP-0440 |
| Supersedes | WIP-0440 bracket publication boundary |
| Superseded by | None |

## Summary

Route `PackageManifestBrackets.w` through direct structured source products and retain it as the 127th physical compiler artifact. Keep token bounds in the package parser and preserve exact opening and closing scalar policy.

## Source route

WIP-0440 normalized both bracket functions but left them on the projected scalar-module route. That route feeds the minimal helper parser and rejected the buffer and UTF-8 projection shape before artifact publication.

The bracket owner already consists entirely of supported structured products: named word projections, one UTF-8 scalar projection, signed local comparisons, Boolean returns, and no calls. Adding its canonical owner to `NativeCompilerPhysicalProductSource` selects that general route. No parser exception, generated helper stub, copied dependency source, or bracket-specific compiler rule is added.

`manifestOpenBracketAt` and `manifestCloseBracketAt` retain two functions and 92 forward-plus-inverse instructions. The product has no imports or relocations.

## Evidence

`NativeCompilerPackageManifestBracketsPhysicalProductExampleTest` compares the complete artifact byte for byte with stage 0. Its executable case covers opening, closing, wrong-scalar, and wrong-kind values. `NativeManifestIdentityExampleTest` retains missing and one-sided sequence rejection through the public parser.

The selected set contains 103 comparable products and 24 callable products. The linked closure retains 107 non-empty module products, 413 functions, and 14,717 forward-plus-inverse instructions. It contains 349,368 code bytes, 11,363 local-type rows, 667 source strings, and 541 unique strings. The 443,144-byte executable closure has SHA-256 `52da3bdf3756caebb53d26455494348fe8670a1cd6d86dcfca97c3f848e33461`.

## Bootstrap identities

Physical selection changes no compiler source. The graph remains at 404 modules, two externals, and 1,951 imports. Its 187,128-byte canonical manifest has SHA-256 `289d05c01224c895bf865d0c681c61ce4c2c4dada241f6fc517d71530cea5224`. Native validation still halts after 78,674,029 transitions. Wheeler SHA-256 still consumes 35,823,392 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,243,510-byte compiler archive retains SHA-256 `78e228b2e8efe553a77a74f59224a059e59f8e18bfbb72db80d9eaef8499747d`. Dependent locks remain unchanged.

## Failure boundary

Reject an out-of-range parser coordinate, wrong token kind, wrong scalar, truncated sequence, projected-route fallback, stale selected-set identity, or closure mismatch before publication. The direct route publishes only after complete artifact equality.

## Acceptance

- [x] Both bracket functions use direct structured source products.
- [x] No bracket-specific lowering rule enters the compiler.
- [x] Complete and malformed sequence behavior executes.
- [x] The retained artifact matches stage 0 byte for byte.
- [x] The physical set contains 127 products and 413 retained functions.
- [x] The linked executable identity names the bracket artifact.

## Rejected alternatives

### Extend the minimal helper parser for this owner

Word and UTF-8 projections already have structured products. Teaching a second path the same shape would preserve duplicate lowering policy.

### Generate signature stubs

The owner has no calls. A stub cannot repair local projection publication.

### Keep the owner unselected

The direct route accepts the normalized source without a limit change. Leaving it outside would preserve a solved boundary.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0440](WIP-0440-isolated-package-manifest-bracket-product.md)
