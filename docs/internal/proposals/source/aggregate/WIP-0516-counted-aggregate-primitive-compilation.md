# WIP-0516: Counted aggregate primitive compilation

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-12 |
| Updated | 2026-09-12 |
| Area | Self-hosting, aggregate lowering, primitive products |
| Depends on | WIP-0049, WIP-0050, WIP-0051, WIP-0054, WIP-0514, WIP-0517 |
| Supersedes | None |
| Superseded by | None |

## Remaining legacy boundary

WIP-0514 compiles declared entries through counted scalar and callable products.
The intact WIP-0498 runner still fails at `compiler_core::requireMinimalProgram`,
instruction 181, local 178, after commit `c540db0f1`. Its test-source dispatcher
still selects `compileMinimal` and the two-to-eight-source variants.

Calling the existing aggregate adapter does not remove that dependency.
`AggregateCompiledCallableBodies.w` builds primitive and supplemental products,
but obtains its primitive artifact through `compileExactProductSource`.
`CompiledCallableBodies.w` sends that source to `compileMinimalCore`. Replacing
only the outer dispatcher would leave the same parser boundary underneath it.

Replace the aggregate adapter's primitive compilation with counted products.
Keep final nominal sections, claim verification, retained linking, and the runner
handoff as explicit later joins. Do not claim an executable nominal artifact from
primitive bytes and supplemental rows alone.

WIP-0517 splits out shared callable-front staging. It removes the closure index's
private delimiter parser and exposes source-local coordinates for this primitive
view. That producer is not yet connected to the aggregate adapter's compiler.

## Contract

1. Consume the admitted source range and its counted scalar, callable, signature,
   entry, aggregate, and coordinate products. Dependency bodies must not enter
   this compilation boundary.
2. Reuse the shared scalar binder, call layouts, direct statements, entry planning,
   and canonical encoding. Do not introduce another expression parser, resolver,
   minimal source family, or exception-driven fallback.
3. Keep projections private. Preserve the mapping between original declaration,
   body, statement, type, and operation coordinates and the primitive view.
   Global declaration-order and literal-assertion decisions must compare facts
   in the same coordinate domain.
4. Preserve ordinary helpers and the selected entry. Library intent remains
   explicit. An executable primitive artifact must retain the selected `HALT`
   entry, not a synthetic trailing function. Libraries retain their canonical
   entry. Reject unjoined effects rather than normalize them away.
5. Keep source claims as detached facts until final nominal code exists. An early
   primitive instruction count must neither certify a final bound nor reject a
   bound that only the final composition can decide. Do not publish a claim-free
   primitive artifact as the finished source artifact.
6. Produce validated primitive function, local-type, instruction, and placement
   windows for the existing selector-driven aggregate composer. Selector zero
   names primitive code, and selector one names supplemental code. Preserve
   function, direction, and instruction ordinals rather than matching opcodes.
7. Validate the complete input batch and output capacities before publication.
   A later failure must preserve every caller-visible row, byte, identity, and
   report. Private scratch may change. Allocate result records before publishing.
8. Remove the aggregate adapter's call to the minimal compiler. Delete an old
   helper only after migrating its remaining callers. Do not keep an equivalent
   wrapper under another name or silently widen an admission profile.

The selected mixed-member source must remain intact at the admission boundary.
Private projections may replace admitted aggregate syntax for primitive planning,
but must retain enough products to reconstruct every removed operation and type.
The final artifact may contain neither nominal carriers nor imported scaffolding.

## Bounds

Keep the current source-local limits: 32,768 source bytes, 4,096 raw tokens,
64 callables, 64 aggregates, 128 cases, 256 members or operations, and 1,024
aggregate arguments. Primitive artifacts remain bounded by 32,768 bytes.
Supplemental code retains its existing 12,288-byte window.

Describe each workspace as the sum of its named column extents and byte buffers.
Count simultaneous storage and lifetime buffer identities separately. The current
aggregate orchestrator reserves 2,275,488 bytes and 39 allocations. That existing
reservation is not permission to add unmeasured storage or assume spare capacity.

The scalar orchestrator already uses 4,063 of 4,096 raw token slots. Extract a
coherent owner instead of extending that file past the scanner bound. Keep
parameter transport within the existing callable ABI. Do not solve a large
signature by increasing argument, frame, scanner, source, or VM limits.

## Evidence required

Use the existing aggregate fixtures and the intact mixed-member source. Include
entry-before-helper and helper-before-entry order, payload-free variants and
enums, aggregate construction and projection, declaration-ordered globals,
contextual names, ordinary claims, and copied UTF-8 coordinates. Compare complete
primitive products and selector coordinates with an independently derived oracle.

Capacity fixtures run history-free. Representative successes and failures retain
real rewind and replay. Check inactive tails, borrowed inputs, private cleanup,
and late malformed rows before dropping storage. Preserve a final-composition
regression whose proof decision differs from the primitive placeholder decision.

## Acceptance

- [ ] The aggregate primitive path no longer invokes the minimal compiler.
- [ ] Counted names, types, calls, globals, entry roles, and coordinate domains agree.
- [ ] Primitive and supplemental joins preserve every admitted aggregate operation.
- [ ] Claims remain detached until final-code verification can decide them.
- [ ] Whole-batch rejection, tails, cleanup, rewind, and replay have direct evidence.
- [ ] Calculated storage, lifetime identities, source bytes, and raw tokens fit.
- [ ] Affected physical products, archives, locks, examples, and documentation agree.
- [ ] The exact verified feature tree is committed, pushed, and checked remotely.
