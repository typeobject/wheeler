# Wheeler compiler

This directory owns the Wheeler-written compiler package. Sources under
`src/main/wheeler` define the scanner, compiler, verifier, codecs, and package driver.
Java does not get a weekend cottage here.

## Package boundary

`compiler/Core.w` owns canonical lowering and artifact verification. `compiler/Driver.w`
owns the stateless source-graph API. `MinimalCompiler.w` is its executable wrapper and
publishes only the verified output range. Identity tools call the same API
instead of maintaining a shadow compiler with a fake moustache.

The package keeps responsibilities narrow:

- `compiler/frontend` owns bounded token, structure, body, and statement parsing.
- `compiler/syntax` owns statement and call shapes.
- `compiler/resolution` owns typed locals, helper calls, operands, and scalar class
  constants.
- `compiler/ir` owns statement, opcode, instruction-form, type, and proof identities.
- `compiler/backend` owns type tables, strings, control flow, returns, and encoding.
- `compiler/Core.w` assembles and verifies one already linked source.
- `compiler/Graphs.w`, `GraphFour.w`, `GraphFive.w`, and `GraphSix.w` coordinate counted frames without topology or helper-arity dispatch.
- `compiler/graphs/SmallStructures.w`, `FourStructures.w`, `Plans.w`, `six/SixPlans.w`, and `seven/Plans.w` build complete rooted acyclic plans for two through seven modules.
- `compiler/graphs/Matrix.w` records canonical edges, roots, root ranks, leaf-first order, visibility, and sharing facts.
- `compiler/graphs/plans/SourceTable.w` owns seven fixed 32,768-byte source slots. Replacement validates before mutation and clears stale tails.
- `compiler/closure/ArchiveSources.w` validates up to 512 sorted package entries and publishes exact path/data offsets only after outer and per-entry SHA-256 checks.
- `compiler/closure/ModuleManifest.w` owns canonical bootstrap-module parsing, binding, cycle rejection, and rooted reachability.
- `compiler/closure/ArchiveModuleSources.w` joins each local source path and identity to one immutable archive range before publication.
- `compiler/closure/PackageTarget.w` validates canonical package metadata and binds the `compiler` tool target to the bootstrap root before closure publication.
- `compiler/packages` owns shared package-manifest syntax, names, paths, semantic versions, and canonical byte layout.
- `compiler/closure/ClosurePlan.w` owns source ranges, import windows and ranks, leaf-first order, and executable-owner bits for up to 512 modules.
- `compiler/closure/ActiveSourceSlots.w` owns eight generation-checked 32,768-byte linked-source leases and destroys bytes on release.
- `compiler/closure/ClosureSchedule.w` stages immutable sources in leaf-first order and publishes per-module slot generations after the complete pass.
- `compiler/closure/ModuleSymbols.w` destroys each staged source after publishing counted scalar declaration products, direct-edge public-symbol counts, and bounded local values.
- `compiler/closure/symbols` owns packed direct-import values and package-bound symbol identities without enlarging the source indexer past its native token window. Resolved scalar module identities bind the package, source, module name, direct dependency products, symbols, resolution bits, and values in leaf-first order. External edges fail closed until locked package product identities exist. The bounded constant evaluator consumes those products for unqualified and qualified expressions. `compiler/closure/products` publishes counted callable signatures, canonical result and parameter type ranges, owner or loan modes, effect bits, result-slot widths, and complete body ranges, rewrites only an executable root against completed scalar products, and compiles arbitrary counted scalar closures without `BoundedGraphPlan` or dependency source. Callable ranges remain archive evidence. Signature identities bind package, owner source, visibility, effects, name, result, and ordered parameter types and loans. Source-local owner, borrowed, mutable-loan, and local-call body products compile to canonical `.wbc` and match stage 0 byte for byte. Compiled products report exact function and maximum local-register counts. `compiler/closure/bodies` decodes exact descriptor, type, forward/inverse, and instruction rows rejects unknown executable opcodes, and binds exact type and code digests to signature, dependency, aggregate, and ownership identities. Local call and uncall operands resolve to stable signature identities before body publication. Linked cross-module calls require public target identities. Pre-link unqualified names and arities apply local shadowing and reject ambiguous imports. Exact product matching includes parameter types, loan modes, result type, and effects. Qualification restricts matching to the written dependency rank. A bounded immutable closure arena retains compiled body artifacts. Counted function windows rebase instruction owners while preserving artifact ranks. Linked instruction emission rebases source-local calls by module function base and atomically rewrites validated imported targets. Stable callable and imported identities map to unique final function rows. Stable aggregate module, kind, and source-type triples map to per-kind final descriptor IDs. Linked local-type windows rewrite owner-scoped nominal codes and exact function-local signed carriers to those IDs. Canonical function descriptors emit only after exact code and type extent validation. Exact source-local string ranges feed counted ASCII bootstrap names that sort, deduplicate, and map to canonical string IDs. Counted globals and aggregate layouts emit with final names, nominal type codes, and descriptor rows. Root manifests and function descriptors resolve names through final string IDs. root entries rebase through counted function windows. Required and optional sections assemble under a verified sorted directory with canonical alignment and zero padding. `compileSourceModuleProductWithImports` preserves a complete primitive local class. `compileAggregateSourceModuleProductWithImports` validates temporary nominal declarations and projections, compiles primitive body portions through nonretained signed carriers, and publishes nominal plus exact function-local carrier projections only after compilation succeeds. `compileCallableModuleProductWithImports` handles counted ranges. Both rewrite resolved qualified or unqualified call ranges and compile against frozen primitive type, loan, effect, and parameter-window products without dependency source and retain only the validated local function prefix. `IdentityRelocationEmitter.w` resolves all imported identities before changing code. `CanonicalProductEmitter.w` separates section emission from verified container publication so callers can drop large product windows between lifetimes. A complete mixed-owner call, global, aggregate, reversible result-slot, and proof fixture uses that boundary to reproduce stage-0 bytes solely from semantic products. WIP-0048 owns complete canonical container emission. Callable body identities bind canonical ordered relocation identities. Aggregate construction operands bind unique layout rows and aggregate product identities. Canonical instructions derive bounded owner and nonescaping-loan event products, whose per-function identities are bound into callable body identities. `compiler/closure/layouts` publishes atomic record, variant, case, and member ranges with primitive, local nominal, and scalar fixed-array type products while local source is leased, projects them into descriptor-compatible rows and copies bounded source-string products into immutable storage, blanks validated local aggregate declarations at stable offsets before primitive body compilation, resolves direct public nominal names from counted artifact strings, maps instruction-local owner events to aggregate and member rows, generates deterministic imported record and variant scaffolding, rewrites resolved nominal ranges after accounting for prior imported-call width changes, resolves temporary callable local types and aggregate construction operands through stable projections, validates canonical `.wbc` products, decodes bounded aggregate, case, and member layouts, and binds them to package, module, artifact, header-ranked local or locked external dependency identities and rows, appends immutable artifacts or descriptor-compatible source products into rebased closure-wide windows while validating and excluding generated aggregate suffixes, resolves local nominal member rows, and checks nonescaping projection loans before owner publication. Header-ranked callable dependency views include only public local or locked external products. Exact matching consumes either product kind without dependency source. Imported-call body linking remains separate.
- `compiler/closure/SmallClosureExecutor.w` bridges exact seven-import counted fixtures to the differential graph executor during migration.
- Focused backend statement, compiler-core, local-type, and scalar-encoding modules keep every physical compiler source below the 32,768-byte native ceiling and within 4,096 semantic tokens.
- `compiler/graphs/plans/GraphExecutor.w` executes constants, direct helpers, mixed direct owners, private helper edges, and the constant-fed helper chain. Dense DAGs, forests, chains, and forks are graph data, not executor identities.
- `compiler/graphs/plans/GraphExecutionOrder.w` selects dependency imports and ready roots without consulting frame order.
- `compiler/graphs/plans/GraphHelperMembers.w` filters repeated executable owners and rotates retained helper groups into canonical order.
- `compiler/graphs/plans/GraphOwnerMetadata.w` carries exact executable-owner order and bounded private-owner name markers.
- `compiler/Driver.w` keeps one small stable API over the graph compilers and core.
- `compiler/backend/results/ResultSlotCodegen.w` owns reversible result-slot entry encoding.
- `compiler/backend/ProgramCodegen.w` emits ordinary helper bodies and package entry code.
- `compiler/closure/layouts/source/instructions/SourceAggregateOperations.w` indexes bounded aggregate constructors and projections without publishing partial ranges. `compiler/closure/layouts/LocalNominalReferences.w` indexes local nominal uses outside declaration bodies, `LocalNominalCarriers.w` rewrites them to compact signed carriers with exact transformed coordinates, `source/carriers/LocalNominalCarrierProjections.w` binds value carriers to function-local coordinates, `CountedLocalNominalCarriers.w` carries them into final linked local-type rewriting. `source/projections/AggregateExpressionProjection.w` replaces outer aggregate expressions with primitive placeholders while preserving source offsets. `AggregatePlaceholderPlacements.w` derives splice ordinals from compiled placeholders. `PrimitivePlaceholderProjection.w` removes those instructions before aggregate composition, and `source/temporaries/SourceStatementProducts.w` derives callable-owned ranges, named values, local counts, and balanced block trees. The block product converts archive coordinates to source-local extents and rejects overlapping callable ranges, detached roots, excess depth, and partial ranges before copying one row. `CallableBlockPlans.w` joins each callable to one root plus contiguous block and direct-statement windows before artifact composition. `CallableInstructionPlans.w` then orders direct and structured-loop code windows by root-statement source ordinal while preserving separate product byte extents and callable-local instruction bases. `CallableLocalTypePlans.w` publishes the matching contiguous signature, direct-statement, and loop type windows without erasing nominal codes or source product identities. `CallableProductIdentityPlans.w` rebases call and aggregate products through those windows and carries ownership and proof identities without numeric closure targets. `SourceProductArtifact.w` passes the six mandatory product sections and an optional proof section through the canonical container emitter, native verifier, and SHA-256 before publication. `DirectStatementProducts.w` emits root declarations and returns. `CallableSourceComposition.w` interleaves direct and structured code and joins exact local types. `SourceModuleProductArtifact.w` turns those products into a canonical source-local module without calling the scalar-helper parser. `SourceLoopProducts.w` validates those block rows and atomically publishes block-grouped statements, signed condition ranges, literal or named limit ranges, parent links, body windows, and depths. `ResolvedLoopProducts.w` binds each signed condition operand to a literal or unique prior local, resolves named limits through counted module-symbol products, and removes source ranges from the retained product. `LoopBodyValues.w` owns callable-value name and type joins. `ResolvedLoopBodyProducts.w` resolves direct signed and Boolean-literal declarations, type-checked signed and Boolean assignments, Boolean and literal comparison assertions, checked local updates, and borrowed-word reads and writes to exact monotonic local bases, closed opcodes, and source-independent operands. `source/temporaries/LoopBufferOperands.w` marks borrowed owners that require explicit reborrow temporaries. `ResolvedLoopBufferProducts.w` resolves direct writes and indexed buffer-to-buffer copies as one typed body product. `source/loops/LoopBodyInstructionEncoding.w` is the sole direct-body byte encoder, local-width owner, and instruction-extent authority for outer and nested loop products. `LoopNestedConditions.w` resolves equality, less-than, and Boolean guards over heterogeneous child windows. `source/loops/LoopInstructionProducts.w` rebases a private copy of each descendant body into the loop frame, composes nested windows, and emits canonical instructions and branch targets byte for byte with stage 0 without changing the resolved rows. `LoopLocalTypeProducts.w` publishes matching frame, guard, and body local types. `LoopNestedBlockProducts.w` emits validated one-arm guard windows at caller-selected code offsets. `LoopCallProducts.w` publishes canonical zero- through seven-argument call code, exact parameter-checked evaluation and transfer types, and target-identity relocations. `LoopBackEdgeProducts.w` requires identical ownership state and releases body loans before each back edge. `AggregateExpressionTemporaries.w` assigns nested expression locals. `source/carriers/SourceCallableTypeProducts.w` retains local nominal signature types independently of carrier source. Aggregate-aware module compilation now applies declaration, expression, local-carrier, callable-stub, and imported-carrier projections in that order. `SourceStatementProducts.w` publishes callable-owned ranges and source ordinals. `SourceValueProducts.w` joins named values in source order, measures indexed reads, and takes explicit statement start and length columns. Flat aggregate rows and structured block rows share one resolver without pretending to have the same layout. Exact splice ordinals come from decoded placeholders. `AggregateFrontendBindings.w` joins those frontend products to exact locals and provisional statement coordinates. `AggregateConstructorTargets.w` resolves local constructor coordinates. `AggregateIndexedOwners.w` binds field-produced and directly typed fixed arrays plus slice destinations to exact structural descriptors. `AggregateProjectionTargets.w` resolves fields and array or slice indexes inside explicit owner windows. `AggregateResolvedOperands.w` joins source-ordered local, descriptor, case, and member products. `ResolvedAggregateOperations.w` admits exact opcodes and operands according to each source kind. `AggregateInstructionComposition.w` merges primitive and aggregate code at validated source-order splice points. Supplemental code archival and counted artifact selectors carry that order into final linked code.
- `compiler/backend/AggregateCodegen.w` emits validated canonical record, variant, fixed-array, and slice instruction forms. `compiler/closure/layouts/source/instructions/AggregateInstructionProducts.w` validates and lowers complete counted operation windows.
- `compiler/verification` owns complete check-before-publication artifact validation.

