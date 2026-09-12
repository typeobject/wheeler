# WIP-0049: Bounded native source-product compilation

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler compiler, module-product, aggregate, ownership, and bootstrap maintainers |
| Created | 2026-08-09 |
| Updated | 2026-09-12 |
| Area | Self-hosting, source lowering, module products, aggregate products, bootstrap |
| Depends on | WIP-0013, WIP-0028, WIP-0044, WIP-0045, WIP-0046, WIP-0047, WIP-0048 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler compiles each scheduled source-local module from its own source, resolved scalar products, imported callable signatures, and nominal aggregate products. It does not read dependency source. The temporary compile artifact is canonical `.wbc`. Wheeler places synthetic signature stubs in a checked suffix and excludes them from the retained local function window.

This proposal owns the missing lowering boundary between counted semantic products and WIP-0047 body products. WIP-0050 owns aggregate-aware parsing, descriptor construction, ownership projection, and temporary nominal declarations. WIP-0048 remains the owner of closure-wide IDs and final container emission.

## Motivation

The native compiler can publish symbols, signatures, aggregate layouts, identities, ownership events, and final sections. Those products do not by themselves compile the complete physical compiler. The current native core accepts a bounded primitive source profile. Imported primitive calls now type-check against signature-only recursive stubs, but local aggregate declarations and imported nominal types still exceed that profile.

Copying a dependency class into the local source would make the test pass and the architecture fail. It would restore source flattening under a shorter name, make private declarations observable, and bind body identity to irrelevant dependency text.

The source-product compiler needs one explicit rule: local source may be read while its work-slot lease is live. Dependency source may not. Everything crossing an edge is a counted product.

## Goals

- Compile a complete source-local class rather than isolated callable fragments.
- Substitute resolved scalar products without copying declarations.
- Compile imported calls from exact signature products.
- Lower local record, variant, fixed-array, and slice declarations.
- Materialize imported nominal descriptors from WIP-0046 products, not source.
- Preserve ownership, loan modes, effects, result slots, proofs, and exact diagnostics.
- Publish only local functions, instructions, types, globals, proofs, and identities.
- Keep every phase bounded, deterministic, and independent of allocation addresses.
- Compile all physical compiler modules before bootstrap promotion.

## Non-goals

- Define final function, string, aggregate, or proof IDs. WIP-0048 owns them.
- Introduce another semantic IR. Canonical `.wbc` 1.0 remains authoritative.
- Execute synthetic stubs.
- Admit unknown opcodes, unresolved calls, or opaque aggregate descriptors.
- Keep generated source, temporary artifacts, or work-slot storage after publication.
- Change the public source language merely to simplify bootstrap compilation.

## Product boundary

One module compilation consumes:

- the leased local source range and its stable module identity.
- local scalar, callable, aggregate, and ownership products.
- ordered direct dependency ranks.
- public imported scalar values and callable signatures.
- imported aggregate module identities and layouts.
- fixed compiler options and recovery limits.

It publishes:

- one canonical source-local `.wbc` product artifact.
- the retained local function and instruction prefix.
- local string, global, aggregate, proof, relocation, and ownership rows.
- stable callable body and aggregate identities.
- exact diagnostic identity on failure.

The publication does not retain dependency source ranges. A caller may archive the validated artifact under `CompiledBodyArchive.w` and release the source lease.

## Signature-only call compilation

This section defines the initial bounded route. The retained direct structured
route now consumes resolved callable products without generated signature source.
WIP-0054 tracks removal of projection and signature-source scaffolding from the
complete production path. Neither route may retain a synthetic callable in final
output.

An imported callable body is not needed to type-check a call. The compiler appends one deterministic temporary function per resolved imported signature. A nonreversible value stub calls itself with its own parameters and returns that call. A void stub calls itself and falls through. These bodies are valid typed bytecode and are never executed.

Stub order follows callable-product order. Duplicate exact signatures fail before generation. The compile result reports the synthetic suffix. `retainLocalFunctionProduct` requires all local instructions to precede every synthetic instruction and excludes both stubs and a compiler-added inert entry.

