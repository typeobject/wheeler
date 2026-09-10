# Self-hosting status and evidence

[Proposal guide](index.mdx) · [Open work](roadmap.md)

The compiler is not self-hosted yet. Stage 0 still produces the compiler used by
the evidence harness. Wheeler compiles and links a growing physical subset, but
there is no complete stage-1/stage-2 fixed point or accepted native recovery seed.

This page owns the cross-proposal progress summary. Individual WIPs own contracts
and historical evidence. Tests and lockfiles own exact current pins. Do not copy
the closure history into each parent after every small adoption patch.

## Three different evidence paths

| Path | What it establishes | What it does not establish |
| --- | --- | --- |
| Native package tests | Wheeler discovers, compiles, executes, and reports admitted test targets from exact source plans | Compilation of every compiler module or the full language profile |
| Counted physical products | Wheeler reads physical archive ranges, emits source-local products, retains local prefixes, and resolves imported calls | A complete compiler until every physical module takes this path |
| Native images and scalar AOT | Verified WBC executes under the named machine-code profile with exact capsule binding | Wheeler-owned native lowering, full runtime parity, or Java-free recovery |

The bounded package compiler uses at most eight source modules in one plan.
The counted closure uses a separate graph profile. Its 512-module bound must not
be described as an eight-source limit, and archive intake has its own 1,024-entry
bound. A limit belongs to one boundary, not to Wheeler as a language.

Native passing execution and report identities now bind actual classical
transition counts rather than zero. [WIP-0500](WIP-0500-native-classical-step-identities.md)
compares complete 255-case reports against independent stage-0 execution across
four disjoint identity shards. This does not close the compiler or recovery gates.

## Pipeline ownership

| Boundary | Owning contract | Completion evidence |
| --- | --- | --- |
| Archive intake, module binding, source leases, and scheduling | [WIP-0044](WIP-0044-counted-native-compiler-closure-execution.md) | Every module binds to its digest-checked physical source range |
| Scalars and callable signatures | [WIP-0045](WIP-0045-counted-native-module-symbol-products.md) | Closed, visible, unambiguous dependency products with stable diagnostics |
| Aggregate layouts and ownership | [WIP-0046](WIP-0046-counted-native-aggregate-layout-products.md) | All nominal products cross source-release and dependency-packing boundaries |
| Callable bodies and relocations | [WIP-0047](WIP-0047-counted-native-callable-bytecode-products.md) | Exact local function/instruction windows and resolved identities |
| Local source lowering | [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md) | Every physical module emits a canonical product without dependency source |
| Aggregate frontend and artifact integration | [WIP-0051](WIP-0051-native-aggregate-frontend-products.md), [WIP-0054](WIP-0054-native-source-product-artifact-integration.md) | Source-derived values reach the emitter without fixture projections |
| Final IDs, sections, verification, and publication | [WIP-0048](WIP-0048-canonical-native-product-linker.md) | Complete compiler artifact from semantic products alone |
| Fixed point and compiler promotion | [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md) | Complete stage equality, diagnostic parity, and diverse derivation |
| Runtime and recovery cutover | [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md), [WIP-0053](WIP-0053-auditable-bootstrap-seed-chain.md) | Reproducible cold native build followed by Java/Gradle deletion |

## Current retained boundary

