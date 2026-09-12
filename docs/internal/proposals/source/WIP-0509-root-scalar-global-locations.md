# WIP-0509: Root scalar global locations

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler, runtime, and bootstrap maintainers |
| Created | 2026-09-12 |
| Updated | 2026-09-12 |
| Area | Self-hosting, scalar binding, global loads and stores |
| Depends on | WIP-0049, WIP-0506, WIP-0507 |
| Supersedes | None |
| Superseded by | None |

## Boundary

This task implements the root scalar part of
[WIP-0507](WIP-0507-native-source-global-access-products.md). It does not complete
that parent. Nested control, global assertions under WIP-0510, counted helper-result stores,
entry selection, nominal composition, and source-independent global instruction
relocation remain required joins.

The initial archive regressions returned a declared global and stored a parameter
before reading it back. Independent stage 0 accepted both references. Native
compilation failed the direct statement plan's failure-coordinate assertion.
The source declarations and the failing statements remain intact.

## Locations and instructions

`SourceGlobalReferences.w` validates every copied name before selecting a
predecessor. It returns a declaration ordinal, not an initializer or a string ID.
`DirectScalarLocations.w` binds named operands to either `LOCAL_MOVE` from a frame
or `LOCAL_LOAD_GLOBAL` from that declaration ordinal. Scalar relations carry the
load opcode explicitly for each named operand. The same relation and encoding
owners handle arithmetic, comparisons, declarations, and ordinary returns.

`DirectGlobalStoreProducts.w` binds the destination separately from its value.
It uses the existing scalar relation and constant lookup, then emits
`LOCAL_STORE_GLOBAL`. A destination never becomes a local binding. Its value may
occupy real temporary locals before the store. Later loads read the changed
state, not a cached initializer.

The scalar destination emitter handles returns and stores through one value
sequence. It rejects unknown load and destination opcodes. The reversible return
owner remains distinct and rejects global locations. It preserves the existing
result-slot instructions and their operand counts.

The first profile rejects a global access when a callable value shares its name.
It also rejects overlapping global/constant names rather than guessing a namespace
or substituting a constant. The parent must still implement complete scope
admission and precedence. Callable and global names remain separate namespaces.

## Publication and bounds

All global name rows validate before body staging, even when the selected name
appears before a malformed later row. Name lookup adds no owned buffer or region.
Copied names retain the eight-global, 256-byte-per-name source profile.

`DirectStatementPublication.w` owns complete row publication. It constructs the
result before copying caller-visible products, types, or code. At commit
`c42ff6e36`, its arena derives from three scanner columns, seven statement columns, the existing loop-body
window, three type columns, three 64-function columns, two 256-call columns, one
statement-width column, and 262,144 code bytes. That is 890,368 bytes in 13 buffers.
[WIP-0510](WIP-0510-root-scalar-assertion-products.md) removes the root assertion
scratch table and reduces this arena to 726,528 bytes in twelve buffers. Neither
milestone increases an interpreter limit. The copy owner checks transport extents.
The statement producer owns semantic validation before calling it.

A copied scalar needs one result local. A binary value needs two operand locals
and one result local. Assignment planning reserves those cells before later
statement coordinates. Instruction lengths derive from header widths and operand
counts. A store's declaration ordinal remains independent of those frame cells.

`SourceIdentifierRanges.w` now owns source-to-copied-name matching. Constant and
global users share it. The constant-named matcher and duplicate return extent
record are gone. Root return emission and product publication have separate
owners to keep the direct statement source within its physical source window.

## Evidence

The implementation passes the original two accesses and twelve expression
cases, including both operand positions, two globals, local copies, arithmetic,
Boolean comparisons, conditional child returns, signed endpoints, and consecutive
stores. Complete artifacts, native digest bytes, and tails match independent
stage 0. Native intake checks all retained global columns.

A separate Java fixture replaces only the synthetic `$library` entry to invoke
the unchanged native callable with arguments 5 and 8 in separate calls. It compares complete machine
state and real rewind/replay with the independently compiled callable. This is
callable execution evidence, not native entry lowering or whole-compiler replay.

Global reference tests cover declaration order, absent names, the eighth global,
256-byte identifiers, malformed later ranges and names, duplicates, preservation,
and rewind/replay. Invalid or shadowed accesses cannot publish an earlier store.
Twenty-four raw scalar cases check terminal local/global indices, exact code
extent, first excess, malformed load/destination opcodes, and inactive bytes.
Ten reversible cases retain the existing slot forms and reject global operands.
These checks compare complete buffers and replay the emission phase. Thirteen
publication-transport cases check active columns, empty/discarded batches,
terminal capacities, first excess, and malformed late output windows. The full
capacity run discards preparation and publication history. Smaller cases retain
real publication and cleanup replay.

Stage 0 originally mistook an uppercase assignment destination for a nominal
type. Assignment punctuation now excludes that local-declaration branch. Five
front tests retain uppercase assignment/update and nominal declaration behavior.
The archive store regression again uses the original uppercase destination.

The final archive and selected physical checks pass with 476 modules, 2,341
constants, and 1,880 callables. Independent repacking and the 2,273-import,
220,899-byte graph agree. The selected 603,784-byte reference keeps its previous
identity. Native graph and separate SHA work measure 78,595,844 and 42,275,628
transitions. These are measured pins, not larger interpreter limits.

A resolved and vendored external consumer compiles an immutable source range that
stores `mod + LIMIT` into declaration ordinal one and then loads it. Its complete
752-byte artifact matches independent stage 0. It retains three globals, one
step claim, five locals, and six callable instructions. Native retained-global
intake and callable execution replay also pass. This does not supply the missing
source-independent instruction relocation or native entry join.

The 181-target workspace check/build, 138 stage-0 tests, source quality and
Tree-sitter checks pass. The 145-example adapter run and final 42-example selection
have no failures or skips. They overlap, so their counts do not describe distinct
coverage. Archive intake took 239.174 seconds and selected physical compilation
352.472 seconds. Ordinary example methods stayed below their two-minute deadline.

Commit `c42ff6e366f489d0d2b3971b20cda264bf04cf06` passed all 52 jobs in
bootstrap run `34687545590`, including `compare-bootstrap-outputs`. Its README,
site, and Push workflows also passed. These results verify this committed root
boundary, not the later assertion work or a self-hosting fixed point.

## Acceptance

- [x] Root reads and stores use declared locations, including later changed values.
- [x] Root scalar expressions and declarations share operand and emission owners.
- [x] Initial artifact, identity, retention, execution, and replay comparisons pass.
- [x] Later invalid names and unsupported shadowing preserve artifact publication.
- [x] Terminal frame/code and malformed scalar location publication checks pass.
- [x] Complete statement/type publication bounds preserve every inactive caller cell.
- [x] Affected ordinary, reversible, loop, call, and aggregate adapters remain verified.
- [x] Physical source bounds, archive/graph identities, locks, and packaged execution agree.
- [x] Documentation and hosted checks agree with the exact committed tree.

No status promotion follows from these focused checks. WIP-0507 and the intact
mixed-member runner remain open.
