# WIP-0179: Sparse aggregate-instruction composition

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and linker maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, aggregate composition, functions, instructions, bounded publication |
| Depends on | WIP-0050, WIP-0178 |
| Supersedes | Full-capacity aggregate composition staging and publication |
| Superseded by | None |

## Summary

Stage and publish aggregate instruction composition through exact function and instruction counts. `AggregateInstructionComposition.w` formerly copied all 640 primitive function words into staging, then published all 640 function words, 24,576 instruction words, and 4,096 artifact selectors.

The composer now stages and publishes ten function columns through `functionCount`, publishes six instruction columns through `composedCount`, and publishes `composedCount` selectors.

## Composition

Primitive placeholder projection supplies filtered function and instruction products. Aggregate code generation supplies one canonical instruction window per operation and one validated placement.

For each function and direction, the composer merges primitive instructions and aggregate windows by adjusted ordinal. Primitive instructions retain artifact selector zero. Aggregate instructions retain selector one and aggregate-code coordinates.

Each aggregate operation enters once. Primitive and aggregate instruction counts sum to `composedCount`.

## Products

Ten function columns retain descriptors with adjusted forward and inverse code lengths.

Six instruction columns retain local function, direction, artifact byte start, opcode, operand count, and encoded length.

One selector row per instruction identifies the primitive or aggregate code artifact. Later archival and linking use that selector instead of recovering provenance from bytes.

## Atomicity

The composer validates function and instruction windows, placement order, operation code extents, direction order, aggregate byte coverage, and final instruction count before publication.

All rows publish after complete composition. Untouched caller rows retain prior contents. Failure publishes no function, instruction, or selector row.

## Bounds

No capacity changes:

- 64 functions
- ten function columns
- 4,096 composed instructions
- six instruction columns
- 4,096 artifact selectors
- 256 aggregate operations

Worst-case work remains identical.

## Evidence

`NativeCompilerAggregateInstructionProductsExampleTest` and aggregate-aware whole-artifact suites cover mixed primitive and aggregate order, forward and inverse directions, code lengths, selectors, malformed placements, and atomic failure.

Product-linked artifact evidence consumes selector-driven composition and reproduces canonical stage-0 bytes.

The compiler archive contains 3,014,158 bytes with SHA-256 `bb47cd5c8a7102c3ba5539cf2e77a031f9a2713995996614e7bca3083aabb048`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `08b5978bc9bc6cdc8c314f5a21375d03369e1a5fa1862a36ba5513fcfe837aac`. Complete evidence passes in 16 minutes and 29 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] Function staging and publication use ten columns through `functionCount`.
- [x] Instruction publication uses six columns through `composedCount`.
- [x] Selector publication writes exactly `composedCount` rows.
- [x] Primitive and aggregate instruction provenance remains explicit.
- [x] Untouched caller rows retain prior contents.
- [x] Focused composition and whole-artifact tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] Complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Concatenate aggregate code after primitive code

Rejected. Source placements interleave both products within each direction.

### Recover artifact provenance from byte coordinates

Rejected. Coordinates overlap across independent artifacts.

### Clear inactive rows

Rejected. Function and composed instruction counts define complete products.

## References

- [WIP-0050](WIP-0050-native-aggregate-source-lowering.md)
- [WIP-0178](WIP-0178-sparse-primitive-placeholder-projection.md)