Qualified and overloaded calls shall be rewritten to deterministic private stub names from resolved call rows. The written dependency rank and stable signature identity remain relocation authority. Source spelling is not final identity.

## Nominal lowering

Local aggregate declarations are parsed and lowered by the native compiler core. Imported nominal types use generated private declarations derived from WIP-0046 products. Generation uses stable product order and synthetic names that cannot collide with source identifiers.

Generated descriptors preserve:

- aggregate kind and source-local descriptor identity.
- ordered record fields.
- ordered variant cases and payload fields.
- fixed-array element type and length.
- slice element type and loan restrictions.
- recursive record and variant edges.
- owner module identity for every nominal reference.

The generated declaration is compile-time scaffolding. Final emission resolves its descriptor through `AggregateDescriptorRows.w`. No synthetic name or temporary descriptor ID survives.

## Ownership and loans

Temporary stubs do not transfer ownership at runtime because final code cannot target them. Their signatures still undergo ordinary type and loan checking.

Local body publication maps each owner-bearing local to a local or imported aggregate projection. Moves, drops, shared loans, mutable loans, and function-boundary releases must agree with instruction-derived ownership products. A projection mismatch invalidates the body before artifact archival or identity publication.

## Ordering and determinism

For one module:

1. validate the leased local source and product windows.
2. substitute scalar products.
3. generate imported nominal declarations in dependency-product order.
4. generate callable stubs in signature-product order.
5. compile and verify the temporary canonical artifact.
6. resolve local, imported, and aggregate relocations by stable identity.
7. exclude every synthetic function and instruction.
8. publish local products atomically.
9. archive the artifact and release the source lease.

Archive entry order, source arrival order, allocation addresses, hash-table probes, and work-slot reuse do not affect bytes or identities.

## Limits

The recovery profile keeps the accepted bounds:

- 512 local modules and 64 direct dependencies.
- 64 local callables and 64 parameters per callable.
- 256 locals per function.
- 4,096 source-local instructions.
- 64 source-local aggregate descriptors.
- 128 source-local variant cases.
- 256 source-local aggregate members.
- 32,768 generated source bytes.
- 32,768 source-local product artifact bytes.
- 16 MiB closure artifact archive.

Generated declarations and stubs count against the source and temporary function limits. They do not increase retained closure counts.

### Complete frame admission

The wide-call fixture exposed two checks that stopped before the existing
256-local boundary. `SourceValueProducts.w` compared the final local count with
255, although its statement checks allowed 256. `CallableSourceComposition.w`
then needed a 257th loop iteration to find the empty slot after a full frame.

Both owners now use an explicit 256-local window. Type composition stops after
the last slot and still requires every input type row to be consumed. A 64-argument
void call after 32 signed declarations fills all 256 locals. Adding one Boolean
assertion needs local 257 and rejects before artifact publication. The complete
admitted artifact matches stage 0. A separate type-composition fixture fills all
four input pools, rejects an unconsumed local 256, gaps, and duplicate origins,
and checks every output cell. Small accepted and rejected compositions rewind.
This corrects frame admission, not the separate call-arity contract in [WIP-0502](WIP-0502-sixty-four-argument-retained-source-calls.md).

WIP-0504's eight-kind mixed signature exposed a separate parameter scan using
256 iterations for tokens rather than locals. Its 64 parameters need more than
256 tokens. The scan now uses the existing 4,096-token bound. Argument and frame
limits do not change. Complete 64-argument artifacts cover all eight scalar/loan
kinds, and restoring the old scan bound fails that fixture.

## Failure behavior

The compiler traps before product publication for:

- missing, private, ambiguous, or mismatched imported signatures.
- qualified calls whose dependency rank does not match the selected product.
- missing or duplicate aggregate products.
- generated-name collision.
- recursive descriptor kinds outside the accepted record and variant graph.
- escaping loans or ownership mismatch.
- a local instruction after the synthetic suffix begins.
- a synthetic target left in retained code.
- any source, function, instruction, aggregate, or artifact limit breach.

