# WIP-0159: Sparse callable-composition publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, callable composition, local types, bounded publication |
| Depends on | WIP-0049, WIP-0054, WIP-0158 |
| Supersedes | Full-capacity callable-composition copies |
| Superseded by | None |

## Summary

Publish only composed callable and local-type rows that survive complete source-product validation. `CallableSourceComposition.w` formerly copied all 320 callable words and all 12,288 local-type words after planning exact callable and type counts.

The composer now publishes five callable columns through `callableCount` and three local-type columns through `typeCount`. Code publication was already bounded by the measured code cursor.

## Composition

For each callable, source order selects every top-level direct statement, call, or loop exactly once. The composer appends its code, instructions, and local types, then adds the canonical void return where required.

The five callable columns retain:

- code start
- code length
- instruction count
- local-type start
- local count

The three type columns retain callable owner, callable-local index, and canonical type code. Signature, direct, call, and loop type products must form one contiguous local sequence with no duplicate producer.

## Atomicity

Statement ownership, root blocks, direct products, calls, root loops, return products, code extents, instruction counts, and local-type coverage finish in private staging.

Active rows replace prior caller contents only after every count agrees. Untouched rows retain prior contents. Malformed composition publishes no callable, type, or code row.

## Bounds

No capacity changes:

- 64 callables
- five callable columns
- 4,096 local types
- three type columns
- 262,144 code bytes
- 4,096 source statements
- 256 calls and root loops

Worst-case work remains identical. A small module no longer pays maximum publication cost.

## Evidence

`NativeCompilerCoreParsingSourceProductsExampleTest` checks callable windows, local types, direct and loop products, and exact artifact bytes. `NativeCompilerStructuredCallSourceProductExampleTest` covers imported and local calls, nested loops and guards, reversible result slots, argument products, malformed children, and atomic failure.

The compiler archive contains 3,007,182 bytes with SHA-256 `519c6025fa6ba7467b78f9925a5c3ed7c1e8019f3e152bd367e322b72add4141`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `9a3fb81e4d75ad52d0ff22deefe636d58d56827ea1de80c1e87a2d96c8c60be9`. WIP-0159 and WIP-0160 together reduce the complete run to 15 minutes and 16 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] Five callable columns publish exactly `callableCount` rows.
- [x] Three local-type columns publish exactly `typeCount` rows.
- [x] Code publication remains bounded by measured bytes.
- [x] Every direct product, call, and root loop is consumed exactly once.
- [x] Signature, direct, call, and loop types form contiguous callable locals.
- [x] Untouched caller rows retain prior contents.
- [x] Focused composition and structured-call tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The linked physical subset publishes twice with identical bytes.
- [x] The complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Clear inactive rows

Rejected. Active counts define this product and callers own unrelated rows.

### Publish while composing each callable

Rejected. A later duplicate product or type gap would expose a partial composition.

### Infer local count from the type capacity

Rejected. A callable owns one contiguous local prefix, not a 4,096-row reservation.

### Raise the evidence deadline

Rejected. Inactive rows carry no composition fact.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0158](WIP-0158-committed-owned-storage.md)