`wheeler.package.yaml`, its exact lock, and the canonical workspace sources define the
closed build. Generated `vendor/` trees belong to exported offline bundles, not source
control.

## Current recovery profile

The bounded compiler accepts one class with an optional entry or an entryless bounded
helper table. It emits the canonical unqualified `$library` halt entry for a library.
`frontend/helpers/ScalarHelperTables.w` owns bounded helper lookup, duplicate checks,
and call resolution. `ScalarHelperLibraries.w` parses members.
`ScalarHelperParsing.w` assembles declarations. `ScalarHelperCallResolution.w` resolves
one member, `ResolvedHelperValidity.w` checks the active prefix,
`ScalarHelperResolution.w` assembles the complete resolved table, and
`ScalarHelperPrograms.w` constructs the IR. That path accepts zero or one general
helper and one through twenty-three public, private, or unqualified zero- through
sixteen-parameter scalar helpers. A one-member array library no longer needs a dummy
function to convince the table that one is a number. Signed-parameter Boolean and signed helpers may
contain bounded equality or less-than guards, computed signed-local preludes, and up to sixty-four same-module or direct imported Boolean calls with typed
early returns. Sixty-four calls may span all twenty-two helpers from seven direct owners, filling the 256-local window without crossing the 512-instruction ceiling. Call sixty-five fails closed. A final Boolean return may forward one zero-, one-, or two-argument helper call. A Boolean helper-call guard may return another one-argument call over the same or a different prior local. Thirty-two pairs fill the call table. `frontend/statements/EarlyResolution.w` owns early-guard local-index resolution. `frontend/calls/ScalarReturnCallResolution.w` owns final scalar-call argument resolution, while `frontend/statements/OperandValidity.w` keeps focused checks out of `LocalStatements.w` and below the repository line limit. `HelperBody.parameterCount` now drives descriptors, frame layout, call checks, and code generation instead of recovering arity from helper-kind identities. Its bounded sixteen-slot `parameterTypes` column now drives canonical type-table emission. `frontend/helpers/HelperParameterTypes.w` fills signed values, shared UTF-8 and byte-view loans, and mutable byte, word, region, and signed-map loans. Mixed signatures match stage 0. Signed and Boolean locals may initialize from exact zero- through two-argument same-module or direct imported calls with matching primitive argument types. Every loan is reborrowed into the call frame. A helper may also allocate one bounded `bytes` owner through a mutable region loan and mutate it with `setByte`. It may explicitly drop the owner, consume it into a UTF-8 result with `freezeUtf8`, or forward that result through an exact two-argument same-module call. Allocation, owner-advancing mutation, freezing, and destruction use the exact stage-0 move windows. The final drop consumes the owner where the last mutation left it. Manufacturing another move would be tidy, wrong, and therefore tempting. A wrong region type, leaked owner, foreign mutation, freeze, or drop, use after consumption, unsupported UTF-8 signature, mismatched forwarded owner, or second destruction publishes nothing. The core fixed-width four- and eight-byte readers exercise the borrowed two-argument path, and `verification/ResultSlotVerifier.w` reproduces stage 0 through those readers. Signed locals also admit exact three- through seven-prior-primitive-local calls. Each loan uses its canonical reborrow. Five, six, and seven arguments use twelve, fourteen, and sixteen temporary locals and the same number of instructions. Eight fail before publication. Code generation consumes the resolved function identity rather than assuming the first function won by seniority. Final same-module or direct imported calls may forward one through seven signed, fixed-array, or loan parameters with exact argument-type checks and canonical move or borrow opcodes. `backend/calls/ReturnCallCodegen.w` emits the family through one bounded path. Seven arguments use fifteen locals and sixteen instructions. An eighth argument receives no parliamentary hearing. A signed helper may return `bufferLength` directly or bind it to a signed local over UTF-8, byte-view, byte, or word loans. It may also bind or directly return `utf8Scalar` or `utf8Width` from a UTF-8 loan and signed index, bind one indexed byte or word from a byte-view, byte, or word loan, or return that element directly without a ceremonial local. Mutable byte and word loans admit `setByte` and `set`, while mutable signed-map loans admit `put`. Each uses signed key or index and value locals. Signed and Boolean helpers may bind or directly return `mapGet` and `mapHas` from a signed-map loan and signed key. Signed fixed-array owners of one through sixty-four elements may enter helper signatures, move through same-module or direct imported calls, and feed indexed reads. Up to sixteen distinct lengths receive descriptors in first declaration order. The seventeenth is rejected before it can improvise a type identity. Entryless void helpers accept zero through sixteen primitive parameters and either an empty body or those writes. Their type table has no imaginary result local. Void and scalar-result helpers may issue zero- through seven-argument calls to same-module or direct imported void helpers with exact primitive types and canonical reborrows. Four through seven sources use two bounded packed operands. Eight fail before publication. Other intrinsic loan reads and writes remain unfinished. Equality and less-than guards may
return any prior signed local. A signed less-than guard may instead return its parameter
minus, divide by, or reduce modulo one scalar. Unresolved guard widths account for their generated temporaries before later declarations resolve, so a local after three guards does not read register four and call it destiny. A twenty-fourth helper fails
before publication. The checked-in `compiler/backend/calls/CallArguments.w`, `compiler/backend/EncodingWidths.w`, imported-constant `compiler/frontend/intrinsics/BorrowedIntrinsicShapes.w`, `compiler/ir/Opcodes.w`,
`compiler/ir/ProofRules.w`, `compiler/ir/ResolvedStatements.w`,
`compiler/ir/StatementKinds.w`, `compiler/ir/StorageOpcodes.w`, `compiler/ir/TypeCodes.w`,
`compiler/ir/limits/CompilerProgramLimits.w`, imported-function `compiler/verification/ResultSlotVerifier.w`,
`compiler/resolution/returns/WideReturnSources.w`, imported-constant
`compiler/resolution/returns/ReturnOpcodeKinds.w`, imported-constant
`compiler/syntax/assignments/NamedLocalAssignmentKinds.w`, imported-constant
`compiler/syntax/assignments/ResolvedLocalAssignments.w`, imported-constant
`compiler/syntax/assertions/ResolvedBooleanLiteralAssertions.w`, imported-constant
`compiler/syntax/assertions/ResolvedLessThanAssertions.w`, imported-constant
`compiler/syntax/assertions/ResolvedLocalPairAssertions.w`,
`compiler/syntax/booleans/BooleanTokens.w`, imported-constant
`compiler/syntax/booleans/ResolvedBooleanLiteralComparisons.w`, imported-constant
`compiler/syntax/comparisons/NamedComparisonKinds.w`, imported-constant
`compiler/syntax/conditionals/LiteralComparisonOperations.w`, imported-constant
`compiler/syntax/conditionals/NamedConditionalBases.w`, imported-constant
`compiler/syntax/conditionals/NamedLiteralComparisonKinds.w`, imported-constant
`compiler/syntax/conditionals/NamedLocalConditionalKinds.w`, imported-constant
`compiler/syntax/conditionals/NamedLocalConditionalValues.w`, imported-constant
`compiler/syntax/conditionals/ResolvedLiteralComparisonKinds.w`, imported-constant
`compiler/syntax/conditionals/ResolvedLocalConditionalKinds.w`, imported-constant
`compiler/syntax/conditionals/ResolvedLocalConditionalOperands.w`, imported-constant
`compiler/syntax/conditionals/ResolvedLocalConditionalSources.w`, imported-constant
`compiler/syntax/locals/NamedLongOperations.w`, imported-constant
`compiler/syntax/locals/ResolvedLocalCopyKinds.w`, imported-constant
`compiler/syntax/locals/ResolvedLocalEqualityKinds.w`, imported-constant
`compiler/syntax/locals/ResolvedLocalInequalityKinds.w`, imported-constant
`compiler/syntax/locals/ResolvedLocalLessThanKinds.w`, imported-constant
`compiler/syntax/locals/ResolvedLocalLiteralComparisons.w`, imported-constant
`compiler/syntax/locals/ResolvedLocalLiteralComparisonSources.w`, imported-constant
`compiler/syntax/locals/ResolvedLongOperations.w`, imported-constant
`compiler/syntax/loops/ResolvedLocalLoopForms.w`, imported-constant
`compiler/syntax/loops/ResolvedLocalLoopKinds.w`, imported-constant
`compiler/syntax/loops/ResolvedLocalLoopOperands.w`, imported-constant
`compiler/syntax/updates/NamedLocalUpdateKinds.w`, imported-constant
`compiler/syntax/updates/ResolvedLocalUpdates.w`, imported-constant `compiler/ir/OpcodeKinds.w`, imported-constant `compiler/ir/TypeKinds.w`,
imported-constant `compiler/ir/InstructionForms.w`, imported-constant
`compiler/syntax/BooleanDeclarationKinds.w`, `compiler/syntax/IdentifierStarts.w`,
`compiler/syntax/tokens/CompilerTokenLimits.w`, `compiler/syntax/tokens/KeywordTokens.w`, `compiler/syntax/tokens/SourceScalars.w`,
`compiler/syntax/helpers/HelperAbi.w`, imported-constant `compiler/syntax/helpers/HelperSignatures.w`,
mixed-owner `compiler/syntax/helpers/HelperValueKinds.w`, imported-constant
`compiler/syntax/EarlyReturnKinds.w`, imported-constant
`compiler/syntax/EarlyReturnResultKinds.w`, `compiler/syntax/LoopKinds.w`,
`compiler/syntax/loops/LoopBodyOpcodes.w`,
`compiler/closure/layouts/source/carriers/LoopBodyLayouts.w`, imported-constant
`compiler/syntax/calls/CallArgumentSources.w`, imported-constant
`compiler/syntax/calls/OneArgumentCalls.w`, imported-constant
`compiler/syntax/calls/TwoArgumentCallKinds.w`, imported-constant
`compiler/syntax/calls/FourArgumentCalls.w`,
`compiler/syntax/calls/assignment/AssignmentCallArities.w`,
`compiler/syntax/calls/assignment/AssignmentCallCodeWidths.w`,
`compiler/syntax/calls/assignment/AssignmentCallColumns.w`,
`compiler/syntax/calls/assignment/AssignmentCallIdentities.w`,
`compiler/syntax/calls/assignment/AssignmentCallInstructionWidths.w`,
`compiler/syntax/calls/assignment/AssignmentCallLocalWidths.w`,
`compiler/syntax/calls/ThreeArgumentCalls.w`, `compiler/syntax/calls/VoidCallKinds.w`,
`compiler/syntax/calls/VoidCallSourceKinds.w`, mixed-owner
`compiler/syntax/calls/VoidCallSourceWidths.w`, imported-function
`compiler/syntax/calls/void/VoidCallSourceForms.w`, `compiler/syntax/calls/VoidCallWidths.w`,
imported-constant
`compiler/syntax/returns/EarlyReturnSources.w`, imported-constant
`compiler/syntax/returns/NamedBooleanReturnKinds.w`, imported-constant
`compiler/syntax/returns/NamedReturnArithmeticKinds.w`, imported-constant
`compiler/syntax/returns/NamedReturnComparisonOperands.w`, imported-constant
`compiler/syntax/returns/NamedSignedReturnKinds.w`, imported-constant
`compiler/syntax/returns/ResolvedEarlyComparisonKinds.w`, imported-constant
`compiler/syntax/returns/ResolvedEarlyResultKinds.w`, imported-function
`compiler/syntax/returns/EarlyComparisonForms.w`, `compiler/syntax/returns/ResolvedLocalReturns.w`,
and imported-constant `compiler/syntax/returns/ResolvedReturnCallKinds.w` modules compile byte for
byte with stage 0. `EarlyReturnKinds.w` now takes the direct structured-product route: its Boolean
helper result guards an exact signed constant child carried by counted symbol products.
`InstructionForms.w` follows through a distinct signed literal child, with later direct branch
prefixes counting that complete call window. `HelperSignatures.w` also uses direct products for all
nine helper-ABI mapping and predicate functions. `BorrowedIntrinsicShapes.w` closes the comparable
physical set with direct helper-call and width products. Structured imported targets now normalize
loan types and publish imported relocations without relinking local calls. One buffer projection
owner emits exact byte and word reads. `VoidCallSyntax.w` is the first physical module to cross
that direct imported boundary. Assignment-call widths, void-call forms and widths, and the early
comparison form now follow it without signature stubs. `StatementKinds.w` owns 139 unresolved statement identities. `LoopKinds.w` owns six loop-form
identities. `ResolvedStatements.w` owns ninety-two resolved columns. `BorrowedIntrinsicKinds.w`
owns separate source and resolved `bufferLength`, `utf8Scalar`, `utf8Width`, indexed-buffer, and mutable-buffer statement identities. `VoidCallSourceKinds.w` owns and classifies unresolved ordinary void calls. `syntax/calls/void/VoidCallSourceForms.w` aggregates all eight source arities and compiles natively with both executable identity owners. `VoidCallKinds.w` owns resolved identities, arity, and third-source decoding. `VoidCallSourceWidths.w` owns source/local widths. `VoidCallWidths.w` owns resolved instruction and encoded widths. `syntax/calls/assignment/AssignmentCallIdentities.w` owns the disjoint source and target columns for zero- through seven-argument assignment calls. `AssignmentCallArities.w`, `AssignmentCallColumns.w`, and `AssignmentCallKinds.w` own arity, column mapping, and shape. `AssignmentCallLocalWidths.w`, `AssignmentCallInstructionWidths.w`, and `AssignmentCallCodeWidths.w` own the three width units. `AssignmentCallSyntax.w` and `AssignmentCallOperands.w` own measurement and source decoding. Focused resolution and codegen owners enforce exact prior primitive types and canonical reborrows. `backend/mutations/MutationCodegen.w` owns ordinary local mutation emission. Focused frontend syntax, typed resolution, register-shape, call-argument, and backend codegen owners validate, size, resolve, and emit the canonical forms. `backend/calls/ScalarValueCallCodegen.w` owns scalar value-call emission, leaving the general code generator to coordinate rather than collect another staircase. `Tokens.w` now sticks to
lexical work instead of running a parser-IR registry from the back room. Real self-source modules beat motivational slides. One of them now owns conditional base mapping instead of leaving it in the parser's coat pocket. The bar has retained counsel. A modular source may carry up to sixty-four sorted unique direct imports.
The header parser validates exact dotted names and rejects malformed, duplicate, unsorted,
or excess imports before publication. Production closure work begins from one counted, digest-verified package archive index. The one- through seven-import entry points remain differential fixtures and accept every rooted acyclic scalar-constant graph within the frame bound. The single-import path links directly. Two through seven imports use plans that record exact edges, direct roots, root ranks, reachability, visibility, sharing, and leaf-first order. `graphs/plans/GraphExecutor.w` consumes those facts through one counted source table.

