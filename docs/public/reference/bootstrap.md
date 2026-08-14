# Bootstrap evidence

A compiler can reproduce its own bugs. That alone doesn't make it trustworthy. WIP-0007 requires two separate checks:

1. stage 0 builds stage 1, and stage 1 builds a byte-identical stage 2.
2. an independently derived trusted compiler produces the same bytes without first running code from the candidate compiler.

The bootstrap gate records successful evidence in `wheeler.bootstrap.yaml`. The repository does not contain that manifest yet because the bounded Wheeler compiler is not self-hosting. Creating the file early would not provide real evidence.

Ordinary CI first runs `./bootstrap/gradlew -p bootstrap :stage0:clean :stage0:build`. This deletes prior stage-0 module outputs and rebuilds the alternate Java compiler seed from source before command-adapter, workspace, or promotion work can use it. The command establishes routine reproduction of the current alternate implementation. It is not a Wheeler fixed point or an independent derivation.

The seed must also be bootstrappable in the source-correspondence sense. Every binary in the required chain names the exact source revision, builder, closed dependencies, normalized environment, build command, output identity, and parent seed. CI runs the recorded command routinely. A checksum identifies an opaque binary but does not explain how source produced it. Wheeler minimizes such roots and keeps the simple alternate stage-0 implementation alive until a smaller auditable path replaces it.

The build driver follows the same rule. `RecoveryDriverBootstrap` validates a sealed source and vendor input closure, explicit execution limits, previous-release identity, environment, command, and expected output before crossing one `PreviousDriver` boundary. The command cannot name the current driver or a network URL. Exact output length and SHA-256 identity validate before the first current driver publishes. Distributors must still supply a real prior recovery release and walk its ancestry rather than starting from an unlabeled compiler download.

`wheeler.seed.yaml` is the canonical record for one seed artifact. Its schema binds the artifact kind, target platform, output identity and length, source revision and identity, build command, working directory, builder, closed dependencies, environment, parent, and independent attestations. The four admitted kinds are `alternate-stage0`, `recovery-release`, `system-toolchain`, and `opaque-root`. An opaque root has empty source and parent fields and complete origin, transport, acquisition-date, and reason fields. Other kinds require source correspondence and forbid opaque metadata. The strict parser rejects unknown fields, alternate key order, noncanonical scalars, a contradictory opaque marker, and malformed identities.

`BootstrapSeedChain` indexes records by the SHA-256 identity of their canonical bytes. Every parent and attestation must be present. Parent walks are bounded and acyclic. An attestation must name the same source revision, source identity, and output identity under a builder identity not already used by the subject or another attestation. This establishes a closed evidence graph. It does not turn an opaque root into source-derived bytes.

`wheeler.recovery.yaml` binds that graph into release evidence. The canonical record carries the complete chain identity and count, sorted opaque-root identities and byte total, source archive, lock, compiler options and limits, fixed-point evidence, diverse-compilation evidence, acceptance artifact set, and parent recovery release. `BootstrapRecoveryEvidence.validate` rederives all chain and opaque totals rather than trusting duplicated release metadata. Fixed-point and diverse identities remain separate fields.

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

