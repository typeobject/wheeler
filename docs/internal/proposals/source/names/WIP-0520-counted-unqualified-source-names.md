# WIP-0520: Counted unqualified source names

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-12 |
| Updated | 2026-09-12 |
| Area | Self-hosting, source names, counted compilation |
| Depends on | WIP-0049, WIP-0514, WIP-0517, WIP-0521 |
| Supersedes | None |
| Superseded by | None |

## Missing name domain

The aggregate adapter accepts an intact class without a module declaration.
Shared callable fronts already represent its absent qualifier as an empty range.
The counted archive compiler rejects that range, and its name writer always
inserts `::`. Injecting a synthetic module would change callable identities and
claim names. Keeping the minimal compiler for these sources would preserve the
boundary that WIP-0516 must remove.

Accept the existing empty-range product in the existing counted path. Do not add
a parser, a fallback compiler, or a source wrapper.

## Contract

An empty module-name window selects bare callable names. A nonempty window keeps
the existing `module::callable` spelling. The class name, declaration-order globals,
source-local callable order, entry role, effects, and original claims do not change.
A library retains `$library`. An executable retains its declared entry.

Validate the complete qualifier window even when its length is zero or no callable
uses it. The start may equal the backing length. Negative starts or lengths,
overflowing coordinates, and lengths above 256 reject. Check these archive inputs
before private storage allocation. Keep result construction before publication
and preserve every caller buffer on rejection.

This API consumes name products. An empty window requests a naming domain, not
proof that arbitrary input lacks a module declaration. Producers must supply the
qualifier from the admitted source front. No dependency source crosses this API.

`requireArchiveSourceNames` owns archive-window preflight. The existing
`materializeSourceModuleNames` omits both the qualifier copy and delimiter for
empty windows. It also validates unused qualifier windows. Neither change needs
new owned storage. Parser and result records remain separate allocations.

The first implementation needs 323 locals in the name orchestrator. Extracting
callable-name writing and canonical ordering reduces that frame to 224 locals.
The two phases use 76 and 92 locals, and the existing byte copier uses 58. Tests
inspect these compiled frames against the unchanged 256-local width. The archive
target-view orchestrator still needs 529 locals. Frame fit for the name owner does
not establish native compilation of its nominal record operations or the caller.

## Bounds and exclusions

Keep 32,768 source and artifact bytes, 4,096 raw tokens, 64 source callable rows,
and 256 identifier bytes. These are different bounds. The current verifier's
`INTERPRETER_FUNCTION_COUNT` admits only 24 final functions. A library's synthetic
entry consumes one of those functions. Staging 64 callables does not establish
publication of 64 functions. Capacity evidence must check this distinction rather
than raise a VM or verifier limit.

The fixture owns fifteen callable columns, four parameter columns, three token
columns, a two-word module range, a one-word parameter counter, the counted scalar
packet, its name-start column, and five report words. Its reservation is
`(4096*15 + 16384*4 + 4096*3 + 2 + 1 + 114689 + 16384 + 5)*8
 + sourceLength + max(1, scalarNameBytes) + 32` bytes in thirty buffers. Freezing the
selected source preserves its identity. Tests compare this sum with actual arena
charges before dropping storage.

This work does not expand argument syntax. In particular, a literal argument in
`observed = helper(7)` remains unjoined. The equivalent counted identifier call
uses a declared local argument. Both inputs stay in the tests, one as an explicit
rejection. Aggregate projection, final nominal sections, imported targets,
physical-owner frame fit, retention, and the runner dispatcher remain open.

## Evidence

Before the change, the intact class-only entry traps in
`requireArchiveSourceNames`. The new fixture stages names, signatures, and bodies
through the shared native fronts and passes those counted products to the archive
compiler. No function in its driver invokes `compileMinimal`.

Nine methods check frame widths, bare libraries, actual entries in both source orders,
contextual helper names, six host-loan signatures, globals, closed constants,
ordinary bounds, and generated-inverse claims. Complete artifacts, SHA outputs,
report fields, caller inputs, globals, and inactive tails agree. Entry artifacts
execute and replay. Publication and cleanup replay from the report boundary.
Malformed empty windows reject before private storage and replay exactly.

Capacity cases run without history. They cover the actual function publication
bound for executables and libraries, rejection immediately above it and at 64
staged callables, an invalid count of 65, a 256-byte identifier and an invalid
257-byte name product, and a complete 32,768-byte source. The full-source case exposed the
separate block-comment loop defect in WIP-0521.

A bound of one fails against the actual emitted entry instructions. The rejected
private container matches an independently constructed invalid artifact byte for
byte, including the original bare claim name and argument. Java also rejects that
container for the failed step bound. This is scalar-code evidence, not a decision
about a later nominal composition.

Stage 0 supplies independent executable artifacts. Its library oracle requires a
module wrapper, so the fixture removes that oracle namespace from semantic
function and claim records before canonical encoding. The native input never
receives that wrapper or altered declarations.

The final focused selection passes twelve new examples and twelve documentation
checks. A separate selection passes 116 affected examples and 32 source checks.
Original physical archive intake passes in four minutes and twenty seconds with
483 modules, 2,442 constants, and 1,903 callables. All 487 protected compiler and
binary-encoding sources remain unchanged after the run. Independent archive and
graph construction agree. The selected 603,784-byte linked reference is unchanged,
so its long body comparison was not rerun.

Four regenerated dependency locks, all 181 workspace targets, and the six-root
Tree-sitter parse pass. A locked consumer matches its complete 4,089,176-byte
driver without a minimal-compiler function. It emits a 776-byte artifact with
bare claims and a global call destination. Complete inputs, output tails, digest,
and report agree. Publication takes 1,707,373 transitions and termination takes
1,707,405 under the unchanged four-million-step command bound. Cleanup rewinds
and replays 32 transitions. This is API execution, not a compiler fixed point.

Hosted run `34735909183` for `76249b327` found an older archive-name fixture
that still rejected an empty qualifier. The follow-up keeps that physical
`CoreParsing.w` case as an acceptance control. It compares the complete private
artifact and identity before cleanup against an independently unqualified
semantic oracle. Negative qualifiers now include a negative length. The shared
test oracle changes names only, never instruction bytes or descriptors.

## Acceptance

- [x] Empty qualifiers use the shared counted path without synthetic source names.
- [x] Complete artifacts, reports, identities, inputs, tails, and execution agree.
- [x] Range rejection, publication, and cleanup retain real rewind and replay.
- [x] Actual function limits and full identifier/source windows have direct checks.
- [x] Actual-code claim rejection preserves every caller output.
- [x] Affected physical products, packages, locks, and documentation agree.
- [ ] The exact verified feature tree is committed, pushed, and checked remotely.
