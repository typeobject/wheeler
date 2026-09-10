# WIP-0054: Native source-product artifact integration

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler compiler, bytecode, linker, and bootstrap maintainers |
| Created | 2026-08-13 |
| Updated | 2026-09-09 |
| Area | Self-hosting compiler, source products, artifact emission, bootstrap closure |
| Depends on | WIP-0045, WIP-0046, WIP-0047, WIP-0048, WIP-0049, WIP-0050, WIP-0051, WIP-0052, WIP-0055, WIP-0056, WIP-0057, WIP-0067 |
| Supersedes | WIP-0052 physical-closure adoption tasks |
| Superseded by | None |

## Boundary

Connect validated declaration, aggregate, callable, statement, loop, relocation,
ownership, and type products directly to canonical artifact emission. Compile
`CoreParsing.w` first, then every physical compiler module. Do not feed projected
source back through the bounded scalar-helper parser.

WIP-0052 supplies structured-loop products. This WIP owns their composition with
the other semantic products and their adoption by the complete compiler. Selected
owners, independently assembled products, and source projections are not that
completion gate. The [status map](self-hosting-status.md) owns current inventories
and same-commit acceptance evidence.

## Current implementation

`StructuredSourceModuleCompiler.w` joins admitted scalar bodies, closed symbols,
signatures, calls, direct statements, loops, types, strings, and proofs. Its
archive adapter freezes only the selected source range and consumes packed
imported names rather than dependency source. `CoreParsing.w` already takes this
route and matches stage 0. Its historical 3,208-byte artifact is the first
integration milestone, not a remaining parser failure.

`compileSourceModuleProductWithImports` still projects other sources, writes
callable stubs, and invokes `compileMinimalCore`. That path remains until those
owners have complete direct lowering. Extending its scalar-helper parser for each
missing product would create a second frontend rather than finish this one.

The nominal path is also incomplete. `AggregateCompiledCallableBodies.w` returns
a primitive artifact plus supplemental instruction products. Its dedicated test
explicitly expects no record or variant descriptors in that primitive artifact.
Calling that helper from the test runner does not assemble a nominal executable.
Source-derived result types, complete frames and instructions, globals, entry,
proofs, strings, and relocations must reach final emission together.

The existing aggregate fixture also uses direct variant-field syntax rejected by
stage 0. It tests those bounded products, not full source-profile parity. Keep
that distinction when adding independent accepted-source fixtures. Do not replace
the intact mixed-member runner case with a primitive control or a projected body.

### Closed result types

The structured compiler consumes local-order result products rather than
rescanning source signatures. The archive adapter copies the selected global
callable rows into a 64-word result table. Calls, direct statements, return
planning, frame composition, and artifact emission use those types. A zero result
means declared `void`, not permission to infer a value result from the body.
Direct products may still infer results for their separate standalone API, but
composition rejects any change to the closed signature before publication.

`SourceCallableResultProducts.w`, its backward signature walk, and its scanner
arena are deleted. The archive adapter adds 512 bytes for retained local results.
The retired pass allocated 98,832 bytes across four buffers and rescanned the
complete source. No parser fallback or compatibility overload replaces it.

`NativeCompilerRetainedResultExampleTest` first demonstrated that changing a
closed signed result to void or Boolean still published a signed artifact. Both
cases now reject. Positive tests compare complete artifacts, SHA-256 identities,
caller input and metadata, and all output tails. They cover each admitted result
kind and the last global callable and parameter rows. Direct preflight checks
short and excess backing, the last consumed result, and callable-count excess
without allocating compiler scratch. These are separate boundary fixtures, not
maximum simultaneous artifact occupancy.

One case retains and rewinds compilation and cleanup after discarding preparation
history. Other archive cases are history-free. Each synthetic library entry also
executes and rewinds independently. That entry check does not execute the authored
helper. Existing byte, comparison, call, reversible, storage-loan, and CoreParsing
fixtures check the migrated composition. Nominal results and the complete driver
join remain open.

### Codec source product

`compiler/verification/Codec.w` is outside the rooted compiler target. Its source
now names the output capacity and exclusive bound as scalar declarations. This
keeps the same capacity check in the existing direct products. It does not add
nested intrinsic expressions to the assertion grammar. The original expression
failed value-product admission before any artifact was published.

