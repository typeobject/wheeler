# WIP-0487: Retained package-manifest target source entry

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-04 |
| Updated | 2026-09-04 |
| Area | Self-hosting, package manifests, source selectors |
| Depends on | WIP-0468, WIP-0486 |
| Supersedes | Inline source-row capacity and sequence admission |
| Superseded by | None |

## Summary

Move per-entry admission into the retained source-collection owner. `PackageManifest.w` no longer decides source-table capacity or adjacent-selector order itself.

## Contract

`manifestTargetSourceEntryProduct` accepts one syntactically valid source-row token, the previous selector token, and the caller-owned source table coordinate. It checks table capacity before comparing selector order. Failure returns minus one. Success returns the current selector token, which becomes the next row's predecessor.

The aggregate parser retains syntax classification, root-coverage projection, and row publication. It calls entry admission before coverage or mutation. This keeps the scalar product within the closed physical source profile without duplicating ordering or capacity policy at the parser boundary.

The entry product takes seven arguments. Imported results bind to named locals before guards. That retained shape avoids widening the call or result surface merely for this parser.

## Physical evidence

`NativeCompilerPackageManifestTargetSourceCollectionPhysicalProductExampleTest` compiles all four collection functions from the canonical archive and compares their complete function and instruction prefixes with stage 0. Three imported-call relocations resolve: selector-token projection, source-table capacity, and strict adjacent ordering.

`NativeManifestExampleTest` executes the integrated path. Canonical first and later rows pass, while a reversed pair fails before coverage and row mutation. Existing exact-capacity evidence for `manifestSourceRowCapacity` remains authoritative for the terminal source-table coordinate.

The physical set remains 112 comparable products and 51 callable products. A fresh closure run retained 143 non-empty module products, 485 functions, and 16,818 forward-plus-inverse instructions. The linked closure contains 400,992 code bytes, 13,515 local-type rows, 811 source strings, and 649 unique strings. Its 513,368-byte executable has SHA-256 `c09523f036fda61b61c82b051ad3bbf37e5e63ea41f23e94c795693d65d986f8`; the closure checksum is `3_230_999_536L`.

## Bootstrap identities

The compiler graph contains 440 modules, two externals, and 2,039 imports. Its 201,094-byte canonical manifest has SHA-256 `f79ee6d76c28108ad91e9540b415fdc6e40539c5a8ed66f22ac8d528bd1b67c6`. Native validation halts after 85,764,726 transitions under the 86,000,000-transition evidence ceiling. Wheeler SHA-256 halts after 38,491,846 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,285,582-byte compiler archive contains 517 entries and has SHA-256 `ad40066584bfdca801e5ae0303ac39648715478157a52d80359a657e974d91f7`. Every dependent lock names that archive.

## Failure boundary

Reject an exhausted caller table or an equal or reversed selector before root-coverage work and row publication. Reject an unresolved selector-coordinate, capacity, or ordering relocation before retaining the physical product. Reject stale manifest, archive, closure, SHA-256, or lock identities before execution.

## Acceptance

- [x] Source-entry capacity and ordering have one retained owner.
- [x] The aggregate parser delegates admission before mutation.
- [x] Success returns the exact selector token used as predecessor state.
- [x] Reversed selectors fail through the integrated parser.
- [x] Three imported calls resolve exactly in the physical product.
- [x] Complete closure evidence includes the entry function.
- [x] Manifest, archive, SHA-256, and dependent locks reflect the change.

## Rejected alternatives

### Move the complete list loop at once

The physical profile does not yet retain Boolean loop sentinels, packed Boolean arithmetic returns, or arbitrary caller-table mutation in one imported-call product. Admission is the reviewable boundary already covered by retained scalar forms. Traversal and publication can move only after their own physical evidence lands.

### Recheck capacity after publication

A terminal row must fail before any table write. Checking afterward would make failure observably partial.

### Return a Boolean

The parser needs the admitted selector as predecessor state. Returning only a verdict would force it to project the same token again or trust an unchecked coordinate.

## References

- [WIP-0468](WIP-0468-retained-package-manifest-target-source-coordinates.md)
- [WIP-0486](WIP-0486-retained-package-manifest-target-source-collection.md)
