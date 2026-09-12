# WIP-0506: Native source global products

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler, runtime, and bootstrap maintainers |
| Created | 2026-09-12 |
| Updated | 2026-09-12 |
| Area | Self-hosting, source state, global initialization, canonical artifacts |
| Depends on | WIP-0017, WIP-0045, WIP-0049, WIP-0051 |
| Supersedes | None |
| Superseded by | None |
| Follow-up | WIP-0507 |

## Failure

The archive source compiler dropped unused class state. The regression produced
496 bytes where independent stage 0 produced 544 bytes. The native artifact
omitted both global descriptors and their names. The source and its declarations
remain intact. The working implementation now produces the complete 544 bytes.

`CompiledGlobalProducts.w` already retains globals from artifacts. That decoder
cannot recover declarations which source emission discarded.
`SourceModuleProductArtifact.w` wrote a zero-global type prefix, and the
callable-free archive branch published before reading those declarations.
Both paths now consume source global products.

The physical compiler entry in `MinimalCompiler.w` has three states. The larger
mixed-member test in [WIP-0498](../WIP-0498-native-test-member-front-admission.md)
also retains state. Neither source can become a complete native product while
this boundary drops or rejects its state.

## Source products

A state declaration is `state long name = expression;`. It is not a constant
symbol. Initializers use the existing exact scalar evaluator and the complete
scoped constant packet from
[WIP-0045](../WIP-0045-counted-native-module-symbol-products.md).
Dependency source does not enter this boundary. Reading another mutable state
as an initializer is not constant evaluation.

`SourceGlobalProducts.w` uses shared member fronts to find declarations. It
publishes declaration-ordered columns for copied name start, copied name length,
signed initial value, and the declaration name's byte start in the module source.
[WIP-0512](WIP-0512-root-global-literal-assertions.md) adds that source coordinate
to preserve declaration-sensitive canonical assertion selection. The product type fixes the state type as
signed 64-bit. It does not encode Boolean or nominal state by pretending that
those values are signed words.

Names use source identifier rules and at most 256 copied ASCII bytes. UTF-8
comments do not change their byte coordinates. Global names remain unqualified
in a source-local artifact. Callable names occupy their existing separate
namespace. A method may share a global's spelling.

The native source window has eight globals, independent of the retained closure's
4,096-global table. Its four columns need `8 * 4` words. Copied names need at
most `8 * 256` bytes. Private value staging therefore needs
`8 * 4 * 8 + 8 * 256 = 2,304` bytes in two buffers.

The caller supplies three 4,096-token scratch columns. Another private window
holds the two module coordinates and two eight-row front columns, for
`2 + 8 * 2` words. The binder clears those selected scratch cells on return and
preserves their tails. A state-free module uses no additional owned buffer or
region. Constructing its result record is not a claim of zero allocation of
any kind.

The binder validates all fronts before allocating value staging. It resolves
all initializers and checks duplicate names and capacities before copying a
caller byte or product cell. Result-record allocation also precedes publication.
Caller prefixes and inactive tails survive success. Rejected later declarations
cannot publish earlier states. Checked arithmetic traps preserve publication,
but need not clear private scratch when the call cannot return.

## Artifact and instruction composition

The archive adapter retains the global window beside scalar constants. It does
not reduce mutable state to constant rows. `SourceModuleNameProducts.w` joins
class, callable, and global names. Its canonical mapping updates manifest,
callable, and global name IDs, including shared spellings.

`SourceGlobalSchema.w` owns the declaration columns and a fourth column of
canonical name IDs. `SourceGlobalSection.w` emits complete descriptors before
container verification. Each descriptor has a name ID, signed type, and both
initial-value words. Declaration order supplies the ordinal. The emitter does
not patch globals into an already verified zero-global artifact.

Source lowering must bind global reads and assignments from the same declared
ordinals. A state destination stays global. It cannot become a synthetic local
or a substituted initializer literal. Initializer products alone do not complete
read/write lowering, entry selection, or nominal composition.

The callable-free path retains state through the same name and descriptor
owners. It also rejects a claim without a callable subject. Both archive entry
points validate the complete scoped constant packet, even when no callable uses
it. No new owner relies on a dummy import for graph reachability.

Artifact storage remains 32,768 bytes and identities remain 32 bytes. The native
lifetime limit remains 65,535 buffers. Callable compilation reuses three private
4,096-word columns for scanning and keeps its 17 metadata buffers. Name ordering
needs four 256-row columns, followed by `8 * (4 + 1) = 40` global publication
cells. The declaration-coordinate extension adds `8 * 8 = 64` bytes to the
original metadata arena, giving `1,029,888 + 64 = 1,029,952` bytes.

