# Bootstrap evidence

A compiler can reproduce its own bugs. That alone doesn't make it trustworthy. WIP-0007 requires two separate checks:

1. stage 0 builds stage 1, and stage 1 builds a byte-identical stage 2.
2. an independently derived trusted compiler produces the same bytes without first running code from the candidate compiler.

The bootstrap gate records successful evidence in `wheeler.bootstrap.yaml`. The repository does not contain that manifest yet because the bounded Wheeler compiler is not self-hosting. Creating the file early would not provide real evidence.

## Profile and module derivation

Publish the complete known feature contract. Callers cannot subtract an inconvenient feature or add one that neither compiler implements:

```text
wheeler bootstrap-features \
  --profile bootstrap-1 \
  --output wheeler.bootstrap-features.yaml
```

Unknown profile names fail without output. The command reparses its canonical bytes before atomic publication.

Derive the compiler target's graph from the canonical source archive rather than maintaining two opinions about its imports:

```text
wheeler bootstrap-modules \
  --source-archive wheeler.compiler.wpk \
  --output wheeler.bootstrap-modules.yaml
```

The command selects the modular `tool` target named `compiler`, parses every `.w` source entry selected by that target, derives external imports, hashes each source, validates the rooted local DAG, reparses the canonical result, and publishes atomically. The Wheeler-native compiler now validates the same sorted unique direct-import header shape for up to sixty-four imports in one source. Its entryless path compiles the checked-in `compiler/backend/calls/CallArguments.w`, `compiler/backend/EncodingWidths.w`, imported-constant `compiler/frontend/intrinsics/BorrowedIntrinsicShapes.w`, `compiler/ir/Opcodes.w`, `compiler/ir/ProofRules.w`, `compiler/ir/ResolvedStatements.w`, `compiler/ir/StatementKinds.w`, `compiler/ir/StorageOpcodes.w`, `compiler/ir/TypeCodes.w`, `compiler/ir/limits/CompilerProgramLimits.w`, imported-function `compiler/verification/ResultSlotVerifier.w`, `compiler/resolution/returns/WideReturnSources.w`, imported-constant `compiler/resolution/returns/ReturnOpcodeKinds.w`, imported-constant `compiler/syntax/assignments/NamedLocalAssignmentKinds.w`, imported-constant `compiler/syntax/assignments/ResolvedLocalAssignments.w`, imported-constant `compiler/syntax/assertions/ResolvedBooleanLiteralAssertions.w`, imported-constant `compiler/syntax/assertions/ResolvedLessThanAssertions.w`, imported-constant `compiler/syntax/assertions/ResolvedLocalPairAssertions.w`, `compiler/syntax/booleans/BooleanTokens.w`, imported-constant `compiler/syntax/booleans/ResolvedBooleanLiteralComparisons.w`, imported-constant `compiler/syntax/comparisons/NamedComparisonKinds.w`, imported-constant `compiler/syntax/conditionals/LiteralComparisonOperations.w`, imported-constant `compiler/syntax/conditionals/NamedConditionalBases.w`, imported-constant `compiler/syntax/conditionals/NamedLiteralComparisonKinds.w`, imported-constant `compiler/syntax/conditionals/NamedLocalConditionalKinds.w`, imported-constant `compiler/syntax/conditionals/NamedLocalConditionalValues.w`, imported-constant `compiler/syntax/conditionals/ResolvedLiteralComparisonKinds.w`, imported-constant `compiler/syntax/conditionals/ResolvedLocalConditionalKinds.w`, imported-constant `compiler/syntax/conditionals/ResolvedLocalConditionalOperands.w`, imported-constant `compiler/syntax/conditionals/ResolvedLocalConditionalSources.w`, imported-constant `compiler/syntax/locals/NamedLongOperations.w`, imported-constant `compiler/syntax/locals/ResolvedLocalCopyKinds.w`, imported-constant `compiler/syntax/locals/ResolvedLocalEqualityKinds.w`, imported-constant `compiler/syntax/locals/ResolvedLocalInequalityKinds.w`, imported-constant `compiler/syntax/locals/ResolvedLocalLessThanKinds.w`, imported-constant `compiler/syntax/locals/ResolvedLocalLiteralComparisons.w`, imported-constant `compiler/syntax/locals/ResolvedLocalLiteralComparisonSources.w`, imported-constant `compiler/syntax/locals/ResolvedLongOperations.w`, imported-constant `compiler/syntax/loops/ResolvedLocalLoopForms.w`, imported-constant `compiler/syntax/loops/ResolvedLocalLoopKinds.w`, imported-constant `compiler/syntax/loops/ResolvedLocalLoopOperands.w`, imported-constant `compiler/syntax/updates/NamedLocalUpdateKinds.w`, imported-constant `compiler/syntax/updates/ResolvedLocalUpdates.w`, imported-constant `compiler/ir/OpcodeKinds.w`, imported-constant `compiler/ir/TypeKinds.w`, imported-constant `compiler/ir/InstructionForms.w`, imported-constant `compiler/syntax/BooleanDeclarationKinds.w`, `compiler/syntax/IdentifierStarts.w`, `compiler/syntax/tokens/CompilerTokenLimits.w`, `compiler/syntax/tokens/KeywordTokens.w`, `compiler/syntax/tokens/SourceScalars.w`, `compiler/syntax/helpers/HelperAbi.w`, imported-constant `compiler/syntax/helpers/HelperSignatures.w`, mixed-owner `compiler/syntax/helpers/HelperValueKinds.w`, imported-constant `compiler/syntax/EarlyReturnKinds.w`, imported-constant `compiler/syntax/EarlyReturnResultKinds.w`, `compiler/syntax/LoopKinds.w`, imported-constant `compiler/syntax/calls/CallArgumentSources.w`, imported-constant `compiler/syntax/calls/OneArgumentCalls.w`, imported-constant `compiler/syntax/calls/TwoArgumentCallKinds.w`, imported-constant `compiler/syntax/calls/FourArgumentCalls.w`, `compiler/syntax/calls/assignment/AssignmentCallArities.w`, `compiler/syntax/calls/assignment/AssignmentCallColumns.w`, `compiler/syntax/calls/assignment/AssignmentCallIdentities.w`, `compiler/syntax/calls/ThreeArgumentCalls.w`, `compiler/syntax/calls/VoidCallKinds.w`, `compiler/syntax/calls/VoidCallSourceKinds.w`, mixed-owner `compiler/syntax/calls/VoidCallSourceWidths.w`, `compiler/syntax/calls/VoidCallWidths.w`, imported-constant `compiler/syntax/returns/EarlyReturnSources.w`, imported-constant `compiler/syntax/returns/NamedBooleanReturnKinds.w`, imported-constant `compiler/syntax/returns/NamedReturnArithmeticKinds.w`, imported-constant `compiler/syntax/returns/NamedReturnComparisonOperands.w`, imported-constant `compiler/syntax/returns/NamedSignedReturnKinds.w`, imported-constant `compiler/syntax/returns/ResolvedEarlyComparisonKinds.w`, imported-constant `compiler/syntax/returns/ResolvedEarlyResultKinds.w`, imported-function `compiler/syntax/returns/EarlyComparisonForms.w`, `compiler/syntax/returns/ResolvedLocalReturns.w`, imported-constant `compiler/syntax/returns/ResolvedReturnCallKinds.w` modules byte for byte with stage 0 and emits the canonical unqualified `$library` halt entry. The path accepts zero or one general helper. It also accepts one through twenty-three public, private, or unqualified zero- through sixteen-parameter scalar helpers through a closed function-table path. The lower bound is one, not “two plus a dummy and a straight face.” One through seven direct edges let dependencies jointly own one through twenty-two helpers while the root owns the remainder of the twenty-three-helper table. The binary wrapper accepts zero through seven imported source frames of at most 32,768 bytes each: zero calls the single-module compiler directly, while seven remains the current ceiling. The exact per-source boundary compiles. Byte 32,769 fails before publication. One three-module chain may first resolve constants into an executable dependency. A twenty-third dependency helper or twenty-fourth total helper remains grounds for refusal rather than improvisation. Bounded native APIs now execute every rooted acyclic scalar-constant graph from one through seven imports. The single-import path links directly. Complete plans own edges, root ranks, leaf-first order, privacy, and exact shared-declaration deduplication from two through seven imports. Frame order and topology identities own nothing. Dense DAGs and redundant direct edges require no new executor. Direct helper sets, mixed direct owners, redundant constant leaves, the constant-fed helper chain, private helper chains, multi-input private helper dependencies, and mixed private constant/helper inputs use the graph executor. Shared and redundant executable dependencies use exact owner-identity filters and retain each helper member group once. Cycles, detached nodes, duplicate modules, eight imports, non-ASCII linked source, and byte 32,769 fail before publication. Sources belonging only to another target, such as the entryless compiler library facade, do not enter this graph. A missing declaration, duplicate module, unsorted import list, dangling local import, cycle, unreachable selected source, link, malformed archive, or changing input produces no output.

