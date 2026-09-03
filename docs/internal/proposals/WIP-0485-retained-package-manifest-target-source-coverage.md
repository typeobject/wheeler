# WIP-0485: Retained package-manifest target source coverage

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-03 |
| Updated | 2026-09-03 |
| Area | Self-hosting, package manifests, source selectors |
| Depends on | WIP-0467, WIP-0484 |
| Supersedes | Inline root-coverage accumulation |
| Superseded by | None |

## Summary

Retain source-list root-coverage accumulation beside source-sequence admission. A target is covered once any validated selector covers its root; later non-covering selectors cannot clear that verdict.

## Contract

`manifestTargetSourceRootCovered` accepts the accumulated verdict and the current selector's verdict. It returns true when the accumulator is true and otherwise returns the current verdict. The positive accumulator test is an explicit Boolean-literal comparison, the conditional form admitted by the retained structured-source profile.

`PackageManifest.w` still computes range coverage through `manifestTargetSourceCoversRoot`, then delegates accumulation before advancing the previous-selector coordinate or publishing the source row. End-of-target validation requires the accumulated verdict whenever a source list is present.

## Physical evidence

`NativeCompilerPackageManifestTargetSourceSequencePhysicalProductExampleTest` compiles both sequence functions from the canonical source archive and compares their complete function and instruction prefixes with stage 0. The sequence artifact retains its one imported ordering relocation; coverage accumulation is owner-local.

`NativeManifestExampleTest` exercises both state transitions. The canonical fixture covers the root in its first row and preserves coverage across a non-covering second row. A second canonical fixture begins with a non-covering selector and covers the root in its later row. A list that never covers the root still traps.

The physical set remains 112 comparable products and 51 callable products. A fresh closure run retained 143 non-empty module products, 483 functions, and 16,764 forward-plus-inverse instructions. The linked closure contains 399,696 code bytes, 13,463 local-type rows, 809 source strings, and 647 unique strings. Its 511,584-byte executable has SHA-256 `848d71b7d0aec9bd7bb72b6d3cf2449048497ac4f41108e560e13807f725c54a`; the closure checksum is `2_223_862_199L`.

## Bootstrap identities

The compiler graph remains 440 modules, two externals, and 2,037 imports. Its 200,974-byte canonical manifest retains SHA-256 `cca81a814f7f902ab754da19435bd10f0b4873dbfd3830d964f2e324587c1966`. Native validation halts after 85,702,691 transitions under the 86,000,000-transition evidence ceiling. Wheeler SHA-256 still halts after 38,467,290 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,284,453-byte compiler archive contains 517 entries and has SHA-256 `2e24da09e90d49e7e73a18171ae4d35dbc00acaa256980bc2dfd6484441526bd`. Every dependent lock names that archive.

## Failure boundary

Reject a target whose complete nonempty selector list never covers its root. Do not clear an earlier positive verdict. Reject a stale graph transition count, closure identity, archive identity, or dependent lock before publication.

## Acceptance

- [x] Coverage accumulation has one retained scalar owner.
- [x] Earlier positive coverage survives later negative coverage.
- [x] Later positive coverage admits an earlier negative selector.
- [x] Complete negative coverage still traps.
- [x] The physical product matches stage 0 with one resolved relocation.
- [x] Complete closure evidence contains both sequence functions.
- [x] Manifest, archive, SHA-256, and dependent locks reflect the source change.

## Rejected alternatives

### Assign true directly in the aggregate parser

That leaves the accumulation rule inside a stateful parser and outside retained physical evidence.

### Replace the accumulator with the current row

Coverage is existential across the complete selector list. Replacement would let a later unrelated source erase valid earlier coverage.

### Short-circuit before range coverage

Range coverage is pure, bounded, and already retained. Keeping projection and accumulation separate leaves each owner scalar and makes both state transitions visible to differential tests.

## References

- [WIP-0467](WIP-0467-retained-package-manifest-target-source-policy.md)
- [WIP-0484](WIP-0484-retained-package-manifest-target-source-sequence.md)
