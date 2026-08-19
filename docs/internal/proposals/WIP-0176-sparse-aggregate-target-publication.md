# WIP-0176: Sparse aggregate-target publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, aggregate constructors, projections, bounded publication |
| Depends on | WIP-0050, WIP-0175 |
| Supersedes | Full-capacity aggregate constructor and projection target copies |
| Superseded by | None |

## Summary

Publish aggregate constructor and projection targets through exact operation counts.

`AggregateConstructorTargets.w` formerly copied all 768 target words. It now publishes three columns through `operationCount`.

`AggregateProjectionTargets.w` formerly copied all 1,024 target words. It now publishes four columns through `operationCount`.

## Constructor targets

Constructor resolution joins source operation names and optional variant cases to one source-local aggregate row. Three columns retain:

- canonical constructor opcode
- aggregate target row
- variant case tag

Records, fixed arrays, and variants retain distinct kind checks. Variant case names resolve uniquely within the target's counted case window.

## Projection targets

Projection resolution joins owner aggregate products, member names, variant case names, and indexed structural owners. Four columns retain:

- canonical projection opcode
- owner aggregate row
- variant case tag
- member index

Record fields, variant payloads, fixed-array indexes, and slice indexes retain exact opcode and target shapes.

## Atomicity

Both stages validate all operation kinds, source ranges, owner products, aggregate kinds, case windows, member windows, names, and uniqueness in private staging.

Active rows replace caller contents only after the complete join succeeds. Untouched rows retain prior contents. Failure publishes no target row.

## Bounds

No capacity changes:

- 256 aggregate operations
- three constructor target columns
- four projection target columns
- 64 local aggregates
- 128 variant cases
- 256 members

Worst-case work remains identical.

## Evidence

Constructor and projection target suites cover records, variants, fixed arrays, slices, duplicate names, wrong kinds, missing owners, and atomic failure.

Resolved operand and whole-artifact suites consume the same target products before canonical code generation.

The compiler archive contains 3,011,637 bytes with SHA-256 `1a3a10e70ec35f1643a9c4912bf6b098f9d47d5d2b1800f6b7e4a2b51dec327d`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `08b5978bc9bc6cdc8c314f5a21375d03369e1a5fa1862a36ba5513fcfe837aac`. Complete evidence passes in 15 minutes and 56 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] Three constructor target columns publish exactly `operationCount` rows.
- [x] Four projection target columns publish exactly `operationCount` rows.
- [x] Record, variant, array, and slice target semantics remain disjoint.
- [x] Name and owner joins complete before publication.
- [x] Untouched caller rows retain prior contents.
- [x] Focused constructor, projection, and artifact tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] Complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Encode targets while parsing syntax

Rejected. Aggregate and owner products close after source operation parsing.

### Share one target schema

Rejected. Constructors and projections carry different canonical operands.

### Clear inactive rows

Rejected. `operationCount` defines each complete product.

## References

- [WIP-0050](WIP-0050-native-aggregate-source-lowering.md)
- [WIP-0175](WIP-0175-sparse-aggregate-operation-publication.md)
