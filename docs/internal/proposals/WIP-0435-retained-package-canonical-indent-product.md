# WIP-0435: Retained package-canonical indent product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-29 |
| Updated | 2026-09-05 |
| Area | Self-hosting, package manifests, canonical sections |
| Depends on | WIP-0049, WIP-0432, WIP-0433 |
| Supersedes | Nested section and indentation policy in `PackageCanonical.w` |
| Superseded by | None |

## Summary

Split canonical manifest section transitions and indentation selection into `PackageCanonicalIndent.w`. Retain it as the 122nd physical compiler product and replace the nested policy tree in `PackageCanonical.w` with two scalar calls.

## Section state

Lines zero through four preserve the current section. Line five enters the target
section. `WORD_DEPENDENCIES` enters section two. `WORD_CAPABILITIES` enters section
three. Other later lines preserve prior state. The old development-dependencies
name described the capabilities hash incorrectly.

Section selection consumes line, exact word code, and prior section. It has no
buffer, source, or token-table dependency.

## Indentation policy

Lines zero and one use zero spaces. Lines two through four use two spaces. Line five and both later section headers use zero spaces.

Other punctuation-led lines use six spaces for two-token dashed values and two spaces for dashed key-value rows. Remaining nested fields use four spaces.

WIP-0049 removed both header hashes. `PackageCanonical.w` classifies the first
word once, calls both scalar products, and commits the next section. The indent
owner imports the shared word constants.

## Evidence

`NativeCompilerPackageManifestWordsExampleTest` covers fixed line ranges, section
transitions and preservation, header indents, dashed indents, and field indent.
[WIP-0049](WIP-0049-bounded-native-source-product-compilation.md#manifest-composition)
owns the combined physical pass. The standalone indent fixture is gone.

The original artifact retained two functions and 85 instructions without imports.
The current owner imports shared word constants. Its combined physical pass
compares complete callable bodies after function-ID rebinding, without admitting
unrelated dependency bodies into the reference.
The following identities record that milestone.

The selected set contains 99 comparable products and 23 callable products. The linked closure retains 102 non-empty module products, 399 functions, and 14,357 forward-plus-inverse instructions. It contains 340,768 code bytes, 11,037 local-type rows, 643 source strings, and 522 unique strings. The 431,552-byte executable closure has SHA-256 `565962dfcc2fb031441d47f4ecdc51c3927ea5c85b24ef590d037f32ae8cdaaa`.

## Bootstrap identities

The compiler graph contains 398 modules, two externals, and 1,944 imports. Its 185,329-byte canonical manifest has SHA-256 `5e46613ac3d9b1938dce20945d2766c6921199a76cc54932190011d4e56ab796`. Native validation halts after 77,446,929 transitions. Wheeler SHA-256 consumes the same bytes in 35,466,740 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,236,138-byte compiler archive has SHA-256 `4b5e79fd6f34a287dba57669548f28fd7b5ef421f963a7fd11f388c443d38511`. Every dependent lock names that archive.

## Failure boundary

Reject an unknown header word as a transition, line or token count outside the caller's bounded domain, unresolved indent call, wrong section preservation, invalid artifact, stale graph identity, or archive mismatch before publication. Unknown later lines retain their section and receive punctuation or field indentation.

## Acceptance

- [x] Section transition policy has one scalar owner.
- [x] Indentation policy has one scalar owner.
- [x] Canonical header identity has one owner.
- [x] Every section and indent class executes.
- [x] The native artifact matches stage 0 byte for byte.
- [x] `PackageCanonical.w` contains no nested indent tree.
- [x] The physical set contains 122 products and 399 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Duplicate header identities in the root loop

Token policy owns exact spellings. Section policy consumes those word codes.
Duplicating either in traversal makes later grammar changes error-prone.

### Return one packed section-indent scalar

Packing introduces a codec and ties two independently testable products together.

### Infer section from indentation

Indentation is validated layout, not semantic section state. Headers own transitions.

### Retain the complete canonical owner now

Array-backed line conditions remain outside the physical set under WIP-0434. This scalar split does not overstate that boundary.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0432](WIP-0432-retained-package-canonical-coordinate-product.md)
- [WIP-0433](WIP-0433-retained-package-canonical-line-kind-product.md)