`compiler/closure/ArchiveSources.w` starts the counted production path. It validates the outer package digest, every entry digest, 512 canonical sorted paths, complete framing, and exact path/data offsets before publishing a column. `PackageTarget.w` parses the complete canonical package manifest and binds one untested `compiler` tool target to the bootstrap root module and source path. Package metadata admits 512 targets, 8,192 source selectors, 512 dependencies, 512 capabilities, and 131,072 tokens within 262,144 bytes. `ModuleManifest.w` then validates canonical syntax, names, binding, cycles, and rooted reachability into counted scratch columns. `ArchiveModuleSources.w` joins each local module path and source identity to one exact immutable archive range before publication. `ClosurePlan.w` then publishes source ranges, import windows and ranks, deterministic leaf-first order, and executable-owner bits. A 257-module chain places its root last. The current 246-module compiler closure joins, plans, and classifies completely. `ActiveSourceSlots.w` provides eight generation-checked linked-source leases over 262,144 mutable bytes. Reuse advances the generation, release destroys bytes, stale handles cannot read or publish, and a ninth concurrent owner fails deterministically. `ClosureSchedule.w` stages immutable sources in leaf-first order and publishes module generations after the complete pass. The 257-module chain's root receives generation 257. `ModuleSymbols.w` uses the same order to publish compact scalar declaration products and direct-edge public-symbol counts before destroying each source lease. The chain publishes 257 symbols. The physical compiler closure publishes 1,102 declarations with peak source count one. `SymbolIdentities.w` gives each declaration a SHA-256 identity bound to the package archive, module source identity, kind, visibility, scalar type, and name. `ScalarModuleIdentities.w` binds each resolved local module to its source, canonical name, direct dependency products, symbols, resolution bits, and values. External edges fail closed until locked package product identities exist. Literal and same-module expressions publish bounded values. `ImportedConstantValues.w` packs direct public values in header and declaration order. The bounded evaluator resolves arithmetic, comparison, Boolean, unqualified, and qualified imported expressions from those products. Two equal unqualified names remain unresolved as ambiguous. `ModuleCallables.w` publishes owner, visibility, canonical name, signature range, complete forward/reverse body range, and parameter count after one staged-source pass. `CallableSignatureProducts.w` separates canonical result and parameter type ranges, owner or loan mode, and entry, reversible, coherent, or test effects. Reversible value products publish their fixed two-local result-slot width. `CallableIdentities.w` binds the package, owner source, visibility, effects, name, result, and ordered parameter types and loans. Invalid loan modes publish no identity bytes. `CompiledCallableBodies.w` compiles one source-local callable or all callables owned by one module into canonical `.wbc` and hashes the exact artifact without reading dependency source. Owner, borrowed, mutable-loan, and local-call fixtures match stage 0. Reused output storage is cleared before emission, including alignment padding. The compiled product decodes its canonical function table and reports exact function and maximum local-register counts. `CompiledFunctionProducts.w` validates exact type windows, contiguous forward and inverse code, and every instruction through `InstructionForms.w`. Unknown executable opcodes fail. `FunctionProductIdentities.w` binds exact type and code digests to signature, ordered callable dependency, aggregate, and ownership identities. `LocalCallRelocations.w` maps local call and uncall operands to stable signature identities and rejects missing function targets before publication. `ImportedCallRelocations.w` verifies linked cross-module calls against public target signature identities and rejects private targets. `SourceCallProducts.w` resolves pre-link unqualified names and arities, applies local shadowing, and rejects ambiguous imports. Exact matching also requires ordered parameter types and loan modes, result type, and effects. Qualified matching is restricted to the written dependency rank. `CompiledAggregateLayouts.w` validates `.wbc` directories and decodes bounded record, array, slice, variant, case, and member rows. `AggregateIdentities.w` binds package, module, artifact, an ordered direct-dependency identity list, counts, and validated rows under a domain-separated SHA-256 identity. `AggregateDependencyProducts.w` packs header-ranked local and locked external identities and fails before copying when one is unavailable. `CountedAggregateLayouts.w` appends one immutable artifact at a time and rebases closure-wide aggregate, case, and member windows. `AggregateTypeResolution.w` resolves source-local nominal member codes to unique owner/type rows. `AggregateLoanVerifier.w` checks move, shared-loan, mutable-loan, and release streams against member owners and rejects escaping loans before publication. Private callables stay local and direct edges count public callables in header rank. The physical closure publishes 1,045 callable products with peak source count one. `ProductRootSource.w` rewrites only the executable root against completed products. It never reads dependency source. `CountedConstantExecutor.w` compiles a 257-module forwarding closure without `BoundedGraphPlan`, retaining the leaf value 41 and matching the corresponding stage-0 normalized root artifact byte for byte. `SmallClosureExecutor.w` carries exact seven-import counted fixtures into the differential executor. Direct constants, a redundant DAG, mixed executable owners, and private helper edges match stage 0 from package and manifest inputs. The bridge is conformance scaffolding, not the production closure ceiling. A mismatched identity publishes nothing. `NativeBootstrapModulesIdentity.w` calls the same parser rather than maintaining a conformance-only metadata dialect. A 513th archive entry fails before hashing or mutation. Core ranged SHA-256 covers every block in the 16 MiB physical evidence ceiling.

