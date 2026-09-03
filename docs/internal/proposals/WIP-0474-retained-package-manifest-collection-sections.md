# WIP-0474: Retained package-manifest collection sections

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-02 |
| Updated | 2026-09-02 |
| Area | Self-hosting, package manifests, collection sections |
| Depends on | WIP-0049, WIP-0442, WIP-0473 |
| Supersedes | Direct top-level collection-key checks in `PackageManifest.w` |
| Superseded by | None |

## Summary

Split top-level dependency and capability section recognition from the parser. `PackageManifestSections.w` binds both canonical key hashes and delegates token grammar to the retained mapping-key owner.

## Section policy

`manifestDependenciesPresent` checks the `dependencies` key at the first token after target rows. `manifestCapabilitiesPresent` checks the `capabilities` key after the dependency section. Each function names its hash before the imported call and returns one Boolean verdict.

The parser advances section cursors, recognizes empty brackets, iterates rows, and owns diagnostics. It no longer imports generic mapping-key policy directly.

## Physical route

The section owner has two functions and two imported calls. It takes the direct imported structured-source path and enters the callable product suffix. Its source route is explicit; signature-only synthesis cannot replace it.

## Evidence

`NativeCompilerPackageManifestSectionsPhysicalProductExampleTest` compares retained functions and instructions with stage 0 and closes both key-policy relocations. `NativeManifestExampleTest` executes empty and nonempty sections and rejects misspelled dependency and capability section keys.

The selected set contains 112 comparable products and 43 callable products. It retains 135 non-empty module products, 474 functions, and 16,364 forward-plus-inverse instructions. The linked closure contains 389,984 code bytes, 13,073 local-type rows, 784 source strings, and 630 unique strings. Its 498,960-byte executable has SHA-256 `8fe1142e496ec36b5153a6ab478056fb0203c91f5d2c230e28bb7fc11676f08f`.

## Bootstrap identities

The compiler graph contains 432 modules, two externals, and 2,018 imports. Its 197,782-byte canonical manifest has SHA-256 `b7e19c43d487165504fe7bc51bb7bcdc48f1cb3f3e046bf29196c75ccef4014d`. Native validation halts after 83,963,697 transitions under the 85,000,000-transition evidence ceiling. Wheeler SHA-256 consumes the same bytes in 37,854,926 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,278,001-byte compiler archive has SHA-256 `468e895e276f349fbe8d40f51e76143778872ea86906df73d2a37f90836cbb1f`. Every dependent lock names that archive.

## Failure boundary

Reject a misspelled section key before bracket recognition, row iteration, or mutation. Reject an unresolved key-policy call, stage-0 mismatch, stale graph identity, archive mismatch, linked-closure mismatch, or lock mismatch before bootstrap publication.

## Acceptance

- [x] Dependency and capability section hashes have one owner.
- [x] The parser no longer imports generic key policy.
- [x] Both section functions use named hashes and Boolean verdicts.
- [x] Both imported calls resolve exactly.
- [x] Empty, nonempty, and misspelled sections execute through the owner.
- [x] The retained library matches stage 0 byte for byte.
- [x] The linked closure contains 155 products and 474 functions.
- [x] Manifest, archive, executable, SHA-256, and locks name the section owner.

## Rejected alternatives

### Fold section keys into row prefixes

Section keys delimit collections; row prefixes validate members. Combining them would give row policy ownership of parser-level state.

### Keep hashes in the parser

The parser should compose section verdicts. Carrying raw hashes there duplicates the target-tail coupling removed by WIP-0469.

### Accept singular aliases

Canonical package manifests have one spelling per section. Compatibility aliases would silently expand the bootstrap language.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0442](WIP-0442-retained-package-manifest-key-product.md)
- [WIP-0469](WIP-0469-retained-package-manifest-target-field-keys.md)
- [WIP-0473](WIP-0473-retained-package-manifest-target-value-coordinates.md)
