# WIP-0153: Sparse source-loop publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, source statements, loops, bounded publication |
| Depends on | WIP-0052, WIP-0056, WIP-0151 |
| Supersedes | Full-capacity source statement, condition, and loop copies |
| Superseded by | None |

## Summary

Publish only active source statement, condition, and loop rows. `SourceLoopProducts.w` formerly copied 28,672 statement words, 1,536 condition words, and 2,304 loop words after computing exact counts.

The product now publishes exact active rows from all three fixed-column tables.

## Statements

For `s` source statements, seven 4,096-row columns publish:

- callable owner
- block row
- callable-local ordinal
- source start
- source length
- first child block
- direct child count

Every statement row remains source ordered and belongs to one validated block tree.

## Conditions and loops

For `c` loop conditions, six 256-row columns publish the exact source condition ranges and operand products.

For `l` loops, nine 256-row columns publish owner, source coordinates, condition row, callable-local ordinal, limit range, first body statement, body statement count, and depth.

The product already computes `statementCount`, `conditionCount`, and `loopCount` before publication. No second count authority is introduced.

## Atomicity

Token scanning, block validation, statement extraction, callable ownership, child joins, loop header parsing, limit parsing, body ranges, depth checks, and all capacities finish in private staging.

Active rows replace prior contents through validated fixed-capacity coordinates. Untouched rows retain prior contents. Any malformed source or limit failure leaves all caller tables unchanged.

## Bounds

No capacity changes:

- 4,096 statements
- 256 conditions
- 256 loops
- seven statement columns
- six condition columns
- nine loop columns

Worst-case work remains identical. Small physical modules no longer copy maximum-sized statement and loop tables.

## Evidence

`NativeCompilerCoreParsingSourceProductsExampleTest` checks 25 statements, seven blocks, two loops, exact source ranges, body joins, depths, values, code, types, composition, and artifact equality.

`NativeCompilerStructuredCallSourceProductExampleTest` checks calls in and after loops, nested conditions, and malformed source publication.

`NativeCompilerPhysicalClosureExampleTest` compares every comparable artifact, validates every retained prefix and relocation, links the exact 97-product subset twice, and rejects malformed footer and relocation products. It passes in 19 minutes and 53 seconds under the unchanged twenty-minute deadline. All container counts and the linked identity `9a3fb81e4d75ad52d0ff22deefe636d58d56827ea1de80c1e87a2d96c8c60be9` remain unchanged.

The compiler archive contains 3,004,308 bytes with SHA-256 `a4248f6715c9b04833ab1cee63249841f407bfcf0fdd2ee11c59cef4df702aab`. Exact dependent locks name that archive.

## Acceptance

- [x] Seven statement columns publish exactly `statementCount` rows.
- [x] Six condition columns publish exactly `conditionCount` rows.
- [x] Nine loop columns publish exactly `loopCount` rows.
- [x] Active rows replace prior contents after complete validation.
- [x] Untouched rows retain prior contents.
- [x] Focused source-loop and artifact tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The 97-product linked subset publishes twice with identical bytes.
- [x] The complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Merge statement and loop products

Rejected. Statements form a block tree. Loops add condition and limit relations.

### Publish while scanning tokens

Rejected. A later malformed loop would expose partial statement products.

### Clear untouched rows

Rejected. Active counts define this product and callers own unrelated rows.

### Raise the evidence deadline

Rejected. Inactive source capacity carries no statement or loop fact.

## References

- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0151](WIP-0151-sparse-loop-body-publication.md)
