# WIP-0162: Sparse callable-return publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, callable returns, bounded publication |
| Depends on | WIP-0056, WIP-0159 |
| Supersedes | Full-capacity implicit-return copies |
| Superseded by | None |

## Summary

Publish implicit-return products only for active callables. `CallableReturnProducts.w` formerly copied all 192 return words after planning an exact callable count.

The planner now publishes three columns of `callableCount` rows.

## Products

For each callable, the planner counts top-level direct, call, and loop instructions and code bytes. Nested calls and loops belong to their root products and do not advance the callable prefix twice.

The three return columns retain:

- whether a void return is required
- callable-local instruction start
- callable-local code start

A void callable receives its measured end coordinates. A value callable receives a zero required bit and signed minus-one starts because its explicit result product owns return emission.

## Atomicity

Statement ownership, root blocks, call argument widths, loop depths, result types, instruction capacity, and code capacity finish in private staging.

All active rows publish after validation. Untouched rows retain caller contents. Failure publishes no return row.

## Bounds

No capacity changes:

- 64 callables
- three 64-row columns
- 4,096 direct products
- 256 calls
- 256 loops
- 32,768 instructions
- 262,144 code bytes

Worst-case work remains identical.

## Evidence

`NativeCompilerCallableReturnProductsExampleTest` checks void and value callables, root products, detached products, measured starts, and atomic failure.

`NativeCompilerCoreParsingSourceProductsExampleTest` checks return products through final callable composition and exact artifact bytes.

The compiler archive contains 3,007,567 bytes with SHA-256 `016276c5165ec57d72a64b10ff8d615a8904c557029f83302a5075a380c54257`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `9a3fb81e4d75ad52d0ff22deefe636d58d56827ea1de80c1e87a2d96c8c60be9`. WIP-0161 and WIP-0162 complete in 15 minutes and 4 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] Three return columns publish exactly `callableCount` rows.
- [x] Void callables retain exact measured end coordinates.
- [x] Value callables retain explicit-return sentinel coordinates.
- [x] Nested products are not counted twice.
- [x] Untouched rows retain caller contents.
- [x] Focused callable-return and artifact tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The linked physical subset publishes twice with identical bytes.
- [x] Complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Add implicit returns during parsing

Rejected. Exact instruction and code starts are product-composition facts.

### Publish each callable immediately

Rejected. A detached direct, call, or loop product may invalidate a later callable.

### Clear inactive rows

Rejected. `callableCount` defines the complete return product.

## References

- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0159](WIP-0159-sparse-callable-composition-publication.md)