Scratch source and temporary artifacts have no identity. Failed compilation leaves no counts, bytes, artifact rank, or body identity published.

## Recovery consequences

Source-product compilation does not set the bootstrap bit. Promotion still requires complete physical closure compilation, byte-identical stage 2, diverse double compilation, and provenance evidence. No `wheeler.bootstrap.yaml` may be checked in before those facts exist.

## Implementation status

- [x] `ProductRootSource.w` substitutes imported scalar products without dependency source. Its physical-module path retains the canonical module declaration while removing product-only imports.
- [x] `ImportedCallableStubs.w` generates deterministic primitive signature stubs.
- [x] `compileSourceModuleProductWithImports` compiles one complete primitive local class from local source and imported products.
- [x] `compileCallableModuleProductWithImports` compiles counted primitive callable ranges.
- [x] Borrowed intrinsic results can feed later typed comparison values. Scalar helper validation now admits every declaration with a concrete result local instead of maintaining a second incomplete declaration whitelist.
- [x] `retainLocalFunctionProduct` excludes stub and compiler-added function suffixes.
- [x] Imported call ranges, including qualified spelling, rewrite to `__wheeler_import_<product-row>` stub names. Any local use of the reserved prefix fails before output mutation.
- [x] `SourceCallProducts.w` resolves unqualified direct dependency calls against packed callable rows and copied WIP-0045 name products. Local shadowing and complete ambiguity validation precede call-row publication. Dependency source is not an argument.
- [x] `CallableTypeProducts.w` resolves primitive source ranges while local source is leased. Closure publication retains every complete primitive signature while explicitly marking nominal peers unavailable. Stub generation consumes only type codes, loan modes, effect masks, and parameter windows. Its API has no dependency-source argument.
- [x] WIP-0050 starts aggregate-aware lowering with atomic record, variant, case, and member products, including mutually recursive local nominal types and deduplicated scalar fixed arrays. Descriptor-compatible rows and copied immutable source-string products now cross the source-release boundary without a temporary artifact.
- [x] Complete primitive bodies compile after validated local aggregate declarations are blanked at stable source offsets.
- [x] `compileAggregateSourceModuleProductWithImports` compiles primitive body portions after local-declaration projection and imported nominal validation. Temporary signed carriers and generated descriptors do not enter the retained artifact. Nominal and exact function-local carrier projections publish only after compilation succeeds.
- [x] WIP-0050 completes local aggregate declaration and instruction lowering.
- [x] Imported nominal names resolve from public WIP-0046 rows and counted artifact-string products without dependency source.
- [x] Imported nominal record and variant compile declarations generate in target-row order and publish owner-scoped temporary source-code projections.
- [x] Resolved imported nominal ranges rewrite after imported calls. Call-name width changes adjust later type ranges without moving or rereading dependency source.
- [x] Counted aggregate archival validates retained descriptor ranges, then removes exact generated aggregate, case, and member suffixes before closure publication.
- [x] Instruction-local create, move, loan, release, and drop owner rows map atomically to aggregate and member projections.
- [x] Final callable local types consume validated temporary nominal projections and exact function-local carrier projections. Aggregate construction operands consume stable aggregate projections.
- [x] Proof and result-slot products compile through the counted path. `ProofRules.w` is retained as its physical semantic owner, `ResultSlotVerifier.w` compiles byte for byte without dependency source, and linked proof rows share the verified product container.
- [x] WIP-0052 publishes bounded multi-statement block and loop products. Physical loops remain source control flow and are not rewritten as recursion. Physical adoption remains tracked by WIP-0052.
- [ ] Every physical compiler module publishes one source-local product artifact.
  The selected set uses direct structured products for callable bodies and canonical
  empty products for callable-free owners. Imported calls resolve from copied names,
  frozen signatures, and packed dependency rows rather than dependency source.
  Exact local prefixes exclude synthetic functions. The current retained boundary
  and evidence live in the [status map](self-hosting-status.md).

