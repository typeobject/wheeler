# WIP-0098: Early callable-free archive publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, bounded storage |
| Depends on | WIP-0054, WIP-0068, WIP-0087, WIP-0097 |
| Supersedes | Empty call-target staging for callable-free archive modules |
| Superseded by | None |

## Summary

Publish callable-free archive modules before allocating call-target and relocation workspaces. The 17 callable-free physical compiler authorities now enter their dedicated artifact builder directly from `compileStructuredArchiveModule`.

The resulting artifacts remain byte-identical. The complete physical closure falls from 17 minutes and 37 seconds to 16 minutes and 32 seconds under the unchanged twenty-minute deadline.

## Problem

WIP-0068 added a bounded callable-free artifact path inside `compileStructuredArchiveModuleWithTargetView`. Its caller still allocated two empty regions before reaching that branch:

- 1,802,240 bytes across imported target rows, parameter rows, names, identities, and qualifier rows, and
- 16,384 bytes across relocation rows, owners, and identities.

A module with zero callables cannot name a local or imported call instruction. These regions had no readable extent and no semantic consumer. Allocating and clearing them 17 times retained dead call scaffolding in the direct physical transaction.

## Fast path

`compileStructuredArchiveModule` checks `callableCount` before creating either empty region. A zero count calls `compileCallableFreeArchiveModule` with the exact archive range and quarantined artifact and identity buffers.

The callable-free builder still:

1. finds exactly one classical class name in the bounded source range,
2. publishes canonical `$library` and class-name strings,
3. passes exact empty local callable, type, and code products to the artifact builder,
4. emits the canonical library entry plus empty global and aggregate sections,
5. hashes the complete staged artifact,
6. verifies the final artifact, and
7. publishes only after all checks pass.

Callable-bearing local modules keep the full target-view path. Imported-target compilation keeps its explicit target and relocation products.

## Validation boundary

The skipped buffers were internal to `compileStructuredArchiveModule`. No caller supplied them, and the callable-free builder never read them. Source, class-name, artifact, identity, and publication validation remain on the selected path.

A nonzero callable count follows the prior allocation and validation path unchanged. The optimization does not infer callable count from source text or artifact output.

## Bootstrap identities

The source change produces a 2,968,928-byte compiler archive with SHA-256 `bbf634b19ec5fa1738991e988a65584996e75a0b02ae071e297518bae7c2ebae`. All four dependent package locks name that archive. The package manifest identity remains `e83091ee70e165f76eefcb2135d2b9620af0906f39affb8a0013e9e60bf894c2`.

The bootstrap module manifest remains 173,585 bytes with 373 modules, two externals, and 1,832 imports. Its SHA-256 is `29a7968928bc345658b8aaca7a175ec07abb67da914d5a2937359efcc312d38e`. Native validation halts after 72,194,824 transitions under the unchanged 73,000,000-transition ceiling.

## Evidence

`NativeCompilerCallableFreePhysicalProductExampleTest` compiles a representative callable-free authority and compares every artifact byte with stage 0. It passes in 4 minutes and 44 seconds.

`NativeCompilerPhysicalClosureExampleTest` compiles all direct and parser-backed physical products, compares complete artifacts, validates retained functions and relocations, links the exact 96-product subset, repeats publication, and rejects malformed footer and relocation products. It passes in 16 minutes and 32 seconds.

The linked container remains byte-identical with SHA-256 `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] Zero-callable archive modules allocate no target-view workspace.
- [x] Zero-callable archive modules allocate no relocation workspace.
- [x] All 17 callable-free physical authorities retain byte-exact artifacts.
- [x] Callable-bearing modules retain the full target and relocation path.
- [x] Final artifact verification remains mandatory.
- [x] Failed publication exposes no staged bytes.
- [x] The complete physical closure remains below its fixed deadline.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Dependent package locks name the current compiler archive.
- [x] Bootstrap manifest size, graph counts, identity, and transition budget are pinned.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Allocate one-word placeholder target arrays

Rejected. The target-view method deliberately validates canonical capacities. A callable-free artifact has no target view and should not fabricate one.

### Cache empty regions across module products

Rejected. Shared mutable scratch would widen ownership and rewind scope for data with no consumer.

### Infer emptiness from an absent call scan

Rejected. Closed callable products own `callableCount`. Source scanning is neither required nor authoritative.

### Raise the closure deadline

Rejected. Removing dead allocation work recovers margin without weakening evidence.

## References

- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0068](WIP-0068-callable-free-source-product-artifacts.md)
- [WIP-0087](WIP-0087-bounded-direct-product-publication.md)
- [WIP-0097](WIP-0097-projection-free-direct-physical-routing.md)
