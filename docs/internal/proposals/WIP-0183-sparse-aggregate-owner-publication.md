# WIP-0183: Sparse aggregate-owner publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and ownership maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, aggregate owners, structural values, bounded publication |
| Depends on | WIP-0051, WIP-0182 |
| Supersedes | Full-capacity aggregate owner and structural-value copies |
| Superseded by | None |

## Summary

Stage and publish aggregate source owners, indexed owners, slice descriptors, and structural value products through exact operation and value counts.

`AggregateSourceOwners.w` formerly published all 256 owner rows. It now publishes through `operationCount`.

`AggregateIndexedOwners.w` formerly staged and published all 256 owner rows and all 1,024 structural-value rows in both its outer and structural joins. It now uses `operationCount` and `valueCount` throughout.

## Source owners

Each aggregate operation receives an aggregate owner and optional variant case from its destination, owner local, placement function, local nominal carrier projection, and constructor target products.

Constructor producers resolve uniquely. Variant case tags remain relative to the source aggregate's case window.

## Structural values

Callable values with exact fixed-array or slice source types bind one structural aggregate descriptor. Type text, kind, and source range must match uniquely.

Indexed operations may inherit an array owner from a prior record or variant field producer. Slice constructors bind their destination value to one slice descriptor.

The structural-value table publishes through `valueCount`. Owner aggregate, case, and slice rows publish through `operationCount`.

## Atomicity

Owner joins validate operation kinds, functions, locals, placements, carrier roles, constructor targets, aggregate kinds, case windows, member names, structural type text, and descriptor uniqueness in private staging.

All active rows publish after complete validation. Untouched rows retain prior contents. Failure publishes no owner, case, slice, or structural-value row.

## Bounds

No capacity changes:

- 256 aggregate operations
- 1,024 callable values
- 64 local aggregate descriptors
- 128 cases
- 256 members

Worst-case work remains identical.

## Evidence

Aggregate source-owner, indexed-owner, structural-owner, slice-descriptor, fixed-array, record-field, variant-payload, and aggregate-aware artifact suites cover exact producers, wrong kinds, duplicate descriptors, missing owners, and atomic failure.

The compiler archive contains 3,017,686 bytes with SHA-256 `a1337db6999a9aa69c2791747569e7ff3f0413c943b58f810963d44162050e8c`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `08b5978bc9bc6cdc8c314f5a21375d03369e1a5fa1862a36ba5513fcfe837aac`. Complete evidence passes in 16 minutes and 19 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] Source owner and case rows publish exactly `operationCount` entries.
- [x] Indexed owner, case, and slice rows stage and publish through `operationCount`.
- [x] Structural value rows stage and publish through `valueCount`.
- [x] Array and slice descriptor joins remain exact and disjoint.
- [x] Untouched caller rows retain prior contents.
- [x] Focused owner, structural value, and artifact tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] Complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Infer owner type from opcode alone

Rejected. Record fields and variant payloads carry member-defined types.

### Match structural descriptors by kind alone

Rejected. Exact source type and descriptor identity are required.

### Clear inactive rows

Rejected. Operation and value counts define complete products.

## References

- [WIP-0051](WIP-0051-native-aggregate-frontend-products.md)
- [WIP-0182](WIP-0182-sparse-aggregate-expression-values.md)