The direct path preserves source-order local coordinates, typed buffer operations,
bounded loop and guard products, call relocations, result slots, generated inverses,
and proof products within the admitted profile. Publication uses measured prefixes
rather than clearing or copying full capacities. The
[compiler catalog](catalog/compiler.md) records those decisions, and the
[manifest catalog](catalog/manifests.md) records the latest physical adoption work.

- [ ] WIP-0048 emits the complete physical compiler closure from those products.

### Source-word admission

[WIP-0497](WIP-0497-exact-source-word-admission.md) replaces token hashes with exact
word codes across compiler and native test-source consumers. The shared
vocabulary has 58 spellings. Sentinel-prefixed ASCII lanes retain length and
order without collisions. Unknown words return zero, and the thirteen-byte word
bound does not shorten identifiers or source leases.

The consolidated pass compares complete Boolean and long-word artifacts and all
short-word and range-classifier bodies after two imported calls resolve.
Declaration tests reject all six reproduced keyword aliases before any name
publication. The scalar pass now consumes every leading state declaration and
rejects unindexed fields instead of silently ending the constant prefix.

Closure classification reuses one token arena across all source leases. The
512-module fixture consumes 524 buffer identities, including host buffers and
caller columns. First and later header failures leave every caller owner cell
unchanged. The scanner, live-byte budget, and lifetime buffer limit do not grow.

[WIP-0498](WIP-0498-native-test-member-front-admission.md) remains open. Automatic
discovery can still ignore a malformed member front and publish a zero-test
report. Exact word classification and explicit-descriptor rejection do not close
that grammar boundary.

### Source classical claims

`SourceClassicalProofs.w` binds `inverse` and `steps` declarations through shared
member fronts. A value binding or method named `theorem` is not a declaration
marker. Every supplied ordinary or `rev` callable must match its source name and
effect. Qualified callable names must name the source module, not a foreign owner
with the same local spelling.

The source-local table has 64 rows and five columns. They carry copied name
start, name length, shared rule code, local callable subject, and signed argument.
Names occupy at most 256 bytes each. Storage follows those capacities and column
counts. Arguments retain all 64 bits. Inverse claims carry `-1`, while step claims
require a positive signed constant expression. Counted constants supply names,
qualifiers, types, and values without reopening dependency source.

The whole batch is staged before publication. Duplicate proof names, unknown or
stale subjects, mismatched effects, circuit rules, invalid bounds, and first-excess
capacities leave caller tables and copied-name storage unchanged. Repeated
subjects with distinct proof names are valid. The 57-case source binding suite
compares complete tables and tails, including 64 maximum-width names, empty
callable windows, and invalid counted windows. Ordinary
cases cover accepted and rejected rewind and replay. The combined capacity case
uses explicitly history-free execution.

The generated-inverse adapter applies coverage policy rather than parsing
theorem syntax. Its one-inverse-per-callable rule remains separate from general
claim binding. Ordinary structured compilation previously rejected all claims
after an earlier path silently dropped a valid step claim. The shared coverage
owner now connects ordinary binding to artifact publication as described below.
The intact mixed-member runner join remains open under WIP-0498.

The ordinary path proves claim absence through the same member fronts. It reuses
three empty 4,096-cell product columns and the module-name pair in an existing
private callable column. The scanner clears these cells before product lowering,
including ordinary rejection. Twelve cases check every cell, the untouched
module-column tail, unchanged region and buffer counts, cleanup, and full rewind
and replay. This scan allocates no buffers. The first integration allocated a
fresh proof-binding workspace for every ordinary module and exhausted the
65,535-buffer lifetime bound. That limit has not been raised.

The next archive pass caught 4,173 raw tokens in the structured compiler owner.
Result validation moved to the target owner, and coverage storage was separated
from the structured compiler. That repair admitted the structured owner in
4,038 raw tokens without changing the 4,096-token scanner window. Physical
front checks cover that owner, both proof owners, and CoreParsing with comment
and header-whitespace variations. They do not establish native compilation of
those owners' bodies.

### Classical artifact publication

