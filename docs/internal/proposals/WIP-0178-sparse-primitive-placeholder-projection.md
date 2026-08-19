# WIP-0178: Sparse primitive-placeholder projection

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, aggregate composition, primitive placeholders, bounded publication |
| Depends on | WIP-0051, WIP-0177 |
| Supersedes | Full-capacity primitive function, instruction, and placement copies |
| Superseded by | None |

## Summary

Stage and publish primitive placeholder projection products through exact counts. `PrimitivePlaceholderProjection.w` formerly copied all 640 function words into staging, then published all 640 function words, 24,576 instruction words, and 768 placement words.

The projector now stages and publishes ten function columns through `functionCount`, publishes six filtered instruction columns through projected instruction count, and publishes three placement columns through `operationCount`.

## Placeholder removal

Primitive lowering represents one aggregate expression with a signed zero placeholder and, where needed, one move into the named destination. The projector validates the exact constant and move operands before removal.

Nested operations sharing one placeholder remove the bridge once. Later placements subtract only preceding removed instructions in the same function and direction.

Function forward or inverse code lengths shrink by exactly 24 bytes per removed instruction. Function IDs, flags, code starts, parameter counts, local counts, and type windows remain unchanged.

## Products

Ten function columns retain the compiled descriptor rows.

Six instruction columns retain local function, direction, artifact byte start, opcode, operand count, and encoded length for every surviving primitive instruction.

Three placement columns retain local function, direction, and adjusted instruction ordinal for every aggregate operation.

## Atomicity

The projector validates operation ranges, placement uniqueness, primitive instruction order, zero placeholders, destination moves, code extents, and removal counts before creating caller products.

All outputs publish after complete filtering. Untouched rows retain prior contents. Failure publishes no function, instruction, or placement row.

## Bounds

No capacity changes:

- 64 primitive functions
- ten function columns
- 4,096 primitive instructions
- six instruction columns
- 256 aggregate operations
- three placement columns

Worst-case work remains identical.

## Evidence

`NativeCompilerPrimitivePlaceholderProjectionExampleTest` covers one-instruction and two-instruction placeholders, placement adjustment, function length changes, and malformed nonzero placeholders.

Aggregate-aware whole-artifact tests consume projected function, instruction, and placement rows before aggregate instruction composition.

The compiler archive contains 3,013,286 bytes with SHA-256 `1d8ed3c17b0e3c1615700aaa1e408d42b822d5c206545b821bc9561177a7b7cb`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `08b5978bc9bc6cdc8c314f5a21375d03369e1a5fa1862a36ba5513fcfe837aac`. Complete evidence passes in 16 minutes and 9 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] Function staging and publication use ten columns through `functionCount`.
- [x] Instruction publication uses six columns through projected instruction count.
- [x] Placement publication uses three columns through `operationCount`.
- [x] Placeholder removal and later ordinal adjustment remain exact.
- [x] Untouched caller rows retain prior contents.
- [x] Focused placeholder and aggregate artifact tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] Complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Remove placeholders during primitive lowering

Rejected. Aggregate operation products own which source expressions are placeholders.

### Recompute function descriptors from code bytes

Rejected. The compiled descriptor product remains authoritative.

### Clear inactive rows

Rejected. Function, projected instruction, and operation counts define complete products.

## References

- [WIP-0051](WIP-0051-native-aggregate-frontend-products.md)
- [WIP-0177](WIP-0177-sparse-aggregate-frontend-binding-publication.md)
