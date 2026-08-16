# WIP-0078: Bounded direct-conditional lookups

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, bounded planning, closure execution |
| Depends on | WIP-0054, WIP-0073, WIP-0075, WIP-0077 |
| Supersedes | Repeated root-block and suffix-wide token scans in direct conditional planning |
| Superseded by | None |

## Summary

Bound direct conditional lookups to their exact source products. The planner caches one root block per current callable owner, derives the child token from validated condition punctuation, and searches only the maximum scalar-return suffix for the child semicolon.

The change preserves every emitted artifact byte. It reduces repeated source-table work in the full physical product closure and keeps the closure evidence method below its fixed twenty-minute deadline.

## Problem

The first conditional product used broad scans at three points:

- every statement rediscovered its callable root block by scanning all statement rows
- every conditional rediscovered its child token by scanning the complete token table
- every child rediscovered its semicolon by scanning every later token

Repository limits bounded those scans, but their products had tighter bounds. As direct routing admitted more classifier modules, repeated broad scans consumed the closure evidence deadline without adding validation.

An attempted statement-row adjacency shortcut was invalid. Statement rows retain source-product ordering, but a parent row and its only child row need not have adjacent storage indexes. Block identity remains the authority for child-statement selection.

## Root-block cache

`DirectStatementProducts.w` and `ResolvedLoopBodyProducts.w` retain the current owner and its root block while they walk source-ordered statements. They recompute the root only when the owner changes. If storage ever returns to an earlier owner, the owner change triggers a fresh exact lookup.

`SourceValueProducts.w` already walks one callable at a time. It now computes that callable's root block once before it measures statements.

The cache changes no persisted product. Statement owner, block identity, source start, and source length remain authoritative.

## Child token

The conditional parser validates `if`, both parentheses, the operation, the right operand, the closing parenthesis, and the opening brace. The only admitted child begins at the next semantic token. `DirectConditionalReturnProducts.w` therefore selects `closeToken + 2` and verifies that its source offset equals the selected child statement start.

The planner still finds the child statement by exact owner and child-block identity. It requires one match. It does not infer a child statement from row adjacency.

## Semicolon window

An admitted scalar child contains at most these semantic tokens after `return`:

- one Boolean literal and a semicolon
- one identifier and a semicolon
- one identifier, one binary operator, one right identifier or signed literal, and a semicolon

Equality and a negative literal add at most two punctuation tokens. The planner searches the next seven tokens after `return`, bounded by the semantic token count, and requires one token at the child's exact terminal source offset. That token must be a semicolon.

The direct scalar relation still validates the complete expression grammar. The short search locates the already measured boundary and does not parse the relation again.

## Exact parent selection

`ResolvedLoopBodyProducts.w` retains its owner, root block, child-block identity, child count, source token, and exact parent scan. A root parent may not be inferred from `childStatement - 1`. A malformed or ambiguous parent leaves the body plan invalid.

This split keeps performance shortcuts out of semantic identity. Source coordinates narrow token work. Block products select statements.

## Evidence

Focused fixtures cover literal, preserved-source, signed binary, and signed constant children. They also cover multiple children and rejected Boolean comparison children. The complete physical product closure compares all selected artifacts with stage 0 after the lookup changes and preserves the linked subset identity.

The local closure run completes under the fixed method deadline with `CompilerMachineRunner.runWithoutRewindHistory`. The test retains the deadline rather than raising it.

## Bootstrap closure

The compiler archive contains 2,955,160 bytes and has identity `1b0b2abf972600fe7f3fe2ce2af202c471276c638a4482fde57b63d0df5039d7`. The package manifest identity remains `e83091ee70e165f76eefcb2135d2b9620af0906f39affb8a0013e9e60bf894c2`. All four dependent locks name both identities.

The bootstrap module manifest remains 172,543 bytes with 372 modules, two externals, and 1,816 imports. Native validation halts after 71,675,747 transitions under the 73,000,000-transition ceiling.

The 96-product physical subset remains unchanged. It contains 228 functions and 8,286 instructions in 246,040 bytes. Its identity is `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] Root-block lookup runs once per contiguous callable-owner statement range.
- [x] Source-value measurement computes one root block per callable.
- [x] Child token selection uses exact condition punctuation and validates the child source start.
- [x] Child semicolon lookup inspects at most seven following semantic tokens.
- [x] Child statements still resolve by exact owner and block identity.
- [x] Parent statements still resolve by exact root block and child-block identity.
- [x] Focused conditional fixtures match stage 0 or fail before publication.
- [x] The complete physical product closure matches stage 0 byte for byte under its existing deadline.
- [x] Compiler archive identities, dependent locks, and bootstrap budgets are current.
- [x] A fresh locked workspace build passes.
- [x] Source, documentation, line, and directory-width policy pass.

## Rejected alternatives

### Raise the closure timeout

Rejected. The repeated scans had tighter product bounds. A larger deadline would hide avoidable work.

### Select the child statement by adjacent row

Rejected. Statement storage order does not make adjacency a semantic relation.

### Search until the end of the token table

Rejected. The child statement already supplies an exact source end, and the admitted scalar grammar has a smaller fixed token window.

### Cache roots by inferred callable order

Rejected. The cache key remains the exact owner. An owner change always recomputes from statement products.

## References

- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0075](WIP-0075-exact-computed-conditional-return-products.md)
- [WIP-0077](WIP-0077-exact-constant-return-products.md)