`ClassicalSourceProductArtifact.w` replaces the inverse-only publisher. It
consumes a verified six-section forward artifact and the shared five-column
source claims. It can preserve existing inverse windows or compose generated
inverses for a homogeneous reversible callable set. No dependency source enters
this boundary.

`SourceProofStrings.w` builds one canonical string union. A proof name can reuse
a class, global, field, variant, or case name already in the artifact. Duplicate
proof names still reject. The 256-string limit counts additions, not claim rows.
Every affected manifest, type, variant, and function name ID is remapped before
section 10 is written.

Rules and signed arguments are no longer inferred from the publication path.
Inverse arguments encode as two all-ones words. Positive step arguments retain
both words. Final verification checks actual composed instructions and the
existing 4,000,000-step native manifest profile. An encoding-valid larger claim
must reject, not narrow to a smaller accepted bound.

The publisher stages complete sections, validates the final container, and hashes
it before copying artifact or identity bytes. Thirty-three differential cases
cover both rules, existing and generated inverses, shared names, full string and
claim capacities, malformed later rows, and rejection without caller mutation.
Small cases rewind and replay. Maximum-width claims and terminal string capacity
run history-free. Keeping the terminal string case's complete history exhausted
the hosted test heap. The VM's limits were not raised.

The publication milestone at `7d5c4cf05` passed the archive and both selected
physical closure methods with 461 modules, 2,238 constants, and 1,857 callables.
Independent packages and graphs agreed, and the selected 527-function container
retained its independently reconstructed bytes and identity. A locked package
consumer published and checked a complete 544-byte step artifact. This was
product publication evidence, not compilation of every physical body.

### Declared global products

[WIP-0506](source/WIP-0506-native-source-global-products.md) joins signed state
initializers with canonical source-module emission. Shared member fronts and the
complete scalar packet produce declaration-ordered names and values. The archive
adapter retains the three declaration columns and adds canonical name IDs. Both
callable and callable-free paths emit globals before container verification.
They no longer discard unused state or invent a fixed class-name ID after adding
global strings.

The structured compiler, direction publisher, and source emitter receive the
class-name ID, global count, global product base, and global rows explicitly.
All direct callers use that contract. Private staging protects artifact and
identity publication on later invalid states, names, and proof bounds.
[WIP-0507](source/WIP-0507-native-source-global-access-products.md) owns the
remaining read/write lowering. Entry, nominal, and intact test-runner composition
remain open. Initializer retention is not their acceptance evidence.

### Scoped constants and ordinary claim composition

`SourceClassicalCoverage.w` joins ordinary claims with the existing homogeneous
reversible policy. It rejects mixed or unsupported effects before composition.
Claim-free ordinary modules reuse the empty scanner and module-range scratch.
Claim-bearing modules stage a local effect column and call the shared binder.
The old inverse-named coverage plan and duplicate policy path are removed.

`ArchiveStructuredSourceModuleCompiler.w` validates the complete detached scalar
packet before copying body columns. The table count and redundant body-name
coordinates must agree. `StructuredSourceModuleCompiler.w` receives the full
seven-column packet beside the reduced columns, binds claims, and passes them to
`StructuredArtifactDirections.w`. The classical publisher verifies the final
private artifact before any caller artifact or identity byte changes.

The join uses no dependency source and no new constant resolver. The copied name
view retains both identifiers and module qualifiers. Local declarations and
imported products reach `evaluateScalarExpressionWithProducts` through the
existing binder. Bounds keep all 64 bits until final verification.

Complete source-to-artifact comparisons cover literal bounds, a local constant
expression, and `example.values::LIMIT + 5` with detached `LIMIT = 3`. A bound of
`LIMIT + 4294967301` rejects despite its low word being eight. Ordinary inverse
claims reject against ordinary code. Corrupt counts, body-name coordinates,
qualifier windows, type and resolution flags, and name bytes reject even when
the constant is unused. Publication storage survives each rejection.

