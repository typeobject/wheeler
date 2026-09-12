# WIP-0507: Native source global access products

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler, runtime, and bootstrap maintainers |
| Created | 2026-09-12 |
| Updated | 2026-09-12 |
| Area | Self-hosting, scalar binding, state reads and writes |
| Depends on | WIP-0049, WIP-0051, WIP-0054, WIP-0506 |
| Supersedes | None |
| Superseded by | None |

## Boundary

[WIP-0506](WIP-0506-native-source-global-products.md) retains signed global
initializers and publishes their descriptors. That work does not bind a state
read in a callable body or an assignment destination. An unused state can now
survive source compilation while the same state still prevents compilation when
a body uses it.

The intact mixed-member test in
[WIP-0498](../WIP-0498-native-test-member-front-admission.md) assigns a helper
result to `observed` and then compares that state with `BASE`. Its state cannot
become a synthetic local or a substituted initializer. The three states in
`MinimalCompiler.w` expose the same missing boundary in a physical compiler
owner.

This task implements access products. Entry selection and nominal composition
remain separate joins. Replacing the test-runner dispatcher with another minimal
parser family is not an implementation of any of them.

## Binding

The input is the complete declaration-ordered global window and copied names.
Use the same ordinals that the source type section emits. The native window has
eight signed globals, not eight new globals per function. Globals do not consume
local declaration identities.

Extend the existing source value and operand binding owners. Local and parameter
scope must take precedence according to the source profile. Reject an unsupported
shadowing form explicitly. Do not guess that an unresolved local is global, and
do not add another constant resolver.

A read creates a signed value at that program point. Later stores change later
reads. The global's initial value is not an immutable replacement for either.
A write consumes an already bound signed operand. Counted helper results use the
existing call result and ownership products before the store.

The products must retain function, statement, and direction coordinates before
instruction emission. Primitive and supplemental ordinals remain distinct.
No relocation may select a global by its final string-table position. Sorting
names does not reorder the declaration window.

## Emission and verification

Use `OPCODE_LOCAL_LOAD_GLOBAL` and `OPCODE_LOCAL_STORE_GLOBAL` from `Opcodes.w`.
`InstructionForms.w` owns their operand counts. The verifier owns their local,
global, and type constraints. Do not duplicate numeric opcodes or infer operand
roles from an unrelated assignment family.

Compose global instructions before final-container verification and hashing.
The type section already contains the declared globals. Retained global rows and
canonical linking must preserve both their values and instruction references
after the source lease ends.

Validate the complete batch before publishing caller products, code, relocation
rows, artifacts, or identities. A bad later destination must not publish an
earlier valid read. Private staging may change during rejection.

Ordinary signed access comes first. Reversible accesses require the existing
reversibility and inverse-coordinate checks. Do not manufacture an inverse by
replacing a stored value with its initializer. Unsupported effects must reject,
not silently become ordinary calls.

## Bounds

Derive storage from the eight-global window, source statement/value capacities,
column counts, and native word width. A global read may need a local result slot,
but cannot reset or evade the function's 256-local bound. Reuse scanner and
binding scratch at disjoint phases rather than consuming new lifetime buffer
IDs for absent accesses.

`StructuredSourceModuleCompiler.w` currently has 960 lines and 4,052 raw tokens.
Its scanner admits 4,096 tokens including comments. Extract coherent binding or
composition owners before extending that near-limit function. Do not widen the
scanner or delete useful documentation to make it fit.

## Required evidence

- Multiple globals retain declaration order even when names sort differently.
- Reads observe signed endpoints and intervening writes, not cached initial values.
- Parameter, local, constant, and state names follow one scope policy.
- Literals, local operands, and counted helper results reach the right state.
- Later invalid names, types, coordinates, destinations, and limits preserve publication.
- Complete artifacts and execution agree with independent source and instruction oracles.
- Representative accepted and rejected paths retain real rewind/replay evidence.
- Source-independent retention and linking preserve global references and values.
- Physical compiler owners advance without projected-away state or erased members.
- The original mixed-member test remains intact while the real counted dispatcher advances.

## Root scalar work

[WIP-0509](WIP-0509-root-scalar-global-locations.md) owns the first root scalar
join. The original archive regressions failed the direct statement plan's
failure-coordinate assertion. They now pass complete independent artifact and
callable execution comparisons through the root product path. Twelve additional bodies
exercise real loads, stores, arithmetic, comparisons, and local declarations.
The source declarations and failing statements remain intact.

Stage 0 also mistook uppercase assignment destinations for nominal declarations.
The assignment front now checks punctuation before selecting that branch. The
original uppercase store passes alongside dedicated front regressions.

This is not the complete access contract. Global conditions and assertions,
helper-result stores, nested accesses, entry/nominal composition, source-independent
instruction relocation, and physical-owner advancement still need their joins
and acceptance evidence. WIP-0509 records the completed root boundary and local
package checks separately from hosted verification. The bounded one-global helper assignment in
[WIP-0499](../WIP-0499-native-global-call-assignments.md) does not discharge those
requirements. Full physical compilation and compiler fixed-point acceptance
remain open in the parent contracts.