The command selects the modular `tool` target named `compiler`, parses every `.w` source entry selected by that target, derives external imports, hashes each source, validates the rooted local DAG, reparses the canonical result, and publishes atomically. The Wheeler-native compiler now validates the same sorted unique direct-import header shape for up to sixty-four imports in one source. Its entryless path compiles the checked-in `compiler/backend/calls/CallArguments.w`, `compiler/backend/EncodingWidths.w`, imported-constant `compiler/frontend/intrinsics/BorrowedIntrinsicShapes.w`, `compiler/ir/Opcodes.w`, `compiler/ir/ProofRules.w`, `compiler/ir/ResolvedStatements.w`, `compiler/ir/StatementKinds.w`, `compiler/ir/StorageOpcodes.w`, `compiler/ir/TypeCodes.w`, `compiler/ir/limits/CompilerProgramLimits.w`, dependency-free `compiler/verification/ResultSlotVerifier.w`, `compiler/resolution/returns/WideReturnSources.w`, imported-constant `compiler/resolution/returns/ReturnOpcodeKinds.w`, imported-constant `compiler/syntax/assignments/NamedLocalAssignmentKinds.w`, imported-constant `compiler/syntax/assignments/ResolvedLocalAssignments.w`, imported-constant `compiler/syntax/assertions/ResolvedBooleanLiteralAssertions.w`, imported-constant `compiler/syntax/assertions/ResolvedLessThanAssertions.w`, imported-constant `compiler/syntax/assertions/ResolvedLocalPairAssertions.w`, `compiler/syntax/booleans/BooleanTokens.w`, imported-constant `compiler/syntax/booleans/ResolvedBooleanLiteralComparisons.w`, imported-constant `compiler/syntax/comparisons/NamedComparisonKinds.w`, imported-constant `compiler/syntax/conditionals/LiteralComparisonOperations.w`, imported-constant `compiler/syntax/conditionals/NamedConditionalBases.w`, imported-constant `compiler/syntax/conditionals/NamedLiteralComparisonKinds.w`, imported-constant `compiler/syntax/conditionals/NamedLocalConditionalKinds.w`, imported-constant `compiler/syntax/conditionals/NamedLocalConditionalValues.w`, imported-constant `compiler/syntax/conditionals/ResolvedLiteralComparisonKinds.w`, imported-constant `compiler/syntax/conditionals/ResolvedLocalConditionalKinds.w`, imported-constant `compiler/syntax/conditionals/ResolvedLocalConditionalOperands.w`, imported-constant `compiler/syntax/conditionals/ResolvedLocalConditionalSources.w`, imported-constant `compiler/syntax/locals/NamedLongOperations.w`, imported-constant `compiler/syntax/locals/ResolvedLocalCopyKinds.w`, imported-constant `compiler/syntax/locals/ResolvedLocalEqualityKinds.w`, imported-constant `compiler/syntax/locals/ResolvedLocalInequalityKinds.w`, imported-constant `compiler/syntax/locals/ResolvedLocalLessThanKinds.w`, imported-constant `compiler/syntax/locals/ResolvedLocalLiteralComparisons.w`, imported-constant `compiler/syntax/locals/ResolvedLocalLiteralComparisonSources.w`, imported-constant `compiler/syntax/locals/ResolvedLongOperations.w`, imported-constant `compiler/syntax/loops/ResolvedLocalLoopForms.w`, imported-constant `compiler/syntax/loops/ResolvedLocalLoopKinds.w`, imported-constant `compiler/syntax/loops/ResolvedLocalLoopOperands.w`, imported-constant `compiler/syntax/updates/NamedLocalUpdateKinds.w`, imported-constant `compiler/syntax/updates/ResolvedLocalUpdates.w`, imported-constant `compiler/ir/OpcodeKinds.w`, imported-constant `compiler/ir/TypeKinds.w`, imported-constant `compiler/ir/InstructionForms.w`, imported-constant `compiler/syntax/BooleanDeclarationKinds.w`, `compiler/syntax/IdentifierStarts.w`, `compiler/syntax/tokens/CompilerTokenLimits.w`, `compiler/syntax/tokens/KeywordTokens.w`, `compiler/syntax/tokens/SourceScalars.w`, `compiler/syntax/helpers/HelperAbi.w`, imported-constant `compiler/syntax/helpers/HelperSignatures.w`, imported-function `compiler/syntax/helpers/HelperResultKinds.w`, mixed-owner `compiler/syntax/helpers/HelperValueKinds.w`, imported-constant `compiler/syntax/EarlyReturnKinds.w`, imported-constant `compiler/syntax/EarlyReturnResultKinds.w`, `compiler/syntax/LoopKinds.w`, `compiler/syntax/loops/LoopBodyOpcodes.w`, `compiler/closure/layouts/source/carriers/LoopBodyLayouts.w`, imported-constant `compiler/syntax/calls/CallArgumentSources.w`, imported-constant `compiler/syntax/calls/OneArgumentCalls.w`, imported-constant `compiler/syntax/calls/TwoArgumentCallKinds.w`, imported-constant `compiler/syntax/calls/FourArgumentCalls.w`, `compiler/syntax/calls/assignment/AssignmentCallArities.w`, `compiler/syntax/calls/assignment/AssignmentCallColumns.w`, `compiler/syntax/calls/assignment/AssignmentCallIdentities.w`, `compiler/syntax/calls/ThreeArgumentCalls.w`, `compiler/syntax/calls/VoidCallKinds.w`, imported-function `compiler/syntax/calls/void/VoidCallOperands.w`, `compiler/syntax/calls/VoidCallSourceKinds.w`, mixed-owner `compiler/syntax/calls/VoidCallSourceWidths.w`, `compiler/syntax/calls/VoidCallWidths.w`, imported-constant `compiler/syntax/returns/EarlyReturnSources.w`, imported-constant `compiler/syntax/returns/NamedBooleanReturnKinds.w`, imported-constant `compiler/syntax/returns/NamedReturnArithmeticKinds.w`, imported-constant `compiler/syntax/returns/NamedReturnComparisonOperands.w`, imported-constant `compiler/syntax/returns/NamedSignedReturnKinds.w`, imported-constant `compiler/syntax/returns/ResolvedEarlyComparisonKinds.w`, imported-constant `compiler/syntax/returns/ResolvedEarlyResultKinds.w`, imported-function `compiler/syntax/returns/EarlyComparisonForms.w`, `compiler/syntax/returns/ResolvedLocalReturns.w`, imported-constant `compiler/syntax/returns/ResolvedReturnCallKinds.w` modules byte for byte with stage 0 and emits the canonical unqualified `$library` halt entry. The path accepts zero or one general helper. It also accepts one through twenty-three public, private, or unqualified zero- through sixteen-parameter scalar helpers through a closed function-table path. The lower bound is one, not “two plus a dummy and a straight face.” One through seven direct edges let dependencies jointly own one through twenty-two helpers while the root owns the remainder of the twenty-three-helper table. The binary wrapper accepts zero through seven imported source frames of at most 32,768 bytes each: zero calls the single-module compiler directly, while seven remains the current ceiling. The exact per-source boundary compiles. Byte 32,769 fails before publication. One three-module chain may first resolve constants into an executable dependency. A twenty-third dependency helper or twenty-fourth total helper remains grounds for refusal rather than improvisation. Bounded native APIs now execute every rooted acyclic scalar-constant graph from one through seven imports. The single-import path links directly. Complete plans own edges, root ranks, leaf-first order, privacy, and exact shared-declaration deduplication from two through seven imports. Frame order and topology identities own nothing. Four imports exhaust every permutation. Five through seven imports cover forward and reverse rotations so one differential cannot monopolize a test worker. Dense DAGs and redundant direct edges require no new executor. Direct helper sets, mixed direct owners, redundant constant leaves, the constant-fed helper chain, private helper chains, multi-input private helper dependencies, and mixed private constant/helper inputs use the graph executor. Shared and redundant executable dependencies use exact owner-identity filters and retain each helper member group once. Cycles, detached nodes, duplicate modules, eight imports, non-ASCII linked source, and byte 32,769 fail before publication. Sources belonging only to another target, such as the entryless compiler library facade, do not enter this graph. A missing declaration, duplicate module, unsorted import list, dangling local import, cycle, unreachable selected source, link, malformed archive, or changing input produces no output.

