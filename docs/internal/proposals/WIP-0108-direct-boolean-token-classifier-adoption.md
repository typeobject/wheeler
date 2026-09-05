# WIP-0108: Direct Boolean token-classifier adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-09-05 |
| Area | Self-hosting compiler, physical closure, lexical products |
| Depends on | WIP-0049, WIP-0054, WIP-0073, WIP-0099 |
| Supersedes | Parser projection for `BooleanTokens.w` |
| Superseded by | None |

## Contract

Compile `BooleanTokens.w` through direct source products. The original adoption
compared one function, 11 instructions, and a 752-byte artifact with stage 0.

[WIP-0497](WIP-0497-exact-source-word-admission.md) replaces hash admission in the
callers. The current function is `booleanTokenCode(long wordCode)`. It accepts
only `TOKEN_TRUE` and `TOKEN_FALSE`, both owned by this module. These values are
opaque word identities, not evidence that arbitrary text spells a Boolean.

## Product path

One signed equality compares the preserved parameter with `TOKEN_TRUE`. Its
child returns Boolean `true`. The final return compares the same parameter with
`TOKEN_FALSE`. The conditional window contributes seven instructions and the
final equality contributes four.

The classifier does not read source text, decode UTF-8, parse a literal, emit a
Boolean constant, or choose a result local. Exact spelling belongs to
`SourceWords.w`. WIP-0099 owns ordinary root Boolean literal returns.

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` remains the route
authority. The product consumes exact equality, conditional-child, literal, and
final-return products without parser projection.

## Evidence

The original standalone pass compared all 752 bytes in 4 minutes and 38 seconds.
Its linked 96-product subset retained identity
`3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.
Those numbers describe that acceptance, not today's selected compiler.

`NativeCompilerSourceWordsPhysicalProductExampleTest` now owns the complete
Boolean artifact comparison alongside exact source-word products. It replaces
the standalone Boolean fixture. The whole-closure test compares the selected
artifacts and callable bodies before linking. Neither pass proves a complete
compiler fixed point.

## Acceptance

- [x] `BooleanTokens.w` uses direct source products.
- [x] The original function and 11 instructions matched the complete stage-0 artifact.
- [x] Both comparisons retain the exact, independently owned word codes.
- [x] The child retains Boolean type and block ownership.
- [x] The classifier derives neither source spelling nor code adjacency.
- [x] The original selected 96-product closure kept its exact linked identity.
- [x] Current consolidated evidence replaces the standalone fixture.

## Rejected alternatives

Comparing source text here would duplicate lexical admission. Treating any
nonzero code as true would accept non-Boolean words. Deriving one code from the
other would invent an arithmetic relationship that the registry does not promise.

Keeping this one-condition classifier on parser projection would discard the
exact direct products that already close its body.
