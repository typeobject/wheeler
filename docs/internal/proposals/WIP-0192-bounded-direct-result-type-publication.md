# WIP-0192: Bounded direct result-type publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-19 |
| Updated | 2026-08-19 |
| Area | Self-hosting compiler, direct statements, result types, bounded publication |
| Depends on | WIP-0150, WIP-0162, WIP-0188 |
| Supersedes | Full-capacity direct result-type copies |
| Superseded by | None |

## Summary

Stage and publish direct statement result types through the exact local function count.

`DirectStatementProducts.w` formerly copied all sixty-four function result rows into private staging and back to the caller for every structured source module. The planner now receives the callable count from the closed source loop product and copies only active rows.

## Function count

`SourceLoopProducts` publishes the local callable count after complete callable, block, statement, condition, and loop validation. Direct statement compilation consumes that count alongside the already counted statements, calls, and values.

The sixty-four-row result-type buffer remains the ABI capacity. `functionCount` is an extent, not another allocation size.

## Prefix state

Direct statement compilation tracks whether each function's emitted instruction prefix remains contiguous. Prefix state now initializes through `functionCount`. Every statement owner is validated against the same closed callable product before prefix state is read.

## Atomicity

Active result types copy into invocation-owned staging before statement classification. Failure changes no caller result row. Successful publication replaces exactly the active prefix. Inactive caller rows retain prior contents.

## Bounds

No capacity changes:

- sixty-four local functions
- 4,096 statements
- 256 calls
- 1,024 values

Worst-case work remains identical.

## Evidence

CoreParsing source products and structured source compilation cover empty and nonempty callable sets, direct returns, call-conditioned returns, loops, local types, failure diagnostics, and exact artifacts.

The compiler archive contains 3,021,037 bytes with SHA-256 `f7739f212acdee08c13edf8c643f7e891ea55772408e173bd5124d96fac0a8c4`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `08b5978bc9bc6cdc8c314f5a21375d03369e1a5fa1862a36ba5513fcfe837aac`. Complete evidence passes in 19 minutes and 3 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] The direct planner receives explicit `functionCount`.
- [x] Result-type staging uses exactly `functionCount` rows.
- [x] Prefix state initializes through exactly `functionCount` rows.
- [x] Result-type publication uses exactly `functionCount` rows.
- [x] Inactive caller rows remain untouched.
- [x] Focused CoreParsing and structured artifact tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] Complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Infer function extent from statements

Rejected. Empty functions remain valid callable products.

### Clear inactive rows

Rejected. Inactive capacity is not part of the product.

### Retain the sixty-four-row copy

Rejected. The closed callable count is already available.

## References

- [WIP-0150](WIP-0150-sparse-source-value-publication.md)
- [WIP-0162](WIP-0162-sparse-callable-return-publication.md)
- [WIP-0188](WIP-0188-sparse-loop-instruction-staging.md)
