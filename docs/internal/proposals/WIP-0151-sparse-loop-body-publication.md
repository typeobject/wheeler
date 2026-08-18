# WIP-0151: Sparse loop-body publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, loop bodies, local coordinates, bounded publication |
| Depends on | WIP-0052, WIP-0056, WIP-0150 |
| Supersedes | Full-capacity resolved body, nested-control, and frame-width copies |
| Superseded by | None |

## Summary

Publish only active loop body, nested control, and statement-width rows. Resolved body publication formerly copied two complete 20,480-word tables and one complete 4,096-word width table for every structured source module.

Loop frame-width merging also copied all 4,096 widths into and out of private staging regardless of statement count.

Both stages now use exact body, nested, and statement counts.

## Resolved bodies

For `b` direct body products, `ResolvedLoopBodyProducts.w` publishes `b` rows from five 4,096-row columns:

- source statement row
- private local base
- closed opcode
- operand kind
- closed operand

For `n` nested controls, it publishes `n` rows from five columns:

- source statement row
- nested condition kind
- condition local
- condition literal
- private local base

For `s` source statements, it publishes `s` physical widths. Private staging initializes only those `s` widths before resolution.

## Loop frame widths

`materializeLoopFrameWidths` stages and republishes only `statementCount` rows. It still scans all active statements for each active loop and requires one exact child-owning loop statement before writing width five.

## Atomicity

Token scanning, source ordering, direct body resolution, call-window joins, nested condition resolution, local bounds, body counts, and loop joins complete before caller mutation.

Active rows replace prior contents. Untouched rows retain prior contents. Any malformed body, nested control, call join, or frame join publishes nothing.

## Bounds

No capacity changes:

- 4,096 source statements
- 4,096 direct body products
- 4,096 nested control products
- 256 loops
- five body columns
- five nested columns

Worst-case work remains identical. Small physical modules no longer publish two maximum-sized body tables.

## Evidence

`NativeCompilerCoreParsingSourceProductsExampleTest` checks 25 statements, 14 direct bodies, three nested controls, exact widths, loop code, local types, source composition, and byte-identical artifact publication.

`NativeCompilerStructuredCallSourceProductExampleTest` covers calls before and inside loops, nested Boolean conditions, and malformed publication.

`NativeCompilerPhysicalClosureExampleTest` compares every comparable artifact, validates every retained prefix and relocation, links the exact 97-product subset twice, and rejects malformed footer and relocation products. It passes in 18 minutes and 47 seconds under the unchanged twenty-minute deadline. All container counts and the linked identity `9a3fb81e4d75ad52d0ff22deefe636d58d56827ea1de80c1e87a2d96c8c60be9` remain unchanged.

The compiler archive contains 3,003,261 bytes with SHA-256 `40115271d826e9439e82d133912e0400944efdab0599d20b9820f16dde4d12b9`. Exact dependent locks name that archive.

## Acceptance

- [x] Five body columns publish exactly `bodyCount` rows.
- [x] Five nested columns publish exactly `nestedCount` rows.
- [x] Physical widths publish exactly `statementCount` rows.
- [x] Loop frame staging touches exactly `statementCount` rows.
- [x] Active rows replace prior contents after complete validation.
- [x] Untouched rows retain prior contents.
- [x] Focused structured loop and artifact tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The 97-product linked subset publishes twice with identical bytes.
- [x] The complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Merge body and nested layouts

Rejected. Direct instructions and nested controls carry different products.

### Publish while resolving statements

Rejected. A later malformed body would expose partial code coordinates.

### Clear untouched rows

Rejected. Active counts define this product and callers own unrelated rows.

### Raise the evidence deadline

Rejected. Inactive body capacity carries no source fact.

## References

- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0150](WIP-0150-sparse-source-value-publication.md)
