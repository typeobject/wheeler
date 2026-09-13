# WIP-0516: Counted aggregate primitive compilation

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-12 |
| Updated | 2026-09-13 |
| Area | Self-hosting, aggregate lowering, primitive products |
| Depends on | WIP-0049, WIP-0050, WIP-0051, WIP-0054, WIP-0514, WIP-0517, WIP-0518, WIP-0519, WIP-0520, WIP-0522 |
| Supersedes | None |
| Superseded by | None |

## Remaining legacy boundary

WIP-0514 compiles declared entries through counted scalar and callable products.
The intact WIP-0498 runner still fails at `compiler_core::requireMinimalProgram`,
instruction 181, local 178, after commit `c540db0f1`. Its test-source dispatcher
still selects `compileMinimal` and the two-to-eight-source variants.

The previous aggregate adapter obtained its primitive artifact through
`compileExactProductSource`, which called `compileMinimalCore`. The development
path now connects `AggregatePrimitiveCompiler.w` to the aggregate adapter and
removes that unused wrapper. Shared callable fronts and the counted archive
compiler produce the claim-free primitive artifact without a minimal fallback.
This does not yet close the original claim, global, and coordinate joins below.

Replace the aggregate adapter's primitive compilation with counted products.
Keep final nominal sections, claim verification, retained linking, and the runner
handoff as explicit later joins. Do not claim an executable nominal artifact from
primitive bytes and supplemental rows alone.

WIP-0517 splits out shared callable-front staging. It removes the closure index's
private delimiter parser and exposes source-local coordinates for this primitive
view. The aggregate primitive compiler now consumes that producer.
WIP-0518 retains original claim coordinates through shared binding so private
primitive views can omit claims without losing them or deciding their truth.
WIP-0519 stages carrier rows and constructs the aggregate report before copying
caller outputs. It repairs publication without replacing the primitive compiler.
WIP-0520 carries empty qualifiers through the existing counted name path so an
intact class-only primitive view needs no synthetic module declaration.
WIP-0522 splits out the counted primitive call and bounded private phases. The
original global, claim, coordinate, and nominal requirements remain here.

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
Supplemental code retains its existing 12,288-byte window. The existing native
verifier admits only 24 final functions, including a library's synthetic entry.
The 64-row staging bound does not establish 64-function artifact publication.
Keep that distinction explicit and do not raise the interpreter limit to hide it.

Describe each workspace as the sum of its named column extents and byte buffers.
Count simultaneous storage and lifetime buffer identities separately. The current
aggregate orchestrator reserves 2,268,704 bytes and uses 39 lifetime buffer
identities. WIP-0522 removes the redundant exact-source copy from WIP-0519's
40-ID path. The reservation derives from 249,280 word cells,
seven simultaneous source buffers, and three code/digest buffers. It is not
permission to add unmeasured storage or assume spare capacity.

The scalar orchestrator already uses 4,063 of 4,096 raw token slots. Extract a
coherent owner instead of extending that file past the scanner bound. Keep
parameter transport within the existing callable ABI. Do not solve a large
signature by increasing argument, frame, scanner, source, or VM limits.

The aggregate adapter also needs phase extraction. WIP-0519 used 55 parameters
and 1,247 stage-0 locals, compared with 1,199 locals before that repair. The
request-based adapter first used 56 parameters and 1,308 locals. Extracting value,
operation, preflight, and publication phases reduces it to 828 locals. Both
parameter lists fit, but neither complete frame meets the 256-local native bound.
Do not substitute buffer accounting or a stage-0-built consumer for native
compilation of this physical owner.

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

## Development integration

`AggregateSourceRequest` groups target intent, original source and class windows,
constant count, and module owner. Detached scalar rows and names remain separate
borrowed products. The aggregate adapter passes the private rewritten source to
the counted compiler, then retains the existing placeholder and supplemental
composition. Its original intact nominal fixture reaches this path with no
`compileMinimal` function in the compiled driver.

The primitive owner reserves 1,146,904 bytes and 25 buffer identities from its
callable, parameter, token, and source columns. Its first compiled frame used
275 locals. Extracting window preflight produces 67-local validation and a
234-local orchestrator under the unchanged 256-local bound. The aggregate
orchestrator still exceeds that bound. WIP-0522 records the extracted phases and
the remaining frame requirement. All twenty publication backings now receive
preallocation validation. The publication replay and late nominal rejection
checks pass. Three
additional failures reach the counted primitive boundary and preserve complete
prepared caller state for invalid entry intent, mismatched scalar counts, and
an invalid unused scalar row. The fixture's scalar table, start table, and
positive empty-name backing add 1,048,585 bytes and three buffer identities.
Its complete caller reservation is 3,416,105 bytes and 41 buffer identities.

Attached claims reject at the primitive boundary. The outer adapter still needs
to bind original claims and globals and preserve their coordinate products.
Rejecting attached claims is not the required detached-claim integration. This
work remains development evidence, not acceptance of the whole WIP. The current
aggregate owner measures 23,973 source bytes and 2,926 raw tokens. The primitive
owner measures 7,848 bytes and 1,086 tokens. The extracted binding owner measures
7,912 bytes and 786 tokens. Those source bounds fit without raising the scanner
limit.

## Remaining joins

WIP-0518 supplies bound claim origins and private same-length erasure. The
aggregate adapter does not consume them yet. Original global binding, projection
coordinates and detached imported targets remain required. WIP-0519 repairs the
existing carrier leak and report ordering. The counted replacement must preserve
that whole-publication contract.

## Acceptance

- [ ] The aggregate primitive path no longer invokes the minimal compiler.
- [ ] Counted names, types, calls, globals, entry roles, and coordinate domains agree.
- [ ] Primitive and supplemental joins preserve every admitted aggregate operation.
- [ ] Claims remain detached until final-code verification can decide them.
- [ ] Whole-batch rejection, tails, cleanup, rewind, and replay have direct evidence.
- [ ] Calculated storage, lifetime identities, source bytes, and raw tokens fit.
- [ ] Affected physical products, archives, locks, examples, and documentation agree.
- [ ] The exact verified feature tree is committed, pushed, and checked remotely.
