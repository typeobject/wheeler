# WIP-0185: Sparse ownership-coordinate publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, linker, and ownership maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, ownership coordinates, source and decoded evidence |
| Depends on | WIP-0046, WIP-0051, WIP-0184 |
| Supersedes | Full-capacity source and decoded ownership coordinate copies |
| Superseded by | None |

## Summary

Publish source-planned and instruction-decoded ownership coordinates through exact event counts.

`SourceOwnershipProducts.w` formerly copied all 32,768 coordinate words. It now publishes four columns through `effectCount`.

`InstructionOwnershipProducts.w` formerly copied the same capacity after decoding artifact instructions. It now publishes four columns through `eventCount`.

The existing agreement check continues to compare both products event by event.

## Coordinate schema

Both products retain:

- source statement
- callable-local instruction
- destination local
- source local

Creation, move, shared loan, mutable loan, release, and drop events use the same coordinate schema. Signed minus one retains an absent destination or source where the event kind permits it.

## Source products

Source ownership effects join planned statement and value coordinates before code generation. Every effect must name one valid statement, instruction offset, and required value local.

## Decoded products

Instruction ownership decoding validates function windows, instruction ownership, direction, opcodes, local indices, artifact selectors, and aggregate supplemental instructions before deriving coordinates.

`ownershipCoordinatesAgree` rejects any source-versus-bytecode difference across the active event count.

## Atomicity

Each producer validates its complete event stream in private staging. Four active columns publish only after every event succeeds. Untouched caller rows retain prior contents. Failure publishes no coordinate row.

## Bounds

No capacity changes:

- 8,192 ownership events per module
- four source coordinate columns
- four decoded coordinate columns
- 4,096 instructions per artifact
- 256 locals per function

Worst-case work remains identical.

## Evidence

Source ownership and instruction ownership suites cover create, move, loan, release, drop, supplemental artifact selection, source agreement, malformed coordinates, invalid opcodes, and atomic failure.

Aggregate owner projection, ownership identity, and product-linked artifact suites consume the same active coordinate rows.

The compiler archive contains 3,018,386 bytes with SHA-256 `85fdcf00d972bdac21bc08a409ca80ac3d935d12a7012c1c06bdb452549978a1`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `08b5978bc9bc6cdc8c314f5a21375d03369e1a5fa1862a36ba5513fcfe837aac`. Complete evidence passes in 16 minutes and 31 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] Source coordinate columns publish exactly `effectCount` rows.
- [x] Decoded coordinate columns publish exactly `eventCount` rows.
- [x] Both products retain one identical four-column schema.
- [x] Active agreement checks remain event exact.
- [x] Untouched caller rows retain prior contents.
- [x] Focused source, decoded, identity, and artifact tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] Complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Trust source ownership without decoding

Rejected. Canonical bytecode must reproduce the planned relation.

### Recover source statement identity from code offsets

Rejected. Source statement products own that coordinate.

### Clear inactive rows

Rejected. Event counts define complete products.

## References

- [WIP-0046](WIP-0046-counted-native-aggregate-layout-products.md)
- [WIP-0051](WIP-0051-native-aggregate-frontend-products.md)
- [WIP-0184](WIP-0184-sparse-aggregate-ownership-projection.md)