`compiler/closure/ArchiveSources.w` starts the counted production path. It validates the outer package digest, every entry digest, 512 canonical sorted paths, complete framing, and exact path/data offsets before publishing a column. `PackageTarget.w` parses the complete canonical package manifest and binds one untested `compiler` tool target to the bootstrap root module and source path. Package metadata admits 512 targets, 8,192 source selectors, 512 dependencies, 512 capabilities, and 131,072 tokens within 262,144 bytes. `ModuleManifest.w` then validates canonical syntax, names, binding, cycles, and rooted reachability into counted scratch columns. `ArchiveModuleSources.w` joins each local module path and source identity to one exact immutable archive range before publication. `ClosurePlan.w` then publishes source ranges, import windows and ranks, deterministic leaf-first order, and executable-owner bits. A 257-module chain places its root last. The current 332-module compiler closure joins, plans, and classifies completely. `ActiveSourceSlots.w` provides eight generation-checked linked-source leases over 262,144 mutable bytes. Reuse advances the generation, release destroys bytes, stale handles cannot read or publish, and a ninth concurrent owner fails deterministically. `ClosureSchedule.w` stages immutable sources in leaf-first order and publishes module generations after the complete pass. The 257-module chain's root receives generation 257. `ModuleSymbols.w` uses the same order to publish compact scalar declaration products and direct-edge public-symbol counts before destroying each source lease. The chain publishes 257 symbols. The physical compiler closure publishes 1,752 declarations with peak source count one. `SymbolIdentities.w` gives each declaration a SHA-256 identity bound to the package archive, module source identity, kind, visibility, scalar type, and name. `ScalarModuleIdentities.w` binds each resolved local module to its source, canonical name, direct dependency products, symbols, resolution bits, and values. External edges fail closed until locked package product identities exist. Literal and same-module expressions publish bounded values. `ImportedConstantValues.w` packs direct public values in header and declaration order. The bounded evaluator resolves arithmetic, comparison, Boolean, unqualified, and qualified imported expressions from those products. Two equal unqualified names remain unresolved as ambiguous. `ModuleCallables.w` publishes owner, visibility, canonical name, signature range, complete forward/reverse body range, and parameter count after one staged-source pass. It validates every callable name range before copying the complete counted name product into a 1 MiB source-independent arena. `CallableSignatureProducts.w` separates canonical result and parameter type ranges, owner or loan mode, and entry, reversible, coherent, or test effects. Reversible value products publish their fixed two-local result-slot width. `CallableIdentities.w` binds the package, owner source, visibility, effects, name, result, and ordered parameter types and loans. Invalid loan modes publish no identity bytes. `CompiledCallableBodies.w` compiles one source-local callable or all callables owned by one module into canonical `.wbc` and hashes the exact artifact without reading dependency source. Owner, borrowed, mutable-loan, and local-call fixtures match stage 0. Borrowed intrinsic result locals also feed later typed comparisons without a source copy bridge. Owner-free Boolean parameters preserve Boolean identity through direct returns, copies, and negation. Void helpers accept direct Boolean assertions, so metadata guards no longer synthesize an invalid buffer read to trap. The counted physical closure also compiles seventy-nine scalar-dependent compiler modules from immutable local archive ranges. Twenty-four use source-local scalar declarations, including the shared loop-body opcode and layout authorities. Fifty-five more consume direct imported scalar products through a canonical module-source projection that retains the module declaration, removes imports, and substitutes only resolved product references. `CallArguments.w` uses imported type and opcode values to select exact reborrow and scalar-move instructions. `LocalTypeEncoding.w` freezes imported type codes and emits each fixed-width row without retaining its former callable dependency. The latest comparable product is `ResultSlotVerifier.w`, which owns fixed-width field decoding locally instead of retaining an external callable dependency. Each artifact is retained in `CompiledBodyArchive.w` under its canonical physical owner before the ordered prefix matches stage 0 byte for byte. Thirteen subsequent physical modules compile through copied callable names, frozen primitive signatures, packed dependency rows, and signature-only stubs. The ninth uses checked local addition behind a signed less-than guard after an imported call result. The tenth compiles `CallForms.w` with frozen Boolean signatures and keeps packed wide-call classification in the retained module, so the selected closure already owns every relocation target. The eleventh compiles `VoidCallOperands.w` after source validity becomes an explicit gap and packed digits become prior locals. The twelfth compiles `HelperResultKinds.w` after signed and nonsigned local-return tests become disjoint call guards. The thirteenth compiles `AssignmentCallOperands.w` after bounded packed traversal becomes tail recursion, source validity becomes a positive gap, and call results bind to prior locals. Stub source ends with one canonical ASCII space after the class brace, giving the scanner a bounded terminator without changing semantic tokens. Source-local Boolean assignment supports equality, local less-than, and reversed literal less-than guards. Both prior locals resolve before a canonical seven-instruction branch is emitted. Their intermediate artifacts are archived after the comparable prefix, yielding 93 framed artifacts. `CoreParsing.w` is the first physical artifact emitted directly from structured source products rather than projected source or signature stubs. Decoded local-to-stub calls publish cross-owner relocation rows with the target WIP-0045 signature identity, while recursive stub calls remain local. Every physical relocation identity resolves uniquely through the complete callable identity hash to its callable product row. Every selected artifact is decoded, and exact source-local function and instruction prefixes pass `retainLocalFunctionProduct`. Signature stubs and compiler-added library entries do not enter those counts. A second bounded lifetime consumes only the immutable artifact stream plus six-byte product and relocation frames. An eight-byte `WPF1` footer binds the version, product count, and relocation count before any product is decoded. It revalidates and appends every nonempty prefix to closure-wide function and instruction windows. Their final extents match stage 0 exactly. Relocation frames carry source product, local instruction, target owner, and target-local function. Every frame and call opcode validates before numeric closure function rows publish. `emitResolvedLinkedInstructionCodeAt` copies closure-ordered instruction records from immutable artifacts and writes only final call operands. The physical subset emits 182,144 code bytes across 222 functions and 7,814 instructions. Its 5,372 primitive local-type rows pass `LinkedLocalTypes.w`. `CompiledStringProducts.w` validates 431 source-local strings, `LinkedStringSection.w` sorts and deduplicates them to 339 final rows, and retained function-name prefixes resolve to those rows. `LinkedFunctionSection.w` then emits exact named descriptors and type windows. One retained synthetic library entry gives the subset a valid root. `LinkedContainer.w` assembles and verifies a 232,256-byte classical artifact with canonical manifest, string, empty global, empty aggregate, function, and code sections. The second lifetime hashes the verified container natively. Two independent runs produce identical bytes and the same SHA-256 identity is `a14f7f74062baef68ce4ff024f5350a8feb655f3ae0f0d2d7502a8b348ee9cea`. The independent stage-0 reader accepts all 222 functions, and the synthetic library entry executes to `HALT`. A malformed relocation owner traps before numeric targets, code, or publication. This is complete executable emission for the physical subset, not the compiler closure. WIP-0054 owns further adoption of the direct WIP-0052 loop-product route now used by `CoreParsing.w` for `ManifestSyntax.w` and later physical modules. `SourceStatementProducts.w` now publishes atomic function owner, parent, depth, source extent, and local ordinal rows for empty through four-level nested blocks. `SourceValueProducts.w` retains each statement's measured logical first local and width beside named values and callable counts. Excess depth, stale or overlapping callable extents, and detached root blocks leave caller rows untouched. `SourceLoopProducts.w` validates that block graph and publishes block-grouped direct statements, lexical ordinals, signed condition ranges, literal or named limit ranges, loop parents, body windows, depths, and an atomic five-local frame-width join. Empty through sixty-four-statement bodies work, while invalid literal bounds and forged block rows publish nothing. `ResolvedLoopProducts.w` then joins signed literal and unique prior-local condition operands to exact value rows and binds named limits through current-module counted scalar products. It rejects use before definition, ambiguity, wrong type spelling, invalid reversals, missing or malformed constants, and forged windows before publication. `LoopBodyValues.w` owns exact visible-name and source-type joins. `ResolvedLoopBodyProducts.w` publishes exact monotonic local bases, one physical-width row per accepted body statement, closed opcodes, and literal or unique prior-local operands for direct signed and Boolean declarations, type-checked assignments, Boolean and literal comparison assertions, checked updates, borrowed word and byte reads and writes, and immutable byte-view reads. Unsupported or ambiguous body rows publish nothing. `DirectStatementProducts.w` emits root declarations, returns, and literal or local assertions, merges each exact physical local width into the statement table, and maps named operands and output types through planned starts. Signed and Boolean returns publish their exact result type into the function descriptor. Void functions publish no fabricated result type or slot and receive one canonical implicit `RETURN`. Unsupported direct return types fail before publication. Exact direct instruction widths feed every later loop target. `LoopInstructionProducts.w` emits canonical limit, comparison, iteration check, direct body, and back-edge instruction bytes from a private rebased copy after validating the complete extent. Planned emission corrects each provisional scalar and packed-buffer body coordinate against its statement start without moving parameters below the containing loop boundary. Its signed/Boolean declaration-assertion-assignment-update fixture, including Boolean literals and prior locals, matches stage 0 byte for byte. Its word and byte fixtures match stage-0 opcode order, parameter loans, local types, and exact enclosing-local operands. Loop-private scratch coordinates remain product-local. `LoopNestedBlockProducts.w` emits source-independent one-arm signed local equality and less-than guard windows after exact child-link validation. `LoopNestedLoopProducts.w` measures a complete nested loop tree before writing code, applies each preceding frame shift once, and keeps nested windows inside the root callable product. The admitted two-level artifact matches stage 0 byte for byte. `LoopCallProducts.w` publishes canonical zero- through seven-argument signed, Boolean, and void calls with typed evaluation and transfer locals mapped from defining value products, one exact physical-width row per call and source statement, planned statement starts for all call temporaries, exact target parameter checks, and stable target-identity relocations at planned instruction rows. `LoopBackEdgeProducts.w` requires exact entry/back-edge ownership state and rejects any body loan not released before the jump, including both branch targets, while the published body rows remain unchanged. `LoopLocalTypeProducts.w` publishes the matching signed and Boolean local-type suffix directly from planned body and nested-control starts. `CallableCoordinateProducts.w` now stages source-ordered physical local, instruction, code, and type coordinates independently of product storage order. `SourceCallableCoordinateProducts.w` joins parameter counts and measured logical, physical, source, and parent statement rows into that plan, which gates structured artifact publication and supplies every loop base. Its bounded two-root fixture includes a nested first root and rejects a logical gap before changing caller rows. Exact artifact evidence also covers a nested first root, work between roots, a second root, a trailing assertion, and a value return. Calls, ownership state, nested blocks, and inverse paths remain. The loops remain structured source control flow rather than recursive rewrites. This is bounded physical source-product evidence, not a closure-wide compilation claim. Reused output storage is cleared before emission, including alignment padding. The compiled product decodes its canonical function table and reports exact function and maximum local-register counts. `CompiledFunctionProducts.w` validates exact type windows, contiguous forward and inverse code, and every instruction through `InstructionForms.w`. Unknown executable opcodes fail. `FunctionProductIdentities.w` binds exact type and code digests to signature, ordered callable dependency, aggregate, and ownership identities. `LocalCallRelocations.w` maps local call and uncall operands to stable signature identities and rejects missing function targets before publication. `ImportedCallRelocations.w` verifies linked cross-module calls against public target signature identities and rejects private targets. `SourceCallProducts.w` resolves pre-link unqualified names and arities, applies local shadowing, rejects ambiguous imports, and binds each copied call token to its narrowest exact source statement. Its production form consumes packed direct-dependency rows and the copied callable-name product. Dependency source is not in the API, and staged call rows publish only after complete ambiguity validation. Exact matching also requires ordered parameter types and loan modes, result type, and effects. Qualified matching is restricted to the written dependency rank. `CompiledBodyArchive.w` retains validated source-local artifacts in one bounded 16 MiB immutable closure arena. `CountedFunctionProducts.w` appends closure-wide function and instruction windows while preserving artifact ranks. `RelocationIdentities.w` binds ordered local and imported targets into each callable body identity. Aggregate construction operands relocate to unique WIP-0046 rows and their aggregate module-product identity. Canonical instructions derive owner creation, move, drop, shared-loan, and function-boundary release products. Source-backed events atomically retain their statement, planned instruction, destination local, and source local, while synthetic releases retain a distinct boundary coordinate. Each function's canonical ownership identity is bound into its callable body identity. Stage 0 predeclares nominal identities, so recursive record and mutually recursive record/variant descriptor graphs lower canonically. Callable dependency views pack only public local or locked external products in header rank. Exact matching consumes those packed views without dependency source. `LinkedInstructionCode.w` emits closure-ordered code, rebases local calls by the owning module's final function base, and atomically rewrites validated imported targets. `CallableFunctionRows.w` maps stable callable and imported identities to unique final function rows. `AggregateDescriptorRows.w` assigns per-kind final IDs and resolves stable module aggregate references. `LinkedLocalTypes.w` rewrites owner-scoped nominal local types to those final IDs. `LinkedFunctionSection.w` emits exact descriptors and final local-type rows after validating code and type extents. `CompiledStringProducts.w` decodes exact source-local string ranges. `LinkedStringSection.w` sorts and deduplicates those counted ASCII bootstrap names and publishes source-to-final IDs. `CompiledGlobalProducts.w` retains split 64-bit initial values. `LinkedAggregateSections.w` emits globals and all four aggregate kinds with final string, type, and descriptor rows. `CompiledFunctionNames.w` maps source-local names through the final string table. `LinkedManifestSection.w` rebases the root entry through its counted function window. `LinkedContainer.w` assembles required and optional sections under a sorted format 1.0 directory, verifies every extent and padding byte, and returns the output length only after structural verification. `CanonicalProductEmitter.w` writes final sections and returns an immutable plan. container publication is a separate lifetime so callers may first drop large source and product windows. The native product-link fixture uses that production boundary to rebuild a complete local-call, global, and aggregate artifact byte for byte without a host `Program` object, runs `verifyArtifact` before publishing its length, and then passes the independent stage-0 reader. `CompiledProofProducts.w` rebases counted names and subjects. `LinkedProofSection.w` emits canonical certificate rows, including split negative arguments. The complete fixture covers a generated reversible result-slot inverse and a mixed-owner imported call rewritten after owner-local emission. `compileSourceModuleProductWithImports` preserves a complete primitive local class, while `compileCallableModuleProductWithImports` compiles counted ranges. both rewrite resolved call ranges, including qualified spelling, to imported signature-only self-recursive stubs. Primitive stub generation consumes frozen type, loan, effect, and parameter-window products and has no dependency-source input. Closure type publication keeps complete primitive signatures available beside explicitly marked nominal peers. `retainLocalFunctionProduct` validates and excludes stub and compiler-added function suffixes. `IdentityRelocationEmitter.w` resolves every fixture relocation identity through `CallableFunctionRows.w` before changing one code operand. numeric source targets do not enter final emission. Production uses the same path with WIP-0045 signature identities. WIP-0048 owns complete canonical section and container emission. `SourceAggregateProducts.w` first publishes atomic record, variant, case, and member source products while the local lease is live. Primitive and mutually recursive local nominal member types resolve in the same atomic product. Scalar fixed-array member types publish deduplicated structural descriptors in encounter order. `AggregateSourceProjection.w` blanks validated local aggregate declarations without moving call offsets before primitive body compilation. `ImportedNominalProducts.w` resolves direct public aggregate names from counted artifact strings. Qualification binds dependency rank and equal unqualified matches stay ambiguous. `AggregateOwnerProjections.w` maps instruction-local create, move, loan, release, and drop events to unique aggregate and member rows before ownership verification. `LinkedLocalTypes.w` resolves validated temporary nominal projections to final descriptor IDs. `AggregateOperandProjections.w` resolves temporary construction operands to aggregate rows and stable product identities. `ImportedNominalStubs.w` emits collision-checked record and variant declarations in target-row order and publishes owner-scoped temporary source-code projections. `CompiledAggregateLayouts.w` validates `.wbc` directories and decodes bounded record, array, slice, variant, case, and member rows. `AggregateIdentities.w` binds package, module, artifact, an ordered direct-dependency identity list, counts, and validated rows under a domain-separated SHA-256 identity. `AggregateDependencyProducts.w` packs header-ranked local and locked external identities and fails before copying when one is unavailable. `CountedAggregateLayouts.w` appends one immutable artifact at a time and rebases closure-wide aggregate, case, and member windows. `AggregateTypeResolution.w` resolves source-local nominal member codes to unique owner/type rows. `AggregateLoanVerifier.w` checks move, shared-loan, mutable-loan, and release streams against member owners and rejects escaping loans before publication. Private callables stay local and direct edges count public callables in header rank. The physical closure publishes 1,335 callable products with peak source count one. `ProductRootSource.w` rewrites only the executable root against completed products. It never reads dependency source. `CountedConstantExecutor.w` compiles a 257-module forwarding closure without `BoundedGraphPlan`, retaining the leaf value 41 and matching the corresponding stage-0 normalized root artifact byte for byte. `SmallClosureExecutor.w` carries exact seven-import counted fixtures into the differential executor. Direct constants, a redundant DAG, mixed executable owners, and private helper edges match stage 0 from package and manifest inputs. The bridge is conformance scaffolding, not the production closure ceiling. A mismatched identity publishes nothing. `NativeBootstrapModulesIdentity.w` calls the same parser rather than maintaining a conformance-only metadata dialect. A 513th archive entry fails before hashing or mutation. Core ranged SHA-256 covers every block in the 16 MiB physical evidence ceiling.

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

