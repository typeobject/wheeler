# WIP-0175: Sparse aggregate-operation publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, aggregate operations, resolved operands, bounded publication |
| Depends on | WIP-0050, WIP-0051, WIP-0174 |
| Supersedes | Full-capacity aggregate operation and resolved-operand copies |
| Superseded by | None |

## Summary

Publish source aggregate operations, arguments, and resolved instruction operands through measured counts.

`SourceAggregateOperations.w` formerly copied all 2,048 operation words and all 4,096 argument words. It now publishes eight operation columns through `operationCount` and four argument columns through `argumentCount`.

`AggregateResolvedOperands.w` formerly copied all 1,536 resolved words. It now publishes six columns through `operationCount`.

## Source operations

The source operation parser normalizes constructors, projections, and postfix indexes into evaluation postorder. Each operation retains:

- callable owner
- source statement
- operation kind
- result value
- source start
- source length
- first argument
- argument count

Each argument retains operation owner, argument index, source value, and source type product.

Nested operations sort by source end and then inner source start. Arguments remap from raw operation IDs to normalized operation order.

## Resolved operands

Operand assembly joins exact destination, owner, argument-local, constructor-target, projection-target, and slice-descriptor products.

Six resolved columns retain canonical opcode and up to five instruction operands. Record, array, slice, variant, field, payload, and indexed projection forms retain their exact opcode shapes.

## Atomicity

Parsing validates complete operation syntax, ownership, source ranges, nesting, argument order, and capacities in private staging. Operand assembly validates every joined product and argument extent before publication.

Active rows replace caller contents. Untouched rows retain prior contents. Failure publishes no operation, argument, or resolved row.

## Bounds

No capacity changes:

- 256 operations
- eight operation columns
- 1,024 arguments
- four argument columns
- six resolved operand columns

Worst-case work remains identical.

## Evidence

Source aggregate operation suites cover records, variants, fixed arrays, slices, field chains, payloads, nested constructors, postfix indexes, malformed syntax, and evaluation order.

Resolved operand, code generation, composition, and whole-artifact suites consume the same rows and reject incomplete joins.

The compiler archive contains 3,011,229 bytes with SHA-256 `40aca3ba5ac00f92869ddf83872bf7d018e67ea587461c665258b655e255d2be`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `08b5978bc9bc6cdc8c314f5a21375d03369e1a5fa1862a36ba5513fcfe837aac`. Complete evidence passes in 16 minutes and 18 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] Eight operation columns publish exactly `operationCount` rows.
- [x] Four argument columns publish exactly `argumentCount` rows.
- [x] Six resolved columns publish exactly `operationCount` rows.
- [x] Nested evaluation order and argument remapping remain exact.
- [x] Untouched caller rows retain prior contents.
- [x] Focused source-operation and resolved-operand tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] Complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Resolve operands while parsing expressions

Rejected. Source syntax, local coordinates, and aggregate targets close in separate products.

### Retain raw operation IDs

Rejected. Canonical code generation consumes evaluation order.

### Clear inactive rows

Rejected. Measured counts define each complete product.

## References

- [WIP-0050](WIP-0050-native-aggregate-source-lowering.md)
- [WIP-0051](WIP-0051-native-aggregate-frontend-products.md)
- [WIP-0174](WIP-0174-sparse-counted-aggregate-projection.md)
