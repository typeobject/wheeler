# WIP-0097: Projection-free direct physical routing

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, source authority |
| Depends on | WIP-0049, WIP-0054, WIP-0087, WIP-0096 |
| Supersedes | Projected source staging for direct physical products |
| Superseded by | None |

## Summary

Stop constructing parser-projected module source for physical modules selected by the direct source-product route. Direct compilation now consumes only the immutable archive source range and closed imported-value products.

Parser-backed physical products retain projected source staging until their callable bodies migrate. Imported callable products retain projection because call discovery and the parser compiler still consume it.

## Problem

The physical closure selected direct compilation only after it had called `writeProductModuleSource`. That helper copied the complete module into a mutable buffer and appended reconstructed imported constant declarations. The direct compiler ignored the buffer and read the exact archive source range instead.

The dead staging path had three costs.

1. It performed source work whose output had no consumer.
2. It preserved parser projection in the successful transaction for modules that had already migrated.
3. It obscured the direct route's source authority during review.

A direct artifact must not depend on an unused parser-shaped shadow of its source.

## Routing rule

The physical closure initializes `physicalSourceLength` to zero. It calls `writeProductModuleSource` only when `directSourceModule` is false.

The imported callable branch asserts that its selected module is not direct before call discovery reads `physicalProductSource`. This assertion closes the only later consumer of the projected buffer.

Direct compilation continues to receive:

- the immutable package archive,
- the exact source start and length for the physical owner,
- callable body ranges and signatures,
- closed local and imported constant rows,
- canonical callable and constant names,
- exact target rows, and
- quarantined artifact and identity buffers.

The route does not omit semantic input. It removes an unconsumed duplicate representation.

## Atomicity

Source projection still occurs before parser-backed compilation and call discovery. A failed projection, call scan, parser compile, direct compile, artifact verification, relocation pass, or linked publication leaves physical output unpublished.

Direct products retain strict final artifact verification. This change does not weaken the `verifyArtifact` gate or expose staged bytes.

## Evidence

`NativeCompilerResolvedLocalLoopKindsPhysicalProductExampleTest` exercises a direct route without projected source staging and compares its complete 776-byte artifact with stage 0. It passes in 4 minutes and 40 seconds.

`NativeCompilerPhysicalClosureExampleTest` exercises all direct and parser-backed physical modules in one transaction. It compares every artifact, validates retained functions and imported relocations, links the exact 96-product subset, repeats publication, and rejects malformed footer and relocation products. It passes in 17 minutes and 37 seconds under the unchanged twenty-minute deadline.

The linked container remains byte-identical with SHA-256 `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] Direct physical products do not call `writeProductModuleSource`.
- [x] Direct physical products read their exact immutable archive ranges.
- [x] Direct products retain closed local and imported constant rows.
- [x] Parser-backed products retain projected source until migration.
- [x] Imported callable products reject accidental direct routing before call discovery.
- [x] Every selected physical artifact remains byte-identical to stage 0.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Keep projection as defensive input

Rejected. The direct compiler has no parameter for projected source. Dead work cannot defend a consumer that does not exist.

### Route projected source into direct compilation

Rejected. That would replace the exact archive range with a reconstructed parser representation and restore duplicate authority.

### Remove projection for parser-backed products

Rejected. Those products still consume the buffer. Their projection disappears when their callable bodies migrate.

### Infer the route from source length

Rejected. `DIRECT_SOURCE_MODULES` and zero callable count remain the explicit route authorities. A zero length records the absence of projection, not module semantics.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0087](WIP-0087-bounded-direct-product-publication.md)
- [WIP-0096](WIP-0096-direct-local-loop-classifier-adoption.md)
