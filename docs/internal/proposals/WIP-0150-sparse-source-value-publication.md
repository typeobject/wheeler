# WIP-0150: Sparse source-value publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, source values, bounded publication |
| Depends on | WIP-0056, WIP-0139, WIP-0148 |
| Supersedes | Full-capacity source value, callable-local, and statement-local copies |
| Superseded by | None |

## Summary

Publish only active source value and local-coordinate rows. `SourceValueProducts.w` formerly copied all 7,168 value words, all 64 callable-local rows, and all 8,192 statement-local words after computing exact value, callable, and statement counts.

The product now publishes exact active rows by column.

## Value products

For `v` named values, the seven 1,024-row columns publish:

- callable owner
- name start
- name length
- provisional local row
- defining statement ordinal
- declaration start
- declaration length

These rows cover parameters and named declarations. Unused value capacity remains caller-owned.

## Local products

For `f` local callables, the function-local table publishes `f` final local counts.

For `s` source statements, the two 4,096-row statement columns publish `s` local bases and `s` local widths.

The product already computes `valueCount`, receives `callableCount` and `statementCount`, and validates each limit before private staging. No second count authority is introduced.

## Atomicity

Scanning, parameter indexing, statement ordering, call matching, type classification, width measurement, local assignment, and all capacity checks finish before caller mutation.

Active rows replace prior contents through validated fixed-capacity coordinates. Untouched rows retain prior contents. Any malformed source or limit failure leaves all output tables unchanged.

## Bounds

No capacity changes:

- 64 local callables
- 1,024 named values
- 4,096 source statements
- seven value columns
- two statement-local columns

Worst-case work remains identical. Small physical modules no longer publish unrelated capacity.

## Evidence

`NativeCompilerStructuredCallSourceProductExampleTest` covers parameters, declarations, calls, loops, reversible result slots, imported targets, qualified targets, borrowed word projections, and malformed publication paths.

`NativeCompilerCoreParsingSourceProductsExampleTest` covers complete direct source-product composition and artifact equality. Its 809-line generated program owner is separate from the 206-line assertion suite. Neither file approaches the 1,000-line limit.

`NativeCompilerPhysicalClosureExampleTest` compares every comparable artifact, validates every retained prefix and relocation, links the exact 97-product subset twice, and rejects malformed footer and relocation products. It passes in 19 minutes and 20 seconds under the unchanged twenty-minute deadline. All container counts and the linked identity `9a3fb81e4d75ad52d0ff22deefe636d58d56827ea1de80c1e87a2d96c8c60be9` remain unchanged.

The compiler archive contains 3,002,802 bytes with SHA-256 `38bfd611b1ddd49f082c7856d0b8800c90bde5d0f9d1f6194659a7fc1db9c903`. Exact dependent locks name that archive.

## Acceptance

- [x] Seven value columns publish exactly `valueCount` rows.
- [x] Callable local counts publish exactly `callableCount` rows.
- [x] Two statement-local columns publish exactly `statementCount` rows.
- [x] Active rows replace prior contents after complete validation.
- [x] Untouched rows retain prior contents.
- [x] Focused structured source-product tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The 97-product linked subset publishes twice with identical bytes.
- [x] The complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Shrink value tables per source

Rejected. Downstream coordinates retain fixed-column direct indexing.

### Publish while scanning statements

Rejected. A later malformed statement would expose partial values and widths.

### Clear untouched rows

Rejected. Active counts define this product and callers own unrelated rows.

### Raise the evidence deadline

Rejected. Unused value capacity carries no source fact.

## References

- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0139](WIP-0139-structured-imported-call-product-foundations.md)
- [WIP-0148](WIP-0148-sparse-referenced-call-target-publication.md)
