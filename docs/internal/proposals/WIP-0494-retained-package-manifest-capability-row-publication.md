# WIP-0494: Retained package-manifest capability-row publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-04 |
| Updated | 2026-09-04 |
| Area | Self-hosting, package manifests, capability rows |
| Depends on | WIP-0471, WIP-0477, WIP-0490 |
| Supersedes | Aggregate-parser capability coordinate projection and row mutation |
| Superseded by | None |

## Summary

Move capability coordinate projection, four-column row publication, and count advancement into the retained capability owner. The aggregate parser still owns collection capacity, adjacent name-and-path ordering, and diagnostics, but no longer lays out accepted capability rows itself.

## Contract

`manifestCapabilityRowProduct` receives a row that has already passed capacity, syntax, path, and ordering checks. It projects quoted name and path starts and lengths before mutation. It then publishes, in order:

1. Capability name start.
2. Capability name length.
3. Capability path start.
4. capability path length.

All destination indexes are named scalar locals. The function returns the next row index only after all four word mutations. The parser installs that result as `capabilityCount`, then advances predecessor and token state.

Capacity remains a caller precondition so an exhausted table fails before parsing or ordering the candidate row. Imported coordinate calls bind before the first write, so unresolved projection cannot leave a partial row.

## Physical evidence

`NativeCompilerPackageManifestCapabilityPhysicalProductExampleTest` compiles both capability-owner functions from the canonical archive and compares their complete function and instruction prefixes with stage 0. Six imported-call relocations resolve exactly: prefix and path validation plus four coordinate projections.

`NativeManifestExampleTest` compares every capability row and count with stage 0. Canonical repeated-name rows preserve both quoted ranges. Malformed prefixes, names, paths, ordering, and section boundaries remain fail-closed.

The physical set remains 112 comparable products and 51 callable products. A fresh closure run retained 143 non-empty module products, 489 functions, and 17,032 forward-plus-inverse instructions. The linked closure contains 406,496 code bytes, 13,738 local-type rows, 815 source strings, and 653 unique strings. Its 520,280-byte executable has SHA-256 `343cfa917d32d2fc4c74bda1bf7857106b7d08f11ba2ade66af8a7115b9cfa2d`. The closure checksum is `876_411_537L`.

## Bootstrap identities

The compiler graph contains 440 modules, two externals, and 2,040 imports. Its 201,177-byte canonical manifest has SHA-256 `b45bcec586256732bc94cb52f9a2522a47652d10121134e446baa37220e89804`. Native validation halts after 85,800,612 transitions under the 86,000,000-transition evidence ceiling. Wheeler SHA-256 halts after 38,503,940 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,287,810-byte compiler archive contains 517 entries and has SHA-256 `bcddfe11d505f8b56b1203f85fbe2c71168b47ecddb3abe92d1b16770c3be13b`. Every dependent lock names that archive.

## Failure boundary

Reject capacity, row syntax, path policy, and ordering before calling publication. Resolve all four coordinate calls before the first write. Advance the count only after all four writes. Reject unresolved physical relocations, stale graph or closure identities, archive mismatch, or dependent-lock mismatch before execution.

## Acceptance

- [x] One retained product owns capability coordinate projection and publication.
- [x] All coordinates resolve before mutation.
- [x] Four columns publish in canonical order.
- [x] Count advancement follows complete publication.
- [x] Capacity, syntax, and ordering remain preconditions.
- [x] The aggregate parser no longer projects or writes capability values.
- [x] Six imported calls resolve in the physical capability product.
- [x] Native and stage-0 capability rows remain identical.
- [x] Complete closure evidence includes capability publication.
- [x] Manifest, archive, SHA-256, and dependent locks reflect the change.

## Rejected alternatives

### Keep publication in the aggregate parser

That leaves validated capability products as token bundles and keeps storage layout in the least focused owner.

### Check capacity only inside publication

The existing parser rejects exhaustion before reading the candidate row. Retaining that order avoids speculative syntax and ordering work at a terminal capacity failure.

### Mutate as each coordinate resolves

A later failed imported call would expose a partial row. Projection is a read phase. Publication begins only after all four values exist.

### Share the dependency publisher

The row widths and field meanings differ. Sharing mutation mechanics would replace two clear fixed layouts with a mode flag and sparse columns.

## References

- [WIP-0471](WIP-0471-retained-package-manifest-capability-coordinates.md)
- [WIP-0477](WIP-0477-retained-package-manifest-capability-rows.md)
- [WIP-0490](WIP-0490-exact-root-word-mutation-products.md)
