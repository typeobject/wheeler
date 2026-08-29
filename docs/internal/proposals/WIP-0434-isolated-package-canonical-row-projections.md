# WIP-0434: Isolated package-canonical row projections

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-29 |
| Updated | 2026-08-29 |
| Area | Self-hosting, package manifests, source products |
| Depends on | WIP-0049, WIP-0433 |
| Supersedes | Compound array expressions in `PackageCanonicalLines.w` |
| Superseded by | None |

## Summary

Route every canonical-line row read through one local scalar projection function. Name every token index, row value, and arithmetic result before punctuation checks. Preserve package behavior and fail closed at the remaining direct conditional-return boundary.

## Problem

WIP-0433 deliberately left `PackageCanonicalLines.w` outside the physical set. Its first physical attempt exposed three separate source-product gaps:

1. Array indexes such as `first + 1` were not direct buffer-projection operands.
2. Declarations combined two array reads and arithmetic in one expression.
3. A returned array expression was not a valid source-value product.

The physical compiler rejected these forms, but the line owner obscured the rejection behind broad expressions. Fixing conditional returns before scalar row projection would leave two authorities for the same read shape.

## Row projection

`rowValue` accepts one mutable word view and one named signed index. It binds `rows[index]` to a signed local and returns that local. Every plain, dashed, punctuation, and final-end helper calls this owner-local function.

Callers name offset constants, token indexes, starts, lengths, kinds, ends, and equality results separately. No array index contains arithmetic. No declaration combines multiple row reads. No return expression reads a row.

The wrapper is local policy, not an imported stub. It has one implementation and ordinary local call coordinates.

## Physical boundary

The normalized owner advances physical source composition past source-value publication. Its focused physical attempt then fails in direct conditional-return materialization after the first group of local row calls. It publishes no artifact and remains outside the selected set.

This WIP does not claim byte equality for `PackageCanonicalLines.w`. WIP-0433 remains the latest retained canonical-line product. The next physical step must close the remaining condition boundary without widening global limits.

## Evidence

`NativeCompilerPackageCanonicalLinesExampleTest` executes plain and dashed key-value lines through the normalized row owner. It checks exact final coordinates, an invalid count, and an invalid final end. `NativeCompilerStructuredCallSourceProductExampleTest` fixes the remaining local-row-call conditional as an explicit no-artifact case.

The complete 121-product closure remains unchanged at 397 functions and 14,272 instructions. Its 429,128-byte executable identity remains `f76cc6a95bb90a6a33096d6ad5eed26f0b4798becab890d5f27310509a917298`.

## Bootstrap identities

The compiler graph remains at 397 modules, two externals, and 1,943 imports. Its 185,040-byte canonical manifest has SHA-256 `f34b99c230acc1e778240e40cc68ff5a64848f4f2fd6ba772b426a3411df38bc`. Native validation halts after 77,448,191 transitions. Wheeler SHA-256 consumes the same bytes in 35,418,020 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,235,304-byte compiler archive has SHA-256 `387ee31b1d28d09e60d242e7d8ad27248c2515498c058fe4b495b23fea8c6980`. Every dependent lock names that archive.

## Failure boundary

Reject an unnamed or arithmetic row index, compound row declaration, direct row return, unavailable token coordinate, invalid line shape, unresolved local projection call, direct conditional-return failure, stale graph identity, or archive mismatch before package publication. A failed physical line artifact never enters the selected set.

## Acceptance

- [x] Every canonical-line row read has one local owner.
- [x] Array indexes are named signed locals.
- [x] Compound row arithmetic is split into scalar declarations.
- [x] Row returns use a named local.
- [x] Plain and dashed line behavior executes unchanged.
- [x] The physical attempt fails before artifact publication.
- [x] The selected closure remains byte-identical.
- [x] Manifest, archive, SHA-256, and locks name the normalized source.

## Rejected alternatives

### Keep direct array expressions

The source product cannot assign stable local coordinates to compound reads and arithmetic.

### Treat the failed physical attempt as evidence

Fail-closed behavior is necessary, but it is not artifact equality. The owner remains unselected.

### Duplicate row reads in each line helper

One local projection owner keeps buffer type, index type, and result type consistent.

### Raise expression or call limits

The normalized source fits existing limits. The remaining condition boundary should be fixed on its own merits.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0433](WIP-0433-retained-package-canonical-line-kind-product.md)