`NativeCompilerCodecSourceProductExampleTest` compiles the complete physical file
against closed verifier signature products, without lending dependency source to
the native compiler. An independently compiled library supplies the expected
codec body, complete frame, and result. Only function IDs are normalized. That
body, a typed import stub, and an inert entry form the independent source-local
artifact oracle. The complete 1,808-byte artifact, SHA-256 identity, relocation,
and every caller byte and cell match, including publication tails.

The test then relocates the actual emitted body into an independently compiled
verifier and entry wrapper. It executes the codec, not merely the inert entry.
Exact and spare capacity preserve the complete input. Empty input, damaged magic,
invalid code, and short output reject before changing caller storage. All those
execution paths rewind. Compilation itself is history-free. Four intended
mutations expose an exclusive capacity bound, excess admission, missing
verification, and a lost return length.

This is one complete source-local product and mixed-dependency execution. It is
not native compilation of the verifier closure or the whole package library.
Those products and stage equality remain required.

### Library facade source product

`NativeCompilerLibraryFacadeExampleTest` passes the unmodified physical
`CompilerLibrary.w` to the callable-free archive compiler. The input retains all
six imports, but contains no dependency source. The closed local callable window
is empty. The facade owns no imported call instruction, so no imported target or
relocation workspace is needed.

The independent stage-0 library contains the dependency closure. The test takes
only its synthetic entry and program name to construct the source-local oracle.
It compares the complete native artifact, SHA-256, function and relocation counts,
all caller metadata, and every output byte, including unused publication storage.
It does not compare that small local artifact to the complete linked library.

Compilation starts at an empty history boundary after private fixture preparation.
Publication and cleanup rewind to that boundary, then replay to the same complete
snapshot. The emitted entry independently executes and rewinds. Short and excess
artifact and identity buffers, and a class name outside the selected source range,
reject without changing caller storage. Neither the source profile nor its bounds
change. No physical source, package archive, graph identity, or lock changes.

This covers the facade's empty local product. It does not compile its imported
bodies, place the facade in the retained physical container, or complete the native
library closure. Every remaining physical owner and final composition still need
their own evidence.

## Inputs and ownership

A source-local artifact is a pure function of:

1. package and immutable module-source identity
2. validated local declarations and aggregate layouts
3. callable signatures, effects, parameter loans, and body extents
4. structured statement and loop products
5. stable local and imported call relocations
6. aggregate operands and ownership products
7. canonical strings, proofs, limits, and manifest products
8. exact ordered direct-dependency product identities

Dependency source, host objects, parser retries, filesystem order, and numeric
pre-link target IDs are not inputs.

| Boundary | Owner |
| --- | --- |
| Callable-to-root-block ownership and coverage | `CallableBlockPlans.w` |
| Source-ordered direct and loop instruction windows | `CallableInstructionPlans.w`, `CallableSourceComposition.w` |
| Logical values to physical frame and scratch windows | WIP-0055, WIP-0056, WIP-0067 |
| Contiguous typed local windows | `CallableLocalTypePlans.w`, `CallableSourceComposition.w` |
| Calls, aggregate operands, proofs, and ownership identities | `CallableProductIdentityPlans.w`, WIP-0057 |
| Closed manifest facts and shared manifest encoding | `LinkedManifestSection.w` |
| Source-local sections, verification, identity, and publication | `SourceModuleProductArtifact.w`, `SourceProductArtifact.w` |
| Final IDs, complete semantic sections, and container publication | WIP-0048 |

Each callable owns exactly one root block. Validate lexical ownership, source
order, result shape, forward and inverse extents, parameter locals, and the whole
local-type suffix. Empty library entry synthesis is one explicit module-level
rule, not a fabricated source callable.

Branches and back edges retain callable-local instruction ordinals until emission.
Enclosing parameters and locals keep their coordinates. Calls retain stable
relocation identities and aggregate operands retain owner/type identities.
Only WIP-0048 assigns final closure IDs.

## Emission and failure

Feed counted globals, aggregates, functions, local types, code, proofs, strings,
and a closed `ModuleManifestProduct` to the canonical section emitters. The result must match stage 0 byte for byte for
the shared source profile. Both the independent reader and native verifier accept
it before `CompiledBodyArchive.w` retains it.

