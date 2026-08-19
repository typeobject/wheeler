# WIP-0177: Sparse aggregate frontend-binding publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, aggregate frontend, placeholder placement, bounded publication |
| Depends on | WIP-0051, WIP-0176 |
| Supersedes | Full-capacity aggregate binding and placement copies |
| Superseded by | None |

## Summary

Publish aggregate frontend bindings and validated primitive placeholder placements through exact operation and argument counts.

`AggregateFrontendBindings.w` formerly copied all 256 destination and owner rows, all 1,024 argument rows, and all 768 provisional placement words.

`AggregatePlaceholderPlacements.w` formerly copied all 768 validated placement words.

Both stages now publish only active products.

## Frontend bindings

Each aggregate operation joins one source statement, destination value, owner value where required, argument value products, and provisional primitive statement coordinate.

Destination and owner locals publish through `operationCount`. Argument locals publish through `argumentCount`. Three provisional placement columns publish through `operationCount`:

- local function
- source block
- source statement ordinal

Nested expressions bind in evaluation order while preserving the named outer destination.

## Placeholder placements

Primitive compilation may lower one aggregate expression to a zero-valued signed placeholder and a move into the named destination. Placeholder validation decodes primitive function and instruction products, requires that exact two-instruction bridge, and records its true instruction ordinal.

Three validated placement columns publish through `operationCount`:

- local function
- direction
- instruction ordinal

Each aggregate operation must match exactly one placeholder bridge.

## Atomicity

Frontend binding validates source ranges, statement ownership, values, locals, operation kinds, argument order, and provisional placements in private staging.

Placeholder validation checks function windows, instruction order, destination locals, zero constants, and bridge uniqueness before publication. Untouched caller rows retain prior contents. Failure publishes no binding or placement row.

## Bounds

No capacity changes:

- 256 operations
- 1,024 arguments
- 256 destination and owner rows
- three provisional placement columns
- three validated placement columns
- 64 local functions
- 4,096 source statements

Worst-case work remains identical.

## Evidence

Aggregate frontend binding and placeholder placement suites cover nested expressions, named values, source order, duplicate ranges, wrong locals, malformed bridges, and atomic failure.

Aggregate-aware whole-artifact tests consume both products before primitive placeholder removal and selector-driven composition.

The compiler archive contains 3,012,041 bytes with SHA-256 `63d5b8d8c0ad508850928c2e25225c13629f3670475884484b6dcfc32d9b0435`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `08b5978bc9bc6cdc8c314f5a21375d03369e1a5fa1862a36ba5513fcfe837aac`. Complete evidence passes in 16 minutes and 26 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] Destination and owner locals publish exactly `operationCount` rows.
- [x] Argument locals publish exactly `argumentCount` rows.
- [x] Provisional placement columns publish exactly `operationCount` rows.
- [x] Validated placement columns publish exactly `operationCount` rows.
- [x] Untouched caller rows retain prior contents.
- [x] Focused binding, placement, and artifact tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] Complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Trust source statement ordinals as instruction ordinals

Rejected. Primitive lowering may add or remove instruction products.

### Recover bindings from final bytecode

Rejected. Final offsets do not own source value identity.

### Clear inactive rows

Rejected. Operation and argument counts define complete products.

## References

- [WIP-0051](WIP-0051-native-aggregate-frontend-products.md)
- [WIP-0176](WIP-0176-sparse-aggregate-target-publication.md)
