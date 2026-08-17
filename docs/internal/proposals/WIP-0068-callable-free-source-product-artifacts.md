# WIP-0068: Callable-free source-product artifacts

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-15 |
| Updated | 2026-08-15 |
| Area | Self-hosting compiler, artifact emission, physical closure |
| Depends on | WIP-0048, WIP-0049, WIP-0054 |
| Supersedes | Parser projection for callable-free physical modules |
| Superseded by | None |

## Summary

Emit canonical library artifacts directly for physical modules that declare no callable bodies. Compile-time constants and identity tables remain source products. They do not create runtime globals or synthetic functions.

The physical closure now sends every callable-free module through one bounded artifact path. Seventeen compiler authorities leave `compileSourceModuleProductWithImports` without entering the structured statement pipeline.

## Problem

A callable-free module still needs a valid `.wbc` artifact. The artifact carries the module program name, one `$library` entry, empty global and nominal-type sections, one empty function descriptor, and one `RETURN` instruction. WIP-0098 selects this builder before allocating target and relocation workspaces.

The old closure projected source and invoked `compileMinimalCore` to produce those fixed sections. Running the complete structured callable pipeline would remove the parser retry, but it would allocate statement, loop, call, ownership, inverse, and proof products for a module that owns none of them. That route also forced zero-callable input through contracts written for one or more source callables.

## Contract

A callable-free source artifact is a pure function of:

1. the immutable archive source range
2. one validated classical class name
3. canonical `.wbc` 1.0 section rules

The emitter publishes these exact strings in lexical order:

1. `$library`
2. the class name

It publishes no source callable, parameter, result, local type, proof, relocation, runtime global, record, array, slice, or variant row. The canonical module emitter adds the sole `$library` descriptor and `RETURN` instruction.

A module enters this path only when its counted callable product is zero. Source text cannot override that count. Modules with one or more callables continue through structured products or the remaining legacy route.

## Implementation

`ArchiveStructuredSourceModuleCompiler.w` checks the counted callable extent before allocating structured metadata. For zero callables it:

- validates the archive-owned class-name range
- stages the two canonical strings
- allocates explicit empty callable, result, type, and code products
- calls `publishClassicalSourceModuleArtifact` with `callableCount=0`
- verifies and hashes the complete artifact before publication

`SourceModuleProductArtifact.w` admits zero source callables while retaining one mandatory synthesized library function. `NativeCompilerPhysicalProductSource` selects the route from `moduleCallableCounts[physicalOwner] == 0`.

The ordinary structured compiler still requires one or more source callables. Callable-free support does not weaken callable, inverse, proof, call-target, or coordinate products.

## Bounds

- source ranges remain at most 32,768 bytes
- string storage remains at most 32,768 bytes
- the private empty-product arena is 140,000 bytes with nine allocations
- output remains one 32,768-byte caller buffer and one 32-byte identity buffer
- publication retains the canonical 16 MiB closure archive ceiling

## Failure behavior

Reject before publication when:

- the callable count is negative or above the source profile bound
- the selected module has no unique classical class name
- either canonical string exceeds its bounded storage
- an allegedly empty callable, type, code, proof, or relocation extent is nonempty
- the assembled artifact fails canonical verification
- the computed identity cannot publish with the artifact

Failure changes no artifact bytes, identity bytes, body count, or retained-product count.

## Acceptance

- [x] `publishClassicalSourceModuleArtifact` admits zero source callables.
- [x] The archive compiler bypasses structured products before their allocation.
- [x] The artifact contains only the canonical library function and empty semantic sections.
- [x] `AssignmentCallIdentities.w` matches stage 0 byte for byte through the native path.
- [x] All 17 callable-free physical compiler modules use the same route.
- [x] The complete 96-product physical closure matches stage 0 byte for byte.
- [x] The linked 228-function container verifies and executes.
- [x] Callable-bearing structured contracts retain their nonempty callable requirement.

## Rejected alternatives

### Run empty modules through every structured product

Rejected. Zero work does not justify allocating five MiB of irrelevant products for each module.

### Keep parser projection for constants

Rejected. Compile-time constants already have counted products, and the runtime artifact contains none of them.

### Emit no function section

Rejected. Canonical library artifacts require one entry function and one terminal `RETURN`.

## References

- [WIP-0048](WIP-0048-canonical-native-product-linker.md)
- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
