# Open proposal work

[Proposal guide](index.mdx) · [Self-hosting status](self-hosting-status.md)

This page lists every Draft, Review, Accepted, and Implementing WIP. Each row
names the remaining contract, not a new promise or a duplicate acceptance suite.
The linked record owns its status, detailed requirements, and design questions.
Completed stages remain in the [topic catalogs](index.mdx#catalog).

Prioritize the compiler's complete physical closure. Add language or runtime
facilities when a real compiler boundary requires them. A working scalar native
image, a passing package shard, and a linked compiler subset are useful evidence,
but none establishes the compiler fixed point.

## Compiler closure

Read these as ownership boundaries in one pipeline. The dependencies in each WIP
refer to the required products, not a demand that every umbrella finish first.

| WIP | Remaining gate |
| --- | --- |
| [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md) | Complete compiler and diagnostic parity, stage-1/stage-2 equality, diverse derivation, and compiler cutover |
| [WIP-0044](WIP-0044-counted-native-compiler-closure-execution.md) | Drive every physical compiler module through the counted closure |
| [WIP-0045](WIP-0045-counted-native-module-symbol-products.md) | Stable candidate diagnostics and complete scalar/callable products across that closure |
| [WIP-0046](WIP-0046-counted-native-aggregate-layout-products.md) | Feed every module's aggregate products through dependency packing and identity publication |
| [WIP-0047](WIP-0047-counted-native-callable-bytecode-products.md) | Retain every physical body and relocation without compile-time scaffolding |
| [WIP-0048](WIP-0048-canonical-native-product-linker.md) | Emit and verify the complete compiler from products alone |
| [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md) | Compile every physical module from local source and dependency products |
| [WIP-0051](WIP-0051-native-aggregate-frontend-products.md) | Replace remaining fixture-projected frontend values with physical source products |
| [WIP-0054](WIP-0054-native-source-product-artifact-integration.md) | Join those products to artifact emission for the entire compiler |

Keep the distinction between implementation and evidence. WIP-0049 owns source
lowering, WIP-0054 owns its artifact integration, and WIP-0048 owns final linking.
Their completion gates meet at WIP-0007. Do not copy each module's history into
all four records.

## Native execution and recovery

| WIP | Remaining gate |
| --- | --- |
| [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md) | Full native execution and trace parity, a cold recovery build, and Java/Gradle deletion |
| [WIP-0025](WIP-0025-native-ffi-and-system-integration.md) | Exact ABI providers, capability and ownership enforcement, and sealed integration |
| [WIP-0026](WIP-0026-self-contained-native-executables.md) | Complete image/runtime conformance, provider integration, and Wheeler-owned image tools |
| [WIP-0032](WIP-0032-unified-io-fabric-and-durability-receipts.md) | Qualify concrete native adapters and crash/power-cut evidence for receipt issuers |
| [WIP-0053](WIP-0053-auditable-bootstrap-seed-chain.md) | Independent builders reproduce and attest the first native recovery release |

Native-image and AOT implementation records establish bounded profiles. They do
not close the runtime, recovery, or durability contracts above.

## Packages and distribution

| WIP | Remaining gate |
| --- | --- |
| [WIP-0009](WIP-0009-wheeler-package-and-build-system.md) | Wheeler-owned workspace execution, binary-library linkage, hermetic recovery, and build-tool cutover |
| [WIP-0022](WIP-0022-package-instances-and-resolution.md) | Contextual instances, aliases, deterministic conflict derivations, and multi-version compilation |
| [WIP-0023](WIP-0023-recipe-repositories-and-reproducible-builds.md) | Complete recipe/variant provenance, repository trust, and reproducible recovery inputs |
| [WIP-0024](WIP-0024-system-package-exports.md) | Canonical install images and reproducible Debian/RPM adapters with explicit lifecycle effects |

A validated source archive or lock graph is not a complete resolver. Native test
package support is one consumer of these products, not the owner of package
semantics.

## Language and library substrate

| WIP | Remaining gate |
| --- | --- |
| [WIP-0012](WIP-0012-wheeler-standard-library.md) | Public core/alloc/std contracts, compiler-scale collections, and Wheeler-owned library use |
| [WIP-0013](WIP-0013-typed-frames-control-flow-and-storage.md) | Protected reversible control, compiler parity, and complete compiler/resolver execution under bounds |
| [WIP-0017](WIP-0017-compile-time-constants-and-finite-enums.md) | Remove duplicate stage-0 tables and migration shims at cutover |
| [WIP-0028](WIP-0028-deterministic-ownership-borrowing-and-regions.md) | Public ownership metadata, returned loans, generic arenas, and native ownership parity |
| [WIP-0029](WIP-0029-parametric-polymorphism-and-bounded-specialization.md) | Closed generic types/functions, bounded specialization, and canonical library IR |
| [WIP-0030](WIP-0030-coherent-type-classes-and-associated-types.md) | Coherent instance resolution, associated members, and checked semantic evidence |
| [WIP-0031](WIP-0031-reversible-quantum-and-effect-polymorphism.md) | Typed callable values, effects, captures, and specialization/inverse/adjoint laws |
| [WIP-0041](WIP-0041-reversible-result-slots-and-explicit-presence-values.md) | Affine and borrowed results, multiple reversible returns, coherent slots, and proof/resource integration |

## Proofs, coherent control, and tasks

| WIP | Remaining gate |
| --- | --- |
| [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md) | General proposition/kernel contracts, independent checking, and self-hosted proof tooling |
| [WIP-0033](WIP-0033-typed-coherent-values-and-reversible-embeddings.md) | Typed coherent values and certified predicate embeddings |
| [WIP-0034](WIP-0034-structured-uncomputation-and-clean-ancilla-scopes.md) | Structured compute/use cleanup and clean ancilla laws |
| [WIP-0035](WIP-0035-reversible-and-coherent-control-flow.md) | Protected or witnessed branches/loops and coherent control |
| [WIP-0036](WIP-0036-symbolic-resource-contracts-and-compositional-cost-evidence.md) | Closed resource expressions, compositional bounds, and evidence checking |
| [WIP-0037](WIP-0037-hierarchical-semantic-routine-graphs.md) | Canonical routine hierarchy and verified transformation receipts |
| [WIP-0039](WIP-0039-deterministic-structured-task-machine-and-global-rewind.md) | Task-tree execution, shared atomics, deterministic replay, and global rewind |
| [WIP-0040](WIP-0040-explicit-schedule-witnesses-for-reversible-task-scopes.md) | Explicit task-schedule witnesses and source-level task inverses |

Keep proof, measurement, rewind, and inverse evidence separate. Existing scalar
result-slot or single-root VM support does not imply these broader contracts.

## Tools, tests, and applications

| WIP | Remaining gate |
| --- | --- |
| [WIP-0010](WIP-0010-executable-application-portfolio.md) | Complete semantic coverage of the portfolio, native trace parity, and offline package builds |
| [WIP-0014](WIP-0014-bounded-certified-program-synthesis.md) | Finite synthesis, independently checked minimality, and an executable Foundry package |
| [WIP-0015](WIP-0015-certified-adversarial-schedule-exploration.md) | Finite schedule search, replay and absence certificates, and an executable Murphy package |
| [WIP-0016](WIP-0016-nonconfigurable-source-formatter.md) | Wheeler formatter/checker parity and removal of the stage-0 tooling path |
| [WIP-0018](WIP-0018-integrated-deterministic-testing.md) | Complete self-hosted compiler testing and deletion of duplicated JUnit semantic authorities |
| [WIP-0019](WIP-0019-integrated-documentation-publication.md) | Wheeler-owned generation of the canonical documentation bundle |
| [WIP-0020](WIP-0020-semantic-coverage-and-evidence-accounting.md) | Remove superseded semantic coverage authorities |
| [WIP-0042](WIP-0042-first-principles-reversible-and-quantum-tutorials.md) | Executable lesson gates, staged curriculum acceptance, and reader-reviewed publication |

## Keep this map useful

Update a row when its remaining boundary changes. Remove it only when the owning
WIP reaches a closed status. Do not add a second task list for the same contract.
Use the child record or commit for implementation detail, and retain the parent's
full acceptance gate until its evidence exists.
