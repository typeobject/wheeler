# WIP-0423: Retained semantic-version scalar product

| Field | Value |
| --- | --- |
| Status | Superseded |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-28 |
| Updated | 2026-08-28 |
| Area | Self-hosting, semantic versions, scalar classification |
| Depends on | WIP-0049, WIP-0416, WIP-0422 |
| Supersedes | Private scalar classifiers in `Semver.w` |
| Superseded by | WIP-0424 semantic-version core validation product |

## Summary

Split semantic-version scalar classification from `Semver.w` and retain it as the 112th physical compiler product. Give validation and comparison one shared ASCII authority before their larger loop products are split.

## Problem

`Semver.w` combined scalar classification, release validation, identifier traversal, precedence comparison, and constraint parsing in one owner. That module remains a poor next unit for physical adoption. Its four scalar predicates, however, are closed and independently useful.

The old private classifiers used literal-left ranges and bare Boolean call guards. Both forms obscured the exact direct conditional product. Keeping private copies while adding physical versions would create two authorities.

## Design

`SemverScalars.w` owns decimal digit, uppercase letter, lowercase letter, and identifier-scalar predicates. Every range puts the scalar on the left and uses one half-open upper bound. The identifier predicate accepts those three classes plus dash.

Boolean call results are named and compared explicitly with `true`. Every conditional has one exact return child. The module has no source buffers, allocation, mutation, or hidden locale dependency.

`Semver.w` imports the new module and calls `semverDigit` and `semverIdentifierScalar`. The former private predicates are deleted. Validation and comparison therefore consume the same scalar decisions that the physical product proves.

This split is the first semantic-version WIP. Validation state and precedence traversal remain in `Semver.w` until their own bounded products are closed.

## Evidence

`NativeCompilerSemverScalarsPhysicalProductExampleTest` compiles the archive source through the native physical pipeline. The Wheeler verifier accepts the result and every byte matches stage 0.

The selected set contains 95 comparable products and 17 callable products. The linked closure retains 92 non-empty module products, 321 functions, and 12,190 forward-plus-inverse instructions. It contains 288,280 code bytes, 9,049 local-type rows, 545 source strings, and 434 unique strings. The 362,032-byte executable closure has SHA-256 `3fecbee716c28ac5a11b6cd5260d78a44f654efeadb6eb46d6291b4e8de6b47b`.

## Bootstrap identities

The compiler graph contains 388 modules, two externals, and 1,932 imports. Its 182,189-byte canonical manifest has SHA-256 `dda70dd55212a49ea5f519588db7de54e7f761d497fc08d8ef89ae794a4e6ff8`. Native validation halts after 76,061,847 transitions. Wheeler SHA-256 consumes the same bytes in 34,866,718 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,209,029-byte compiler archive has SHA-256 `9320aa26ddcfff3129754b56217f58094f1bc7fba4bfd95a4526bf94bd4c275c`. Every dependent lock names that archive.

## Failure boundary

Reject a malformed module source, unresolved scalar helper, ambiguous imported name, non-signed argument, malformed Boolean guard, invalid artifact, or stale source identity before publication. Scalars outside ASCII return false. No classifier reads adjacent input.

## Acceptance

- [x] Semantic-version scalar classification has one owner.
- [x] `Semver.w` contains no private duplicate classifier.
- [x] Every range uses local-left half-open comparisons.
- [x] Identifier classification admits only digits, ASCII letters, and dash.
- [x] The native artifact passes the Wheeler verifier.
- [x] The complete artifact matches stage 0 byte for byte.
- [x] The physical set contains 112 products and 321 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Retain all of `Semver.w` at once

Validation and precedence still contain several independent loop-state problems. One monolithic WIP would hide their failure boundaries.

### Copy the private predicates

A copied physical owner would drift from validation. The old predicates are removed and all callers import the new authority.

### Use host character classes

Semantic versions use exact ASCII grammar. Locale and Unicode categories are not part of the package format.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0416](WIP-0416-boolean-source-conditional-return-products.md)
- [WIP-0422](WIP-0422-retained-package-path-product.md)