The archive fixture rewinds and replays the complete coverage phase for accepted
claims, rejected subjects, and claim absence. It checks phase snapshots rather
than claiming a full compiler-run rewind. Absence adds no owned buffer or region.
The claim-bearing effect arena is `64 * 8` bytes with one allocation. The shared
proof arena has `64 * 5` words and `64 * 256` copied-name bytes, for
`64 * 5 * 8 + 64 * 256` bytes and two allocations. These bounds do not widen the
scanner, lifetime-buffer, or final-proof limits.

The archive and both selected physical closure methods pass with 464 modules,
2,256 constants, and 1,860 callables. Independent source intake, two package
encodings, and the canonical 2,210-import graph agree. The selected 603,784-byte,
527-function container retains its independently reconstructed identity. The
structured owner uses 4,030 raw tokens, including comments, within the unchanged
4,096-token scanner window.

A locked external consumer compiles a source-local callable and its qualified
imported step claim. Only the selected source range and detached products enter
the compiler. Its complete 568-byte artifact matches an independently compiled
reference. The consumer halts after 1,117,859 transitions. This is source-product
compilation through packaged owners, not a native-built compiler executable.

This closes ordinary primitive source claim composition. It does not compile the
intact state/nominal/test fixture, every physical compiler body, or a fixed point.

### Source whitespace and comment termination

Bootstrap run 34451894674 exposed a regression in the new absence gate. The
physical CoreParsing fixture uses a tab between `class` and its name. The native
scanner classified that tab as punctuation. The declaration-product route had
not needed to rescan that header before source claim admission was added.

`Scanner.w` now owns the complete source whitespace set, including horizontal
tabs, carriage returns, and the admitted Unicode separators. Nonbreaking spaces
remain non-whitespace. Line comments end at carriage return or line feed, so a
claim after a carriage return cannot disappear inside a comment. No proof-local
trivia filter or source rewrite was added.

Forty-seven scanner cases compare lexical acceptance, exact UTF-8 token ranges,
full caller columns and tails, input preservation, cleanup, rewind, and replay.
Binding and absence tests cover claims after carriage-return-terminated comments.
The original complete CoreParsing archive-name regression also passes.

### Manifest composition

- [x] Manifest words use exact length and two base-128 ASCII lanes, not polynomial
  hashes. `PackageManifestWords.w` owns the 23 fixed spellings and their word
  codes. Token policy delegates exact classification and keeps token coordinates,
  ordering, and punctuation. The twelve-byte vocabulary bound does not limit names, paths, or quoted
  values. Words longer than twelve bytes return zero before reading their ranges.
- [x] `tokenHash`, `quotedHash`, and `keywordAt` are gone from manifest policy.
  Keys, Boolean and kind decoding, schema-version policy, and canonical layout
  consume exact word codes. Key callers use shared constants. The key owner
  checks lower bounds, column capacities, and identifier kind before reading text.
- [x] Regressions reject `trvF`, `topM`, and `tetU`, which the old parser accepted
  as `true`, `tool`, and `test`. Independent stage 0 rejects all three. Tests cover
  every fixed word, mutations at every character, both lanes, leading NUL aliases,
  non-ASCII candidates, long unknown values, signed extremes, and complete rewind.
  Parser and admission tests preserve failure offsets and exact source prefixes.
- [x] Fixed-word classification and token policy have separate source owners.
  Three word groups stay inside the existing 255-local frame profile. The split
  keeps the word artifact inside the unchanged 32,768-byte per-module buffer.
  No general conditional-declaration, nested-loop, or inequality lowering changed.
- [x] The combined word pass compares the complete word artifact and the indent,
  header-state, token, key, and kind bodies after all nine imported calls resolve.
  Constant-importing consumers use callable comparison so unrelated dependency
  bodies cannot enter the oracle. The pass replaces five standalone physical
  passes. The confirming archive and retained-closure run passes with the refreshed
  declaration counts and executable identity.
- [x] Lock, workspace, and snapshot readers no longer call the deleted hash APIs.
  `wheeler.packages.metadata_tokens` reuses positive manifest word codes and owns
  nine negative extension codes. Three copied key validators are gone. Shared
  tests reject every field-key hash alias, check complete unpublished host output,
  and rewind. Package-source fixtures derive compiler dependencies from imports.
  These callers remain separate from retained compiler-product evidence.

