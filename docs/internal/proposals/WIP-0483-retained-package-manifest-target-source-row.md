# WIP-0483: Retained package-manifest target source row

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-02 |
| Updated | 2026-09-02 |
| Area | Self-hosting, package manifests, source selectors |
| Depends on | WIP-0466, WIP-0468, WIP-0482 |
| Supersedes | Inline source-row bounds, dash, and selector composition |
| Superseded by | None |

## Summary

Retain one physical owner for the syntactic and scalar policy of a package target source row. The aggregate parser now asks one bounded question before applying collection order, root coverage, capacity, and publication policy.

## Contract

`manifestTargetSourceRowValid` projects the selector coordinate, rejects an out-of-range row before token reads, requires the canonical sequence dash, and validates one quoted logical-path selector. It returns false for collection termination and malformed rows. The caller decides whether termination is valid from the number of rows already consumed.

Ordering, root coverage, source-table capacity, and publication remain in the collection loop. They depend on prior rows or caller-owned storage and do not belong to one-row syntax.

The target directory had again reached its ten-file ceiling. The source policy, source coordinates, and new row composer now live under `target/source/`. Their module names and public contracts remain unchanged.

## Physical evidence

`NativeCompilerPackageManifestTargetSourceRowPhysicalProductExampleTest` compiles the retained owner from the canonical archive and compares its function and instruction totals with stage 0. Three imported-call relocations resolve exactly: selector coordinates, dash syntax, and selector-path policy.

`NativeManifestExampleTest` executes two canonical selectors and empty nonmodular source sets. It rejects escaping paths, malformed row shape, non-covering roots, and reverse lexical order through the delegated loop.

The selected physical set is now 112 comparable products and 50 callable products. A fresh closure run retained 142 non-empty module products, 481 functions, and 16,734 forward-plus-inverse instructions. The linked closure contains 398,992 code bytes, 13,432 local-type rows, 805 source strings, and 644 unique strings. Its 510,456-byte executable has SHA-256 `b71b3d4f00ae33aa4f55a998daf88e938de08462d80f34d80084a6afd605949a`. The closure checksum is `3_072_015_695L`.

## Bootstrap identities

The compiler graph contains 439 modules, two externals, and 2,035 imports. Its 200,573-byte canonical manifest has SHA-256 `e18b9a6091863ec4f6695a42021fb11bd5396030784efb6b0c4cb00d9f947845`. Native validation halts after 85,447,432 transitions under the 86,000,000-transition evidence ceiling. Wheeler SHA-256 halts after 38,395,012 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,283,378-byte compiler archive contains 516 entries and has SHA-256 `37e710e316250b2f98e9feb432cfcff39ebeb9c71dc8c612f8f3c29a41c179b9`. Every dependent lock names that archive.

## Failure boundary

Reject an out-of-range selector coordinate before token reads. Reject a missing dash or malformed path before ordering, root coverage, or source-table publication. Reject unresolved retained calls, stale source paths, graph identity drift, archive mismatches, or lock mismatches before execution.

## Acceptance

- [x] One retained owner validates source-row shape and selector policy.
- [x] Bounds precede token reads.
- [x] Collection termination remains distinct from collection acceptance.
- [x] Ordering, coverage, capacity, and publication remain caller-owned.
- [x] Three imported calls resolve exactly in the physical product.
- [x] The source concern has its own bounded directory.
- [x] Complete closure evidence includes the retained owner.
- [x] Manifest, archive, SHA-256, and dependent locks reflect the new source and paths.

## Rejected alternatives

### Move the complete source loop

The loop owns mutable publication and adjacent-row state. Moving it with scalar row syntax would produce a broad transport rather than a reviewable retained policy.

### Treat the first invalid row as an error

A valid collection ends when the required target tail begins. The caller knows whether at least one source was accepted and whether the root was covered.

### Keep a flat target directory

Further target-row work would repeatedly hit the layout ceiling. Grouping source policy by concern removes that churn.

## References

- [WIP-0466](WIP-0466-retained-package-manifest-target-source-product.md)
- [WIP-0468](WIP-0468-retained-package-manifest-target-source-coordinates.md)
- [WIP-0482](WIP-0482-retained-package-manifest-target-module-head.md)
