# WIP-0058: Nested source call window products

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler and callable-layout maintainers |
| Created | 2026-08-14 |
| Updated | 2026-08-14 |
| Area | Self-hosting compiler, structured control flow, calls |
| Depends on | WIP-0052, WIP-0055, WIP-0057 |
| Supersedes | Nested call-window work in WIP-0057 |
| Superseded by | None |

## Summary

Compose calls inside loop and nested-control code windows without flattening their source owners. A nested call must use the same statement-local, instruction, and code coordinates as its enclosing control product.

## Problem

WIP-0057 composes source-root calls beside root loops and direct statements. `LoopInstructionProducts.w` still owns each complete nested code window. A separate root call buffer cannot splice a call into that window after loop branches and back edges have received offsets.

The loop product must admit a call as one measured body product before it calculates branch spans. Call emission must not infer an enclosing loop from source order after code exists.

## Products

Each nested call retains:

- exact source statement and enclosing block
- enclosing root loop and nested depth
- statement-local physical start and width
- instruction offset inside the root-loop window
- code offset and encoded length inside the root-loop window
- ordered argument value products
- stable target product

`LoopInstructionProducts.w` consumes those rows while it recursively measures the enclosing body. `LoopLocalTypeProducts.w` consumes the same statement-local row.

## Invariants

- A call belongs to the narrowest statement and one exact enclosing block.
- Recursive loop measurement includes call instructions before branch spans publish.
- A nested call never enters the root-call code buffer.
- Call result locals remain inside the call statement's planned physical window.
- Reordered call and loop storage leaves artifact bytes unchanged.
- Failure preserves loop windows, call windows, types, code, and relocations.

## Bounds

- four structured nesting levels
- 256 calls per module
- seven arguments per call
- 32,768 instructions per callable
- 262,144 code bytes per module

## Plan

1. Bind each call statement to its exact enclosing block and root loop.
2. Add call extents to recursive loop-body measurement.
3. Emit nested call code during recursive loop composition.
4. Publish nested call instruction and code offsets from the loop window.
5. Merge nested call local types through planned statement starts.
6. Verify relocations and ownership against the composed artifact.

## Acceptance

- A call in the first nested root precedes a direct statement and a second root byte for byte.
- A depth-four call compiles and a depth-five call publishes nothing.
- Signed, Boolean, and void nested calls retain exact local windows.
- A malformed nested argument leaves every caller buffer unchanged.
- Shuffled loop and call product storage does not change the artifact.

## Rejected alternatives

### Splice encoded calls after loop emission

Rejected. Branch spans and relocation instruction rows would already be stale.

### Lift nested calls to callable roots

Rejected. That changes execution order and destroys block ownership.

## References

- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0055](WIP-0055-source-ordered-callable-coordinate-products.md)
- [WIP-0057](WIP-0057-source-call-relocation-and-ownership-coordinate-products.md)
