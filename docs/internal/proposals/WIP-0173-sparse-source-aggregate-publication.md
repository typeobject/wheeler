# WIP-0173: Sparse source-aggregate publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, aggregate frontend, bounded publication |
| Depends on | WIP-0050, WIP-0051, WIP-0167 |
| Supersedes | Full-capacity source aggregate and layout copies |
| Superseded by | None |

## Summary

Publish parsed and projected source aggregate products through measured counts. Two stages formerly copied complete capacities:

- `SourceAggregateProducts.w` copied 832 aggregate, 640 case, and 2,048 member words.
- `SourceAggregateLayouts.w` copied those capacities again plus all 512 string rows.

Parsed products now publish thirteen aggregate columns through `aggregateCount`, five case columns through `caseCount`, and eight member columns through `memberCount`.

Descriptor-compatible products publish nine aggregate columns through `aggregateCount`, four case columns through projected case count, four member columns through projected member count, and source-string rows through `stringCount`.

## Parsed products

Source parsing retains aggregate kind, names, source ranges, case and member windows, structural element kinds, fixed lengths, and resolved type products. Record members and variant cases remain source ordered. Structural arrays and slices receive deterministic synthetic aggregate rows.

Every nominal member type resolves to one local aggregate or one primitive type before publication.

## Descriptor-compatible layouts

Projection assigns per-kind local descriptor IDs, stable module ownership, string IDs, case windows, member windows, and fixed-array lengths.

Record and variant names become counted source-string products. Array and slice element types become unnamed member rows. The projected layout matches the compiled aggregate decoder's local row schema.

## Atomicity

Parsing validates syntax, names, duplicate types, case ownership, member ownership, type references, structural descriptors, and all capacities in private staging.

Projection validates every source range and type relation before publishing. Active rows replace caller contents. Untouched rows retain prior contents. Failure publishes no row.

## Bounds

No capacity changes:

- 64 local aggregates
- 128 variant cases
- 256 members
- 512 source strings
- thirteen parsed aggregate columns
- five parsed case columns
- eight parsed member columns
- nine projected aggregate columns
- four projected case and member columns

Worst-case work remains identical.

## Evidence

Source aggregate product and projection suites cover records, recursive names, variants, duplicate cases, arrays, slices, malformed members, structural type products, string ranges, and atomic failure.

Aggregate-aware source artifact tests consume projected rows without retaining frontend scaffolding.

The compiler archive contains 3,010,505 bytes with SHA-256 `0ffa52c4828b6abec7ef92b46dd9ef46757ff8ae44220c1c4db7fe32f9d9e80b`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `08b5978bc9bc6cdc8c314f5a21375d03369e1a5fa1862a36ba5513fcfe837aac`. WIP-0173 and WIP-0174 complete in 16 minutes and 28 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] Parsed aggregate, case, and member columns publish measured counts.
- [x] Projected aggregate, case, member, and string rows publish measured counts.
- [x] Structural aggregate synthesis retains deterministic order.
- [x] Descriptor-compatible row schemas remain unchanged.
- [x] Untouched caller rows retain prior contents.
- [x] Focused aggregate frontend and projection tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] Complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Publish while parsing declarations

Rejected. Later duplicate names or unresolved member types would expose partial products.

### Keep source and projected schemas identical

Rejected. Source ranges and compiled descriptor IDs have different owners.

### Clear inactive rows

Rejected. Measured counts define each complete product.

## References

- [WIP-0051](WIP-0051-native-aggregate-frontend-products.md)
- [WIP-0050](WIP-0050-native-aggregate-source-lowering.md)
- [WIP-0167](WIP-0167-bounded-structured-artifact-publication.md)
