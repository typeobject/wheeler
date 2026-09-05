# WIP-0054: Native source-product artifact integration

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler compiler, bytecode, linker, and bootstrap maintainers |
| Created | 2026-08-13 |
| Updated | 2026-09-05 |
| Area | Self-hosting compiler, source products, artifact emission, bootstrap closure |
| Depends on | WIP-0045, WIP-0046, WIP-0047, WIP-0048, WIP-0049, WIP-0050, WIP-0051, WIP-0052, WIP-0055, WIP-0056, WIP-0057, WIP-0067 |
| Supersedes | WIP-0052 physical-closure adoption tasks |
| Superseded by | None |

## Summary

Connect validated source-independent declaration, aggregate, callable, statement, loop, relocation, ownership, and type products directly to the canonical module artifact emitter. The integration must compile `CoreParsing.w`, then every physical compiler module, without feeding projected source back through the bounded scalar-helper parser.

WIP-0052 finished the bounded structured-loop product layer. This WIP owns its use in production artifact construction. The split keeps loop semantics separate from compiler orchestration and makes the remaining self-hosting boundary reviewable.

## Problem

`compileSourceModuleProductWithImports` still projects source, writes callable stubs, and invokes `compileMinimalCore`. That route was useful while the native compiler accepted a small scalar subset. It is now the wrong boundary for product-complete modules.

`CoreParsing.w` exposes the failure. Its loops contain buffer reads, Boolean decisions, nested blocks, writes, and updates. The source-product pipeline already resolves and emits those operations independently. The scalar-helper parser accepts only a single update in a loop body, so reparsing discards the stronger products and traps before publication.

Teaching the scalar-helper parser every product form would create a second frontend. Rewriting loops as recursion would change frame and step behavior. Flattening dependency source would destroy owner and relocation identity. None is acceptable.

## Contract

One source-local module artifact is a pure function of:

1. package and immutable module-source identity
2. validated local declaration and aggregate products
3. callable signatures, effects, parameter loans, and body extents
4. structured statement and loop products
5. source-independent local and imported call relocations
6. aggregate operand and ownership products
7. canonical string, proof, limit, and manifest products
8. exact ordered direct-dependency product identities

Dependency source, host objects, parser retry, filesystem order, and numeric pre-link target IDs are not inputs.

The integrator validates every window and count before writing output. It writes into private bounded staging storage, verifies the complete `.wbc`, computes its identity, and only then publishes length and product rows. Failure leaves caller output, identity, relocation, and archive counts unchanged.

## Integration layers

### Callable plans

For each source-local callable, join the callable product to one root statement block. Validate lexical ownership, statement order, result shape, forward and inverse extents, parameter locals, and the complete local-type suffix. Empty library entry synthesis remains one explicit module-level rule, not a fake source callable.

### Instruction composition

Compose ordinary statement windows and structured-loop windows in source order. Branch and back-edge targets are callable-local instruction ordinals until final code emission. WIP-0067 maps loop values and private windows to exact physical locals before production code emission. Enclosing parameters and locals keep their coordinates.

Call operands remain stable relocation identities through composition. Aggregate operands remain stable owner/type identities. Numeric closure IDs appear only in WIP-0048 final emission.

### Module artifact emission

Feed counted globals, aggregates, functions, local types, code, proofs, and strings to the existing canonical section emitters. The resulting artifact must match stage 0 byte for byte for the shared source profile. The independent stage-0 reader and native verifier both accept it before `CompiledBodyArchive.w` retains it.

### Cutover

Adopt physical modules in closure order. `CoreParsing.w` is first because it exercises two direct multi-statement loops without aggregate noise. `ManifestSyntax.w`, `CompiledBodyArchive.w`, package token utilities, and later compiler modules follow.

WIP-0068 sends callable-free modules directly to the canonical artifact emitter. After every callable-bearing physical module uses product integration, delete product-to-source projection, imported callable source stubs, and the scalar-helper loop retry from the production closure path. Keep a bounded recovery parser only while an accepted recovery seed still names it.

## Bounds

The first integration profile retains current ceilings:

