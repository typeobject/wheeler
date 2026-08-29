# WIP-0426: Retained semantic-version coordinate product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-28 |
| Updated | 2026-08-28 |
| Area | Self-hosting, semantic versions, bounded coordinates |
| Depends on | WIP-0049, WIP-0052, WIP-0417, WIP-0418, WIP-0425 |
| Supersedes | Private semantic-version coordinate loops in `Semver.w` |
| Superseded by | None |

## Summary

Split and retain `SemverCoordinates.w` as the 114th physical compiler product. Project core component values, prerelease starts, and identifier ends without loop-body returns or nested cursor mutation.

## Problem

Semantic-version precedence used three small coordinate loops inside `Semver.w`. Each loop combined UTF-8 projection, delimiter detection, cursor mutation, and an early stop. Core extraction also nested multiplication and two additions in one assignment.

Those loops are independent of precedence policy. Leaving them in the facade would force the later comparison WIP to close coordinate mechanics and ordering in one artifact.

## Coordinate products

Core component projection tracks cursor, current component ordinal, and selected value. Dash sends the cursor to the release end. Dot advances the ordinal. A digit contributes only when the prior ordinal matches the requested major, minor, or patch coordinate. Multiplication, scalar addition, and ASCII offset subtraction are named declarations.

Prerelease projection tracks cursor and a projected start initialized to the release end. The first dash records `cursor + 1` and ends traversal.

Identifier projection tracks cursor and a projected end initialized to the prerelease end. The first dot records its cursor and ends traversal.

Every loop computes all next values from the same prior row. Each source scalar has one scalar projection, one width projection, and one cursor assignment. No helper reads beyond the supplied half-open range.

`Semver.w` imports the new owner and deletes its private copies. Precedence policy now calls the public coordinate functions.

## Evidence

`NativeCompilerSemverCoordinatesPhysicalProductExampleTest` compiles the coordinate owner through the native physical pipeline. The Wheeler verifier accepts the result and every byte matches stage 0. A focused executable fixture projects `10.20.30-alpha.7` to all three core values, the prerelease start, and both identifier ends.

The selected set contains 96 comparable products and 18 callable products. The linked closure retains 94 non-empty module products, 361 functions, and 13,350 forward-plus-inverse instructions. It contains 316,360 code bytes, 10,114 local-type rows, 589 source strings, and 476 unique strings. The 398,952-byte executable closure has SHA-256 `65301e9e45042d5e407cceb716f6dc680ba80d61803829a0f9bbc4bdb846bf3e`.

The 114-product closure crosses the former 24-minute method deadline on the reference host. The closure-evidence method deadline rises to 45 minutes. The Gradle task deadline rises to 50 minutes. Routine focused tests retain their existing bounds.

## Bootstrap identities

The compiler graph contains 390 modules, two externals, and 1,935 imports. Its 182,853-byte canonical manifest has SHA-256 `c43d5ee12abd175999fbf58b5a86b7fdb7c5bc08f64b106218afcd84018605f9`. Native validation halts after 76,341,189 transitions. Wheeler SHA-256 consumes the same bytes in 35,001,744 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,218,891-byte compiler archive has SHA-256 `cd12d26124da5becdc9f9c2f44b67ee25790845b9c9f362534d4565c07804455`. Every dependent lock names that archive.

## Failure boundary

Reject a component outside the caller's closed set, malformed UTF-8 projection, unresolved coordinate call, arithmetic overflow, coordinate above 255, invalid artifact, stale source identity, or closure run beyond the explicit evidence deadline before publication. Delimiters stop traversal but never enter component values.

## Acceptance

- [x] Core, prerelease, and identifier coordinates have one owner.
- [x] `Semver.w` contains no private duplicate coordinate loop.
- [x] Every next field consumes one prior state row.
- [x] Core arithmetic uses focused declarations.
- [x] The native artifact passes the Wheeler verifier.
- [x] The complete artifact matches stage 0 byte for byte.
- [x] Focused execution covers core, prerelease, and identifier coordinates.
- [x] The physical set contains 114 products and 361 retained functions.
- [x] The complete closure passes under the explicit evidence deadline.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Keep coordinate loops in the comparison facade

Coordinate mechanics and precedence policy have separate invariants. One artifact would make both harder to review.

### Advance cursors inside delimiter branches

Each loop has one cursor product. Delimiters select the end coordinate instead of bypassing the ordinary update.

### Parse all three core components in one packed return

The bytecode profile has scalar returns. Packing would add a codec and duplicate overflow concerns already handled by validation.

### Remove the complete closure test to avoid its deadline

Focused artifacts do not prove linked owner, relocation, string, type, and container identities. The measured test remains mandatory under an explicit bound.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0417](WIP-0417-utf8-loop-projection-products.md)
- [WIP-0418](WIP-0418-focused-loop-arithmetic-declarations.md)
- [WIP-0425](WIP-0425-retained-semver-prerelease-validation-product.md)
