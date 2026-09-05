# WIP-0491: Retained package-manifest target source-entry publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-04 |
| Updated | 2026-09-05 |
| Area | Self-hosting, package manifests, source selectors |
| Depends on | WIP-0468, WIP-0487, WIP-0490 |
| Supersedes | Aggregate-parser source-row publication |
| Superseded by | None |
| Follow-up | WIP-0049 source-list traversal and count commits |

## Summary

Publish admitted selectors inside the retained collection owner.
`manifestTargetSourceEntryProduct` checks capacity and order, projects the range,
and writes both columns before returning its token. WIP-0049 now keeps that entry
private, derives its predecessor from consecutive token rows, and owns complete
source-list traversal. The aggregate parser no longer carries source-loop state.

## Contract

Entry publication is ordered:

1. Project the selector token from the source row.
2. Reject exhausted row capacity.
3. Reject a selector that does not strictly follow its predecessor.
4. Project the quoted selector start and length.
5. Write both columns at the admitted source index.
6. return the selector token for coverage and traversal state.

No row byte changes before capacity and ordering succeed. The first selector remains predecessor-free. The second column uses a named adjacent-index local, keeping the mutation inside the exact direct root word-write profile established by WIP-0490.

The collection increments its private count only after a positive selector
result. Rejection cannot advance that count or continue into coverage composition.
The parser commits the returned count only after complete list admission.

## Physical evidence

The original five-function pass resolved six imported calls: selector projection,
row capacity, ordering, root coverage, selector start, and selector length. Both
word mutations remained owner-local. [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md#manifest-composition)
now compares complete collection bodies in its combined target pass.

`NativeCompilerPackageManifestSourceCollectionExampleTest` compares every source
table cell. `NativeManifestExampleTest` checks round trips, exact failure offsets,
and admitted prefixes for modular and nonmodular targets. Empty, malformed,
duplicate, reversed, and non-covering collections remain rejected.

The physical set remains 112 comparable products and 51 callable products. A fresh closure run retained 143 non-empty module products, 486 functions, and 16,873 forward-plus-inverse instructions. The linked closure contains 402,392 code bytes, 13,572 local-type rows, 812 source strings, and 650 unique strings. Its 515,136-byte executable has SHA-256 `81bd0cb1335a2964d3cb6e1295a109145b173ccb569b57c7ab929fc46afed525`. The closure checksum is `2_176_650_417L`.

## Bootstrap identities

The compiler graph contains 440 modules, two externals, and 2,038 imports. Its 201,041-byte canonical manifest has SHA-256 `c263abcf3b018075d56a7343d666b48b420d54263169a090c63e03e5551f0de6`. Native validation halts after 85,732,354 transitions under the 86,000,000-transition evidence ceiling. Wheeler SHA-256 halts after 38,479,512 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,286,643-byte compiler archive contains 517 entries and has SHA-256 `0ffb2c5caefc88d5f104de459575e35db9452bf40d482e33c7986ad9a3418554`. Every dependent lock names that archive.

## Failure boundary

Reject capacity and order before coordinate projection or mutation. Reject an unresolved coordinate call before physical artifact publication. Reject a negative entry product before count advancement, coverage composition, or later traversal. Reject stale graph, closure, archive, or dependent-lock identities before execution.

## Acceptance

- [x] One retained entry product owns capacity, order, coordinates, and row publication.
- [x] Rejection precedes both row mutations.
- [x] The aggregate parser no longer imports source-coordinate policy.
- [x] The aggregate parser no longer writes source rows.
- [x] Count and coverage advance only after publication succeeds.
- [x] Six imported calls resolve in the physical product.
- [x] Native and stage-0 manifest rows remain identical.
- [x] Complete closure evidence includes both word mutations.
- [x] Manifest, archive, SHA-256, and dependent locks reflect the change.

## Rejected alternatives

### Leave row mutation in the aggregate parser

That would keep entry admission split after capacity, ordering, and returned selector state had moved behind one retained call.

### Publish before checking order

A duplicate or reversed selector must leave caller-owned storage untouched. Rollback is not a substitute for ordered validation.

### Duplicate quoted-range arithmetic

The retained source-coordinate owner already defines both columns. Publication imports those products and closes their relocations.

### Use an expression as the second mutation index

The direct root mutation profile accepts exact prior locals. A named adjacent index is explicit, retained, and byte-identical with stage 0.

## References

- [WIP-0468](WIP-0468-retained-package-manifest-target-source-coordinates.md)
- [WIP-0487](WIP-0487-retained-package-manifest-target-source-entry.md)
- [WIP-0490](WIP-0490-exact-root-word-mutation-products.md)