- 64 source statements per callable block
- four nested structured blocks
- 64 source-local callables per module artifact
- seven call arguments
- 65,535 local registers and instructions per function
- 32,768 source bytes per physical module
- 32,768 artifact bytes per source-local physical product
- 16 MiB immutable physical product archive

A bound is checked before allocation, copying, rebasing, or publication. Expansion requires measured closure evidence and a separate patch.

## Failure behavior

Reject before publication on:

- detached, overlapping, reused, or excessively nested blocks
- a statement not owned by exactly one callable and block
- unresolved, ambiguous, late, or mistyped local operands
- a loop limit without one positive bounded value
- a call without one exact signature and relocation identity
- an aggregate operand without one owner-scoped product identity
- mismatched ownership state at a branch, return, or loop back edge
- noncontiguous code or local-type windows
- branch or relocation targets outside their callable or closure
- a section extent, padding byte, count, or identity that fails canonical verification

No fallback reparses source after one of these failures.

## Migration

1. Publish one counted callable-to-root-block plan.
2. Compose direct statements and loop products into one callable instruction window.
3. Publish exact callable local-type windows from signatures and statement products.
4. Carry call, aggregate, and ownership identities through the composed window.
5. Emit one complete source-local module artifact through WIP-0048 section writers.
6. Differentially compile `CoreParsing.w` and retain it in the physical archive.
7. Adopt every remaining physical multi-statement-loop module in closure order.
8. Adopt aggregate and call-heavy physical modules through the same interface.
9. Delete production product-to-source projection, signature-stub source, and parser retry paths.
10. Emit the complete physical compiler closure and perform fixed-point comparison.

## Progress