Callable-free compilation needs a source copy, three scanner columns, and name
products which its old empty facade did not read. Its calculated arena holds
`278,785 + 64 = 278,849` bytes and 14 buffers. State-bearing binding temporarily
adds 2,304 bytes in two buffers. State-free binding itself still adds no owned storage. These
per-call budgets do not establish full-closure lifetime headroom.

[WIP-0499](../WIP-0499-native-global-call-assignments.md) covers the bounded scalar
helper path. Its existing one-global call assignment is not a substitute for
these counted products. Do not extend that parser to conceal the source-product
gap.

## Evidence and remaining implementation

The working-tree regression
`retainsUnusedStatesAndTheirScopedConstantInitializers` passes complete artifact
comparison. It preserves both declarations, including a signed endpoint and a
qualified imported initializer. Further artifact checks combine globals with
proof names which reorder or share strings.

The current binder has focused source-oracle, preservation, and replay tests.
They cover declaration order, signed endpoints, local and imported constants,
method/state name sharing, Unicode offsets, interleaved nominal fronts, malformed
later members, duplicate names, state reads in initializers, and arithmetic traps.
The terminal eight maximum-width names and first-excess cases run history-free.
A separate snapshot check proves that absence consumes no new owned buffers or
regions.

`SourceModuleStrings.w` now orders raw name directories and returns old-to-new
IDs. Its tests cover shared spellings, UTF-8 byte order, prefixes, full directory
and byte windows, first-excess windows, and rejected later ranges. Module names,
global names, and proof names use the same `SourceStringRanges.w` comparator.
The existing proof publisher tests still pass after removal of its private
comparison implementation.

The directory uses stable bottom-up merge sorting. At most 256 rows require at
most eight merge passes, rather than repeatedly comparing every qualified name
against the whole table. Four scratch columns retain the original-to-final IDs,
sorted starts and lengths, and stable original indices. Sorting adds no owned
buffer.

The focused publication run passed 80 example methods and 25 source checks.
It includes both callable-free entry paths, signed endpoints, local constant
initializers, shared class/global names, eight globals, and rejected later
states and claims. Section tests check complete bytes, input preservation,
publication tails, signed words, invalid windows and names, and full driver
rewind/replay. Large name capacities explicitly run history-free.

A later adapter run passed 144 examples. The archive regression also checks the
complete native SHA-256 output and every inactive artifact byte before cleanup.
Its emitted global-bearing artifacts enter `appendCompiledGlobalProducts` in a
second VM. Independent names and values determine all five retained columns.
The test checks every prefix and tail cell and replays the complete intake phase.
It does not claim whole-compiler replay.

Archive intake and both selected physical closure methods passed in 9 minutes
53 seconds. The archive binds 470 modules, 2,316 constants, and 1,868 callables.
Independent repacking agrees with the 2,235-import, 217,379-byte manifest. Its
native graph and SHA executions take 77,407,846 and 41,602,098 transitions. The
selected 603,784-byte linked reference remains unchanged. These are archive and
selected-body checks, not compilation of every physical body.

Proposal indexing now walks nested contracts and retains their relative paths.
A nested duplicate-ID regression protects catalog, roadmap, and dependency
coverage. The previous directory-only scan omitted both contracts in this split.

The 181-target workspace check and build pass. Four dependent locks use the
independently repacked compiler. A separately resolved and vendored consumer
publishes globals and a shared-name step claim in 1,461,972 transitions. Its
complete 632-byte artifact matches independent stage 0. Executing that artifact
preserves all three initial values, including both signed endpoints. The
compiler archive identity is
`8129bbecfd2bcc8512ceb5e2d1e5ac35d886b46d524e966d3ed6fc664d3a9777`.

Global read/write instruction binding remains open in
[WIP-0507](WIP-0507-native-source-global-access-products.md). Entry and nominal
composition remain open in their parent contracts. These checks do not establish
a compiler fixed point or advance the intact mixed-member runner through its
remaining dispatcher.

## Acceptance

- [x] Shared fronts and scoped scalar products bind declaration-ordered initial values.
- [x] Complete output preservation and accepted, rejected, and trapped replay are checked.
- [x] Terminal name/global capacities and absence without new owned storage are checked.
- [x] Complete name directories and manifest/function/global IDs remain canonical in tested sources.
- [x] Callable and callable-free sources retain every admitted declared global.
- [x] Tested primitive artifacts, initialization, identities, and retained global rows match independent oracles.
- [x] Invalid later declarations, descriptor rows, names, and proof limits preserve publication.
- [x] Archive intake, selected physical evidence, packages, locks, and final documentation agree.

WIP-0507 retains the access and instruction-rejection requirements from this
split. The original mixed-member fixture must still advance through the real
source-product dispatcher under WIP-0498. Neither requirement disappears when
declaration retention passes.

This task does not by itself complete
[WIP-0049](../WIP-0049-bounded-native-source-product-compilation.md), full physical
compiler compilation, or a compiler fixed point. Maintainers retain status
approval.
