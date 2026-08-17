# WIP-0102: Compact empty imported-target views

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, call products, bounded storage |
| Depends on | WIP-0054, WIP-0059, WIP-0087, WIP-0101 |
| Supersedes | Full-capacity empty imported-target workspaces |
| Superseded by | None |

## Summary

Represent an empty imported call-target view with one-element carrier buffers. Local structured compilation no longer allocates full 4,096-target row, name, identity, parameter, and qualifier capacities when `importedTargetCount` is zero.

Nonempty imported target views retain every canonical capacity check. Relocation output remains fully sized because a local-only module may still publish local call rows.

## Problem

Both local structured compiler wrappers created full imported-target workspaces before calling the common structured compiler. An empty archive view reserved 1,802,240 bytes. An empty local-source view reserved 1,835,008 bytes, including callable effects.

The common compiler then validated those unread capacities in three places:

1. the archive adapter,
2. the structured compiler entry, and
3. the source call-target table.

Zero imported targets made every imported row, name byte, parameter row, identity byte, and qualifier row unread. Repeated full allocation and duplicate validation retained storage and semantic authorities without a product extent.

## Storage rule

The archive adapter now allocates 64 bytes for seven one-element empty carriers. The local-source adapter allocates 32,832 bytes for the same carriers plus the required 4,096 callable-effect rows.

`compileStructuredSourceModuleWithTargets` owns imported-view capacity validation. When `importedTargetCount` is nonzero, it requires exact capacities for target rows, parameter rows, names, identities, qualifier names, qualifier starts, qualifier lengths, and dependency ranks. When the count is zero, it reads none of those carriers.

`SourceCallTargetTable.w` no longer repeats capacity checks already completed by its only structured compiler caller. It still validates every output table capacity and publishes from staged rows only after complete local and imported target validation.

## Relocations

The compact view does not shrink `publishedRelocations`, `publishedRelocationOwners`, or `publishedRelocationIdentities`. A local-only module can call another local callable. WIP-0101 exercises that case and retains one exact forwarded Boolean result call.

Imported target count and relocation count therefore remain independent product extents.

## Atomicity

A nonempty imported view with any noncanonical capacity traps before target-table construction. An empty view admits no imported target reads. Local call discovery, argument binding, code emission, relocation publication, artifact verification, and output publication remain unchanged.

No successful output exposes capacity tails. Failure publishes neither target rows nor artifact bytes.

## Bootstrap identities

The compiler archive contains 2,969,475 bytes and has SHA-256 `a6910a3c260ea3d67029dc971ef502bc75f06ba565bf53f6b67774217b39f7f5`. All four dependent package locks name that archive. The package manifest identity remains `e83091ee70e165f76eefcb2135d2b9620af0906f39affb8a0013e9e60bf894c2`.

The bootstrap module manifest remains 173,627 bytes with 373 modules, two externals, and 1,833 imports. Its SHA-256 is `73100fb3b9ce6fc2e03bcd4d4dc10e9e3ecf4b2d3927f52bbf7ce844a0c52504`. Native validation halts after 72,223,230 transitions under the unchanged 73,000,000-transition ceiling. Wheeler-native SHA-256 retains its 33,239,462-transition count because manifest length is unchanged.

## Evidence

`NativeCompilerStructuredComparisonSourceProductExampleTest` exercises the compact local-source adapter with no imported targets. `NativeCompilerNamedBooleanReturnKindsPhysicalProductExampleTest` exercises the compact archive adapter while retaining a local Boolean call relocation.

`NativeCompilerPhysicalClosureExampleTest` compares every selected artifact, validates retained functions and relocations, links the exact 96-product subset, repeats publication, and rejects malformed footer and relocation products. It passes in 17 minutes and 1 second, down from 17 minutes and 38 seconds, under the unchanged twenty-minute deadline.

The linked container remains byte-identical with SHA-256 `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] Empty archive target views use one-element carriers.
- [x] Empty local-source target views use one-element carriers.
- [x] Callable-effect rows retain their exact 4,096-row capacity.
- [x] Local relocation outputs retain their exact capacities.
- [x] Nonempty imported target views retain canonical capacity checks.
- [x] The target-table builder no longer duplicates input capacity authority.
- [x] Local and imported target result semantics remain unchanged.
- [x] Every physical artifact remains byte-identical to stage 0.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Dependent locks and bootstrap graph fixtures name current products.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Shrink relocation outputs with imported target count

Rejected. Local calls can publish relocations when imported target count is zero.

### Retain full arrays as defensive scratch

Rejected. The empty extent has no legal read. Unused capacity is not evidence.

### Validate capacities in every consumer

Rejected. The structured compiler entry owns the imported view contract. Duplicate checks drift and add source work.

### Add a new validation module

Rejected. A new callable or module would perturb physical product coordinates and linked-container identity for a storage-only refactor.

## References

- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0059](WIP-0059-imported-source-call-target-products.md)
- [WIP-0087](WIP-0087-bounded-direct-product-publication.md)
- [WIP-0101](WIP-0101-direct-boolean-return-classifier-adoption.md)