Modules, externals, and imports are sorted and unique. Every local import resolves, every external import is declared, every local module is reachable from the root, the local graph is acyclic, source paths are unique, and each source identity must match the file inside the canonical compiler archive. The bounds are 10,000 local modules, 10,000 external modules, and 100,000 direct imports. `NativeBootstrapModulesIdentity.w` now covers one through 512 sorted local modules, zero through sixty-four externals, and up to 3,072 imports with unique paths, complete binding, rooted reachability, and cycle detection. It also enforces strict names and paths, exact canonical bytes, and fail-closed identity publication. A 257-module chain crosses the former local ceiling. A source guard pins the check before a 513th append without buying a long rejection fixture. Nine-, ten-, and thirteen-module DAGs over sixty-four externals pin executable coverage at 512, 576, and 768 imports. Sorted module and external tables use bounded binary lookup. A source guard test pins the check before a 3,073rd append without buying another long rejection fixture. Its 262,144-byte input budget covers the current 334-module, 1,600-import, 151,149-byte compiler closure, whose stage-0 identity the native executable reproduces in 60,824,980 transitions. It does not claim the full graph ceiling. A bound written in a comment allocates no table. This manifest records the graph actually trusted for bootstrap. Directory enumeration is not a module system.

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

See WIP-0007 for the bootstrap process. The [package and build reference](packages.md) defines canonical package, lock, repository, and artifact-set identities.
