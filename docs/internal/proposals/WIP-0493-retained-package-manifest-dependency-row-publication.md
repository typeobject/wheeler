# WIP-0493: Retained package-manifest dependency-row publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-04 |
| Updated | 2026-09-04 |
| Area | Self-hosting, package manifests, dependency rows |
| Depends on | WIP-0470, WIP-0476, WIP-0490 |
| Supersedes | Aggregate-parser dependency coordinate projection and row mutation |
| Superseded by | None |

## Summary

Move dependency coordinate projection, five-column row publication, and count advancement into the retained dependency owner. At this milestone, the parser kept capacity, ordering, and diagnostics. WIP-0049 now composes capacity, admission, and publication in `manifestDependencyEntryProduct`.

## Contract

`manifestDependencyRowProduct` receives a row that has already passed capacity, syntax, semantic-version, and ordering checks. It projects quoted name and version starts and lengths before mutation. It then publishes, in order:

1. Dependency kind.
2. Name start.
3. Name length.
4. Version start.
5. Version length.

All destination indexes are named scalar locals. The function returns the next row index only after all five word mutations. The entry product passes that result to the parser, which installs `dependencyCount` and advances its token cursor.

Capacity remains a caller precondition so an exhausted table still fails before parsing or ordering the candidate row. No mutation runs on that path. Imported coordinate calls bind before the first write, so unresolved projection cannot leave a partial row.

## Physical evidence

The milestone compared both dependency-owner functions with stage 0 and resolved seven imported calls: three validators and four coordinate projections. Current physical evidence lives in `NativeCompilerPackageManifestEntryPhysicalProductExampleTest`. The combined pass also checks complete entry composition.

`NativeManifestExampleTest` compares every dependency row and count with stage 0. Canonical multiple-row input preserves kind and both quoted ranges. Malformed prefixes, names, semantic versions, order, and section boundaries remain fail-closed.

The physical set remains 112 comparable products and 51 callable products. A fresh closure run retained 143 non-empty module products, 488 functions, and 16,970 forward-plus-inverse instructions. The linked closure contains 404,880 code bytes, 13,674 local-type rows, 814 source strings, and 652 unique strings. Its 518,288-byte executable has SHA-256 `6a172144c82caa704443cf851f791d6b603f149984ad09683401478c484c12f0`. The closure checksum is `1_779_900_740L`.

## Bootstrap identities

The compiler graph contains 440 modules, two externals, and 2,039 imports. Its 201,109-byte canonical manifest has SHA-256 `a851c5a7aca438342b31fa7375cf5b5f68042d57815794993e6bed8e786cd82e`. Native validation halts after 85,765,417 transitions under the 86,000,000-transition evidence ceiling. Wheeler SHA-256 halts after 38,491,726 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,287,506-byte compiler archive contains 517 entries and has SHA-256 `b73742188a149dbac1160fb609c96a3957f0f3ca5931b958dff9c47b6a68d16d`. Every dependent lock names that archive.

## Failure boundary

Reject capacity, row syntax, semantic fields, and ordering before calling publication. Resolve all four coordinate calls before the first write. Advance the count only after all five writes. Reject unresolved physical relocations, stale graph or closure identities, archive mismatch, or dependent-lock mismatch before execution.

## Acceptance

- [x] One retained product owns dependency coordinate projection and publication.
- [x] All coordinates resolve before mutation.
- [x] Five columns publish in canonical order.
- [x] Count advancement follows complete publication.
- [x] Capacity, syntax, and ordering remain preconditions.
- [x] The aggregate parser no longer projects or writes dependency values.
- [x] Seven imported calls resolve in the physical dependency product.
- [x] Native and stage-0 dependency rows remain identical.
- [x] Complete closure evidence includes dependency publication.
- [x] Manifest, archive, SHA-256, and dependent locks reflect the change.

## Rejected alternatives

### Keep publication in the aggregate parser

That leaves validated dependency products as token bundles and keeps storage layout in the least focused owner.

### Check capacity only inside publication

Capacity must precede candidate-row work. WIP-0049 preserves that order inside the entry product, before private admission and the existing row publisher.

### Mutate as each coordinate resolves

A later failed imported call would expose a partial row. Projection is a read phase. Publication begins only after all four values exist.

### Return no count product

Count advancement is the publication commit marker. Returning the next row keeps it ordered after the fifth write.

## References

- [WIP-0470](WIP-0470-retained-package-manifest-dependency-coordinates.md)
- [WIP-0476](WIP-0476-retained-package-manifest-dependency-rows.md)
- [WIP-0490](WIP-0490-exact-root-word-mutation-products.md)