The evidence gate derives the same graph independently and requires exact agreement. The generated file is evidence, not authority over source syntax.

## Evidence command

The final stage-0 gate is:

```text
wheeler bootstrap-manifest \
  --source-archive wheeler.compiler.wpk \
  --source-lock wheeler.package.lock.yaml \
  --feature-manifest wheeler.bootstrap-features.yaml \
  --module-manifest wheeler.bootstrap-modules.yaml \
  --options-manifest wheeler.compiler-options.yaml \
  --limits-manifest wheeler.compiler-limits.yaml \
  --ordinary-toolchain ordinary-toolchain.provenance \
  --ordinary-compiler stage0.compiler \
  --ordinary-runtime stage1.runtime \
  --ordinary-verifier verifier.wbc \
  --stage-1 compiler-stage1.wbc \
  --stage-2 compiler-stage2.wbc \
  --ordinary-diagnostics ordinary.diagnostics \
  --diverse-toolchain diverse-toolchain.provenance \
  --diverse-compiler trusted.compiler \
  --diverse-runtime trusted.runtime \
  --diverse-verifier trusted.verifier \
  --diverse-output compiler-diverse.wbc \
  --diverse-diagnostics diverse.diagnostics \
  --acceptance-artifacts acceptance \
  --output wheeler.bootstrap.yaml
```