The row-publication series ends at
[WIP-0495](WIP-0495-retained-package-manifest-target-row-publication.md).
Its identities describe that milestone. Current graph, archive, and executable
pins live in the evidence tests below. Subsequent private composition work stays
in [WIP-0049's checklist](WIP-0049-bounded-native-source-product-compilation.md#manifest-composition)
unless it needs a separate contract.

The retained package-manifest owners cover tokens, names, paths, semantic
versions, canonical framing, header fields, collection keys, row capacities,
ordering policy, dependency and capability validation, target field policy,
source-selector admission and coverage, and row publication. Dependency and
capability entry products own capacity, field validation, adjacent ordering, row
publication, and count commits. Dependencies require strictly increasing names.
Capabilities allow equal names only when paths increase strictly. Both preserve
distinct malformed-row and ordering diagnostics. Capacity checks reject negative
and overflowing row indexes. Entry tests compare every written and untouched cell.
The whole-closure test compares complete frames and relocated instructions with
stage 0 for every selected callable product. It also compares the complete
comparable artifact prefix byte for byte. Counts
remain capacity checks, not substitutes for body parity.

Ordinary retained calls now admit 64 ordered identifiers across root, loop,
and qualified imported calls. Signed and Boolean values and UTF-8, byte-view,
mutable-byte, mutable-word, mutable-region, and mutable-map loans retain exact
types and defining-value coordinates.
[WIP-0502](WIP-0502-sixty-four-argument-retained-source-calls.md) extends the shared
call layout beyond WIP-0496's eight-argument milestone. Nine-, 55-, and 64-argument
bodies match independent artifacts. Wide signed calls execute through an
independent wrapper and rewind. The entry-product regression follows 29 imported
targets, and the archive pass binds all 451 modules. This does not compile the
complete value-planning or frame-composition owners natively. Canonical locks and
the workspace build pass for `76b211806`. Hosted run 34159406697 passes all 52
jobs on that commit, including all sixteen native compiler-package rows. That
acceptance does not cover the later storage-loan changes.

[WIP-0503](WIP-0503-retained-region-and-map-call-loans.md) adds exact region and map
loan binding without widening buffer operations. Local and imported artifacts
match stage 0. A native-produced caller invokes an independent callee that
allocates through its region loan and mutates its map loan. The complete execution
rewinds. Owned storage arguments remain excluded. Local physical, archive, and
workspace checks pass. The formatting repair at `7e63b4721` passes 51 hosted jobs,
but native shard 15 exceeds the unchanged twelve-minute method deadline in run
34166510984. Those jobs do not establish package acceptance.

[WIP-0504](WIP-0504-complete-retained-call-statement-windows.md) validates complete
ordinary call windows and removes the second qualified-call width pass. Qualified
signed and Boolean forwarding now matches complete artifacts, including exact
mixed-loan arguments. A native-produced qualified caller executes allocation and
map mutation through an independent callee and rewinds. Unsupported call tails
reject without publication instead of silently losing their values. Complete
compiler composition and the intact nominal runner remain separate work.
Hosted run 34173276816 on `ae690860a` passes 51 jobs, but native shard 15 again
exceeds the unchanged twelve-minute deadline. It is not package acceptance.

[WIP-0505](WIP-0505-nominal-carrier-frame-coordinates.md) repairs nominal carrier
frame coordinates in final type linking. Value-returning functions have a
serialized result-type prefix, not an extra frame local. Complete type tables
and reconstructed artifacts preserve that distinction. Independent typed callers
execute the restored callees and rewind. This does not supply complete nominal
source artifacts or repair the intact mixed-member runner.

Hosted run [34180345032](https://github.com/typeobject/wheeler/actions/runs/34180345032)
on `f78ead83f` passes all 52 jobs, including all sixteen native compiler-package
rows. Each row executes the selected test method under the unchanged twelve-minute
deadline. This supplies same-commit package acceptance for the committed storage,
call-window, and carrier changes. It does not cover the unfinished member-front
overlay, complete compiler composition, or a fixed point. Shard 15 passes this
run, but that does not explain the two predecessor timeouts.

The final semantic container publisher now checks capacity before artifact
allocation, verifies private bytes, and copies only the measured artifact extent.
Complete-buffer failures cover invalid code, entry, types, and proofs. Accepted
artifacts preserve unused caller bytes, execute, and rewind. The 16 MiB extent
check remains separate from maximum-size semantic artifact acceptance.
[WIP-0048](WIP-0048-canonical-native-product-linker.md#container-publication-regression)
owns this repair. It does not close the source-to-nominal join in
[WIP-0054](WIP-0054-native-source-product-artifact-integration.md).
Hosted run [34186361333](https://github.com/typeobject/wheeler/actions/runs/34186361333)
on `13f7622f9` finishes 51 of 52 jobs successfully. Native shard 6 exceeds the
unchanged twelve-minute deadline. That commit has no full package acceptance.

Final manifest emission now consumes a closed product instead of rereading the
root artifact. Retained source-local emission uses the same word encoder. Complete
binding windows and output bytes are checked before publication. This removes
one artifact dependency. It does not supply the missing nominal bodies or their
complete source-to-final composition.

Hosted run [34191525605](https://github.com/typeobject/wheeler/actions/runs/34191525605)
on `7aae570bf` passes all 52 jobs, including all sixteen native compiler-package
rows. Every selected method executes under the unchanged twelve-minute deadline.
This supplies same-commit package acceptance for the committed manifest-product
and container-publication changes. It does not cover the member-front overlay,
complete physical source-to-artifact compilation, or stage equality. The later
passing shard 6 does not explain its predecessor's timeout.

[WIP-0508](WIP-0508-checked-imported-nominal-fragments.md) gives imported nominal
source writers one checked declaration encoder. The reference writer calls that
owner instead of duplicating its names, declarations, and temporary projections.
Complete type-ID windows cannot overwrite kind tags. Both insertion positions
retain their complete source and projection results. An independently compiled
rewritten record fixture executes and rewinds. This is scaffolding adoption, not
a complete nominal artifact pipeline or hosted acceptance of the member overlay.
At that fragment milestone, the unfinished member-front overlay had four
unreachable physical owners: aggregate operand projections, aggregate owner
projections, imported nominal product resolution, and source aggregate strings.
Its intact mixed-member runner rejected in `requireMinimalProgram`. The separate
primitive control did not replace either gate. Later uncommitted source-data work
called the aggregate string owner, leaving three module orphans in that
experiment. Callable-free data artifacts do not supply the missing nominal bodies.

Hosted run [34220715075](https://github.com/typeobject/wheeler/actions/runs/34220715075)
on `571c5166a` passes all 52 jobs and all sixteen native compiler-package rows.
Every selected method executes under the unchanged twelve-minute deadline. The
audited method-to-build-success upper bounds range from 277.499765 to 675.176708
seconds. This supplies same-commit package acceptance for the checked nominal
fragments. It does not cover later register-storage changes, the unfinished
source-data composition, the member overlay, or whole-compiler self-hosting.

Hosted run [34230344433](https://github.com/typeobject/wheeler/actions/runs/34230344433)
on `8f1b65f04` passes all 52 jobs and all sixteen native compiler-package rows.
Each selected method executes under the unchanged twelve-minute deadline. Audited
method-to-build-success upper bounds range from 286.499954 to 678.999894 seconds.
This accepts the unchanged-register storage patch on its own commit. It does not
cover later string-linking changes or the unfinished source-data and member work.

The [WIP-0048](WIP-0048-canonical-native-product-linker.md) string emitter now reuses
exact spelling prefixes and stable duplicate representatives. It drops the second
name search and the fixed-width wrapper. Full sections, counted ID maps, rejection
storage, and small-case rewind pass direct boundary checks. The independent row,
name-byte, section-byte, and executable limits remain unchanged.

Hosted run [34240882904](https://github.com/typeobject/wheeler/actions/runs/34240882904)
on `78d28ea97` passes all 52 jobs and all sixteen native compiler-package rows.
Every selected method executes under the unchanged twelve-minute deadline.
Audited method-to-build-success upper bounds range from 365.999613 to 670.502182
seconds. This supplies same-commit package acceptance for counted string linking.
It does not cover the uncommitted library-entry tests, source-data composition,
member fronts, complete physical compiler emission, or stage equality.

[WIP-0184](WIP-0184-sparse-aggregate-ownership-projection.md#shared-operand-owner)
consolidates aggregate operand projection and local resolution. Both APIs share
one lookup and atomic publisher, with parent/replacement boundary parity and no
separate projection module. Strict lookup still rejects missing descriptors.
Filtered lookup still leaves unmatched constructors outside its product.
`Driver.w` imports this owner but calls neither API. This is a proved code
replacement, not production adoption or the missing source-to-final nominal join.
Rooted module membership cannot establish that join. Local acceptance covers 98
distinct JUnit identities, 450 physical archive bindings, selected source-artifact
and complete retained-callable parity, four refreshed consumer locks, and a
497-artifact workspace. The locked minimum-state consumer retains its complete
artifact and coverage bytes. These are local checks, not same-commit hosted
package acceptance or compilation of every physical source owner.

[WIP-0184](WIP-0184-sparse-aggregate-ownership-projection.md#shared-frame-keys)
also replaces duplicate function/local searches with one frame projection owner.
Instruction-local aggregate/member coordinates and module-scoped final carriers
keep separate schemas. The local-type emitter consumes the shared locator, while
whole-table, last-row, rejection, rewind, and mutation checks cover both policies.
The old owner module and passive frontend import are gone. Neither the emitter
nor owner-event projection has a complete driver-owned nominal path. Generic
primitive ownership events still cannot be treated as aggregate member loans.
Local validation covers 83 executed JUnit identities, 450 archive bindings,
selected physical artifacts and complete retained callable bodies, four refreshed
consumer locks, and a 497-artifact workspace. All six root policy checks and five
main-root API checks pass. Conformance entry comments and Effects facets remain
open. These local checks do not themselves supply hosted package acceptance.

Hosted run [34326207343](https://github.com/typeobject/wheeler/actions/runs/34326207343)
on `198c8563c` passes all 52 jobs and all sixteen native compiler-package methods.
Each method executes under the unchanged twelve-minute deadline. Audited
method-to-build-success upper bounds range from 287.603330 to 652.487199 seconds.
This accepts the committed frame-key replacement, not the dirty nominal overlay
or the subsequent graph-window change.

[WIP-0044](WIP-0044-counted-native-compiler-closure-execution.md#counted-owner-windows)
replaces repeated full-edge scans with parser-owned numeric owner windows. The
same 216,281-byte nominal manifest now publishes its graph identity in 77,181,931
transitions instead of reaching the unchanged 89-million ceiling without output.
A combined 512-module/3,072-import control retains complete metadata identity.
Its graph work falls from 26.3 million to 2.9 million transitions with no additional
arena. These are bounded graph checks, not accepted overlay locks, native emission
of every compiler source, nominal execution, or stage equality.

Hosted run [34334217832](https://github.com/typeobject/wheeler/actions/runs/34334217832)
on `beb49cdbe` passes all 52 jobs and all sixteen native compiler-package methods.
Audited method-to-build-success upper bounds range from 367.498252 to 672.461070
seconds under the unchanged twelve-minute deadline. This accepts counted graph
traversal on that commit, not the dirty nominal overlay or the later physical
inventory test.

[WIP-0098](WIP-0098-early-callable-free-archive-publication.md#complete-current-callable-free-inventory)
now checks every current callable-free owner in the rooted `compiler` target in
one archive pass. All twenty-one are import-free constant authorities. Their complete
8,062-byte transport matches independent artifacts and metadata. Every synthetic
entry verifies, executes, and rewinds. The archive pass remains history-free.
This is complete coverage of that inventory, not physical nominal-descriptor or
nominal-body coverage. The first-authority-only test is deleted. The rooted target
excludes the package's `CompilerLibrary.w` and `compiler/verification/Codec.w`.
Every physical main source still requires product evidence. The codec and empty
facade now have separate source-local evidence below. Complete native library
compilation and retained publication remain open.

This does not widen the separate bounded helper
compiler's seven-argument profile. Generated inverses still reject calls with
arguments. That lowering boundary remains in WIP-0049.

[WIP-0497](WIP-0497-exact-source-word-admission.md) replaces source-keyword hashes
with exact codes for 59 words, including `enum`. This includes Boolean literals, primitive types,
intrinsics, and test metadata. Two length-bearing ASCII lanes admit the fixed
vocabulary without limiting identifier length. Declaration tests reject all six
reproduced keyword aliases before publishing names. One physical pass compares
the Boolean and long-word artifacts and complete short-word and range-classifier
bodies after two imported calls resolve.

[WIP-0498](WIP-0498-native-test-member-front-admission.md) owns a separate frontend
gap. Automatic discovery still ignores some malformed member fronts and can
publish a successful zero-test report. Explicit descriptors detect the missing
cases, but they do not validate the source grammar.

[WIP-0499](WIP-0499-native-global-call-assignments.md) adds signed call assignments
into the bounded helper compiler's existing class-state slot. Exact local-name
precedence prevents wrong-type or duplicate locals from falling back to globals.
Helper selection, canonical strings, frame planning, and emission preserve the
same destination. Complete artifacts compare for zero through seven arguments
and a 23-helper entry. This does not supply WIP-0498's test projection or the
full mixed nominal compiler join.

[WIP-0501](WIP-0501-native-signed-ordering-assertions.md) gives direct signed `<`
assertions two full-width operand words with independent literal, local, or global
origins. The original minimum-state source now compiles with its assertion intact.
Complete artifacts and false-comparison traps match stage 0. Typed parameters,
lexical precedence, compiler publication, and rewind retain focused evidence.
General Boolean expressions and direct global literal-call arguments remain open.

Hosted run `34150655780` at `a6384a6f6` passes all 52 jobs, including all sixteen
native compiler-package shards. The twelve-minute method deadlines and case-identity
partition remain unchanged. This supplies same-commit package acceptance, not
complete physical compiler lowering or the WIP-0498 nominal-runner join.

Manifest token policy now uses exact word codes. The old hashes admitted malformed
spellings such as `trvF`, `topM`, and `tetU`. Tests reject those aliases, long
unknown words, and invalid extents without losing row diagnostics. The combined
pass compares the complete word artifact and every body from five consumer
modules after nine imported calls resolve. Refreshed archive and retained-closure checks pass.
Lock, workspace, and snapshot readers also use exact words. Their separate tests
reject field-key aliases before host publication and restore the initial state on
rewind. This does not place those readers in the retained compiler product set.

`PackageManifest.w` still coordinates complete parsing. Source-list traversal,
ordering, coverage, and row publication share one collection product. Complete
target admission now joins the head, optional module, collection, and test tail.
It returns the validated tail coordinate instead of an aggregate parser carrier.
The parser derives row fields from that coordinate and the token tables. Rejected
targets retain admitted selector prefixes but commit no count or target row.
Target capacity, adjacent ordering, publication orchestration, and the remaining
collection loops stay open. Tests preserve exact offsets and every row cell.

Archive emission uses lexical module and class names from declaration products.
The four name columns publish together after the complete pass. Callable and
callable-free emission validate name extents without raw-text rediscovery.
Constant lookup compares lexical uses with packed name bytes, not guessed local
source offsets. Direct statements and loop limits share the bounded comparison.
Unused constants cannot alias the module-header prefix. Duplicate, unresolved,
and nonsigned matching products reject before publication.

After manifest composition, the remaining physical compiler modules must enter
the same product route. Final linking and the fixed-point comparison remain
separate gates. Do not mark either complete from a subset count.

[WIP-0054](WIP-0054-native-source-product-artifact-integration.md#closed-result-types)
now carries closed signed, Boolean, and void results through structured calls,
direct statements, and artifact emission. The backward signature parser and its
scanner arena are deleted. Damaged result products reject before publication.
Complete caller-storage comparisons, direct preflight without scratch allocation,
and compilation rewind cover the join. Nominal result products remain outside
this scalar composition. Local validation executes 163 distinct JUnit identities,
binds all 449 compiler-target modules, and checks 711 canonical package inputs in
four owning test-task audits. Five main API roots, all six root policy gates, the
497-artifact workspace and site, a locked consumer, and the native ordering and
spine targets pass. The graph identity takes 73,374,451 transitions under the
unchanged 89-million ceiling. These are scoped gates, not compilation of every
physical main source or stage equality.

Hosted run [34375785935](https://github.com/typeobject/wheeler/actions/runs/34375785935)
on `df1a9e014` passes all 52 jobs and all sixteen executed native compiler-package
methods. Audited method-to-build-success upper bounds range from 258.799221 to
687.901583 seconds under the unchanged twelve-minute deadline. This accepts the
retained-result patch, not the dirty nominal overlay or subsequent codec work.

[WIP-0054](WIP-0054-native-source-product-artifact-integration.md#codec-source-product)
now also checks `Codec.w` outside the rooted compiler target. Its scalar output
bound admits the complete authored function through direct products. The full
source-local artifact, frame, instruction body, imported relocation, SHA-256, and
caller storage match independent expectations. The actual emitted body executes
and rewinds against an independently compiled verifier and wrapper. This is not
native compilation of that dependency closure or `CompilerLibrary.w`.

Scoped codec acceptance passes 58 distinct JUnit identities, the 449-module target
archive binding, six root policy gates, and four owning-task audits of all 711
canonical package inputs. Five main API roots, the 497-artifact workspace and site,
the locked minimum consumer, and native ordering 3/3 and spine 7/7 also pass. The
consumer retains 568 artifact bytes, 772 coverage bytes, seven steps, and state 7.
The compiler archive and four locks change. Rooted graph and executable identities
do not. A separate conformance API check reported fifteen missing comment or Effects
facets at that milestone. Commit `6c8ef9494` repairs those comments and extends
the source-quality gates to all six main roots. All conformance target and
dependency artifacts remain byte-identical.

[WIP-0054](WIP-0054-native-source-product-artifact-integration.md#library-facade-source-product)
now checks the unmodified `CompilerLibrary.w` through the callable-free archive
compiler. Its complete local artifact, SHA-256, metadata, publication tails,
rejections, and compilation rewind pass. Its single entry executes and rewinds.
The native input contains the facade's six imports but no dependency source.
That empty local artifact does not compile the imported library bodies or place
them in the retained physical container. This evidence changes no Wheeler source,
archive, graph, or lock identity.

[WIP-0050](WIP-0050-native-aggregate-source-lowering.md) now admits enum declarations
into source aggregate products rather than silently omitting them. Payload-free
cases follow stage 0's lexical enum order. Ordinary variants keep declaration
order. Complete row, capacity, malformed-input, rewind, and replay checks cover
this boundary. The mixed-member runner still needs complete source-to-final
composition. Enum row admission does not make that runner or the compiler
self-hosted.

[WIP-0048](WIP-0048-canonical-native-product-linker.md#classical-proof-products)
retains generated-inverse and static-step certificates through counted intake and
final section emission. Circuit rules no longer enter the function-subject table.
Split arguments, complete rebasing windows, and later malformed rows are checked
before publication. A complete artifact with both classical rules matches stage
0. The final verifier still checks the claim against actual code and limits.
This closes a retained-proof gap, not source theorem lowering or the mixed-member
runner join.

Hosted run [34421714092](https://github.com/typeobject/wheeler/actions/runs/34421714092)
on `b80b50be3` failed: one terminal-case identity shard reached its two-minute
method deadline and another job could not resolve JUnit's BOM. The later bootstrap
run [34428229529](https://github.com/typeobject/wheeler/actions/runs/34428229529)
on `505312113` passes. README, site, and CodeQL workflows also pass for that commit.
The later pass does not explain or repair the earlier timing failure.

## Evidence locations

Paths below are authoritative inventories and executable checks, not another
copy of their generated hashes.

| Evidence | Source |
| --- | --- |
| Selected physical module owners | [NativeCompilerPhysicalSelection.java](../../../bootstrap/examples/src/test/java/com/typeobject/wheeler/examples/NativeCompilerPhysicalSelection.java), [NativeCompilerPhysicalModules.java](../../../bootstrap/examples/src/test/java/com/typeobject/wheeler/examples/NativeCompilerPhysicalModules.java) |
| Every callable-free compiler-target owner | [NativeCompilerCallableFreePhysicalProductExampleTest.java](../../../bootstrap/examples/src/test/java/com/typeobject/wheeler/examples/NativeCompilerCallableFreePhysicalProductExampleTest.java) |
| Canonical graph and archive derivation | [CompilerSources.java](../../../bootstrap/examples/src/test/java/com/typeobject/wheeler/examples/CompilerSources.java) |
| Native graph validation and exact transition pin | [NativeBootstrapModulesIdentityExampleTest.java](../../../bootstrap/examples/src/test/java/com/typeobject/wheeler/examples/NativeBootstrapModulesIdentityExampleTest.java) |
| Wheeler SHA-256 differential evidence | [NativeSha256ExampleTest.java](../../../bootstrap/examples/src/test/java/com/typeobject/wheeler/examples/NativeSha256ExampleTest.java) |
| Physical archive/declaration binding | [NativeCompilerArchiveClosureExampleTest.java](../../../bootstrap/examples/src/test/java/com/typeobject/wheeler/examples/NativeCompilerArchiveClosureExampleTest.java) |
| Retained products, relocation, and linked executable pins | [NativeCompilerPhysicalClosureExampleTest.java](../../../bootstrap/examples/src/test/java/com/typeobject/wheeler/examples/NativeCompilerPhysicalClosureExampleTest.java) |
| Manifest behavior and round-trip evidence | [NativeManifestExampleTest.java](../../../bootstrap/examples/src/test/java/com/typeobject/wheeler/examples/NativeManifestExampleTest.java) |
| Compiler package test invocation | [NativeCompilerPackageTest.java](../../../bootstrap/tools/src/test/java/com/typeobject/wheeler/tools/NativeCompilerPackageTest.java) and the compiler package's test targets |

## Choose the verification scope

Run focused source-product and behavior tests while a change is still moving.
After changing physical sources, derive the graph and archive again, update exact
dependent locks, and verify an affected locked consumer. Run complete closure
evidence when the retained set, code products, relocation, or final linker
changes. Do not run it to check proposal navigation or prose.

The explicit closure task's deadlines live in
[bootstrap/examples/build.gradle](../../../bootstrap/examples/build.gradle).
The dedicated compiler package shard task lives in
[bootstrap/tools/build.gradle](../../../bootstrap/tools/build.gradle).
Keep timing policy there rather than republishing stale limits in every WIP.

Completed implementation records live in the
[compiler](catalog/compiler.md), [manifest](catalog/manifests.md),
[testing](catalog/testing.md), [package](catalog/packages.md), and
[platform](catalog/platform.md) catalogs. They explain how each boundary arrived,
not whether today's full compiler has passed it.
