# WIP-0054: Native source-product artifact integration

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler compiler, bytecode, linker, and bootstrap maintainers |
| Created | 2026-08-13 |
| Updated | 2026-08-13 |
| Area | Self-hosting compiler, source products, artifact emission, bootstrap closure |
| Depends on | WIP-0045, WIP-0046, WIP-0047, WIP-0048, WIP-0049, WIP-0050, WIP-0051, WIP-0052 |
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
- [x] `CallableBlockPlans.w` joins each local callable to exactly one root block plus contiguous callable-local block and direct-statement windows. It validates owners, root parents, depths, local ordinals, complete coverage, and caller-output atomicity.
- [ ] Direct and structured-loop instruction windows compose in exact source order.
- [ ] Signature, direct-statement, and loop local types compose into one exact callable window.
- [ ] Call, aggregate, ownership, and proof identities survive composition without numeric pre-link IDs.
- [ ] One complete source-local module artifact emits directly from products.
- [ ] `CoreParsing.w` matches stage 0 byte for byte and enters `CompiledBodyArchive.w`.
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
