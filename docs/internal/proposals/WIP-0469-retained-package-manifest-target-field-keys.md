# WIP-0469: Retained package-manifest target-field keys

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-02 |
| Updated | 2026-09-02 |
| Area | Self-hosting, package manifests, target rows |
| Depends on | WIP-0049, WIP-0442, WIP-0464, WIP-0465, WIP-0467 |
| Supersedes | Direct `module`, `sources`, and `test` key checks in `PackageManifest.w` |
| Superseded by | None |

## Summary

Move the three target-tail key verdicts to their field owners. Module, source, and test policy now each bind their canonical key hash and delegate token grammar to `PackageManifestKeys.w`. The parser no longer carries target-tail key hashes.

## Field keys

`manifestTargetModulePresent` checks the optional `module` key at the coordinate supplied by WIP-0463. A false verdict leaves the target nonmodular. Malformed module content still rejects after presence succeeds.

`manifestTargetSourcesPresent` checks the required `sources` key after a valid module field. Its false verdict rejects before selector iteration or row mutation.

`manifestTargetTestPresent` checks the required `test` key at the first token after the optional source list. Its false verdict rejects before Boolean parsing and kind policy.

Each owner names the key hash in a local before the imported call. Both stage 0 and the bounded structured-source compiler accept this source shape. Documentation quotes the literal `module` spelling so the archive scanner sees exactly one source module declaration.

## Physical route

Module and source policy retain one additional relocation each. Test policy changes from a call-free comparable product to a callable product with one resolved key-policy relocation. The selected set remains 152 products: 110 comparable and 42 callable.

## Evidence

The module, source, and test physical-product tests compare retained functions and instructions with stage 0 and close three, five, and one relocation respectively. `NativeManifestExampleTest` executes the composed target parser and rejects misspelled `module`, `sources`, and `test` keys independently.

The closure retains 132 non-empty module products, 456 functions, and 16,178 forward-plus-inverse instructions. It contains 385,400 code bytes, 12,837 local-type rows, 760 source strings, and 609 unique strings. Its 491,040-byte executable has SHA-256 `1de6833e6e8604757ab98554d42143917db62574d6666649fc9e3904ede28c2e`.

## Bootstrap identities

The compiler graph contains 429 modules, two externals, and 2,015 imports. Its 196,800-byte canonical manifest has SHA-256 `bb7abe1fecadcd6b39235243ad9036eb144f475386120718338dd340bb50c401`. Native validation halts after 83,701,512 transitions under the 84,000,000-transition evidence ceiling. Wheeler SHA-256 consumes the same bytes in 37,671,405 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,270,261-byte compiler archive has SHA-256 `ca71fd71b57e0ab1b70ae4cb9273a3acdaf1adc2ceac653e4f66509b262346a5`. Every dependent lock names that archive.

## Failure boundary

Reject a misspelled field key before value parsing, selector iteration, table mutation, or row publication. Reject an unresolved key-policy call, stage-0 mismatch, stale graph identity, archive mismatch, linked-closure mismatch, or lock mismatch before bootstrap publication.

## Acceptance

- [x] Module, sources, and test key hashes each have one field owner.
- [x] The parser carries no target-tail key hash.
- [x] Each owner delegates key grammar to retained token policy.
- [x] All nine owner relocations resolve exactly.
- [x] Misspelled target-tail keys execute through the composed parser.
- [x] The retained libraries match stage 0 byte for byte.
- [x] The linked closure contains 152 products and 456 functions.
- [x] Manifest, archive, executable, SHA-256, and locks name the field owners.

## Rejected alternatives

### Add a target-tail key switch

A shared switch would separate each hash from the field policy that consumes its value. It would also create another discriminator that the parser must interpret.

### Keep hashes in the parser

The parser should compose field verdicts. Owning hashes there repeats the coupling removed from dependency, capability, and header fields.

### Accept aliases

Canonical manifests have one spelling for each field. Alias handling belongs at an explicit migration boundary, not in the bootstrap parser.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0442](WIP-0442-retained-package-manifest-key-product.md)
- [WIP-0464](WIP-0464-retained-package-manifest-target-test-product.md)
- [WIP-0465](WIP-0465-retained-package-manifest-target-module-product.md)
- [WIP-0467](WIP-0467-retained-package-manifest-target-source-policy.md)