Validate every window and count before publication. Private section storage is
not public artifact storage. `CanonicalProductEmitter.w` measures the complete
aligned container before allocating its artifact buffer, verifies private bytes,
and only then copies them to caller output. It allocates the measured extent,
not the backing output capacity. Malformed sections and insufficient capacity
reject before artifact allocation. Semantic failures leave every caller byte
unchanged, not merely its unpublished length.

Reject detached, overlapping, reused, or over-nested blocks. Reject statements
without one callable and block owner, unresolved or mistyped operands, invalid
loop limits, ambiguous call targets, missing aggregate identities, and mismatched
ownership across branches, returns, or back edges. Noncontiguous code or types,
escaping branches or relocations, and invalid sections also reject. Failure
changes no caller artifact, identity, relocation, or archive count. Do not retry
through another parser.

## Bounds

Current boundaries remain independent:

| Boundary | Limit |
| --- | --- |
| Source statements in one callable block | 64 |
| Nested structured blocks | Four |
| Source-local callable products | 64 |
| Ordinary retained call arguments | 64 ordered identifiers, WIP-0502 |
| Separate scalar-helper call arguments | Seven |
| Retained frame locals | 256, indexed `0..255` |
| Indexed source-local artifact functions | 64, including any synthesized entry |
| Indexed source-local artifact instructions | 4,096 |
| Call-local type pool | 4,096 |
| Source bytes and semantic tokens | 32,768 bytes and 4,096 tokens |
| Source-local retained artifact | 32,768 bytes |
| Immutable physical product archive | 16 MiB |
| Final canonical container | 16 MiB, WIP-0048 |

A value-returning frame may serialize 257 type words: one result plus 256 locals.
That prefix is not a frame local. The closure type pool has its own 1,048,576-word
bound. The bytecode format's wider coordinates do not widen these retained tables.
Individual boundary tests do not prove simultaneous source, frame, function,
code, type-pool, and artifact occupancy. Check each bound before the operation it
protects. Expansion needs measured evidence and a separate patch.

## Verified milestones

- [x] WIP-0045 through WIP-0048 supply counted identities, layouts, callable windows,
  final IDs, and canonical section emission.
- [x] WIP-0050 and WIP-0051 supply bounded aggregate source and frontend products.
- [x] WIP-0052, WIP-0055, WIP-0056, and WIP-0067 compose structured loops with exact
  source order, physical locals, scratch windows, and ownership checks.
- [x] `CoreParsing.w` matches stage 0 and enters the physical body archive.
- [x] `ManifestSyntax.w`, `AggregateSourceProjection.w`, and selected later owners
  use direct products. Their individual adoption WIPs own historical artifacts.
- [x] WIP-0068 sends callable-free sources directly to artifact emission without
  parser projection or structured-product allocation.
- [x] WIP-0057 carries call relocations and ownership through composed windows.
- [x] WIP-0502 through WIP-0504 cover retained arity, storage loans, complete call
  windows, and the shared 256-local frame boundary.
- [x] WIP-0505 separates carrier frame coordinates from serialized result prefixes.
- [x] Retained source-local emission and final linking share a manifest product and
  encoder. Final section emission no longer rereads a root artifact for these facts.

These are scoped milestones. The former blanket check for every physical
multi-statement-loop module was not a complete-closure acceptance result. The
remaining checklist below preserves that requirement.

## Remaining migration and acceptance

- [ ] Every physical multi-statement-loop module compiles without dependency source.
- [ ] Aggregate and call-heavy modules use the same direct composition interface.
- [ ] Complete nominal source artifacts preserve results, frames, instructions,
  globals, entry, proofs, strings, and relocations together.
- [ ] The intact mixed-member native runner executes its original selected body.
- [ ] Combined resource checks cover synthesized entries as well as source callables.
- [ ] Every physical compiler module publishes one product-built artifact matching
  stage 0, with complete negative, boundary, publication, and execution checks.
- [ ] Product-to-source projection, imported signature-stub source, and scalar-loop
  retry leave the production closure path. Retain a recovery parser only while an
  accepted recovery seed names it.
- [ ] The complete physical compiler artifact verifies independently and recompiles
  its source to byte-identical stage 2.

Do not replace loops with recursion: that changes frames and tested steps. Do not
flatten dependency sources: that loses owner, visibility, relocation, and source
lifetime boundaries. Do not link numeric targets early: closure order is not a
source semantic. None of those shortcuts supplies the missing products.
