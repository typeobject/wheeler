# WIP-0155: Sparse physical-loop publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, physical loops, local types, bounded publication |
| Depends on | WIP-0052, WIP-0067, WIP-0151, WIP-0153 |
| Supersedes | Full-capacity physical body, resolved loop, and local-type copies |
| Superseded by | None |

## Summary

Publish only active physical loop products. Three stages still copied fixed capacities:

- `ResolvedLoopProducts.w` copied complete condition and loop tables
- `PhysicalLoopBodyProducts.w` copied complete body and nested tables into and out of staging
- `LoopLocalTypeProducts.w` copied all 12,288 type words

All three stages already compute exact active counts. They now use them.

## Resolved loops

For `l` loops, six 256-row condition columns and nine 256-row loop columns publish exactly `l` rows.

Resolution still requires every source condition to be consumed once, exact owner and ordinal joins, typed local or literal operands, resolved limits, body ranges, update forms, direction, reversal state, and depth.

## Physical bodies

For `b` body products, five 4,096-row body columns stage and republish exactly `b` rows.

For `n` nested controls, five 4,096-row nested columns stage and republish exactly `n` rows.

Physical statement starts stage only `statementCount` rows. Local remapping, call windows, body opcodes, packed operands, nested condition locals, and private local bases all validate before publication.

## Local types

For `t` loop-local types, three 4,096-row columns publish owner, local row, and canonical type for exactly `t` rows.

The type product still proves complete loop frames, direct bodies, nested guards, nested child bodies, borrowed temporaries, and nonoverlapping local coordinates.

## Atomicity

Each stage validates its complete private product before caller mutation. Active rows replace prior contents through fixed-capacity coordinates. Untouched rows retain prior contents. Any malformed relation leaves all caller tables unchanged.

## Bounds

No capacity changes:

- 256 loops
- 4,096 body products
- 4,096 nested controls
- 4,096 local type rows
- five body columns
- five nested columns
- three type columns

Worst-case work remains identical. Small physical modules no longer copy full physical loop capacity.

## Evidence

`NativeCompilerCoreParsingSourceProductsExampleTest` checks resolved loops, physical body and nested rows, exact local types, code composition, and artifact equality.

`NativeCompilerStructuredCallSourceProductExampleTest` checks direct and imported calls in root and nested loop windows.

`NativeCompilerPhysicalClosureExampleTest` compares every comparable artifact, validates every retained prefix and relocation, links the exact 97-product subset twice, and rejects malformed footer and relocation products. It passes in 19 minutes and 39 seconds under the unchanged twenty-minute deadline. All container counts and the linked identity `9a3fb81e4d75ad52d0ff22deefe636d58d56827ea1de80c1e87a2d96c8c60be9` remain unchanged.

The compiler archive contains 3,006,230 bytes with SHA-256 `c8600af793cc3e7df088e3818c89f2c02d7407a123d4f00f781cd8e7b202edee`. Exact dependent locks name that archive.

## Acceptance

- [x] Resolved condition and loop columns publish exactly `loopCount` rows.
- [x] Physical body columns stage and publish exactly `bodyCount` rows.
- [x] Physical nested columns stage and publish exactly `nestedCount` rows.
- [x] Physical starts stage exactly `statementCount` rows.
- [x] Local type columns publish exactly `typeCount` rows.
- [x] Active rows replace prior contents after complete validation.
- [x] Untouched rows retain prior contents.
- [x] Focused physical loop, type, and artifact tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The 97-product linked subset publishes twice with identical bytes.
- [x] The complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Merge physical body and type products

Rejected. Code coordinates and type coordinates remain independent evidence.

### Publish while remapping locals

Rejected. A later malformed nested control would expose partial physical rows.

### Clear untouched rows

Rejected. Active counts define this product and callers own unrelated rows.

### Raise the evidence deadline

Rejected. Inactive physical capacity carries no loop fact.

## References

- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0067](WIP-0067-exact-physical-loop-value-products.md)
- [WIP-0151](WIP-0151-sparse-loop-body-publication.md)
- [WIP-0153](WIP-0153-sparse-source-loop-publication.md)
