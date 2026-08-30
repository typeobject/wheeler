# WIP-0440: Isolated package-manifest bracket product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-30 |
| Updated | 2026-08-30 |
| Area | Self-hosting, package manifests, source products |
| Depends on | WIP-0049, WIP-0439 |
| Supersedes | Generic private punctuation checks in `PackageManifest.w` |
| Superseded by | None |

## Summary

Split opening and closing sequence-bracket checks into `PackageManifestBrackets.w`. Move token bounds into the package parser, reject truncated empty sequences explicitly, and isolate the remaining physical source-product failure without adding an unverified artifact to the selected set.

## Bracket policy

`manifestOpenBracketAt` accepts only punctuation kind three with Unicode scalar 91. `manifestCloseBracketAt` does the same for scalar 93. Both read a caller-validated token coordinate, name kind, start, scalar, expected kind, and expected scalar, and use ordered comparisons rather than a compound array expression.

`PackageManifest.w` checks the opening and closing coordinates before either call. An opening bracket without a closing token now fails at the opening coordinate. Missing or reversed dependency and capability brackets fail before row parsing or publication.

The old `(source, kinds, starts, count, token, scalar)` helper is gone. It admitted punctuation values that canonical package metadata never uses and mixed bounds with scalar policy.

## Physical boundary

Stage 0 executes the split owner and the complete package parser. Focused physical attempts covered the original bounded five-parameter shape, named scalar projections, early bound rejection, and the final four-parameter bracket-only shape. Each failed in structured module composition at `requireMinimalProgram` before artifact publication.

The owner therefore remains outside `NativeCompilerPhysicalModules`. The failure does not change the 126-product set, retain a partial prefix, or claim byte equality. The next source-product change must admit this isolated bracket shape without special-casing package policy.

## Evidence

`NativeCompilerPackageManifestBracketsExampleTest` executes opening, closing, wrong-scalar, and wrong-kind cases. `NativeManifestIdentityExampleTest` rejects missing, opening-only, and closing-only dependency and capability sequences. Manifest and archive examples parse and hash complete metadata through the split owner. The adjacent retained row product still compiles byte for byte from the enlarged archive and manifest.

The selected set remains at 102 comparable products and 24 callable products. Its last complete closure evidence retains 106 non-empty module products, 411 functions, and 14,625 forward-plus-inverse instructions. It contains 347,192 code bytes, 11,287 local-type rows, 663 source strings, and 538 unique strings. The 440,416-byte executable identity remains `bbb6496215bcd38ee32ad9cf8fd6dd0d9274eb7369bd6767d398513af2c3cacc`.

## Bootstrap identities

The compiler graph contains 404 modules, two externals, and 1,951 imports. Its 187,128-byte canonical manifest has SHA-256 `289d05c01224c895bf865d0c681c61ce4c2c4dada241f6fc517d71530cea5224`. Native validation halts after 78,674,029 transitions. Wheeler SHA-256 consumes the same bytes in 35,823,392 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,243,510-byte compiler archive has SHA-256 `78e228b2e8efe553a77a74f59224a059e59f8e18bfbb72db80d9eaef8499747d`. Every dependent lock names that archive.

## Failure boundary

Reject an out-of-range opening or closing coordinate, wrong token kind, wrong scalar, truncated sequence, stale graph evidence, archive mismatch, or attempted bracket artifact publication. A failed physical attempt changes no retained output.

## Acceptance

- [x] Opening and closing brackets have one scalar owner.
- [x] The parser contains no generic punctuation helper.
- [x] Token bounds precede every bracket projection.
- [x] Complete and malformed sequence forms execute.
- [x] The physical attempt fails before artifact publication.
- [x] The selected physical set remains at 126 products.
- [x] Manifest, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Keep a caller-selected scalar

Canonical package metadata uses exactly two sequence punctuation values. A runtime scalar broadens policy without adding a valid form.

### Read before checking token count

A missing closing bracket must fail as syntax, not as an out-of-range buffer access.

### Select the failed owner

Stage execution is not byte equality. The physical set admits only complete published artifacts.

### Special-case brackets in product composition

The source shape is ordinary scalar and buffer logic. The compiler must admit it through general source products.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0439](WIP-0439-retained-package-manifest-row-product.md)
