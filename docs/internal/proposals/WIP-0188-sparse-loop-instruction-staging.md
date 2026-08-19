# WIP-0188: Sparse loop-instruction staging

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, loop instructions, body products, bounded staging |
| Depends on | WIP-0155, WIP-0161 |
| Supersedes | Full-capacity loop body, condition, and call-coordinate staging |
| Superseded by | None |

## Summary

Stage loop instruction inputs and republish call instruction starts through exact counts. `LoopInstructionProducts.w` formerly copied all body, condition, and call-start capacities before measuring loop code, then copied all 256 call starts back to the caller.

The emitter now stages five body columns through `bodyCount`, six condition columns through `loopCount`, and call starts through `callCount`. Final call-start publication also uses `callCount`.

## Loop staging

Five body columns retain source statement, opcode, operand kind, operand value, and local base for each resolved loop body instruction.

Six condition columns retain resolved condition kind, operands, limits, direction, and update products for each loop.

Call instruction starts retain root or nested call coordinates. Nested loop emission rebases those starts as enclosing loop headers and bodies add instructions.

## Measurement and emission

The emitter validates loop owners, depth, blocks, body statement windows, body products, calls, nested loops, local frames, and source order.

It measures every root loop before output mutation, computes owner-local instruction biases, checks complete code capacity, then emits roots in source order. Measured and emitted instruction and byte totals must agree exactly.

## Atomicity

All mutable body, condition, loop-start, and call-start work occurs in private staging. Failed measurement publishes no code or coordinate.

Successful emission updates root loop starts and active call starts only. Untouched rows retain caller contents.

## Bounds

No capacity changes:

- 4,096 body products in five columns
- 256 loops in six condition columns
- 256 calls
- four nested loop levels
- 262,144 code bytes

Worst-case work remains identical.

## Evidence

Loop instruction, nested block, nested body, call, local type, buffer, and CoreParsing source-product suites cover root and nested loops, source order, rebasing, calls, guards, buffers, malformed ownership, and atomic failure.

The compiler archive contains 3,020,044 bytes with SHA-256 `63ab429805d963f327f5caf984950a2ab0617e81c1ef1ababdba04ac171c9728`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `08b5978bc9bc6cdc8c314f5a21375d03369e1a5fa1862a36ba5513fcfe837aac`. Complete evidence passes in 16 minutes and 11 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] Five body columns stage exactly `bodyCount` rows.
- [x] Six condition columns stage exactly `loopCount` rows.
- [x] Call starts stage and publish exactly `callCount` rows.
- [x] Measured and emitted loop extents remain equal.
- [x] Untouched caller rows retain prior contents.
- [x] Focused loop instruction, nested product, and artifact tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] Complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Emit while measuring

Rejected. A later nested-loop or capacity failure would expose partial code.

### Recompute call starts after code emission

Rejected. Nested emission already owns exact instruction rebasing.

### Clear inactive call starts

Rejected. `callCount` defines the complete call-coordinate product.

## References

- [WIP-0155](WIP-0155-sparse-physical-loop-publication.md)
- [WIP-0161](WIP-0161-sparse-call-instruction-publication.md)
