# WIP-0508: Checked imported nominal fragments

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler and aggregate maintainers |
| Created | 2026-09-08 |
| Updated | 2026-09-08 |
| Area | Imported nominal scaffolding, projection publication |
| Depends on | WIP-0050, WIP-0187 |
| Supersedes | Duplicate unchecked nominal declaration emitters |
| Superseded by | None |

## Boundary

Give the two imported-nominal source writers one checked declaration-fragment
owner. [WIP-0050](WIP-0050-native-aggregate-source-lowering.md) owns the surrounding
lowering contract. [WIP-0187](WIP-0187-sparse-nominal-reference-publication.md) owns
counted projection publication.

`ImportedNominalStubs.w` and `ImportedNominalReferences.w` duplicate generated
names, reserved-prefix checks, declaration bytes, and temporary type-code assembly.
They also admit type IDs that overwrite the nominal kind tag. On clean `2a7f5e40c`,
a first record ID of `0x10000000` produces `0x20000000`: a record declaration gets
a variant projection code. The native writer does not reject.

## Change

`ImportedNominalStubs.w` owns a declaration fragment: byte length and projection
count, with sorted record/variant declarations and counted owner/type-code/target
columns. It also owns bounded generated-name writing and the existing reserved
namespace check. `ImportedNominalReferences.w` calls those operations rather than
keeping a second encoder.

A fragment consumes one 4,096-cell selection bitmap, selected aggregate kinds,
module owner, separate first record and variant IDs, and caller output windows.
Only bits zero and one are valid. At most 64 selected targets may be emitted.
Target order, not request order, determines declaration and projection order.

Validate all selection cells, kinds, dimensions, output capacity, and both type-ID
windows before writing any caller byte or projection cell. IDs occupy the lower
28 bits of their temporary type code. A nonempty window may not cross that boundary.
An empty window may start at the one-past-end position. Record and variant counters
remain independent. This encoding bound does not widen the source-local descriptor,
frame, closure, or executable limits.

The fragment encoder allocates no staging after complete preflight. Publication
replaces only the measured byte window and three counted projection windows.
Unused bytes and cells remain unchanged. The existing source writers still stage
their complete reconstruction before publishing it.

Keep placement separate from spelling. The standalone writer inserts before class
close. Reference rewriting inserts before first use after class open and retains
call-width adjustments. Share declaration bytes without changing those positions,
existing type ordering, or the reserved namespace policy. No parser retry or new
source-placement grammar is introduced.

Delete the duplicate declaration loop, generated-name writer, and reserved-prefix
implementation from `ImportedNominalReferences.w`. Its import of the shared owner
must support actual calls, not merely make the physical graph connected.

## Evidence

Preserve complete source output from both placement policies and compare all
projection columns and unused tails. Compile a rewritten reference fixture with
the independent compiler, execute it, and rewind both the writer and executable.

Check target0/4095, 64 selections/excess65, duplicate requests, malformed first and
later kinds/bits, wrong dimensions, source/output windows, reserved namespace
collisions, empty windows, and last/first-excess temporary type IDs. Small negative
fixtures must isolate the rejected field and preserve every caller cell and byte.
Use mutations to prove ordering, kind-tag separation, complete preflight, and the
production reference writer's adoption of the shared checks.

The focused suites compare all 49,152 projection cells and every caller output
byte, including unused tails. Fragment tests use complete nonuniform aggregate
and projection columns. The 32 KiB capacity fixtures use sparse byte canaries and
compare the entire buffer. They accept the last byte and reject the first excess
extent and backing. They do not claim a maximum-size semantic artifact.
Fixture initialization uses three-cell chunks to stay below the unchanged 1 GiB
heap while retaining complete rewind. Single-cell initialization exhausted that
heap and is not acceptance evidence.

Seven restored mutations cover kind-tag bounds through the production reference
writer, early publication, target order, independent type counters, projection
dimensions, partial name writes, and reserved namespace checks. The complete
rewritten source constructs a record, calls a record-field reader, sets state to
seven, passes its assertion, and rewinds after independent compilation and encoding.

The isolated review verifies 75 distinct JUnit identities, all 451 physical archive
bindings, the retained package-entry targets, and the existing graph and SHA
bounds. The graph halts after 88,837,725 transitions below 89 million. The compiler
archive contains 3,383,574 bytes with SHA-256
`d98bf1cc2daef04f9103cabaa51e3ea502dd88419d5f610c6b51463e10623fbe`.
Four dependent locks name that archive. All 713 canonical package inputs bind to
the relevant Gradle tasks. Raw package manifests equal canonical bytes.

A fresh workspace build produces 497 artifacts. Five main API roots and the public
site pass. The locked minimum-state consumer matches all 568 artifact bytes and
772 coverage bytes, executes seven tested transitions, and observes state seven.
The native spine passes seven cases and the signed-ordering suite passes three.
These are local checks of the isolated feature, not hosted acceptance or evidence
for the unfinished member-front overlay.

## Acceptance

- [x] One owner emits checked names, declarations, and temporary projections.
- [x] Both source writers preserve their complete source and projection results.
- [x] Kind-tag aliases and malformed later inputs reject before publication.
- [x] Boundaries, independent compilation, execution, and rewind pass.
- [x] Duplicate emitters are deleted and the production reference path calls the owner.
- [x] Docs, relevant integration, identities, and dependent locks agree.

## Remaining work

Fragments remain temporary scaffolding, not retained semantic artifacts. Complete
nominal frames, instructions, descriptors, globals, entry, proofs, relocations,
physical compiler parity, and stage equality remain with WIP-0051/WIP-0054.
