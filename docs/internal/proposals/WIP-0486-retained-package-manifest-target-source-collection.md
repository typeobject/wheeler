# WIP-0486: Retained package-manifest target source collection

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-03 |
| Updated | 2026-09-03 |
| Area | Self-hosting, package manifests, source selectors |
| Depends on | WIP-0483, WIP-0484, WIP-0485 |
| Supersedes | Split source-sequence owner and inline collection completion |
| Superseded by | None |

## Summary

Give the target source collection one retained owner. Sequence admission, existential root-coverage accumulation, and final collection validity now live in `PackageManifestTargetSourceCollection.w`; the narrower sequence file is gone.

## Contract

A target without a module has no source collection and passes collection completion. A modular target has a present collection and must publish at least one source row whose selector covers the target root. Strict adjacent ordering remains independent of coverage: every row must follow its predecessor even after root coverage becomes true.

`manifestTargetSourceCollectionComplete` receives the presence bit, published row count, and accumulated coverage verdict. Absence returns true. Presence with zero rows returns false. Every other present collection returns its coverage verdict.

The aggregate parser owns token traversal and row mutation. It calls collection completion after scanning and before target-tail parsing. A failure returns the unchanged invalid target product.

## Physical evidence

`NativeCompilerPackageManifestTargetSourceCollectionPhysicalProductExampleTest` compiles all three collection functions from the canonical archive and compares complete stage-0 products. The one imported-call relocation remains the strict-order call into source-selector policy. Coverage accumulation and collection completion are owner-local.

`NativeManifestExampleTest` accepts an absent collection on a nonmodular target, preserves first-row coverage, accepts later-row coverage, and rejects a present empty collection. Reversed selectors and complete non-coverage still trap before target publication.

The physical set remains 112 comparable products and 51 callable products. A fresh closure run retained 143 non-empty module products, 484 functions, and 16,780 forward-plus-inverse instructions. The linked closure contains 400,056 code bytes, 13,476 local-type rows, 810 source strings, and 648 unique strings. Its 512,144-byte executable has SHA-256 `73855c7af7f07dca69f39ac9ae96b5c978d9f83a1f4d33859340e7ff67baa707`; the closure checksum is `1_938_119_802L`.

## Bootstrap identities

The compiler graph remains 440 modules, two externals, and 2,037 imports. The renamed owner lengthens its canonical manifest to 200,980 bytes, with SHA-256 `771d9f1faf3caa08aab12578ca03fea139368dd697a2d187d01e7a30c671d17e`. Native validation halts after 85,700,999 transitions under the 86,000,000-transition evidence ceiling. Wheeler SHA-256 halts after 38,467,242 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,284,926-byte compiler archive contains 517 entries and has SHA-256 `45f5a6fe7c698d584b63942fe2cc543545fcbafeaa3fddece19ff98f399cb27c`. Every dependent lock names that archive.

## Failure boundary

Reject a present empty list, a nonempty list without root coverage, or a reversed adjacent pair before target-tail parsing and target publication. Reject the removed sequence module name, stale graph identity, stale archive identity, or unresolved ordering relocation before execution.

## Acceptance

- [x] One owner contains sequence, coverage, and completion policy.
- [x] The superseded sequence source and physical test names are removed.
- [x] Absent source collections remain valid for nonmodular targets.
- [x] Present collections require at least one row and root coverage.
- [x] Empty, reversed, and non-covering fixtures trap.
- [x] The physical product matches stage 0 with one relocation.
- [x] Complete closure evidence includes all three collection functions.
- [x] Manifest, archive, SHA-256, and dependent locks carry the renamed owner.

## Rejected alternatives

### Keep sequence and completion in separate files

They are scalar policy over one source-list lifetime and neither publishes data. Separate files would preserve a naming accident while spending another archive row and graph node.

### Treat zero rows as absence

The grammar distinguishes an omitted optional collection from an explicitly present empty collection. A modular target promises sources; an empty promise is malformed.

### Move row mutation into scalar policy

Collection policy decides admission. The aggregate parser still owns caller-provided columns and publishes only after every row verdict succeeds.

## References

- [WIP-0483](WIP-0483-retained-package-manifest-target-source-row.md)
- [WIP-0484](WIP-0484-retained-package-manifest-target-source-sequence.md)
- [WIP-0485](WIP-0485-retained-package-manifest-target-source-coverage.md)
