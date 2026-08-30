# WIP-0438: Retained package-manifest kind product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-30 |
| Updated | 2026-08-30 |
| Area | Self-hosting, package manifests, scalar classification |
| Depends on | WIP-0049, WIP-0052, WIP-0420 |
| Supersedes | Private kind decoders in `PackageManifest.w` |
| Superseded by | None |

## Summary

Split canonical Boolean, target-kind, and dependency-kind decoding into `PackageManifestKinds.w`. Retain the new owner as the 125th physical compiler artifact and resolve its five calls against the retained token-policy owner.

## Kind policy

`manifestBooleanToken` maps `true` to one, `false` to zero, and every other token to minus one. It hashes token text once.

`manifestTargetKind` admits quoted `deployable`, `library`, and `tool` values as kinds one through three. `manifestDependencyKind` admits quoted `normal`, `development`, and `build` values on the same ordinal range. Both reject nonquoted input before hashing its payload. Unknown quoted values remain kind zero.

The numeric products remain unchanged from the package-manifest parser. Moving them gives each spelling table one owner and removes 72 lines of private policy from `PackageManifest.w`.

## Physical product

The owner retains three functions and 122 forward-plus-inverse instructions. One Boolean hash call and each decoder's quoted-shape and quoted-hash calls produce five imported relocations. Every relocation resolves to `PackageManifestTokens.w`. No dependency source or signature-only stub enters the linked product.

The selected set contains 101 comparable products and 24 callable products. The linked closure retains 105 non-empty module products, 407 functions, and 14,565 forward-plus-inverse instructions. It contains 345,688 code bytes, 11,219 local-type rows, 657 source strings, and 533 unique strings. The 438,168-byte executable closure has SHA-256 `670540626edab03e1f4b67c736e273885b80241e36fd328a19c9f6e761f64cf5`.

## Bootstrap identities

The compiler graph contains 402 modules, two externals, and 1,949 imports. Its 186,558-byte canonical manifest has SHA-256 `0759369597d303449bf4cc6a3c6173742fad2fd95c84e37db0bad94e6a32ffa5`. Native validation halts after 78,477,370 transitions. Wheeler SHA-256 consumes the same bytes in 35,713,130 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,240,215-byte compiler archive has SHA-256 `03afee9a284d5c4c8dc8aa2f729b7a25e04e5c3aa5f722a0640e3f005823ae17`. Every dependent lock names that archive.

## Evidence

`NativeCompilerPackageManifestKindsPhysicalProductExampleTest` executes every accepted target and dependency spelling plus both Boolean values. Its physical case compares the complete owner artifact with stage 0, retains exact function and instruction counts, and requires all five callable relocations to resolve.

`NativeManifestExampleTest`, `NativeManifestIdentityExampleTest`, `NativeArchiveExampleTest`, and `NativeArchiveIdentityExampleTest` derive current compiler module closures instead of copying dependency lists. They parse, hash, inspect, and reject complete manifest and archive fixtures through the split parser.

`NativeBootstrapModulesIdentityExampleTest` and `NativeSha256ExampleTest` pin the enlarged source graph. `NativeCompilerPhysicalClosureExampleTest` rebuilds, links, reads, and executes the complete selected closure.

## Failure boundary

Reject a nonquoted kind, unknown spelling, unresolved token-policy target, stale source graph, archive mismatch, or closure identity mismatch before publication. Classification failure remains a scalar zero or minus one for the package parser to reject. It never fabricates a known kind.

## Acceptance

- [x] Boolean and kind spelling tables have one public owner.
- [x] `PackageManifest.w` contains no duplicate kind decoder.
- [x] Every accepted spelling executes under stage 0.
- [x] Manifest and archive examples derive current module closures and execute.
- [x] The retained artifact matches stage 0 byte for byte.
- [x] All five imported relocations resolve to the retained token owner.
- [x] The physical set contains 125 products and 407 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Keep private copies in the parser

That leaves token policy inseparable from row-heavy target and dependency parsing and cannot retain the closed scalar product.

### Hash nonquoted values

Token kind is part of canonical manifest syntax. Hash equality must not turn an identifier into a quoted kind.

### Duplicate token hashing

The retained token owner already defines exact UTF-8 traversal and quoted boundaries. A second implementation would split canonical policy and remove relocation evidence.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0420](WIP-0420-retained-package-manifest-token-product.md)
