# WIP-0193: Terminal aggregate-operation failure

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-19 |
| Updated | 2026-08-19 |
| Area | Self-hosting compiler, aggregate syntax, failure atomicity, bounded execution |
| Depends on | WIP-0051, WIP-0175 |
| Supersedes | Nonadvancing invalid aggregate-operation scans |
| Superseded by | None |

## Summary

Terminate aggregate-operation scanning as soon as syntax validity is lost.

A constructor with a trailing argument separator made `stageArguments` return an invalid product after the outer scanner had entered the constructor branch. The scanner advanced once, reached another token with `valid == false`, and then neither branch advanced `cursor`. The bounded loop eventually trapped on its iteration limit instead of returning the invalid product.

`SourceAggregateOperations.w` now moves `cursor` to the semantic end whenever `valid` becomes false.

## Failure contract

Malformed aggregate syntax is not a resource-exhaustion event. The planner must complete in bounded time, report `valid == false`, and publish no operation or argument row.

Downstream callers continue to assert planner validity before projection, binding, target resolution, or code generation. A caller that ignores the verdict may trap, but it cannot observe published malformed rows.

## Covered paths

The terminal failure rule applies after invalid:

- record and variant construction
- slice construction
- indexed projection
- nested postfix ownership resolution
- argument framing

Branches that already move `cursor` to the semantic end remain unchanged.

## Bounds

No capacity changes:

- 4,096 semantic tokens
- 256 aggregate operations
- 1,024 aggregate arguments

Successful transition counts and source order remain unchanged. Invalid scans stop earlier.

## Evidence

`NativeCompilerSourceAggregateOperationsExampleTest` covers a trailing constructor separator. The planner no longer reaches its loop-iteration trap. The downstream fixture rejects the invalid verdict before publication and leaves its output bytes zero.

The existing suite continues to cover missing delimiters, nested constructors, fixed arrays, slice constructors, postfix slice indexes, projections, source order, and evaluation order.

The compiler archive contains 3,021,106 bytes with SHA-256 `3378eeff4264eb113988db8dd45a788fcef0227ed42df22d28668ee1930f65f6`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `08b5978bc9bc6cdc8c314f5a21375d03369e1a5fa1862a36ba5513fcfe837aac`. Complete evidence passes in 16 minutes and 35 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] Any invalid scan forces terminal cursor state.
- [x] Trailing constructor separators do not exhaust the scan loop.
- [x] Invalid operation and argument rows remain unpublished.
- [x] Existing aggregate-operation products remain unchanged.
- [x] Focused aggregate-operation tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] Complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Let the loop bound report malformed syntax

Rejected. Resource exhaustion is not a syntax verdict.

### Advance one token after failure

Rejected. No later token can restore an atomic product.

### Publish the valid prefix

Rejected. Aggregate operation products are module transactions.

## References

- [WIP-0051](WIP-0051-native-aggregate-frontend-products.md)
- [WIP-0175](WIP-0175-sparse-aggregate-operation-publication.md)