Each file argument must point to a physical, nonsymlink file no larger than 16 MiB. Only the two diagnostics files may be empty.

The acceptance argument must point to a closed artifact tree. Its canonical `wheeler.artifact-set.json` must still match every `.wbc` file in that tree. The command checks each input before and after reading it, so a file that changes during hashing causes an error.

`NativeArtifactSetIdentity.w` independently reproduces the domain-separated identity for the bounded bootstrap slice: strict canonical JSON no larger than 4,096 bytes and one through eight sorted safe ASCII `.wbc` paths. It rejects forged embedded identities and publishes only the verified 32-byte digest. It does not open the named artifacts. Physical-file closure, bytecode verification, stable reads, and the 65,535-artifact production ceiling remain the stage-0 command's job until WIP-0032 file traversal and the native verifier replace that boundary. Hashing a shopping list does not prove the groceries exist.

Before it publishes anything, the command:

- strictly decodes the canonical `wheeler.compiler` package archive.
- parses the schema-3 snapshot-bound lock and requires its exact canonical YAML bytes.
- binds that lock to the source manifest.
- parses exact schema-1 feature, generated module, option, and limit manifests.
- requires every profile name to match the source package.
- requires the module graph to be closed, acyclic, rooted, and free of dead modules.
- rehashes every declared module source from the compiler archive, reparses its module header, and rejects undeclared `.w` entries.
- independently decodes and re-encodes stage 1, stage 2, and the diverse output.
- compares all three complete `.wbc` byte strings.
- compares the ordinary and diverse diagnostic bytes.
- requires different ordinary and diverse toolchain identities.
- requires different ordinary and diverse compiler identities.
- recomputes the closed acceptance artifact-set identity.
- requires that set to contain the compiler fixed point.
- parses its own output before replacing the destination atomically.

The command never runs a candidate artifact. A static manifest also cannot prove that an earlier build script followed the right order. The promotion job must show that the diverse comparison happened before candidate execution, bind both toolchain provenance files, and run acceptance only after the comparison gate.

Two copies of the same opaque compiler do not count as independent derivations, even when their filenames differ.