The graph executor also links direct helper sets, mixed direct constants and helpers, private helper chains and forks, shared helper DAGs, redundant direct helper leaves, and the constant-fed helper chain. The plan records executable-owner kinds before edge mutation. `graphs/plans/GraphHelperMembers.w` filters repeated owner groups by exact planned identity. `GraphOwnerMetadata.w` carries retained order and writes inert name markers for owners private to the root. `backend/HelperOwners.w` freezes three seven-word columns for `compiler/Core.w`. The helper-arity linkers and source-order network are deleted.

`graphs/plans/SourceTable.w` owns seven fixed 32,768-byte slots. Initialization validates all active sources before writing. Replacement validates before mutation and clears the old tail. The synthetic root has separate storage, so seven imports do not become an eight-node loophole. Exact duplicate declarations and executable owner groups collapse once. A mismatch, eighth executable owner, twenty-third dependency helper, twenty-fourth total helper, or eight-module frame fails before publication. General symbol
resolution remains future work. Entry and helper bodies
admit at most sixty-four statements. Scanner metadata admits 4,096 tokens across a 32,768-byte
physical or linked source window. Linked graph arenas and the counted source selector admit the same
32,768 bytes. Its copy loop uses a sixteen-bit packed limit field. Byte 32,769 traps before mutation.
A four-helper differential crosses the former 16 KiB line, and a padded two-import source pins the
new refusal boundary. The
current slice covers typed signed and Boolean locals,
assertions, assignments, checked scalar operations, calls, results, and narrow explicitly limited
loops.

