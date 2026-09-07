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

Ordinary retained calls now admit eight ordered identifiers across root, loop,
and qualified imported calls. Signed and Boolean values and UTF-8, byte-view,
mutable-byte, and mutable-word loans retain exact types and defining-value coordinates.
[WIP-0496](WIP-0496-eight-argument-retained-source-calls.md) owns the shared call
layout and first-excess evidence. It does not widen the separate bounded helper
compiler's seven-argument profile. Generated inverses still reject calls with
arguments. That lowering boundary remains in WIP-0049.

[WIP-0497](WIP-0497-exact-source-word-admission.md) replaces source-keyword hashes
with exact codes for 58 words. This includes Boolean literals, primitive types,
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

Hosted acceptance at `34b255f84` completed 51 of 52 jobs successfully. Native
package row 1 exhausted its unchanged twelve-minute method deadline. Successful
rows from other commits do not complete that package gate.

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

## Evidence locations

Paths below are authoritative inventories and executable checks, not another
copy of their generated hashes.

| Evidence | Source |
| --- | --- |
| Selected physical module owners | [NativeCompilerPhysicalSelection.java](../../../bootstrap/examples/src/test/java/com/typeobject/wheeler/examples/NativeCompilerPhysicalSelection.java), [NativeCompilerPhysicalModules.java](../../../bootstrap/examples/src/test/java/com/typeobject/wheeler/examples/NativeCompilerPhysicalModules.java) |
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