## Compiler input schemas

The accepted source profile is an exact `wheeler.bootstrap-features.yaml` vocabulary:

```yaml
schema: 1
profile: "bootstrap-1"
features:
  - name: "affine-borrows"
    version: 1
  - name: "boolean-scalars"
    version: 1
  - name: "bounded-loops"
    version: 1
  - name: "byte-output"
    version: 1
  - name: "byteview-input"
    version: 1
  - name: "checked-arithmetic"
    version: 1
  - name: "compile-time-constants"
    version: 1
  - name: "exhaustive-variants"
    version: 1
  - name: "fixed-scalar-array-fields"
    version: 1
  - name: "generated-inverse-proofs"
    version: 1
  - name: "module-linking"
    version: 1
  - name: "nominal-records"
    version: 1
  - name: "owned-regions"
    version: 1
  - name: "signed-scalars"
    version: 1
  - name: "static-calls"
    version: 1
  - name: "strict-utf8-input"
    version: 1
  - name: "word-buffers"
    version: 1
```

Feature names are sorted and unique. Schema 1 accepts exactly this seventeen-feature `bootstrap-1` set, all at version 1. `NativeBootstrapFeaturesIdentity.w` reconstructs those sole canonical bytes, requires exact complete consumption, and reproduces the stage-0 identity for manifests up to 2,048 bytes. A feature version names a semantic contract, not a marketing release. Unknown, duplicated, missing, reordered, empty, or oversized vocabularies fail closed. Adding a feature therefore requires a new reviewed profile contract and changes its identity even if somebody forgot to update a slide deck.

The exact compiler module closure uses `wheeler.bootstrap-modules.yaml`:

```yaml
schema: 1
profile: "bootstrap-1"
root: "wheeler.compiler"
externals:
  - "wheeler.core"
modules:
  - name: "wheeler.compiler"
    source: "src/main/wheeler/MinimalCompiler.w"
    identity: "<sha256>"
    imports:
      - "wheeler.compiler.backend"
      - "wheeler.core"
  - name: "wheeler.compiler.backend"
    source: "src/main/wheeler/compiler/backend/Codegen.w"
    identity: "<sha256>"
    imports:
      - "wheeler.core"
```

Modules, externals, and imports are sorted and unique. Every local import resolves, every external import is declared, every local module is reachable from the root, the local graph is acyclic, source paths are unique, and each source identity must match the file inside the canonical compiler archive. The bounds are 10,000 local modules, 10,000 external modules, and 100,000 direct imports. `NativeBootstrapModulesIdentity.w` now covers one through 512 sorted local modules, zero through sixty-four externals, and up to 3,072 imports with unique paths, complete binding, rooted reachability, and cycle detection. It also enforces strict names and paths, exact canonical bytes, and fail-closed identity publication. A 257-module chain crosses the former local ceiling. A source guard pins the check before a 513th append without buying a long rejection fixture. Nine-, ten-, and thirteen-module DAGs over sixty-four externals pin executable coverage at 512, 576, and 768 imports. Sorted module and external tables use bounded binary lookup. A source guard test pins the check before a 3,073rd append without buying another long rejection fixture. Its 262,144-byte input budget covers the current 246-module, 1,295-import, 113,633-byte compiler closure, whose stage-0 identity the native executable reproduces in 43,834,464 transitions. It does not claim the full graph ceiling. A bound written in a comment allocates no table. This manifest records the graph actually trusted for bootstrap. Directory enumeration is not a module system.

Bootstrap options use exact `wheeler.compiler-options.yaml` bytes:

```yaml
schema: 1
compiler:
  profile: "bootstrap-1"
  source-maps: false
```

Limits use exact `wheeler.compiler-limits.yaml` bytes:

```yaml
schema: 1
limits:
  source-bytes: 16777216
  tokens: 100000
  nesting: 256
  declarations: 10000
  symbols: 10000
  instructions: 1000000
  diagnostics: 1000
  heap-bytes: 268435456
  stack-depth: 1024
  steps: 10000000
```

Each limit is a positive canonical integer no larger than 1,073,741,824. The schema requires all ten limits and rejects unknown keys. A launcher must apply the same values to both derivations. `NativeCompilerLimitsIdentity.w` consumes the exact canonical field order and decimal spelling, checks all ten bounds, and reproduces the stage-0 identity for manifests up to 512 bytes. Hashing one limits file while using different limits would make the provenance false.

