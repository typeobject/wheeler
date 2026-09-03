# WIP-0475: Retained package-manifest empty sections

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-02 |
| Updated | 2026-09-02 |
| Area | Self-hosting, package manifests, collection sections |
| Depends on | WIP-0049, WIP-0440, WIP-0474 |
| Supersedes | Direct empty-section bracket control in `PackageManifest.w` |
| Superseded by | None |

## Summary

Retain the three-way empty-section decision outside the package-manifest parser. `PackageManifestEmptySection.w` distinguishes a row sequence, an empty bracket pair, and a malformed bracket sequence.

## Classification

`manifestEmptySectionKind` returns zero when the current token starts a row, one when it starts the canonical `[]` pair, and negative one when an opening bracket lacks an immediate closing bracket. The function checks the close-token bound before reading the token.

The parser calls the classifier for dependency and capability sections. It advances a valid empty pair, enters row parsing on zero, and reports the section coordinate on a negative result. The parser no longer imports bracket-token policy.

## Physical route

The classifier has one function and two imported bracket-policy calls. It takes the direct imported structured-source path and enters the callable product suffix. Both calls resolve to retained bracket functions.

## Evidence

`NativeCompilerPackageManifestEmptySectionPhysicalProductExampleTest` compares the retained function and instructions with stage 0 and closes both relocations. `NativeManifestExampleTest` executes both canonical empty sections and rejects unterminated dependency and capability brackets.

The selected set contains 112 comparable products and 44 callable products. It retains 136 non-empty module products, 475 functions, and 16,415 forward-plus-inverse instructions. The linked closure contains 391,224 code bytes, 13,120 local-type rows, 787 source strings, and 632 unique strings. Its 500,536-byte executable has SHA-256 `0da3b222354653a5408a492326c3d49c98b1951f8897ad242af7b86b95ec8d8c`.

## Bootstrap identities

The compiler graph contains 433 modules, two externals, and 2,019 imports. Its 198,092-byte canonical manifest has SHA-256 `cb47324598358b9f57aa11adb2887af5d89337d6c68032658cb062607624c9a9`. Native validation halts after 84,065,622 transitions under the 85,000,000-transition evidence ceiling. Wheeler SHA-256 consumes the same bytes in 37,916,236 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,278,609-byte compiler archive has SHA-256 `349d3f6c939a832befac7578c1bf342f1369e7eabb0fc5e48a3011d7616e27c2`. Every dependent lock names that archive.

## Failure boundary

Reject a bounded opening bracket without an immediate close before row iteration or mutation. Reject an unresolved bracket call, stage-0 mismatch, stale graph identity, archive mismatch, linked-closure mismatch, or lock mismatch before bootstrap publication.

## Acceptance

- [x] Empty-section classification has one owner.
- [x] The parser no longer imports bracket-token policy.
- [x] The classifier distinguishes rows, empty pairs, and malformed pairs.
- [x] Both imported bracket calls resolve exactly.
- [x] Empty and malformed dependency and capability sections execute through the owner.
- [x] The retained library matches stage 0 byte for byte.
- [x] The linked closure contains 156 products and 475 functions.
- [x] Manifest, archive, executable, SHA-256, and locks name the classifier.

## Rejected alternatives

### Return a Boolean

A Boolean cannot distinguish a nonempty section from a malformed empty section. Conflating those paths would defer a bracket diagnostic into row parsing.

### Read the close token before checking the bound

The opening bracket may be the final token. Bounds are policy, not an assumption supplied by the parser.

### Keep the decision in the parser

That leaves imported bracket policy and duplicated three-way control in the orchestration module.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0440](WIP-0440-isolated-package-manifest-bracket-product.md)
- [WIP-0474](WIP-0474-retained-package-manifest-collection-sections.md)
