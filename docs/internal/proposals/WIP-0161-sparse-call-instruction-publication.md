# WIP-0161: Sparse call-instruction publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, call coordinates, bounded publication |
| Depends on | WIP-0057, WIP-0156, WIP-0157 |
| Supersedes | Full-capacity source-call instruction copies |
| Superseded by | None |

## Summary

Publish source-call instruction starts and windows only for active calls. `SourceCallInstructionProducts.w` formerly copied all 256 start rows and all 768 window rows after planning an exact call count.

The planner now publishes `callCount` start rows and three `callCount` window columns. The structured source compiler invokes this planner before and after final direct-code sizing, so the removed inactive work occurred twice per module.

## Products

Calls are selected in source order. A call owns one statement, one target shape, one argument count, and one measured instruction and byte extent.

The start row records the callable-local instruction start for a root call. Nested calls retain zero in that row and receive their final enclosing coordinate later.

The three window columns retain:

- code start
- instruction count
- code length

Every active call receives all three rows. No inactive row is part of this product.

## Atomicity

Statement ownership, nesting, prior direct and loop windows, call order, argument count, instruction capacity, code capacity, and duplicate starts finish in private staging.

Active rows publish only after every call is selected once. Untouched rows retain caller contents. Failure publishes no start or window row.

## Bounds

No capacity changes:

- 256 calls
- 256 start rows
- three 256-row window columns
- 32,768 instructions
- 262,144 code bytes
- four levels of structured nesting

Worst-case work remains identical.

## Evidence

`NativeCompilerSourceCallInstructionProductsExampleTest` checks root and nested calls, source order, direct and loop prefixes, malformed ownership, and atomic publication.

`NativeCompilerCoreParsingSourceProductsExampleTest` checks the preliminary and final call-instruction plans through exact artifact composition.

The compiler archive contains 3,007,567 bytes with SHA-256 `016276c5165ec57d72a64b10ff8d615a8904c557029f83302a5075a380c54257`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `9a3fb81e4d75ad52d0ff22deefe636d58d56827ea1de80c1e87a2d96c8c60be9`. WIP-0161 and WIP-0162 complete in 15 minutes and 4 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] Start publication writes exactly `callCount` rows.
- [x] Window publication writes three columns of `callCount` rows.
- [x] Root and nested call semantics remain distinct.
- [x] Every active call is selected exactly once.
- [x] Untouched rows retain caller contents.
- [x] Focused call-instruction and artifact tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The linked physical subset publishes twice with identical bytes.
- [x] Complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Publish only root starts

Rejected. Active nested rows must replace stale caller contents with zero before later nesting composition.

### Fold starts into call emission

Rejected. Instruction coordinates close before final call bytes emit.

### Clear inactive rows

Rejected. `callCount` defines the complete product.

## References

- [WIP-0057](WIP-0057-source-call-relocation-and-ownership-coordinate-products.md)
- [WIP-0156](WIP-0156-sparse-source-call-layout-publication.md)
- [WIP-0157](WIP-0157-sparse-call-emission-publication.md)
