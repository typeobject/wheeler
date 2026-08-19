# WIP-0190: Bounded qualified-call width publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, qualified calls, statement widths, bounded publication |
| Depends on | WIP-0156, WIP-0188 |
| Supersedes | Full-capacity qualified-call statement-width copies |
| Superseded by | None |

## Summary

Stage and publish qualified-call statement widths through the exact statement count. `QualifiedSourceCallProducts.w` formerly copied all 4,096 statement-width rows into staging and back to the caller for every structured module.

`materializeQualifiedCallStatementWidths` now receives `statementCount` from the closed source loop plan and copies only that active prefix.

## Qualified widths

The ordinary parser measures default statement widths before target resolution. A canonically qualified imported call may require a different physical local width after its exact target result kind and arity are known.

For each qualified call, the planner validates:

- source call start and `::` qualification
- statement owner
- target row
- arity zero through seven
- result kind void, signed, or Boolean

Width is `2 * arity` for void calls and `2 * arity + 2` for value calls.

## Statement extent

`statementCount` comes from `SourceLoopProducts` after complete callable, block, statement, condition, and loop publication. Empty modules admit zero rows. The planner does not infer extent from call owners because statements without calls remain valid width products.

The statement-width buffer keeps its 4,096-row capacity. Only its active prefix enters qualified-call staging and publication.

## Atomicity

All active widths copy into private staging before qualified calls are inspected. Every qualified call and target shape validates before caller widths change.

The active statement prefix replaces caller contents after complete validation. Untouched rows retain prior contents. Failure publishes no width.

## Bounds

No capacity changes:

- 4,096 source statements
- 256 calls
- 4,096 callable targets
- seven call arguments

Worst-case work remains identical.

## Evidence

Qualified source-call product, source-call layout, structured call, CoreParsing source-product, and physical closure suites cover qualification, arity, void and value results, malformed qualifiers, ambiguity, width replacement, and atomic failure.

The compiler archive contains 3,020,194 bytes with SHA-256 `b9647e2e36586f2bb262e8a55455497abc1a6305b09cd2ac0748db84dd0f5d76`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `08b5978bc9bc6cdc8c314f5a21375d03369e1a5fa1862a36ba5513fcfe837aac`. Complete evidence passes in 16 minutes and 14 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] The width planner receives explicit `statementCount`.
- [x] Width staging and publication use exactly `statementCount` rows.
- [x] Qualified void and value widths retain exact formulas.
- [x] Statement extent comes from the closed source product.
- [x] Untouched caller rows retain prior contents.
- [x] Focused qualified-call, layout, and artifact tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] Complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Infer statement extent from call owners

Rejected. Noncall statements still own measured widths.

### Update caller widths while resolving calls

Rejected. A later malformed target would expose a partial update.

### Retain the 4,096-row copy

Rejected. Closed statement products already own the active extent.

## References

- [WIP-0156](WIP-0156-sparse-source-call-layout-publication.md)
- [WIP-0188](WIP-0188-sparse-loop-instruction-staging.md)
