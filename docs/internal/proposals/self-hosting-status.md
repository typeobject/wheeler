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

`PackageManifest.w` still coordinates complete parsing. The next acceptance
boundary is complete target and collection composition through retained products,
including failure offsets, validation order, and unchanged output on rejection.
Extracting another helper is useful only when it closes part of that boundary.

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
