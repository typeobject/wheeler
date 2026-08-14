# WIP-0054: Native source-product artifact integration

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler compiler, bytecode, linker, and bootstrap maintainers |
| Created | 2026-08-13 |
| Updated | 2026-08-14 |
| Area | Self-hosting compiler, source products, artifact emission, bootstrap closure |
| Depends on | WIP-0045, WIP-0046, WIP-0047, WIP-0048, WIP-0049, WIP-0050, WIP-0051, WIP-0052, WIP-0055, WIP-0056 |
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

Compose ordinary statement windows and structured-loop windows in source order. Branch and back-edge targets are callable-local instruction ordinals until final code emission. Loop-private locals rebase once against the callable's exact prior local count. Enclosing parameters and locals keep their coordinates.

Call operands remain stable relocation identities through composition. Aggregate operands remain stable owner/type identities. Numeric closure IDs appear only in WIP-0048 final emission.

### Module artifact emission

Feed counted globals, aggregates, functions, local types, code, proofs, and strings to the existing canonical section emitters. The resulting artifact must match stage 0 byte for byte for the shared source profile. The independent stage-0 reader and native verifier both accept it before `CompiledBodyArchive.w` retains it.

### Cutover

Adopt physical modules in closure order. `CoreParsing.w` is first because it exercises two direct multi-statement loops without aggregate noise. `ManifestSyntax.w`, `CompiledBodyArchive.w`, package token utilities, and later compiler modules follow.

After every physical module uses product integration, delete product-to-source projection, imported callable source stubs, and the scalar-helper loop retry from the production closure path. Keep a bounded recovery parser only while an accepted recovery seed still names it.

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
- [x] The direct artifact path now admits signed-local Boolean equality declarations and Boolean, local-to-literal, literal-to-local, and local-to-local assertions inside one loop body. `LoopBodyValues.w` owns the shared declaration and assertion products. Encoding, local widths, local types, and rebasing have one authority. A source-independent fixture composes all forms with a bounded literal-plus-local borrowed-word read and a local-plus-local byte-view copy, emits a complete artifact, and matches stage 0 byte for byte. The same artifact path emits a root literal-to-local assertion before ordinary declarations, then embeds one nested loop with exact frame, branch, back-edge, code-window, and local-type coordinates. Direct assertion widths participate in every later branch target. A fifth nested loop, a literal above 65,535, and a mutable-byte sum read fail before artifact publication.
- [x] `StructuredSourceModuleCompiler.w` owns the bounded orchestration from callable body extents, source-independent symbols, signatures, and canonical strings through block, value, loop, direct-statement, local-type, composition, verification, hashing, and artifact publication. `ArchiveStructuredSourceModuleCompiler.w` freezes only the selected local source range, rebases callable bodies, consumes packed imported-value names, applies parameter loans, and builds canonical qualified function names. The production physical archive sends `CoreParsing.w` through this route instead of `compileSourceModuleProductWithImports`. Its artifact is byte-identical to the separately inspected layers and stage 0. The 93-product subset links 222 functions and 7,814 instructions into a verified 232,256-byte container with identity `a14f7f74062baef68ce4ff024f5350a8feb655f3ae0f0d2d7502a8b348ee9cea`.
- [ ] WIP-0055 replaces distributed local and instruction rebasing with one source-ordered callable coordinate product. WIP-0056 supplies exact statement-local extents before its first closure fixture covers sequential root loops, a nested-first root, direct statements between roots, a trailing assertion, and the return slot.
- [ ] Mixed void, signed, and Boolean result kinds plus implicit void returns publish through the product artifact emitter.
- [ ] Source call arguments, callable identities, relocations, and ownership rows compose into the same callable window.
- [ ] `ManifestSyntax.w` and `AggregateSourceProjection.w` enter the physical archive through direct products.
- [ ] Every physical multi-statement-loop module compiles without dependency source.
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
