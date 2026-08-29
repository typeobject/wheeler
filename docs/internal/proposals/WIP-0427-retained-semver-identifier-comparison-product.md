# WIP-0427: Retained semantic-version identifier comparison product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-29 |
| Updated | 2026-08-29 |
| Area | Self-hosting, semantic versions, precedence |
| Depends on | WIP-0048, WIP-0049, WIP-0419, WIP-0424, WIP-0426 |
| Supersedes | Private identifier comparison in `Semver.w` |
| Superseded by | None |

## Summary

Split semantic-version identifier classification and precedence into `SemverIdentifierComparison.w`. Retain it as the 115th physical compiler product, resolve its imported digit classifier to the core-validation owner, and delete the private comparison copy from `Semver.w`.

## Problem

`Semver.w` mixed release traversal with identifier policy. Its identifier loop returned from nested branches at the first difference. Numeric classification returned early at the first nondigit. Neither shape fit the bounded physical loop product.

A first structured form expressed reverse coordinates as `common - 1` and `last - offset` declarations. Stage 0 emitted both subtractions. The physical loop declaration path treated those forms as copies and shortened the function by four instructions. Keeping that mismatch would make the callable product appear valid while changing comparison coordinates.

## Numeric state

`semverNumericIdentifier` carries a signed state initialized to one. Each iteration projects one scalar and width, calls the retained core `semverDigit`, and computes the next state from the prior row. Zero is absorbing. One final helper converts the state to a Boolean result.

The public contract requires a nonempty identifier. Release validation establishes that precondition before comparison.

## Precedence

Numeric identifiers sort before mixed identifiers. Among numeric identifiers, shorter canonical decimal text sorts first. Equal-length numeric identifiers then follow lexical order, which is equivalent to numeric order after leading zeroes have been rejected. Mixed identifiers use lexical order directly.

Lexical comparison scans the common prefix in reverse. A mutable reverse coordinate starts at the common length and decrements once per iteration. Later iterations overwrite the comparison, so the earliest differing scalar wins. This is the same first-difference rule as forward early return without loop-body return products.

The shorter identifier sorts first when the common prefix is equal. A first-nonzero selector gives class precedence over numeric length, then gives both precedence over lexical order.

All valid semantic-version identifiers are ASCII. Scalar offsets are therefore byte offsets after validation.

## Imported calls

The callable product emits one imported identity for `semverDigit`. Local classification, selection, and comparison calls stay owner-local. Every imported relocation resolves to the retained `SemverCoreValidation.w` product before linking.

The owner retains 11 functions and 302 forward-plus-inverse instructions. Focused evidence decodes the physical artifact and checks each owned function extent, in addition to the aggregate retained counts.

## Evidence

`NativeCompilerSemverIdentifierComparisonPhysicalProductExampleTest` retains the callable owner, resolves every imported core target, and verifies per-function instruction extents against stage 0. Its executable fixture covers numeric classification, numeric-before-mixed order, numeric length, mixed lexical order, prefix order, and equality.

The selected set contains 96 comparable products and 19 callable products. The linked closure retains 95 non-empty module products, 372 functions, and 13,652 forward-plus-inverse instructions. It contains 323,704 code bytes, 10,381 local-type rows, 602 source strings, and 488 unique strings. The 408,680-byte executable closure has SHA-256 `b24606dc92a7b1e75d11d285360984b4abce77ec194be4fbf1cb149ff563cb5b`.

## Bootstrap identities

The compiler graph contains 391 modules, two externals, and 1,936 imports. Its 183,157-byte canonical manifest has SHA-256 `d17d64522f2bb2ac250ff792800f3138236c8d6f50c05d4fd6c536e59dcb2100`. Native validation halts after 76,409,730 transitions. Wheeler SHA-256 consumes the same bytes in 35,050,344 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,222,685-byte compiler archive has SHA-256 `807e5e1e1d797f9d541f2961926adcf9831c963035ef1a1a0521a00d17020ca2`. Every dependent lock names that archive.

## Failure boundary

Reject an empty identifier at the caller boundary, invalid identifier scalar, unresolved digit identity, signature mismatch, unsupported subtraction-to-copy lowering, coordinate above 255, unmatched relocation, invalid artifact, or stale graph identity before closure publication. Local helper calls never consume relocation rows.

## Acceptance

- [x] Identifier comparison has one owner below 24 functions.
- [x] `Semver.w` contains no private identifier classifier or comparator.
- [x] Numeric state is absorbing and has no loop-body return.
- [x] Numeric, mixed, length, lexical, prefix, and equal cases execute.
- [x] Reverse traversal preserves first-difference ordering.
- [x] Every imported digit call resolves to the retained core owner.
- [x] Every owned function instruction extent matches stage 0.
- [x] The physical set contains 115 products and 372 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Keep early returns in `Semver.w`

That leaves comparison policy coupled to the facade and outside the physical loop product.

### Use temporary subtraction declarations

The physical declaration path does not encode those loop forms. Silent copy fallback changed both reverse coordinates. A checked decrement already has an exact product and matches stage 0.

### Scan forward and overwrite every difference

The last difference would win. Preserving the first difference would require another nested guard or state selector in the loop.

### Parse numeric identifiers into a signed value

Length and lexical comparison are sufficient after canonical validation. Parsing would reintroduce overflow policy into precedence.

## References

- [WIP-0048](WIP-0048-canonical-native-product-linker.md)
- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0419](WIP-0419-local-right-nested-loop-guards.md)
- [WIP-0424](WIP-0424-retained-semver-core-validation-product.md)
- [WIP-0426](WIP-0426-retained-semver-coordinate-product.md)