- [x] `manifestDependencyEntryProduct` and `manifestCapabilityEntryProduct` own
  complete entry publication. Each checks capacity, validates every field, checks
  adjacent ordering, projects coordinates, and publishes the row before returning
  the next count. Zero reports disorder. Minus one reports malformed input or
  exhausted capacity. The parser preserves name and row-start diagnostic offsets.
- [x] Preceding coordinates come from the consecutive row grammar. First rows
  need no predecessor. The parser's carriers, wrappers, ordering imports, and
  predecessor state are gone. Admission is private to each retained owner.
- [x] Capacity predicates reject negative indexes and compare against the number
  of complete rows. They do not multiply unchecked indexes. Partial rows and
  signed-overflow cases reject without touching caller storage.
- [x] Entry tests compare every published coordinate and every sentinel-filled
  rejected or trailing cell. They cover all dependency kinds, capability pair
  ordering, field-before-order diagnostics, capacity-before-order rejection,
  and count commits. Manifest regressions pin exact offsets and unchanged output.
- [x] One focused physical test replaces five archive passes. It compares all
  three capacity/coordinate artifacts byte for byte and both entry owners'
  complete frames and relocated instructions with stage 0. A valid but misbound
  imported target must fail comparison.
- [x] `manifestTargetSourceCollectionProduct` owns source-list traversal, row
  admission, ordering, coverage, and the next source-row count. It admits 1,024
  selectors and makes one terminal probe. A first-excess selector returns failure
  without publishing that row. Admitted prefixes remain on rejection, but the
  caller commits a count only after a nonempty collection covers its root.
- [x] The parser's source loop, predecessor, coverage state, and separate
  completion verdict are gone. The required tail receives no redundant completion flag.
  Source-table tests compare every cell, including partial capacity and preceding
  collections. Parser tests retain exact target-start diagnostics and distinguish
  admitted source prefixes from unpublished target rows.
- [x] `manifestTargetAdmissionProduct` validates the token-column windows, target
  head, optional module, complete source collection, and required test tail. Its
  eight arguments include the source table and offset. It returns the validated
  test-key token, or `-1` without committing a count. Earlier source rows remain
  on rejection. A present empty list cannot impersonate an absent list.
- [x] `TargetParse` and `parseTarget` are gone. The parser derives kind, name,
  root, module, source count, test value, and next cursor from admitted token
  coordinates. `manifestTargetSourceCount` requires an admitted tail, not an
  arbitrary integer. Target capacity still precedes admission. Complete field
  checks still precede target-name ordering and target-row publication.
- [x] Admission tests cover every target kind, empty and absent lists, partial
  capacity, malformed windows, signed extremes, exact prefixes, and full rewind.
  Parser tests compare every target and source cell with the independent stage-0
  model and preserve capacity, field, and ordering diagnostic precedence.
- [x] `NativeCompilerPackageManifestTargetAdmissionPhysicalProductExampleTest`
  compares the complete coordinate artifact and the admission, head, module
  head, collection, and tail bodies after all 35 imported calls resolve. The
  coordinate owner now uses direct structured products. This one pass replaces
  the separate head, module-head, and collection passes.
- [ ] Complete target publication and remaining collection composition through
  retained products. The aggregate parser still owns target capacity, adjacent
  target ordering, publication orchestration, target/dependency/capability
  iteration, allocation, and complete manifest publication.

Entry signatures and retained calls now both admit eight values.
[WIP-0496](WIP-0496-eight-argument-retained-source-calls.md) covers root and loop
calls, qualified imported targets, exact mixed scalar/loan types, and rejection
before argument, width, code, relocation, or artifact publication. The bounded
helper compiler retains its separate seven-argument profile. Generated inverses
still reject argument-bearing calls. Their transfer and cleanup sequences need
inverse lowering. Complete parser integration also remains open.

### Archive name products

