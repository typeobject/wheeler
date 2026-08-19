# WIP-0181: Sparse aggregate body-product transfer

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and linker maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, aggregate body compilation, bounded publication |
| Depends on | WIP-0051, WIP-0175, WIP-0176, WIP-0177, WIP-0179, WIP-0180 |
| Supersedes | Full-capacity aggregate body transaction copies |
| Superseded by | None |

## Summary

Transfer aggregate-aware body products from private transaction staging through their exact plan counts. `AggregateCompiledCallableBodies.w` formerly recopied complete capacities after every producer had already returned measured extents.

The transaction now transfers only active constructor targets, composed functions and instructions, selectors, resolved operations, projection targets, bindings, placements, values, local counts, statements, and nominal projections.

## Product extents

The transfer uses these existing authorities:

- `operationCount` for constructor targets, projection targets, resolved operands, destination and owner locals, and placements
- `argumentCount` for argument locals
- `primitiveFunctions.functionCount` for composed function descriptors
- `composition.instructionCount` for composed instructions and artifact selectors
- `expressionValues.valueCount` for value products
- `localCallableCount` for function local counts
- `sourceStatements.statementCount` for source statement rows
- local, imported, and carrier projection plan counts for nominal rows

Supplemental code, primitive artifact bytes, and identities were already copied through measured byte lengths.

## Schemas

The transaction retains:

- three constructor target columns
- ten composed function columns
- six composed instruction columns
- one artifact selector per instruction
- six resolved operand columns
- four projection target columns
- destination and owner locals
- one argument-local column
- three placement columns
- seven value columns
- one local-count row per local callable
- six statement columns
- eight local, three imported, and four imported-carrier nominal columns

No schema or stride changes.

## Atomicity

Every producer validates and stages its complete product before the aggregate body transaction reaches transfer. The transaction publishes only after primitive compilation, placeholder projection, supplemental code generation, instruction composition, nominal source rewriting, and identity generation all succeed.

Untouched caller rows retain prior contents. Any failed producer traps before transfer.

## Bounds

No capacity changes. Existing limits remain 64 functions, 4,096 instructions, 256 operations, 1,024 arguments and values, 4,096 statements, 512 local nominal references, and 4,096 imported aggregate targets.

Worst-case work remains identical.

## Evidence

Aggregate-aware source product, source aggregate operation, primitive placeholder, imported nominal, local carrier, composition, and whole-artifact suites consume the transaction outputs and compare canonical stage-0 artifacts.

The compiler archive contains 3,017,101 bytes with SHA-256 `cd4d66d360ffb05ee26d2e44bfa73ab38cbe687a64509dbbe4c592351b9a31e0`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `08b5978bc9bc6cdc8c314f5a21375d03369e1a5fa1862a36ba5513fcfe837aac`. Complete evidence passes in 16 minutes and 31 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] Every transferred table uses its producer's exact count.
- [x] Function, instruction, selector, operation, argument, value, callable, and statement extents remain distinct.
- [x] Local and imported nominal column strides remain unchanged.
- [x] Artifact, supplemental code, and identity copies remain byte bounded.
- [x] Untouched caller rows retain prior contents.
- [x] Focused aggregate body and whole-artifact tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] Complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Return one untyped row count

Rejected. Independent product tables have different extents.

### Let callers inspect inactive tails

Rejected. Producer plans own every complete extent.

### Merge private staging with caller tables

Rejected. The aggregate transaction must remain atomic across all producers.

## References

- [WIP-0051](WIP-0051-native-aggregate-frontend-products.md)
- [WIP-0175](WIP-0175-sparse-aggregate-operation-publication.md)
- [WIP-0176](WIP-0176-sparse-aggregate-target-publication.md)
- [WIP-0177](WIP-0177-sparse-aggregate-frontend-binding-publication.md)
- [WIP-0179](WIP-0179-sparse-aggregate-instruction-composition.md)
- [WIP-0180](WIP-0180-sparse-nominal-projection-publication.md)
