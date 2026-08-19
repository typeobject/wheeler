# WIP-0182: Sparse aggregate-expression values

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, aggregate expressions, frontend values, bounded publication |
| Depends on | WIP-0051, WIP-0181 |
| Supersedes | Full-capacity aggregate expression value staging and publication |
| Superseded by | None |

## Summary

Stage and publish aggregate expression value products through exact value counts. `AggregateExpressionTemporaries.w` formerly copied all 7,168 value words into staging and back to the caller.

The planner now stages seven columns through the input `valueCount` and publishes seven columns through `valueCount + temporaryCount`.

Function local counts retain their fixed 64-row transfer because the current interface carries no callable count. WIP-0182 does not invent one from sparse statement owners.

## Expression values

Each value row retains:

- local function owner
- source result kind
- source type product
- callable-local index
- source statement ordinal
- source start
- source length

A nested aggregate operation without an existing named result receives one new signed carrier local. An outer aggregate operation reuses its unique enclosing named value and expands that value's exact source range.

Operations in the same function cannot publish duplicate exact source ranges.

## Local counts

The planner validates each selected function and local count before appending a temporary. No function may exceed 256 locals, and no module may exceed 1,024 value products.

The fixed local-count table remains copied atomically with the value product. A later interface may add callable count, but source statement ownership is not a substitute for an explicit extent.

## Atomicity

All operation ranges, enclosing statements, function owners, existing values, nesting relations, local capacities, and final value extents validate in private staging.

Seven active value columns publish after complete validation. Untouched value rows retain prior contents. Failure publishes no value or local-count change.

## Bounds

No capacity changes:

- 256 aggregate operations
- 1,024 values
- seven value columns
- 64 function local-count rows
- 256 locals per function
- 4,096 source statements

Worst-case value work remains identical.

## Evidence

`NativeCompilerAggregateExpressionTemporariesExampleTest` covers named outer values, nested temporary order, local growth, missing outer values, duplicate ranges, and atomic failure.

Aggregate-aware source product and whole-artifact suites consume the expanded value count through frontend bindings and final body-product transfer.

The compiler archive contains 3,017,712 bytes with SHA-256 `23ee0f57408686b1f13fbc7c97b723190dc09da50859e1915bd2c8f6323ade03`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `08b5978bc9bc6cdc8c314f5a21375d03369e1a5fa1862a36ba5513fcfe837aac`. Complete evidence passes in 16 minutes and 24 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] Input value staging copies seven columns through `valueCount`.
- [x] Output value publication writes seven columns through final value count.
- [x] Nested temporaries retain evaluation order and exact source ranges.
- [x] Fixed local-count publication remains explicit rather than inferred.
- [x] Untouched value rows retain prior contents.
- [x] Focused expression temporary and artifact tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] Complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Derive callable count from statements

Rejected. Empty callable bodies remain valid.

### Reuse one temporary for overlapping nested expressions

Rejected. Evaluation order gives each nested operation one result value.

### Clear inactive value rows

Rejected. Final value count defines the complete product.

## References

- [WIP-0051](WIP-0051-native-aggregate-frontend-products.md)
- [WIP-0181](WIP-0181-sparse-aggregate-body-product-transfer.md)
