# WIP-0154: Sparse source-block publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, source statements, block trees, bounded publication |
| Depends on | WIP-0056, WIP-0153 |
| Supersedes | Full-capacity source statement and block-tree copies |
| Superseded by | None |

## Summary

Publish only active source statement and block-tree rows. `SourceStatementProducts.w` had two full-capacity publication loops:

- 24,576 words for callable source statements
- 6,144 words for balanced source blocks

Both products already compute exact counts. Publication now uses those counts across six fixed columns.

## Callable statements

For `s` callable source statements, six 4,096-row columns publish owner, provisional block, callable-local ordinal, provisional child, source start, and source length.

This flat statement product remains separate from the structured loop statement table. Callers that need balanced controls use the block product and WIP-0153 loop product.

## Block tree

For `b` source blocks, six 1,024-row columns publish callable owner, parent block, depth, source start, source length, and first child block.

The scanner still requires one exact root open and close per callable, balanced braces, maximum depth four, monotonic source ranges, and complete body coverage before publication.

## Atomicity

Token scanning, statement width measurement, brace matching, parent selection, child selection, callable ownership, depth, source ranges, and all capacities finish in private staging.

Active rows replace prior contents through validated fixed-capacity coordinates. Untouched rows retain prior contents. Any malformed statement or block tree leaves caller tables unchanged.

## Bounds

No capacity changes:

- 64 local callables per module product
- 4,096 source statements
- 1,024 source blocks
- six statement columns
- six block columns

Worst-case work remains identical. Small physical modules no longer copy maximum statement and block tables.

## Evidence

`NativeCompilerSourceStatementProductsExampleTest` checks flat callable statement ownership, ranges, order, and malformed rejection.

`NativeCompilerCoreParsingSourceProductsExampleTest` checks seven balanced blocks, 25 structured statements, loop and child joins, composition, and artifact equality.

`NativeCompilerPhysicalClosureExampleTest` compares every comparable artifact, validates every retained prefix and relocation, links the exact 97-product subset twice, and rejects malformed footer and relocation products. It passes in 19 minutes and 53 seconds under the unchanged twenty-minute deadline. All container counts and the linked identity `9a3fb81e4d75ad52d0ff22deefe636d58d56827ea1de80c1e87a2d96c8c60be9` remain unchanged.

The compiler archive contains 3,004,308 bytes with SHA-256 `a4248f6715c9b04833ab1cee63249841f407bfcf0fdd2ee11c59cef4df702aab`. Exact dependent locks name that archive.

## Acceptance

- [x] Six callable statement columns publish exactly `statementCount` rows.
- [x] Six block columns publish exactly `blockCount` rows.
- [x] Active rows replace prior contents after complete validation.
- [x] Untouched rows retain prior contents.
- [x] Focused statement, block, and artifact tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The 97-product linked subset publishes twice with identical bytes.
- [x] The complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Merge flat and structured statement tables

Rejected. They serve different parsing stages and carry different columns.

### Publish while scanning braces

Rejected. A later malformed close would expose a partial tree.

### Clear untouched rows

Rejected. Active counts define this product and callers own unrelated rows.

### Raise the evidence deadline

Rejected. Inactive block capacity carries no source fact.

## References

- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0153](WIP-0153-sparse-source-loop-publication.md)
