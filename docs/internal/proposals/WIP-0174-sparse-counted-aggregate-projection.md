# WIP-0174: Sparse counted-aggregate projection

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and linker maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, counted aggregate layouts, bounded publication |
| Depends on | WIP-0046, WIP-0173 |
| Supersedes | Full-capacity projected aggregate staging copies |
| Superseded by | None |

## Summary

Copy descriptor-compatible source aggregate rows into counted local staging through measured local counts. `CountedAggregateLayouts.w` formerly copied all 576 aggregate, 512 case, and 1,024 member words before appending one projected module.

The projected append path now copies nine aggregate columns through `localAggregateCount`, four case columns through `localCaseCount`, and four member columns through `localMemberCount`.

Compiled aggregate products already enter through exact decoder counts. Both paths continue through one validated closure append.

## Counted append

The shared append validates:

- one unprocessed module owner
- local and closure aggregate, case, and member capacities
- aggregate kinds and local IDs
- case and member windows
- member aggregate and case ownership
- canonical member type codes

It then rebases local case and member coordinates onto closure-wide counts and marks the module processed.

## Source projection boundary

The source projection path consumes the nine-column aggregate, four-column case, and four-column member schema from WIP-0173. It does not retain parsed source-only columns.

Active rows enter private local staging. Unused source capacity never crosses into the counted append.

## Atomicity

All projected rows copy into invocation-owned staging. The shared append validates complete local products before changing closure rows or the processed-module bit.

Untouched staging capacity remains irrelevant. Closure publication remains bounded by local counts.

## Bounds

No capacity changes:

- 64 aggregates per module
- 128 cases per module
- 256 members per module
- 4,096 closure aggregates
- 8,192 closure cases
- 16,384 closure members
- 512 module owners

Worst-case work remains identical.

## Evidence

`NativeCompilerAggregateProductsExampleTest` compares compiled and projected aggregate paths, validates rebased closure rows and identities, and rejects malformed products.

Aggregate-aware source product and linked aggregate section suites consume the same counted rows.

The compiler archive contains 3,010,505 bytes with SHA-256 `0ffa52c4828b6abec7ef92b46dd9ef46757ff8ae44220c1c4db7fe32f9d9e80b`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `08b5978bc9bc6cdc8c314f5a21375d03369e1a5fa1862a36ba5513fcfe837aac`. WIP-0173 and WIP-0174 complete in 16 minutes and 28 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] Nine projected aggregate columns copy through `localAggregateCount`.
- [x] Four projected case columns copy through `localCaseCount`.
- [x] Four projected member columns copy through `localMemberCount`.
- [x] Compiled and projected paths retain one shared append authority.
- [x] Closure coordinates remain rebased by prior exact counts.
- [x] Focused counted aggregate and linked section tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] Complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Append source rows directly to closure tables

Rejected. Descriptor-compatible local validation remains shared with compiled products.

### Retain parsed source-only columns

Rejected. The counted linker consumes compiled descriptor semantics only.

### Duplicate append validation by product kind

Rejected. Compiled and projected products must obey one closure coordinate authority.

## References

- [WIP-0046](WIP-0046-counted-native-aggregate-layout-products.md)
- [WIP-0173](WIP-0173-sparse-source-aggregate-publication.md)
