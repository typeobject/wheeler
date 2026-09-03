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
- [ ] Every physical compiler module publishes one source-local product artifact. The counted physical closure now compiles seventy-nine modules directly from immutable local archive ranges. Twenty-four own their scalar declarations locally, including `LoopBodyOpcodes.w` and `LoopBodyLayouts.w`. Another fifty-five consume direct imported scalar products. WIP-0124 routes `CallArguments.w` directly and selects exact source parameters, reborrow opcodes, and scalar-move opcodes from closed products. `LocalTypeEncoding.w` freezes imported type codes and emits each fixed-width row without retaining its former callable dependency. The latest comparable product is `ResultSlotVerifier.w`, which owns fixed-width field decoding locally instead of retaining an external callable dependency. Their dependency imports are removed only after values, types, visibility, qualification, and ambiguity have resolved. Each artifact enters `CompiledBodyArchive.w` under its physical module owner before the ordered seventy-nine-product prefix matches stage 0 byte for byte. Fifteen subsequent physical modules resolve imported calls from copied callable names, packed direct-dependency rows, and frozen primitive signature products. No physical module retains a signature-only stub. WIP-0141 routes three assignment-call width products directly. WIP-0142 routes three void-call form and width products directly. WIP-0143 routes `EarlyComparisonForms.w` directly. WIP-0149 routes `AssignmentCallKinds.w` directly. The ninth uses checked local addition behind a signed less-than guard after an imported call result. The tenth compiles `CallForms.w`, freezes Boolean call signatures, and keeps packed wide-call classification inside the retained module so every relocation target is already in the selected physical set. The eleventh compiles `VoidCallOperands.w` after source validity becomes an explicit gap and packed digits become prior locals. The twelfth compiles `HelperResultKinds.w` after signed and nonsigned local-return tests become disjoint call guards. The thirteenth compiles `AssignmentCallOperands.w` after packed traversal becomes bounded tail recursion, source validity becomes a positive gap, and helper-call results bind before branch returns. Stub source ends with one canonical ASCII space after the class brace, giving the scanner a bounded terminator without changing semantic tokens. Source-local Boolean mutation now admits equality, local less-than, and reversed literal less-than guards. Resolution binds both prior locals before code generation, and malformed target types publish no artifact. Their signature-stub artifacts are retained as intermediate products. `VoidCallSyntax.w` follows as one direct imported structured product with one closure relocation. WIP-0411 adds direct `AssignmentCallSyntax.w` and `WideLocalCalls.w` products and closes the transitive `CallForms.w` target. WIP-0413 adds direct `EarlyUtf8CallForms.w`. WIP-0414 splits signed results, forwarding membership, local-result membership, and their statement identities into focused owners and brings the set to 106 framed artifacts. WIP-0415 retains `ManifestAssertions.w` as artifact 107. WIP-0416 admits Boolean source children and retains `ManifestProfile.w` as artifact 108. WIP-0417 adds exact UTF-8 scalar and width declarations to structured loop products without changing the retained set. WIP-0418 follows with focused literal multiplication and two-local addition declarations. WIP-0419 adds local-right equality and less-than guards plus exact Boolean literal assignment in nested loop bodies. WIP-0420 uses those products to retain `ManifestTokens.w` as artifact 109. WIP-0421 follows with `Names.w` as artifact 110 and replaces nested name-control trees with total state machines. WIP-0422 retains `Paths.w` as artifact 111 with explicit escape, component, and dot state. WIP-0423 splits semantic-version scalar classification. WIP-0424 extends that retained owner into `SemverCoreValidation.w` as artifact 112 and splits prerelease policy before the verifier bound. WIP-0425 retains imported-call `SemverPrereleaseValidation.w` as artifact 113. WIP-0426 splits and retains `SemverCoordinates.w` as artifact 114. WIP-0427 retains imported-call `SemverIdentifierComparison.w` as artifact 115. WIP-0428 splits release precedence and retains imported-call `SemverCoreComparison.w` as artifact 116. WIP-0429 retains wrapped-call `SemverPrereleaseComparison.w` as artifact 117. WIP-0430 retains `SemverReleaseComparison.w` as artifact 118, WIP-0431 closes `Semver.w` as artifact 119, WIP-0432 retains `PackageCanonicalCoordinates.w` as artifact 120, WIP-0433 retains `PackageCanonicalLineKinds.w` as artifact 121, WIP-0435 retains `PackageCanonicalIndent.w` as artifact 122, WIP-0436 retains `PackageCanonicalProfile.w` as artifact 123, WIP-0437 retains `PackageCanonicalTokenState.w` as artifact 124, WIP-0438 retains imported-call `PackageManifestKinds.w` as artifact 125, and WIP-0439 retains `PackageManifestRows.w` as artifact 126. WIP-0440 isolates `PackageManifestBrackets.w`, WIP-0441 retains it through direct structured source products as artifact 127, WIP-0442 retains imported-call `PackageManifestKeys.w` as artifact 128, and WIP-0443 raises the physical owner profile to 256 while retaining `PackageManifestSelectorState.w` as artifact 129. WIP-0444 retains `PackageManifestRanges.w` as artifact 130, WIP-0445 through WIP-0447 retain selector composition as artifacts 131 through 133, WIP-0448 through WIP-0453 retain header composition as artifacts 134 through 139, WIP-0454 through WIP-0456 retain dependency fields as artifacts 140 through 142, WIP-0457 and WIP-0458 retain capability fields as artifacts 143 and 144, and WIP-0459 through WIP-0462 retain target prefix, name, root, and initial coordinates as artifacts 145 through 148. WIP-0463 completes the target-row coordinate surface in artifact 148, WIP-0464 retains target test policy as artifact 149, WIP-0465 retains optional module-name policy as artifact 150, WIP-0466 retains source-selector path policy as artifact 151, WIP-0467 completes selector order and root coverage in that product, WIP-0468 retains source-row coordinates, WIP-0469 moves test policy into the callable set while retaining target-tail keys, and WIP-0470 and WIP-0471 retain dependency and capability coordinates, WIP-0472 assigns collection ordering to field owners, and WIP-0473 completes retained target value coordinates, WIP-0474 retains top-level collection sections, WIP-0475 retains empty-section classification, WIP-0476 retains complete dependency rows, and WIP-0477 retains complete capability rows. WIP-0478 raises archive intake, WIP-0479 carries the wider coordinates through module binding and closure planning, and WIP-0480 retains the required target head as artifact 159. `CoreParsing.w`, reversible `ReversibleTokenCoordinates.w`, `ManifestSyntax.w`, `AggregateSourceProjection.w`, `TypeKinds.w`, `WideReturnSources.w`, `LocalTypeEncoding.w`, `ResultSlotVerifier.w`, `ResolvedLocalLoopOperands.w`, `BooleanDeclarationKinds.w`, and `BooleanTokens.w` enter through the direct structured source-product route and carry no projected dependency source or signature stubs. `TypeKinds.w` resolves its imported mask from an exact local source-anchored name product. `WideReturnSources.w` emits complete scalar declarations from local values and module-local constants. `LocalTypeEncoding.w` emits root byte mutations from exact physical values. `ResultSlotVerifier.w` emits root byte projections, signed comparison returns, typed byte-view arguments, and forwarded result calls. `ResolvedLocalLoopOperands.w` emits two exact signed arithmetic declarations and returns. `FourArgumentCalls.w` emits exact one-arm Boolean-literal returns under signed equality and less-than conditions. `LiteralComparisonOperations.w`, `ResolvedLocalCopyKinds.w`, `ResolvedLocalLessThanKinds.w`, and `ResolvedLocalLiteralComparisons.w` use the same closed product and retain no projected dependency source. `ResolvedLocalEqualityKinds.w` and `ResolvedLocalInequalityKinds.w` add exact signed computed conditional children. `ResolvedEarlyComparisonKinds.w`, `ResolvedLiteralComparisonKinds.w`, `ResolvedLocalLiteralComparisonSources.w`, `ResolvedLocalPairAssertions.w`, and `ResolvedLongOperations.w` use the same closed range-decoder products. `ResolvedBooleanLiteralAssertions.w`, `ResolvedBooleanLiteralComparisons.w`, and `ResolvedLessThanAssertions.w` add the remaining Boolean-literal and assertion range decoders. `ResolvedLocalAssignments.w` adds exact signed and Boolean assignment ranges plus target-local decoding. `ResolvedLocalConditionalKinds.w` adds exact half-open conditional, negation, assignment, and assignment-value range classification. `ResolvedLocalConditionalOperands.w` adds exact subtraction and modulo decoding across resolved conditional regions. `ResolvedLocalConditionalSources.w` adds exact prior-value, subtraction, and XOR range classification. `ResolvedLocalLoopKinds.w` adds the bounded resolved local-loop column classifier. `ResolvedLocalLoopForms.w` adds exact condition, limit, reversal, direction, and update form decoding. `ResolvedLocalReturnStatements.w` owns the columns, `ResolvedLocalResultKinds.w` classifies signed results, and `ResolvedLocalReturns.w` retains aggregate membership and source decoding. `ResolvedLocalUpdates.w` adds exact update, named-source, and target-local decoding across add, subtract, and XOR regions. `ForwardedHelperResultStatements.w` owns forwarding identities, `ForwardedHelperResultKinds.w` classifies membership, and `ResolvedReturnCallKinds.w` retains arity and packed-source products. WIP-0097 removes parser-projected source staging from every migrated direct product. `AssignmentCallArities.w` adds all unresolved named identities and half-open resolved target columns. `AssignmentCallColumns.w` adds exact zero- through seven-argument source identities and resolved target-column bases. `EarlyReturnResultKinds.w` adds exact helper, comparison, signed, and computed guard-result classification. `EarlyReturnSources.w` adds exact helper and comparison guard column boundaries and base-relative source decoding. WIP-0123 closes exact local Boolean call-conditioned literal returns and routes `OpcodeKinds.w` and `ResolvedEarlyResultKinds.w` without projection. WIP-0135 carries signed constant children through a separate value column and routes `EarlyReturnKinds.w` directly. WIP-0136 adds signed literal children, counts earlier call windows in direct branch prefixes, and routes `InstructionForms.w` directly. WIP-0137 routes all nine `HelperSignatures.w` mapping and predicate functions directly from `HelperAbi.w` constant products. WIP-0138 routes `BorrowedIntrinsicShapes.w` directly and completes the 83-module comparable set without parser projection. WIP-0139 normalizes imported parameter loans, filters local relocations, measures declaration calls, and unifies byte and word projection products. WIP-0140 uses that path for `VoidCallSyntax.w`, adding the first direct imported structured product after the comparable set. WIP-0141 moves all three assignment-call width products from signature stubs to the same direct boundary. WIP-0142 follows with `VoidCallSourceForms.w`, `VoidCallSourceWidths.w`, and `VoidCallWidths.w`. WIP-0143 follows with `EarlyComparisonForms.w`. WIP-0149 later adds `AssignmentCallKinds.w`. WIP-0144 keeps its direct imported instruction-target table private and removes one MiB of dead caller staging. WIP-0145 publishes at most 512 touched instruction-target rows instead of copying all 131,072 rows. WIP-0146 publishes only active imported target and parameter rows. WIP-0147 does the same for the combined local and imported source-call target table. WIP-0148 limits qualifier and referenced-target publication to active rows. WIP-0150 limits source value and local-coordinate publication to active rows. WIP-0151 follows for resolved body, nested-control, and frame-width rows. WIP-0153 limits structured source statement, condition, and loop publication to active rows. WIP-0154 follows for flat callable statements and balanced block trees. WIP-0155 limits resolved loop, physical body, nested-control, and loop-local type publication to active rows. WIP-0156 limits source-call layout and call-owning width publication to active rows. WIP-0157 follows for call relocation, identity, local-type, and width outputs. WIP-0159 limits callable composition and local-type publication to active rows. WIP-0160 follows for callable and source-product coordinates. WIP-0161 and WIP-0162 limit call-instruction and callable-return publication to active rows. WIP-0163 follows for reversible result, inverse, relocation, and proof products. WIP-0164 limits decoded function and instruction publication to canonical artifact counts. WIP-0165 bounds source-artifact publication by canonical length, WIP-0166 limits archive-source index publication to validated entries, and WIP-0167 preserves the exact boundary through structured direction selection. WIP-0168 routes `CallForms.w` directly and removes its generated signature stubs. WIP-0169 follows for `HelperResultKinds.w`, WIP-0170 follows for `HelperValueKinds.w`, WIP-0171 follows for `VoidCallOperands.w`, and WIP-0172 routes `AssignmentCallOperands.w` directly and removes the final signature stub. WIP-0188 limits loop instruction staging to active body, condition, and call rows. WIP-0190 bounds qualified-call width staging by the closed statement count. WIP-0192 bounds direct result-type staging and publication by the closed function count. `IdentifierStarts.w` adds exact ASCII uppercase, underscore, lowercase, and gap classification. `CallArgumentSources.w` adds exact first-local and second-local classification for two-argument call forms. `CallArguments.w` adds exact seven-source selection and typed move or reborrow opcode products. `OneArgumentCalls.w` adds exact argument-source and result-type classification for bounded one-argument calls. `ThreeArgumentCalls.w` adds named and packed identity classification, token offsets, and exact third-source decoding. `VoidCallSourceKinds.w` adds exact unresolved zero- through three-argument void-call classification. `VoidCallKinds.w` adds fixed and packed resolved identity classification, third-source decoding, and exact arity products. `TwoArgumentCallKinds.w` adds all twelve exact result-type, argument-type, and argument-source classifications. `NamedConditionalBases.w` adds exact signed constant child and final returns. `NamedLiteralComparisonKinds.w` adds literal-condition statement classification. `NamedLocalConditionalKinds.w` adds exact positive, negated, assignment, and assignment-value statement classification. `NamedLocalAssignmentKinds.w` adds one leaf Boolean assignment classifier. `NamedLocalConditionalValues.w` adds signed-value conditional classification. `NamedComparisonKinds.w` adds repeated constant-conditioned Boolean return windows. `NamedLocalUpdateKinds.w` and `NamedLongOperations.w` add the named signed-scalar classifier layer. `NamedReturnComparisonOperands.w` adds exact right-local comparison classification. `NamedSignedReturnKinds.w` adds signed equality, inequality, and ordering return classification. `NamedReturnArithmeticKinds.w` adds mixed less-than and equality arithmetic-return classification. `ReturnOpcodeKinds.w` adds exact ambiguous, comparison, and arithmetic literal-right opcode selection. `NamedBooleanReturnKinds.w` adds exact Boolean comparison classifiers and one forwarded local Boolean result call. Seventeen callable-free physical authorities enter through the canonical empty-callable product emitter. `ManifestSyntax.w` also proves canonical lexical function-name insertion for a multi-callable artifact. Decoded local-to-stub calls publish cross-owner relocation rows with the target callable signature identity. Recursive calls inside each stub remain owner-local. Every relocation identity resolves uniquely through the complete callable identity hash to the originating callable product row. Every selected artifact is decoded and its exact source-local function and instruction prefix passes `retainLocalFunctionProduct`. Signature stubs and compiler-added library entries remain outside those counts. A separate bounded lifetime consumes only the immutable artifact stream plus six-byte product and relocation frames. An eight-byte `WPF1` footer binds the version, product count, and relocation count before any product is decoded. It appends each nonempty prefix to closure-wide function and instruction windows, whose final extents match stage 0 exactly. Relocation frames carry the source product, local instruction, target owner, and target-local function. All frames and call opcodes validate before numeric closure function rows publish. `emitResolvedLinkedInstructionCodeAt` then copies closure-ordered instruction records from the immutable artifacts and writes only final call operands. The physical subset emits 395,440 code bytes across 478 functions and 16,589 instructions. Its 13,288 primitive local-type rows pass `LinkedLocalTypes.w`. `CompiledStringProducts.w` retains 796 source-local strings after removing verifier stubs, and `LinkedStringSection.w` sorts and deduplicates them to 638 final rows, and retained function-name prefixes resolve to those rows. `LinkedFunctionSection.w` then emits exact named descriptors and type windows. One retained synthetic library entry gives the subset a valid root. `AtomicLinkedContainer.w` stages and verifies a 505,856-byte classical artifact with canonical manifest, string, empty global, empty aggregate, function, and code sections. The second lifetime drops its source and product windows before it hashes and publishes the verified container natively. Two independent runs produce identical bytes and the same SHA-256 identity is `44e503b4acba2b6bb606fe6fa0699e74332911f2a478e2981dc4585e387199ff`. The independent stage-0 reader accepts all 478 functions, and the synthetic library entry executes to `HALT`. A malformed relocation owner traps before numeric targets, code, or publication. This is complete executable emission for the physical subset, not byte equality for the compiler closure. Closure-wide iteration remains.
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
- [WIP-0139: Structured imported-call product foundations](WIP-0139-structured-imported-call-product-foundations.md)
- [WIP-0140: Direct void-call syntax physical product](WIP-0140-direct-void-call-syntax-physical-product.md)
- [WIP-0141: Direct assignment-call width products](WIP-0141-direct-assignment-call-width-products.md)
- [WIP-0142: Direct void-call form and width products](WIP-0142-direct-void-call-form-and-width-products.md)
- [WIP-0143: Direct early-comparison form product](WIP-0143-direct-early-comparison-form-product.md)
- [WIP-0144: Private structured instruction-target staging](WIP-0144-private-structured-instruction-target-staging.md)
- [WIP-0145: Sparse structured instruction-target publication](WIP-0145-sparse-structured-instruction-target-publication.md)
- [WIP-0146: Sparse imported-target publication](WIP-0146-sparse-imported-target-publication.md)
- [WIP-0147: Sparse source-call target-table publication](WIP-0147-sparse-source-call-target-table-publication.md)
- [WIP-0148: Sparse referenced call-target publication](WIP-0148-sparse-referenced-call-target-publication.md)
- [WIP-0149: Direct assignment-call kind product](WIP-0149-direct-assignment-call-kind-product.md)
- [WIP-0150: Sparse source-value publication](WIP-0150-sparse-source-value-publication.md)
- [WIP-0151: Sparse loop-body publication](WIP-0151-sparse-loop-body-publication.md)
- [WIP-0153: Sparse source-loop publication](WIP-0153-sparse-source-loop-publication.md)
- [WIP-0154: Sparse source-block publication](WIP-0154-sparse-source-block-publication.md)
- [WIP-0155: Sparse physical-loop publication](WIP-0155-sparse-physical-loop-publication.md)
- [WIP-0156: Sparse source-call layout publication](WIP-0156-sparse-source-call-layout-publication.md)
- [WIP-0157: Sparse call-emission publication](WIP-0157-sparse-call-emission-publication.md)
- [WIP-0159: Sparse callable-composition publication](WIP-0159-sparse-callable-composition-publication.md)
- [WIP-0160: Sparse callable-coordinate publication](WIP-0160-sparse-callable-coordinate-publication.md)
- [WIP-0161: Sparse call-instruction publication](WIP-0161-sparse-call-instruction-publication.md)
- [WIP-0162: Sparse callable-return publication](WIP-0162-sparse-callable-return-publication.md)
- [WIP-0163: Sparse reversible-evidence publication](WIP-0163-sparse-reversible-evidence-publication.md)
- [WIP-0164: Sparse compiled-function publication](WIP-0164-sparse-compiled-function-publication.md)
- [WIP-0165: Bounded source-artifact publication](WIP-0165-bounded-source-artifact-publication.md)
- [WIP-0166: Sparse archive-source index publication](WIP-0166-sparse-archive-source-index-publication.md)
- [WIP-0167: Bounded structured-artifact publication](WIP-0167-bounded-structured-artifact-publication.md)
- [WIP-0168: Direct call-form physical product](WIP-0168-direct-call-form-physical-product.md)
- [WIP-0169: Direct helper-result kind physical product](WIP-0169-direct-helper-result-kind-physical-product.md)
- [WIP-0170: Direct helper-value kind physical product](WIP-0170-direct-helper-value-kind-physical-product.md)
- [WIP-0171: Direct void-call operand physical product](WIP-0171-direct-void-call-operand-physical-product.md)
- [WIP-0172: Direct assignment-call operand physical product](WIP-0172-direct-assignment-call-operand-physical-product.md)
- [WIP-0188: Sparse loop-instruction staging](WIP-0188-sparse-loop-instruction-staging.md)
- [WIP-0190: Bounded qualified-call width publication](WIP-0190-bounded-qualified-call-width-publication.md)
- [WIP-0192: Bounded direct result-type publication](WIP-0192-bounded-direct-result-type-publication.md)
- [WIP-0411: Closed assignment and wide-call source products](WIP-0411-closed-assignment-and-wide-call-products.md)