A class may place one contiguous block of at most 256 `const long` or `const boolean`
declarations around its optional signed state and before its helper or entry. Constants may
initialize that state, including a forward reference when state comes first. Splitting the
constant block around state fails rather than creating two lookup rules. Their bounded
expressions admit decimal, hexadecimal, and binary
integers, Booleans, parentheses, checked arithmetic, `!`, `^`, `&`, `==`, `<`, checked
`rotateRight32`, and forward same-class dependencies. A lookup allows 4,096 evaluation steps, dependency paths stop at
sixty-four declarations, and parentheses stop at depth thirty-two. Cycles, unknown names,
type errors, malformed forms, and arithmetic traps publish nothing.

The resolver substitutes evaluated values into matching local declarations, scalar helper
returns, scalar assignments, checked signed updates including generated reversible helper updates,
one- or two-argument scalar helper calls,
right operands of signed arithmetic and ordering expressions, signed or Boolean equality and
inequality expressions,
signed arithmetic or typed scalar comparison returns, signed or Boolean equality assertions, signed ordering assertions, conditions and their
state-update values, bounded loop conditions and limits, and affine-region byte and allocation
limits. Calls and mutations
may mix constants with prior locals. Helper parameters and locals cannot reuse constant names.
Constants create no global, initializer, lookup, or declaration-order artifact noise. The
native header path accepts direct import declarations. The linker resolves bounded public
scalar constants through unqualified or canonical owner-qualified uses and preserves stage-0
artifact bytes. It covers every rooted tree topology over one through four imports, one
shared-dependency diamond, the five-module direct star, chain, four-leaf fork, three-leaf fork beside a direct import, one chain edge beside three direct imports, a two-leaf fork beside two direct imports, two independent chains beside a direct import, a three-module chain beside two direct imports, a four-module chain beside a direct import, a nested two-leaf fork beside a direct import, two nested fork levels, and a shared diamond with a side leaf, plus the six-module direct star, full chain, five-leaf fork, one three-leaf fork beside two direct imports, one nested two-leaf fork beside two direct imports, one uneven two-branch tree beside two direct imports, one fork beside one chain and one direct import, three independent chains, one three-module chain beside one two-module chain and one direct import, one chain edge beside four direct imports, one two-leaf fork beside three direct imports, one three-module chain beside three direct imports, one four-module chain beside two direct imports, and two independent chains beside two direct imports, plus the seven-module direct star, full chain, six-leaf fork, one chain edge beside five direct imports, one two-leaf fork beside four direct imports, two independent chains beside three direct imports, three independent chains beside one direct import, one three-module chain beside four direct imports, one four-module chain beside three direct imports, one five-module chain beside two direct imports, one six-module chain beside one direct import, one three-module chain beside one two-module chain and two direct imports, two three-module chains beside one direct import, one two-leaf fork beside one two-module chain and two direct imports, one nested two-leaf fork beside three direct imports, one nested three-leaf fork beside two direct imports, one deep nested two-leaf fork beside two direct imports, one uneven nested fork beside two direct imports, two paired nested chains joined below two direct imports, one extended three-branch fork beside two direct imports, one long branch joined with one leaf beside two direct imports, one asymmetric nested fork beside two direct imports, one shared diamond beside three direct imports, one shared diamond with a side leaf beside two direct imports, two serial shared diamonds, one three-leaf fork beside three direct imports, one four-leaf fork beside two direct imports, and one five-leaf fork beside one direct import, while preventing intermediate
exports from reaching the root.
Repeated dependency declarations are deduplicated only when their private token sequences
match exactly. Sharing a name and a hopeful expression does not count. Root collisions with
imported private names, colliding exports, unsupported four-module DAGs, unsupported five-module graphs, other six- and seven-module graphs, graphs with eight or more imports, and general multi-file linking remain stage-0 work until native differential artifacts pin
them down.

