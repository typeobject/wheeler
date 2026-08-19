# WIP-0184: Sparse aggregate ownership projection

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, linker, and ownership maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, aggregate ownership, operand relocation, bounded publication |
| Depends on | WIP-0046, WIP-0051, WIP-0183 |
| Supersedes | Full-capacity aggregate owner and operand projection copies |
| Superseded by | None |

## Summary

Publish aggregate ownership projections and aggregate operand relocations through exact counts.

`AggregateOwnerProjections.w` formerly copied all 16,384 projection words. It now publishes two columns through `eventCount`.

`AggregateOperandProjections.w` formerly copied all 12,288 relocation words and all 131,072 identity bytes. It now publishes three columns through `relocationCount` and exactly 32 identity bytes per relocation.

## Owner projections

Instruction-derived ownership events join function-local carrier projections to counted aggregate and member rows. Two columns retain:

- aggregate target row
- member target row

Move events require the destination carrier to agree with the event aggregate and member. Create, loan, release, and drop events retain their validated owner coordinates.

## Operand relocations

Aggregate constructor instructions carry temporary local descriptor operands before final linking. Three relocation columns retain:

- local instruction row
- counted aggregate target
- aggregate kind

Each relocation also retains the 32-byte aggregate product identity. Record, array, slice, and variant constructor opcodes map to distinct kinds.

## Atomicity

Owner projection validates event kinds, local coordinates, projection uniqueness, and aggregate/member agreement in private staging.

Operand projection validates instruction ranges, opcodes, encoded operands, module ownership, projection uniqueness, aggregate target, kind, and identity before publication. Untouched rows and identity bytes retain caller contents. Failure publishes no product.

## Bounds

No capacity changes:

- 8,192 ownership events
- two owner projection columns
- 4,096 instructions and operand relocations
- three relocation columns
- 32 identity bytes per relocation
- 16,384 nominal projections

Worst-case work remains identical.

## Evidence

Aggregate owner projection, instruction ownership, aggregate operand projection, linked local type, product identity, and whole-artifact suites cover moves, loans, releases, drops, constructor kinds, malformed operands, identity mismatch, duplicate projections, and atomic failure.

The compiler archive contains 3,018,020 bytes with SHA-256 `a7930d6403d44a662ded78cb1fb841a19ec1ad275293b4deccb363fcdfe431b0`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `08b5978bc9bc6cdc8c314f5a21375d03369e1a5fa1862a36ba5513fcfe837aac`. Complete evidence passes in 16 minutes and 31 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] Owner projection columns publish exactly `eventCount` rows.
- [x] Operand relocation columns publish exactly `relocationCount` rows.
- [x] Identity publication writes exactly `relocationCount * 32` bytes.
- [x] Aggregate kind and target joins remain exact.
- [x] Untouched caller rows and identity bytes retain prior contents.
- [x] Focused ownership, operand projection, and artifact tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] Complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Rewrite constructor operands before identity resolution

Rejected. Final numeric descriptors require stable aggregate product identities first.

### Bind ownership by local type code alone

Rejected. Function, local slot, aggregate, and member coordinates are required.

### Clear inactive rows and identity bytes

Rejected. Event and relocation counts define complete products.

## References

- [WIP-0046](WIP-0046-counted-native-aggregate-layout-products.md)
- [WIP-0051](WIP-0051-native-aggregate-frontend-products.md)
- [WIP-0183](WIP-0183-sparse-aggregate-owner-publication.md)
