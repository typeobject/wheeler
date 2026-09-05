# WIP-0488: Retained package-manifest target source coverage composition

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-04 |
| Updated | 2026-09-05 |
| Area | Self-hosting, package manifests, source selectors |
| Depends on | WIP-0467, WIP-0485, WIP-0487 |
| Supersedes | Aggregate-parser coverage projection and accumulation |
| Superseded by | None |

## Summary

Move root-coverage composition behind the retained collection boundary.
`manifestTargetSourceCoverage` joins the selector, root, and accumulated verdict.
WIP-0049 now calls it privately from complete source-list traversal. The aggregate
parser carries neither coverage state nor a direct source-policy import.

## Contract

`manifestTargetSourceCoverage` projects whether the admitted selector covers the target root, feeds that verdict to `manifestTargetSourceRootCovered`, and returns the accumulated result. Both calls bind before return. A previous positive verdict remains positive, a current positive verdict promotes a negative accumulator, and two negative verdicts remain negative.

Entry admission still runs first. A rejected capacity or ordering product returns
before coverage work. WIP-0491 moved publication into the admitted entry. Coverage
composition follows that publication, and collection completion checks the final
accumulator after traversal.

Removing the aggregate parser's direct source-policy import leaves the collection owner as the only route from parser state to selector order and coverage policy.

## Physical evidence

The original five-function pass resolved four imported calls: selector projection,
capacity, strict order, and root coverage. Accumulation remained owner-local.
[WIP-0049](WIP-0049-bounded-native-source-product-compilation.md#manifest-composition)
now compares complete collection bodies in its combined target pass.

`NativeManifestExampleTest` executes both accumulator transitions. Its primary modular target covers the root in the first selector and preserves that state through the second. The late-coverage fixture begins negative and becomes positive on its second selector. Complete non-coverage still traps at collection completion.

The physical set remains 112 comparable products and 51 callable products. A fresh closure run retained 143 non-empty module products, 486 functions, and 16,838 forward-plus-inverse instructions. The linked closure contains 401,496 code bytes, 13,541 local-type rows, 812 source strings, and 650 unique strings. Its 514,112-byte executable has SHA-256 `02f042d5fd0f22a0f12070958158ac9de4433b66bc68c09c762621fb3391fd6a`. The closure checksum is `49_300_181L`.

## Bootstrap identities

The compiler graph contains 440 modules, two externals, and 2,038 imports. Its 201,035-byte canonical manifest has SHA-256 `c65f6e84725177cbb9db56901202aac9e91ed68e7d780f0915d766ff2b513daa`. Native validation halts after 85,730,997 transitions under the 86,000,000-transition evidence ceiling. Wheeler SHA-256 halts after 38,479,560 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,285,960-byte compiler archive contains 517 entries and has SHA-256 `59e386e6ec918f5108f39fa23becd2ad91cdcba17a31a99a1aeaf97c55e284b1`. Every dependent lock names that archive.

## Failure boundary

Reject source-entry capacity or order before calling coverage composition. Reject a completed present collection whose accumulated coverage remains false. Reject an unresolved root-range relocation, stale graph count, stale closure identity, archive mismatch, or dependent lock mismatch before execution.

## Acceptance

- [x] Root projection and accumulation have one retained composition function.
- [x] The aggregate parser no longer imports scalar source policy directly.
- [x] Entry rejection precedes coverage work.
- [x] First-row and later-row coverage transitions execute.
- [x] Complete non-coverage still fails collection completion.
- [x] Four imported calls resolve exactly in the physical product.
- [x] Complete closure evidence includes the composition function.
- [x] Manifest, archive, SHA-256, and dependent locks reflect the change.

## Rejected alternatives

### Leave projection in the aggregate parser

That would preserve a direct policy edge after sequence and capacity admission had moved behind the collection owner.

### Replace accumulated state with the current selector verdict

Coverage is existential across the list. A later unrelated source cannot erase earlier root coverage.

### Fold coverage into entry admission

Capacity and ordering can reject without reading root ranges. Keeping coverage as the next scalar stage preserves that failure order and fits the retained physical call profile.

## References

- [WIP-0467](WIP-0467-retained-package-manifest-target-source-policy.md)
- [WIP-0485](WIP-0485-retained-package-manifest-target-source-coverage.md)
- [WIP-0487](WIP-0487-retained-package-manifest-target-source-entry.md)
