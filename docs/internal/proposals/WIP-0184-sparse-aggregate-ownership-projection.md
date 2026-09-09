# WIP-0184: Sparse aggregate ownership projection

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, linker, and ownership maintainers |
| Created | 2026-08-18 |
| Updated | 2026-09-08 |
| Area | Self-hosting compiler, aggregate ownership, operand relocation, bounded publication |
| Depends on | WIP-0046, WIP-0051, WIP-0183 |
| Supersedes | Full-capacity aggregate owner and operand projection copies |
| Superseded by | None |

## Summary

Publish aggregate ownership projections and aggregate operand relocations through
exact counts. Unused caller storage is not part of the product.

`AggregateOwnerProjections.w` formerly copied all 16,384 projection words. It now
publishes two columns through `eventCount`.

Operand projection formerly copied all 12,288 relocation words and all 131,072
identity bytes. `AggregateOperandRelocations.w` now owns strict local resolution
and filtered imported projection. Both publish three counted columns and exactly
32 identity bytes per relocation. The separate `AggregateOperandProjections.w`
implementation and its passive frontend import are deleted.

## Owner projections

Instruction-derived ownership events join function/local/aggregate/member
projections to counted aggregate and member rows. This is not the final linker's
owner/function/frame-local/aggregate carrier schema. Two output columns retain:

- aggregate target row
- member target row

Move events require the destination projection to agree with the event aggregate
and member. Create, loan, release, and drop events retain their validated owner
coordinates.

## Operand relocations

Aggregate constructor instructions carry local descriptor operands before final
linking. Three relocation columns retain:

- local instruction row
- counted aggregate target
- aggregate kind

Each relocation also retains the 32-byte aggregate product identity. Record,
array, slice, and variant constructor opcodes map to distinct kinds.

Strict local lookup requires exactly one kind/type match among at most 64
checked descriptors. The selected row is the target. All rows share one supplied
identity. A missing or duplicate match traps without publication.

Filtered projection validates every counted owner/kind/type/target row, then
selects by owner, kind, and temporary ID. The selected projection supplies the
target and its complete identity. An unmatched constructor produces no relocation.
A duplicate makes the plan invalid. The two policies share lookup, private
staging, and counted publication.

Callers replace `wheeler.compiler.closure.aggregate_operand_projections` imports
with `wheeler.compiler.closure.aggregate_operand_relocations`.
`AggregateOperandProjectionPlan` moves with its API and keeps the same two fields.
No compatibility module remains.

## Atomicity

Owner projection validates event kinds, local coordinates, projection uniqueness,
and aggregate/member agreement in private staging.

The operand owner consumes checked instruction rows. It classifies their
constructor opcodes and validates each complete type-operand window before
reading it. Canonical instruction framing remains the instruction producer's
responsibility, not this accessor's.

The selected product supplies all 32 identity bytes. Projection does not compute
or certify that identity. Caller rows and identity bytes change only after the
complete instruction window succeeds. Rejected products and unused tails retain
every caller value.

## Bounds

- 8,192 ownership events and two owner projection columns
- 4,096 instructions and operand relocations
- three relocation columns and 32 identity bytes per relocation
- 64 source-local descriptors, separately from 16,384 imported projections

Both operand APIs stage 229,376 bytes in two private allocations. Count and
backing failures reject before either allocation. The local descriptor and
imported projection capacities remain independent.

## Evidence

### Original sparse publication

Aggregate owner projection, instruction ownership, aggregate operand projection,
linked local type, product identity, and whole-artifact suites cover moves, loans,
releases, drops, constructor kinds, malformed operands, identity mismatch,
duplicate projections, and atomic failure.

That compiler archive contains 3,018,020 bytes with SHA-256
`a7930d6403d44a662ded78cb1fb841a19ec1ad275293b4deccb363fcdfe431b0`.
Its dependent locks name that archive. This is a milestone receipt, not the
current compiler pin.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts,
retained prefixes, and relocations. It links the 233-function, 8,556-instruction
subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces
SHA-256 `08b5978bc9bc6cdc8c314f5a21375d03369e1a5fa1862a36ba5513fcfe837aac`.
That evidence passes in 16 minutes and 31 seconds under its twenty-minute deadline.

### Shared operand owner

`NativeCompilerAggregateOperandBoundaryExampleTest` passes against both parent
implementations and the shared owner with identical transport and expected
products. Ten methods cover all four constructor kinds, exact owner selection,
strict versus filtered absence, late duplicates, complete operand windows, every
required column, identity backing, negative and first-excess counts, and
unselected malformed projection rows. Complete caller buffers, input bytes,
identities, and unused tails compare.

The last local descriptor, owner 511, target 4,095, instruction row 4,095, and
projection row 16,383 have separate accepted controls. These are accessor and
table bounds, not simultaneously full canonical source artifacts. The raw operand
fixtures do not validate whole-container framing.

Small fixtures rewind to their initial machine snapshots. A full-driver retained
maximum-projection attempt exhausts the unchanged heap. The two large row fixtures
instead build metadata without history, then retain and rewind the complete API
call and cleanup to the prepared snapshot. They do not prove preparation rewind.
Sparse input canaries and the selected identity are initialized, while every
caller byte and cell is compared.

Ten mutants break owner selection, kind selection, uniqueness, strict absence,
identity selection, atomic publication, the last instruction, the last projection,
column preflight, or operand-window checking. Each reaches the intended failing
assertion or trap. All source hashes and the complete source inventory restore
after every run.

## Original acceptance

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

## Remaining adoption

`Driver.w` imports the operand owner but calls neither relocation API. Direct
fixtures exercise both entry points. The proved replacement removes duplicate
lookup and publication code. It does not implement the source-to-final operand
join in [WIP-0054](WIP-0054-native-source-product-artifact-integration.md).
Rooted module membership alone is not production adoption.

## Rejected alternatives

**Rewrite constructor operands before identity resolution.** Final numeric
descriptors require stable aggregate product identities first.

**Bind ownership by local type code alone.** Function, local slot, aggregate, and
member coordinates are required.

**Clear inactive rows and identity bytes.** Event and relocation counts define
complete products.

## References

- [WIP-0046](WIP-0046-counted-native-aggregate-layout-products.md)
- [WIP-0051](WIP-0051-native-aggregate-frontend-products.md)
- [WIP-0183](WIP-0183-sparse-aggregate-owner-publication.md)
