# WIP-0049: Bounded native source-product compilation

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler compiler, module-product, aggregate, ownership, and bootstrap maintainers |
| Created | 2026-08-09 |
| Updated | 2026-08-15 |
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

The source-product compiler needs one explicit rule: local source may be read while its work-slot lease is live. dependency source may not. Everything crossing an edge is a counted product.

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

The generated declaration is compile-time scaffolding. Final emission resolves its descriptor through `AggregateDescriptorRows.w`. no synthetic name or temporary descriptor ID survives.

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
- [ ] Every physical compiler module publishes one source-local product artifact. The counted physical closure now compiles seventy-nine modules directly from immutable local archive ranges. Twenty-four own their scalar declarations locally, including `LoopBodyOpcodes.w` and `LoopBodyLayouts.w`. Another fifty-five consume direct imported scalar products. WIP-0124 routes `CallArguments.w` directly and selects exact source parameters, reborrow opcodes, and scalar-move opcodes from closed products. `LocalTypeEncoding.w` freezes imported type codes and emits each fixed-width row without retaining its former callable dependency. The latest comparable product is `ResultSlotVerifier.w`, which owns fixed-width field decoding locally instead of retaining an external callable dependency. Their dependency imports are removed only after values, types, visibility, qualification, and ambiguity have resolved. Each artifact enters `CompiledBodyArchive.w` under its physical module owner before the ordered seventy-nine-product prefix matches stage 0 byte for byte. Thirteen subsequent physical modules resolve imported calls from copied callable names, packed direct-dependency rows, and frozen primitive signature products. The ninth uses checked local addition behind a signed less-than guard after an imported call result. The tenth compiles `CallForms.w`, freezes Boolean call signatures, and keeps packed wide-call classification inside the retained module so every relocation target is already in the selected physical set. The eleventh compiles `VoidCallOperands.w` after source validity becomes an explicit gap and packed digits become prior locals. The twelfth compiles `HelperResultKinds.w` after signed and nonsigned local-return tests become disjoint call guards. The thirteenth compiles `AssignmentCallOperands.w` after packed traversal becomes bounded tail recursion, source validity becomes a positive gap, and helper-call results bind before branch returns. Stub source ends with one canonical ASCII space after the class brace, giving the scanner a bounded terminator without changing semantic tokens. Source-local Boolean mutation now admits equality, local less-than, and reversed literal less-than guards. Resolution binds both prior locals before code generation, and malformed target types publish no artifact. Their signature-stub artifacts are retained as intermediate products, yielding 96 framed artifacts. `CoreParsing.w`, reversible `ReversibleTokenCoordinates.w`, `ManifestSyntax.w`, `AggregateSourceProjection.w`, `TypeKinds.w`, `WideReturnSources.w`, `LocalTypeEncoding.w`, `ResultSlotVerifier.w`, `ResolvedLocalLoopOperands.w`, `BooleanDeclarationKinds.w`, and `BooleanTokens.w` enter through the direct structured source-product route and carry no projected dependency source or signature stubs. `TypeKinds.w` resolves its imported mask from an exact local source-anchored name product. `WideReturnSources.w` emits complete scalar declarations from local values and module-local constants. `LocalTypeEncoding.w` emits root byte mutations from exact physical values. `ResultSlotVerifier.w` emits root byte projections, signed comparison returns, typed byte-view arguments, and forwarded result calls. `ResolvedLocalLoopOperands.w` emits two exact signed arithmetic declarations and returns. `FourArgumentCalls.w` emits exact one-arm Boolean-literal returns under signed equality and less-than conditions. `LiteralComparisonOperations.w`, `ResolvedLocalCopyKinds.w`, `ResolvedLocalLessThanKinds.w`, and `ResolvedLocalLiteralComparisons.w` use the same closed product and retain no projected dependency source. `ResolvedLocalEqualityKinds.w` and `ResolvedLocalInequalityKinds.w` add exact signed computed conditional children. `ResolvedEarlyComparisonKinds.w`, `ResolvedLiteralComparisonKinds.w`, `ResolvedLocalLiteralComparisonSources.w`, `ResolvedLocalPairAssertions.w`, and `ResolvedLongOperations.w` use the same closed range-decoder products. `ResolvedBooleanLiteralAssertions.w`, `ResolvedBooleanLiteralComparisons.w`, and `ResolvedLessThanAssertions.w` add the remaining Boolean-literal and assertion range decoders. `ResolvedLocalAssignments.w` adds exact signed and Boolean assignment ranges plus target-local decoding. `ResolvedLocalConditionalKinds.w` adds exact half-open conditional, negation, assignment, and assignment-value range classification. `ResolvedLocalConditionalOperands.w` adds exact subtraction and modulo decoding across resolved conditional regions. `ResolvedLocalConditionalSources.w` adds exact prior-value, subtraction, and XOR range classification. `ResolvedLocalLoopKinds.w` adds the bounded resolved local-loop column classifier. `ResolvedLocalLoopForms.w` adds exact condition, limit, reversal, direction, and update form decoding. `ResolvedLocalReturns.w` adds signed and Boolean local-return classification and source-local decoding. `ResolvedLocalUpdates.w` adds exact update, named-source, and target-local decoding across add, subtract, and XOR regions. `ResolvedReturnCallKinds.w` adds exact forwarding-call identity, arity, and packed-source products. WIP-0097 removes parser-projected source staging from every migrated direct product. `AssignmentCallArities.w` adds all unresolved named identities and half-open resolved target columns. `AssignmentCallColumns.w` adds exact zero- through seven-argument source identities and resolved target-column bases. `EarlyReturnResultKinds.w` adds exact helper, comparison, signed, and computed guard-result classification. `EarlyReturnSources.w` adds exact helper and comparison guard column boundaries and base-relative source decoding. WIP-0123 closes exact local Boolean call-conditioned literal returns and routes `OpcodeKinds.w` and `ResolvedEarlyResultKinds.w` without projection. WIP-0135 carries signed constant children through a separate value column and routes `EarlyReturnKinds.w` directly. WIP-0136 adds signed literal children, counts earlier call windows in direct branch prefixes, and routes `InstructionForms.w` directly. WIP-0137 routes all nine `HelperSignatures.w` mapping and predicate functions directly from `HelperAbi.w` constant products. WIP-0138 routes `BorrowedIntrinsicShapes.w` directly and completes the 83-module comparable set without parser projection. `IdentifierStarts.w` adds exact ASCII uppercase, underscore, lowercase, and gap classification. `CallArgumentSources.w` adds exact first-local and second-local classification for two-argument call forms. `CallArguments.w` adds exact seven-source selection and typed move or reborrow opcode products. `OneArgumentCalls.w` adds exact argument-source and result-type classification for bounded one-argument calls. `ThreeArgumentCalls.w` adds named and packed identity classification, token offsets, and exact third-source decoding. `VoidCallSourceKinds.w` adds exact unresolved zero- through three-argument void-call classification. `VoidCallKinds.w` adds fixed and packed resolved identity classification, third-source decoding, and exact arity products. `TwoArgumentCallKinds.w` adds all twelve exact result-type, argument-type, and argument-source classifications. `NamedConditionalBases.w` adds exact signed constant child and final returns. `NamedLiteralComparisonKinds.w` adds literal-condition statement classification. `NamedLocalConditionalKinds.w` adds exact positive, negated, assignment, and assignment-value statement classification. `NamedLocalAssignmentKinds.w` adds one leaf Boolean assignment classifier. `NamedLocalConditionalValues.w` adds signed-value conditional classification. `NamedComparisonKinds.w` adds repeated constant-conditioned Boolean return windows. `NamedLocalUpdateKinds.w` and `NamedLongOperations.w` add the named signed-scalar classifier layer. `NamedReturnComparisonOperands.w` adds exact right-local comparison classification. `NamedSignedReturnKinds.w` adds signed equality, inequality, and ordering return classification. `NamedReturnArithmeticKinds.w` adds mixed less-than and equality arithmetic-return classification. `ReturnOpcodeKinds.w` adds exact ambiguous, comparison, and arithmetic literal-right opcode selection. `NamedBooleanReturnKinds.w` adds exact Boolean comparison classifiers and one forwarded local Boolean result call. Seventeen callable-free physical authorities enter through the canonical empty-callable product emitter. `ManifestSyntax.w` also proves canonical lexical function-name insertion for a multi-callable artifact. Decoded local-to-stub calls publish cross-owner relocation rows with the target callable signature identity. Recursive calls inside each stub remain owner-local. Every relocation identity resolves uniquely through the complete callable identity hash to the originating callable product row. Every selected artifact is decoded and its exact source-local function and instruction prefix passes `retainLocalFunctionProduct`. Signature stubs and compiler-added library entries remain outside those counts. A separate bounded lifetime consumes only the immutable artifact stream plus six-byte product and relocation frames. An eight-byte `WPF1` footer binds the version, product count, and relocation count before any product is decoded. It appends each nonempty prefix to closure-wide function and instruction windows, whose final extents match stage 0 exactly. Relocation frames carry the source product, local instruction, target owner, and target-local function. All frames and call opcodes validate before numeric closure function rows publish. `emitResolvedLinkedInstructionCodeAt` then copies closure-ordered instruction records from the immutable artifacts and writes only final call operands. The physical subset emits 193,736 code bytes across 228 functions and 8,286 instructions. Its 5,729 primitive local-type rows pass `LinkedLocalTypes.w`. `CompiledStringProducts.w` validates 444 source-local strings, `LinkedStringSection.w` sorts and deduplicates them to 349 final rows, and retained function-name prefixes resolve to those rows. `LinkedFunctionSection.w` then emits exact named descriptors and type windows. One retained synthetic library entry gives the subset a valid root. `AtomicLinkedContainer.w` stages and verifies a 246,040-byte classical artifact with canonical manifest, string, empty global, empty aggregate, function, and code sections. The second lifetime drops its source and product windows before it hashes and publishes the verified container natively. Two independent runs produce identical bytes and the same SHA-256 identity is `1c0f823871c389bb88ad3df25ae5e4804ecf91ced8ff24e14e71822377047bab`. The independent stage-0 reader accepts all 228 functions, and the synthetic library entry executes to `HALT`. A malformed relocation owner traps before numeric targets, code, or publication. This is complete executable emission for the physical subset, not byte equality for the compiler closure. Closure-wide iteration remains.
- [ ] WIP-0048 emits the complete physical compiler closure from those products.

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

**Invent an unresolved bytecode format.** `.wbc` remains the sole semantic IR. temporary stubs are ordinary verified functions removed before publication.

**Assign nominal IDs from generated names.** Names are scaffolding. Stable aggregate identities and final descriptor rows are authority.

## References

- [WIP-0052: Bounded native structured-loop products](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0135: Exact call-conditioned constant-return products](WIP-0135-exact-call-conditioned-constant-return-products.md)
- [WIP-0136: Exact call-conditioned signed-literal products](WIP-0136-exact-call-conditioned-signed-literal-products.md)
- [WIP-0137: Direct helper-signature adoption](WIP-0137-direct-helper-signature-adoption.md)
- [WIP-0138: Direct borrowed-intrinsic shape adoption](WIP-0138-direct-borrowed-intrinsic-shape-adoption.md)
