# WIP-0160: Sparse callable-coordinate publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, callable coordinates, bounded publication |
| Depends on | WIP-0055, WIP-0056, WIP-0159 |
| Supersedes | Full-capacity callable and product-coordinate copies |
| Superseded by | None |

## Summary

Publish only active callable and source-product coordinate rows. `CallableCoordinateProducts.w` formerly copied all 320 callable words and all 36,864 coordinate words after planning exact callable and product counts.

The planner now publishes five callable columns through `callableCount` and nine product columns through `productCount`.

## Callable coordinates

For `f` local callables, five 64-row columns publish:

- physical local count
- instruction count
- code start
- code length
- first local type

Parameter counts seed each callable frame. Source products then advance physical locals, instruction rows, code bytes, and local type rows in strict source order.

## Product coordinates

For `p` source products, nine 4,096-row columns publish:

- physical local start
- physical local end
- instruction start
- instruction count
- code start
- code length
- first local type
- local type count
- validated product extent

Parent and descendant products retain exact nesting. Every product is consumed once by its callable owner.

## Atomicity

Source order, owner, parent, depth, logical local ranges, physical widths, instruction counts, code lengths, local type counts, callable totals, and all capacities finish in private staging.

Active rows replace prior contents through fixed-capacity coordinates. Untouched rows retain prior contents. Any malformed coordinate relation leaves caller tables unchanged.

## Bounds

No capacity changes:

- 64 local callables
- five callable columns
- 4,096 source products
- nine product columns
- 256 physical locals per callable
- 32,768 instructions
- 262,144 code bytes

Worst-case work remains identical. Small modules no longer publish maximum coordinate capacity.

## Evidence

`NativeCompilerCallableCoordinateProductsExampleTest` checks source ordering, nested extents, callable totals, untouched rows, logical gaps, and malformed overlap rejection.

`NativeCompilerCoreParsingSourceProductsExampleTest` checks statement physical starts, direct and loop windows, code, local types, composition, and artifact equality.

The compiler archive contains 3,007,182 bytes with SHA-256 `519c6025fa6ba7467b78f9925a5c3ed7c1e8019f3e152bd367e322b72add4141`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `9a3fb81e4d75ad52d0ff22deefe636d58d56827ea1de80c1e87a2d96c8c60be9`. WIP-0159 and WIP-0160 together reduce the complete run to 15 minutes and 16 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] Five callable columns publish exactly `callableCount` rows.
- [x] Nine coordinate columns publish exactly `productCount` rows.
- [x] Every source product is consumed once by one callable.
- [x] Active rows replace prior contents after complete validation.
- [x] Untouched rows retain prior contents.
- [x] Focused coordinate and artifact tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The linked physical subset publishes twice with identical bytes.
- [x] The complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Compute coordinates during code composition

Rejected. Layout products close before code bytes move.

### Publish while visiting products

Rejected. A later overlap or count mismatch would expose partial coordinates.

### Clear untouched rows

Rejected. Active counts define this product and callers own unrelated rows.

### Raise the evidence deadline

Rejected. Inactive coordinate capacity carries no layout fact.

## References

- [WIP-0055](WIP-0055-source-ordered-callable-coordinate-products.md)
- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0159](WIP-0159-sparse-callable-composition-publication.md)
