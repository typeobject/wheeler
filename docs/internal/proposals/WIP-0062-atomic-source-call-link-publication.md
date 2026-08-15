# WIP-0062: Atomic source-call link publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and linker maintainers |
| Created | 2026-08-15 |
| Updated | 2026-08-15 |
| Area | Self-hosting compiler, closure linker, publication |
| Depends on | WIP-0048, WIP-0059, WIP-0060, WIP-0061 |
| Supersedes | Closure-publication work split from WIP-0060 |
| Superseded by | None |

## Summary

Stage structured source artifacts, relocation products, retained prefixes, identity resolution, linked sections, and the final container under one bounded transaction. A missing or stale package-bound callable identity must leave every caller-owned output buffer untouched. Successful builds publish only the final container and its identity.

## Problem

WIP-0060 completes the products required to link an imported source call. The structured compiler can publish an independently verified source-local artifact before the closure linker sees every target identity. That artifact is valid intermediate evidence, but it cannot become a public build output if closure identity resolution later fails.

The physical closure linker already stages canonical function, type, string, code, and container sections. The source-product path must enter that same transaction. A driver that publishes the source artifact first and catches a later linker trap would expose verifier scaffolding and violate fail-closed package semantics.

## Products

One source-call link transaction retains:

- the immutable source-local artifact and its package identity
- callable owners and exact owner-local relocation coordinates
- package-bound target identities
- retained local function, type, name, instruction, and code prefixes
- final closure function targets
- canonical linked section lengths and identities
- the verified final container and its SHA-256 identity

The transaction retains these products privately and publishes none of them as build output. It publishes the verified container and its identity together or publishes neither.

## Invariants

- The transaction never treats a verifier stub as a closure function.
- Complete closure callable identities authorize every external relocation.
- A stale, missing, duplicate, private, or mismatched target aborts before caller mutation.
- Dependency, target, call, and archive storage order cannot affect linked bytes.
- The final string, type, function, and code sections contain only retained rows.
- The independent verifier accepts the final container before publication.
- Dependency source is absent from the transaction lifetime.

## Bounds

- 512 source-local artifacts
- 4,096 retained closure functions
- 131,072 retained instructions
- 65,536 relocation events
- 16 MiB immutable artifact archive
- 4 MiB linked code
- 32-byte package, callable, artifact, and container identities

## Implementation

`ImportedStructuredArchiveModuleCompiler.w` now stages the source-local artifact, artifact identity, relocation rows, relocation owners, relocation identities, and closure instruction targets. It decodes the staged artifact, excludes verifier suffix functions, resolves every package-bound target identity, and only then copies those products into caller-owned buffers. A stale target traps while all public buffers still hold their sentinels.

`AtomicLinkedContainer.w` validates canonical section inputs, assembles the complete container in a 16 MiB private arena, verifies it, hashes it, and copies container and identity bytes only after every check passes. `CompiledBodyArchive.w` accepts any positive archive capacity through the 16 MiB ceiling, so a bounded build pays for its admitted product set rather than the ceiling.

The physical-product transaction now allocates its 4 MiB body archive only after package and closure validation. Its second lifetime builds canonical retained string, type, function, and code sections, drops every source and product buffer, and calls `publishAtomicLinkedContainer`. Only the verified container and its identity cross the publication boundary. The transaction does not publish the source-local artifacts, relocation tables, or section archive as build outputs.

## Plan

1. [x] Define one caller-owned staging record for source artifacts and relocation products.
2. [x] Decode and retain every local prefix before any public archive append.
3. [x] Resolve all package-bound identities and rewrite closure instruction targets.
4. [x] Build canonical string, type, function, code, and container sections from retained rows.
5. [x] Verify and hash the complete container.
6. [x] Keep every intermediate private and publish only container and identity bytes in one final copy.
7. [x] Prove stale-identity atomicity and shuffled-storage byte equality.

## Acceptance

- A valid qualified imported call executes through the final linked target.
- Signed, Boolean, and void calls retain exact parameter, result, and local windows.
- Two calls to one imported identity share one final function target.
- No verifier stub descriptor, type row, name, string, instruction, or code byte survives.
- A stale package-bound identity leaves every caller-owned output sentinel unchanged.
- Shuffled dependency, target, call, and archive storage produces byte-identical containers.
- The final container passes the independent reader and verifier without dependency source.

## Rejected alternatives

### Publish the source artifact before linking

Rejected. A valid intermediate artifact is not a valid closure output.

### Delete stubs after container emission

Rejected. Section offsets and identities would already include scaffold bytes.

### Recover from a missing identity with a numeric target

Rejected. Numeric packing is not semantic authority.

## References

- [WIP-0048](WIP-0048-canonical-native-product-linker.md)
- [WIP-0059](WIP-0059-imported-source-call-target-products.md)
- [WIP-0060](WIP-0060-imported-call-stub-and-relocation-products.md)
- [WIP-0061](WIP-0061-qualified-imported-source-calls.md)