- [x] WIP-0045 publishes counted module and callable identities.
- [x] WIP-0046 publishes aggregate layouts, identities, dependency products, and final descriptor rows.
- [x] WIP-0047 publishes callable bodies, stable relocations, local types, proof products, and ownership identities.
- [x] WIP-0048 emits and verifies canonical linked sections and complete containers from counted products.
- [x] WIP-0049 retains source-local artifacts and closure-wide function windows without dependency source.
- [x] WIP-0050 and WIP-0051 publish aggregate source and frontend products.
- [x] WIP-0052 publishes direct, nested, call-bearing, ownership-checked structured-loop code and local types.
- [x] The dependency-free `LoopBodyOpcodes.w` and `LoopBodyLayouts.w` authorities compile from immutable archive ranges and are retained in the physical prefix.
- [x] Outer and nested loop products call `LoopBodyInstructionEncoding.w`. `LoopInstructionProducts.w` composes resolved Boolean and literal-comparison guards into the enclosing loop window, rebases descendant locals once, and publishes matching guard and child local types. The nested path owns no private update encoding.
- [x] Buffer products preserve owned and borrowed owner modes through word and byte reads, writes, and indexed copies. Immutable byte-view reads and byte-view-to-buffer copies share the byte opcode path without acquiring write authority. Borrowed paths publish explicit owner temporaries and matching word, byte, or byte-view local types. A complete byte-product source module verifies and matches stage 0 byte for byte.
- [x] The physical `CoreParsing.w` source publishes 25 statements, seven blocks, two loops, 15 owner-scoped values, 14 direct loop leaves, three nested guards, and both named 4,096-iteration limits. `DirectStatementProducts.w` emits its declarations and returns. `CallableSourceComposition.w` interleaves direct and loop code while joining exact signature and local-type rows. `SourceModuleProductArtifact.w` emits the six canonical sections, verifies and hashes the 3,208-byte result, and appends the byte-identical artifact to `CompiledBodyArchive.w`. `SourceValueProducts.w` keeps structured value resolution below the physical token ceiling. It follows source ordinals, measures indexed reads, accepts explicit row coordinates, and treats each callable root independently.
- [x] `CallableBlockPlans.w` joins each local callable to exactly one root block plus contiguous callable-local block and direct-statement windows. It validates owners, root parents, depths, local ordinals, complete coverage, and caller-output atomicity.
- [x] `CallableInstructionPlans.w` composes direct and structured-loop windows by root-statement source ordinal. It publishes callable-local instruction bases, source product selectors, exact byte extents, per-callable totals, and nothing on duplicate, detached, overlapping, or over-limit input.
- [x] `CallableLocalTypePlans.w` composes signature, direct-statement, and loop rows into contiguous owner-local windows. Primitive and nominal codes retain their source product kind and identity. Duplicate, missing, excessive, or reordered locals leave caller rows unchanged.
- [x] `CallableProductIdentityPlans.w` rebases call and aggregate identities through composed instruction windows while carrying callable-level ownership and proof identities. It retains all 32 identity bytes and source-product rows. Numeric closure target IDs do not enter the product.
- [x] `SourceProductArtifact.w` assembles the six mandatory product sections and an optional proof section through the WIP-0048 container emitter. It verifies and hashes the private 32,768-byte artifact before atomically publishing bytes or identity.
- [x] `CoreParsing.w` matches stage 0 byte for byte and enters `CompiledBodyArchive.w`.
- [x] Root direct products emit `bufferLength` declarations for owned or borrowed words, bytes, UTF-8, and immutable byte views. The product preserves the exact source buffer type, emits one signed result, rejects scalar operands before publication, and matches stage 0 byte for byte for byte-view and mutable-byte loans.
- [x] The direct artifact path now admits signed-local Boolean equality declarations and Boolean, local-to-literal, literal-to-local, and local-to-local assertions inside one loop body. `LoopBodyValues.w` owns the shared declaration and assertion products. Encoding, local widths, local types, and rebasing have one authority. A source-independent fixture composes all forms with a bounded literal-plus-local borrowed-word read and a local-plus-local byte-view copy, emits a complete artifact, and matches stage 0 byte for byte. The same artifact path emits a root literal-to-local assertion before ordinary declarations, then embeds one nested loop with exact frame, branch, back-edge, code-window, and local-type coordinates. Direct assertion widths participate in every later branch target. A fifth nested loop, a literal above 65,535, and a mutable-byte sum read fail before artifact publication.
- [x] `StructuredSourceModuleCompiler.w` owns the bounded orchestration from callable body extents, source-independent symbols, signatures, and canonical strings through block, value, loop, direct-statement, local-type, composition, verification, hashing, and artifact publication. `ArchiveStructuredSourceModuleCompiler.w` freezes only the selected local source range, rebases callable bodies, consumes packed imported-value names, applies parameter loans, and builds canonical qualified function names. The production physical archive sends `CoreParsing.w`, reversible `ReversibleTokenCoordinates.w`, `ManifestSyntax.w`, and `AggregateSourceProjection.w` through this route instead of `compileSourceModuleProductWithImports`. Their artifacts are byte-identical to the separately inspected layers and stage 0. The manifest artifact covers void, signed, and Boolean results, root and nested loops, byte-view reads, Boolean conditions, and canonical lexical function-name insertion. The aggregate artifact adds indexed source preflight, sequential root loops, nested controls, mutable-byte writes, and exact physical nested-value products. The 96-product subset links 228 functions and 8,286 instructions into a verified 246,040-byte container with identity `5fc2ddaec2835c516d52d1e8b1254aeaf50789c72d7b42cd0060b026b880ec25`.
- [x] WIP-0055 replaces distributed local and instruction rebasing with one source-ordered callable coordinate product. WIP-0056 supplies exact statement-local extents, and its nested-first sequential-root fixture matches stage 0 through the trailing assertion and return slot. WIP-0063 owns generated inverse integration.
- [x] Signed and Boolean result kinds publish through direct statement, callable composition, and function descriptor products with exact planned return slots.
- [x] Void result kinds publish no fabricated result type or slot. `CallableSourceComposition.w` appends one canonical implicit `RETURN`, and the function descriptor publishes no value-result flag or type. The complete void artifact matches stage 0.
- [x] WIP-0057 composes source call arguments, callable identities, relocations, and ownership rows into the same callable window.
- [x] `ManifestSyntax.w` enters the physical archive through direct products. Its four callables preserve void, signed, and Boolean result identities. Canonical lexical function-name insertion remaps source-ordered descriptors without changing callable coordinates.
- [x] WIP-0067 replaces inferred production loop rebasing with exact physical value, packed operand, nested-condition, and scratch-window products. Logical-coordinate rebasing remains only for isolated product fixtures. Bounded body, nested, loop, and direct-statement failure coordinates identify malformed products before publication.
- [x] `AggregateSourceProjection.w` enters the physical archive through direct products. Its 8,096-byte artifact verifies and matches stage 0 byte for byte.
- [x] WIP-0068 emits callable-free artifacts without parser projection or structured-product allocation. All 17 callable-free physical authorities produce byte-identical canonical library artifacts through one bounded route.
- [x] WIP-0069 emits complete ordinary scalar return relations and rejects statement suffix loss. `TypeKinds.w` resolves its imported mask from an exact name product and matches stage 0 byte for byte. WIP-0049 now supplies packed name bytes without raw source-use discovery.
- [x] WIP-0070 emits complete signed scalar declaration relations and module-local constant products. All nine `WideReturnSources.w` callables match stage 0 byte for byte.
- [x] WIP-0071 emits root byte-buffer mutations and simple constant initializers. All three `LocalTypeEncoding.w` callables match stage 0 byte for byte.
- [x] WIP-0072 emits four-local root byte projections, signed comparison returns, typed byte-view arguments, and forwarded result calls. All seven `ResultSlotVerifier.w` callables match its 6,040-byte stage-0 artifact byte for byte.
- [x] `ResolvedLocalLoopOperands.w` enters through direct scalar declaration and return products. Both callables match its 1,200-byte stage-0 artifact byte for byte.
- [x] WIP-0073 emits exact one-arm root conditional returns with signed less-than or equality conditions and one Boolean-literal child. `FourArgumentCalls.w` matches its five-function, 39-instruction, 1,864-byte stage-0 artifact byte for byte.
- [x] WIP-0074 routes `LiteralComparisonOperations.w`, `ResolvedLocalCopyKinds.w`, `ResolvedLocalLessThanKinds.w`, and `ResolvedLocalLiteralComparisons.w` through direct products. Their 17 functions and 273 instructions match 10,080 stage-0 artifact bytes. One ordered list owns callable-bearing direct-route migration state.
- [x] WIP-0075 extends exact root conditionals with preserved signed and signed binary child returns. `ResolvedLocalEqualityKinds.w` and `ResolvedLocalInequalityKinds.w` match their eight-function, 72-instruction, 3,360-byte stage-0 artifacts byte for byte.
- [x] WIP-0076 routes five bounded range decoders through direct scalar and conditional products. Their 17 functions and 477 instructions match 15,760 stage-0 artifact bytes without dependency-source projection.
- [x] WIP-0077 emits exact ordinary signed constant returns in one local. `NamedConditionalBases.w` matches its three-function, 159-instruction, 4,592-byte stage-0 artifact byte for byte.
- [x] WIP-0078 bounds root-block and conditional token lookups to their source products. The complete physical closure remains byte-identical under its existing evidence deadline.
- [x] WIP-0079 emits exact ordinary signed-literal root and conditional returns in one local. The complete physical closure remains byte-identical without consuming a new direct-route slot.
- [x] WIP-0080 emits exact root Boolean literal, preserved-source, signed less-than, and signed equality declarations. Two- and four-local windows match stage 0 byte for byte.
- [x] WIP-0081 routes `NamedLocalAssignmentKinds.w` through direct conditional and scalar return products. Its two functions and 12 instructions match the 792-byte stage-0 artifact.
- [x] WIP-0082 emits exact ordinary Boolean source-source equality returns and declarations. Mixed equality and Boolean less-than fail before artifact publication.
- [x] WIP-0084 routes `NamedComparisonKinds.w` through repeated direct conditional windows and a final scalar return. Its three functions and 131 instructions match the 4,040-byte stage-0 artifact.
- [x] WIP-0086 routes the named local-update and signed-operation classifiers through direct conditional, constant, and scalar return products. Their six functions and 279 instructions match 8,448 stage-0 bytes.
- [x] WIP-0087 publishes only measured direct product, type, statement-width, and code extents. The complete physical closure retains exact artifact and linked-container bytes under its unchanged deadline.
- [x] WIP-0088 routes `NamedReturnComparisonOperands.w` through direct conditional and final equality products. Its one function and 32 instructions match the 1,328-byte stage-0 artifact.
- [x] WIP-0089 routes `NamedSignedReturnKinds.w` through direct conditional and final equality products. Its three functions and 33 instructions match the 1,608-byte stage-0 artifact.
- [x] WIP-0090 routes `NamedReturnArithmeticKinds.w` through direct less-than, equality, and Boolean child products. Its two functions and 64 instructions match the 2,256-byte stage-0 artifact.
- [x] WIP-0091 routes `NamedLiteralComparisonKinds.w` through seven direct conditional windows and one final equality. Its one function and 53 instructions match the 1,856-byte stage-0 artifact.
- [x] WIP-0092 routes `NamedLocalConditionalValues.w` through seven direct conditional windows and one final equality. Its one function and 53 instructions match the 1,848-byte stage-0 artifact.
- [x] WIP-0093 routes three resolved Boolean and assertion range decoders through direct less-than, subtraction, and child return products. Their nine functions and 87 instructions match 4,672 stage-0 bytes.
- [x] WIP-0094 routes `ResolvedLocalAssignments.w` through direct range guards and target subtraction products. Its four functions and 78 instructions match the 2,912-byte stage-0 artifact.
- [x] WIP-0095 routes `BooleanDeclarationKinds.w` through seven direct conditional windows and one final equality. Its one function and 53 instructions match the 1,840-byte stage-0 artifact.
- [x] WIP-0096 routes `ResolvedLocalLoopKinds.w` through one direct lower-bound guard and final upper-bound comparison. Its one function and 11 instructions match the 776-byte stage-0 artifact.
- [x] WIP-0097 removes unconsumed parser-projected source staging from every direct physical product while preserving exact archive ranges and closed imported-value rows.
- [x] WIP-0098 publishes zero-callable archive modules before allocating empty target and relocation workspaces, recovering physical closure deadline margin without changing artifact bytes.
- [x] WIP-0099 emits exact ordinary `true` and `false` root return products with Boolean local types and fail-closed terminal punctuation.
- [x] WIP-0100 routes `ResolvedLocalLoopForms.w` through direct modulo, division, conditional, and Boolean literal return products. Its four functions and 21 instructions match the 1,392-byte stage-0 artifact.
- [x] WIP-0101 routes `NamedBooleanReturnKinds.w` through exact comparison children and one forwarded local Boolean call. Its three functions and 40 instructions match the 1,800-byte stage-0 artifact.
- [x] WIP-0102 replaces full-capacity empty imported-target workspaces with compact carriers while retaining nonempty capacity checks and local relocation output.
- [x] WIP-0103 routes `ResolvedLocalConditionalOperands.w` through four exact arithmetic child windows and one final subtraction. Its one function and 40 instructions match the 1,592-byte stage-0 artifact.
- [x] WIP-0104 routes `ResolvedLocalReturns.w` through exact signed and Boolean range predicates plus source-local subtraction products. Its three functions and 44 instructions match the 1,880-byte stage-0 artifact.
- [x] WIP-0106 routes `ResolvedLocalUpdates.w` through exact update, source-kind, and target-local range products. Its three functions and 99 instructions match the 3,304-byte stage-0 artifact.
- [x] WIP-0107 routes `ReturnOpcodeKinds.w` through exact imported statement constants and materialized signed return products. Its three functions and 83 instructions match the 2,776-byte stage-0 artifact.
- [x] WIP-0108 routes `BooleanTokens.w` through exact token-hash equality and Boolean literal products. Its one function and 11 instructions match the 752-byte stage-0 artifact.
- [x] WIP-0109 routes `IdentifierStarts.w` through exact uppercase, underscore, lowercase, and gap boundary products. Its one function and 39 instructions match the 1,464-byte stage-0 artifact.
- [x] WIP-0110 routes `CallArgumentSources.w` through exact first-local and second-local call statement identities. Its two functions and 78 instructions match the 2,592-byte stage-0 artifact.
- [x] WIP-0111 routes `OneArgumentCalls.w` through exact argument-source and result-type statement identities. Its four functions and 79 instructions match the 2,840-byte stage-0 artifact.
- [x] WIP-0112 routes `ThreeArgumentCalls.w` through exact named and packed statement identities, token offsets, and third-source decoding. Its five functions and 48 instructions match the 2,192-byte stage-0 artifact.
- [x] WIP-0113 routes `TwoArgumentCallKinds.w` through all twelve exact result-type, argument-type, and argument-source statement identities. Its four functions and 156 instructions match the 4,808-byte stage-0 artifact.
- [x] WIP-0114 routes `ResolvedLocalConditionalKinds.w` through exact half-open conditional, negation, assignment, and assignment-value regions. Its four functions and 100 instructions match the 3,472-byte stage-0 artifact.
- [x] WIP-0116 routes `ResolvedLocalConditionalSources.w` through exact prior-value, subtraction, and XOR regions. Its three functions and 117 instructions match the 3,752-byte stage-0 artifact.
- [x] WIP-0117 routes `EarlyReturnResultKinds.w` through exact helper, comparison, signed, and computed result identities. Its six functions and 80 instructions match the 3,184-byte stage-0 artifact.
- [x] WIP-0118 routes `VoidCallSourceKinds.w` through exact unresolved zero- through three-argument statement identities. Its one function and 25 instructions match the 1,128-byte stage-0 artifact.
- [x] WIP-0119 routes `EarlyReturnSources.w` through exact helper and comparison guard column boundaries and base-relative sources. Its two functions and 107 instructions match the 3,464-byte stage-0 artifact.
- [x] WIP-0120 routes `VoidCallKinds.w` through exact fixed and packed resolved identities, third-source decoding, and arity products. Its three functions and 143 instructions match the 4,280-byte stage-0 artifact.
- [x] WIP-0121 routes `AssignmentCallColumns.w` through exact zero- through seven-argument source identities and resolved target-column bases. Its two functions and 116 instructions match the 3,496-byte stage-0 artifact.
- [x] WIP-0122 routes `AssignmentCallArities.w` through all unresolved named identities and half-open resolved target columns. Its one function and 121 instructions match the 3,528-byte stage-0 artifact.
- [x] WIP-0123 emits exact local Boolean call-conditioned literal returns and routes `OpcodeKinds.w` and `ResolvedEarlyResultKinds.w` directly. Their complete 3,336-byte and 7,728-byte artifacts match stage 0.
- [x] WIP-0124 routes `CallArguments.w` through exact seven-source selection and typed move or reborrow opcode products. Its two functions and 88 instructions match the 2,800-byte stage-0 artifact.
- [x] WIP-0126 routes `NamedLocalConditionalKinds.w` through exact positive, negated, assignment, and assignment-value statement identities. Its four functions and 198 instructions match the 5,912-byte stage-0 artifact.
- [x] WIP-0127 routes `ResolvedReturnCallKinds.w` through exact forwarding-call identity, arity, and packed-source products. Its six functions and 277 instructions match the 8,392-byte stage-0 artifact.
- [x] Every callable-free physical module compiles without dependency source.
- [x] Every physical multi-statement-loop module compiles without dependency source.
- [ ] Every physical compiler module publishes one product-built artifact.
- [ ] Product-to-source projection and signature-stub source leave the production path.
- [ ] The complete physical compiler closure emits, verifies, and reaches a fixed point.

## Acceptance

- Product integration reads no dependency source and does not invoke `compileMinimalCore`.
- Empty through 64-statement loop bodies retain exact source order, types, branches, and relocations.
- Four nested blocks, calls, buffer operations, assertions, updates, and ownership back edges compose.
- Failed composition changes no caller-visible artifact or product count.
- `CoreParsing.w` and every later physical module match stage 0 byte for byte.
- The final compiler artifact verifies independently and recompiles its own source to the same bytes.
- Superseded source projection, stub generation, and scalar loop production paths are deleted.

## Rejected alternatives

### Extend the scalar-helper parser indefinitely

Rejected. It would duplicate source-product resolution and preserve the parser as a second compiler authority.

### Rewrite structured loops as recursive calls

Rejected. It changes frame depth, step accounting, diagnostics, and artifact shape.

### Flatten dependency source and compile one synthetic class

Rejected. It destroys module ownership, visibility, relocation identity, and bounded source lifetimes.

### Link numeric function IDs early

Rejected. Closure order is not a source semantic. Stable product identities must survive until final emission.

## References

- [WIP-0044](WIP-0044-counted-native-compiler-closure-execution.md)
- [WIP-0048](WIP-0048-canonical-native-product-linker.md)
- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