The canonical registry also owns `CALL_RESULT_SLOT`, `UNCALL_RESULT_SLOT`,
`RESULT_FILL_CONSTANT`, `RESULT_FILL_SOURCE`, `RESULT_FILL_BINARY`,
`RESULT_FILL_BINARY_SOURCES`, and `RETURN_RESULT_SLOT`. The Wheeler verifier accepts the first canonical signed result-slot
descriptor and generated-inverse proof. The native compiler lowers a `rev long` helper with
up to two signed parameters that returns one signed literal, evaluated constant, preserved
signed parameter, checked operation over either signed parameter and a constant, or checked
operation over two signed parameters. Independent checked operations may bind signed locals before the tail return selects one exact relation. Its entry interleaves one or more result calls with signed checks against literals,
constants, or other results already produced. The emitted function flags, adjacent slot locals, forward
and inverse bodies, call, return, and proof bytes match stage 0 exactly. The bounded
Wheeler interpreter executes both call directions against the same artifact. A committed
VM history remains irrelevant to the generated inverse, as it should unless time travel
has acquired a debugger dependency.

The narrow loop body and local constant graph are deliberate limits, not parser folklore.
Unsupported syntax fails before output publication. Each extension must match stage 0 byte
for byte before the profile claims it.

## Promotion

The temporary Java seed lives in [`../bootstrap/stage0`](../bootstrap/stage0). It compiles
this package into stage 1. Stage 1 must then compile the same sources into a byte-identical
stage 2. Promotion also requires the diverse-bootstrap and provenance evidence from
WIP-0007. A fixed point catches drift. Repetition alone does not exorcise a malicious
ancestor.

Examples consume this package through exact locks. They do not carry compiler copies.
New implementation features land in Wheeler once the recovery profile can express and
test them. Any Java addition needs a concrete stage-crossing reason and a deletion
condition.