Archive emission consumes module and class names from the declaration pass's
lexical archive ranges. The raw declaration scans and their range carriers are
gone. Local, imported, and callable-free paths use the same closed name facts.
The emitter validates source-local class extents and the existing 256-byte name
bound before artifact or identity publication. Comments and header whitespace
do not supply another declaration identity.

`NativeCompilerArchiveNamesExampleTest` compares complete artifacts and every
rejected output cell. `NativeCompilerEmptyArchiveNamesExampleTest` covers both
callable-free paths, foreign source ranges, and the last admitted and first
excess class-name lengths. The CoreParsing fixture now accepts binary input and
copies exact bytes before freezing its UTF-8 source. UTF-8 comment coordinates
there do not widen the counted source lease's separate ASCII profile.

Constant lookup now consumes the packed name bytes from
`ImportedConstantValues.w`. `symbolStarts` indexes that name view, not local
source or an archive-adjusted source offset. Direct declarations, relations,
returns, call-conditioned children, and loop limits compare their lexical use
with the same checked name product. Matching retains the 256-byte ASCII name
bound and selected-owner, signed-type, resolution, and uniqueness checks.
Loop limits count every matching name before checking type and resolution.
An invalid duplicate cannot disappear behind a valid signed product.

The archive compiler no longer searches for a representative source use.
`sourceNameUse`, `identifierByte`, and `NameUseRange` are gone. An absent imported
name cannot fall back to source offset zero and impersonate a local named `mod`
through the `module` header prefix. Unused products need no local source spelling.

`NativeCompilerArchiveConstantNamesExampleTest` compares complete artifacts for
that regression, repeated names, UTF-8 comment coordinates, root declarations,
conditional children, loop limits, and the last admitted name length. It checks
every rejected artifact and identity cell. The name-product fixture covers
mismatches, partial windows, signed extremes, untouched names, and full rewind.
Loop-product fixtures check every unpublished row cell and full rewind.
Remaining statement forms, complete target composition, and compiler-wide
physical integration remain open.

## Acceptance

- Primitive imported-call fixtures compile without dependency bodies.
- Stub order and temporary bytes are invariant under source arrival order.
- No retained instruction targets a stub or compiler-added entry.
- Local recursive aggregates and imported nominal signatures compile byte for byte with stage 0.
- Private and ambiguous products fail before output mutation.
- Ownership and loan failures publish no artifact or identity.
- Every physical compiler module compiles within the recovery profile.
- The complete closure passes WIP-0048 emission and native semantic verification.
- No authored file reaches 1,000 lines.
- No Wheeler source directory exceeds ten files.

## Rejected alternatives

**Copy dependency source.** That is source flattening and destroys the product boundary.

**Keep stubs in final bytecode.** Unreachable implementation debris still changes IDs, proofs, costs, and identity.

**Use host AST or `Program` objects.** Java is replaceable stage 0 and cannot own recovery products.

**Invent an unresolved bytecode format.** `.wbc` remains the sole semantic IR. Temporary stubs are ordinary verified functions removed before publication.

**Assign nominal IDs from generated names.** Names are scaffolding. Stable aggregate identities and final descriptor rows are authority.

## References

- [Self-hosting status and evidence](self-hosting-status.md)
- [Compiler implementation records](catalog/compiler.md)
- [Retained manifest products](catalog/manifests.md)
- [WIP-0044: Counted closure execution](WIP-0044-counted-native-compiler-closure-execution.md)
- [WIP-0045: Module symbol products](WIP-0045-counted-native-module-symbol-products.md)
- [WIP-0046: Aggregate layout products](WIP-0046-counted-native-aggregate-layout-products.md)
- [WIP-0047: Callable bytecode products](WIP-0047-counted-native-callable-bytecode-products.md)
- [WIP-0048: Canonical product linker](WIP-0048-canonical-native-product-linker.md)
- [WIP-0050: Aggregate source lowering](WIP-0050-native-aggregate-source-lowering.md)
- [WIP-0051: Aggregate frontend products](WIP-0051-native-aggregate-frontend-products.md)
- [WIP-0052: Structured-loop products](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0054: Artifact integration](WIP-0054-native-source-product-artifact-integration.md)