Source maps may be enabled only when their normalized logical source identities are part of the canonical output.

`NativeCompilerOptionsIdentity.w` accepts exactly the schema-1 canonical bytes, a 1--128 byte profile in the declared identifier alphabet, and canonical `true` or `false`. It reproduces the stage-0 SHA-256 only after complete validation and exact input consumption. The bounded fixture ceiling is 256 bytes. `ManifestSyntax.w` owns the shared fail-closed fragment comparison used here and by native artifact-set validation. Duplicate tiny parsers become large disagreements remarkably quickly.

Each ordinary and diverse toolchain argument uses exact canonical `wheeler.toolchain.yaml`:

```yaml
schema: 1
toolchain:
  kind: "independent-stage0"
  source: "<sha256>"
  builder: "<sha256>"
  dependencies: "<sha256>"
  environment: "<sha256>"
```

`kind` is `recovery-seed`, `independent-stage0`, or `host-source`. The other fields bind the reviewed toolchain source, its builder, its closed dependency set, and its normalized build environment. `NativeToolchainIdentity.w` accepts only that exact field order, canonical quoted spelling, four lowercase SHA-256 values, and a final LF within its 512-byte budget. The stage-0 parser applies the same canonical-byte check. A map with the right facts in a different order is not the file named by the digest.

The kind is only an audit category. Promotion still requires distinct full provenance and compiler identities, plus a review that confirms the two derivations are truly independent.

## Canonical evidence schema

Schema 2 has one strict canonical `wheeler.bootstrap.yaml` form:

```yaml
schema: 2
source:
  archive: "<sha256>"
  manifest: "<sha256>"
  lock: "<sha256>"
  profile: "bootstrap-1"
  features: "<sha256>"
  modules: "<sha256>"
  options: "<sha256>"
  limits: "<sha256>"
ordinary:
  toolchain: "<sha256>"
  compiler: "<sha256>"
  runtime: "<sha256>"
  verifier: "<sha256>"
  stage-1: "<sha256>"
  stage-2: "<sha256>"
  diagnostics: "<sha256>"
diverse:
  toolchain: "<sha256>"
  compiler: "<sha256>"
  runtime: "<sha256>"
  verifier: "<sha256>"
  output: "<sha256>"
  diagnostics: "<sha256>"
acceptance:
  artifact-set: "<sha256>"
```

All identities are lowercase SHA-256 values. `source.archive` identifies the canonical package archive, `source.manifest` identifies the package manifest, and `source.lock` identifies the canonical lock. `source.features` fixes the accepted semantic vocabulary. `source.modules` fixes the rooted source graph and each source byte string.

Features, modules, options, and limits remain separate inputs. A changed resource limit must not look like the same compilation. Toolchain, compiler, runtime, and verifier identities describe both complete derivations instead of the host that ran them.

The schema constructor enforces these rules:

```text
ordinary.stage-1 == ordinary.stage-2
ordinary.stage-1 == diverse.output
ordinary.diagnostics == diverse.diagnostics
ordinary.toolchain != diverse.toolchain
ordinary.compiler != diverse.compiler
```

`NativeBootstrapManifestIdentity.w` applies the exact schema-2 field order, validates all twenty-one identities and the bounded source profile, enforces these five relationships, consumes the final LF, and only then publishes SHA-256. Its 2,048-byte ceiling is enough for the sole canonical form. Stage 0 now makes the same canonical-byte comparison. A permissive YAML parse is not provenance, however politely indented.

These checks are required for promotion, but they do not prove that source and output match by themselves. The trust case also depends on review, reproducible host builds, the strict verifier, source comparison, fixed-point evidence, and independent derivation.

## Publication and retention

A recovery candidate includes the compiler artifact, its canonical source archive and lock, `wheeler.bootstrap.yaml`, every referenced provenance input, and the closed acceptance artifact set. Publication is content-addressed and all-or-nothing.

Cache paths, repository aliases, download URLs, CI run numbers, wall-clock times, and usernames are transport details. They do not affect the artifact or bootstrap identity.

The manifest is generated and must not be hand-edited. A failed comparison produces no new manifest.

Deleting extra cache copies must not change the evidence graph. Losing a referenced provenance object makes the candidate impossible to verify, so the candidate cannot be promoted.

See [WIP-0007](../proposals/WIP-0007-self-hosting-compiler-and-bootstrap.md) for the bootstrap process. The [package and build reference](packages.md) defines canonical package, lock, repository, and artifact-set identities.
