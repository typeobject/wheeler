# WIP-0443: Retained package-manifest selector-state product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-31 |
| Updated | 2026-09-04 |
| Area | Self-hosting, package manifests, physical closure bounds |
| Depends on | WIP-0049, WIP-0052, WIP-0442 |
| Supersedes | Private duplicated selector loops in `PackageManifest.w` and the 128-product owner bound |
| Superseded by | None |
| Follow-up | WIP-0445 for prefix traversal and WIP-0446 for completion policy |

## Summary

Split source-selector traversal into range and scalar-state owners. Retain `PackageManifestSelectorState.w` as the 129th physical compiler artifact, raise the exhausted physical-owner profile from 128 to 256 products, and keep the range loop outside the selected set until its imported loop calls compose.

## Selector state

`manifestSelectorLengthKind` classifies a selector longer than its root as minus one, a proper prefix as zero, and equal length as one. `manifestSelectorSame` carries one fail-closed equality bit across each scalar pair. WIP-0446 later moved completion and next-root projection into their own retained owner.

`PackageManifestSelectors.w` originally owned UTF-8 traversal over caller-projected interior ranges. WIP-0445 later moved traversal to a call-free prefix owner. `PackageManifest.w` names token rows, interior starts, and interior lengths before making the range call. Its former two-loop selector helper is gone.

The range owner executes equal, directory-prefix, longer, mismatched, and nonseparator forms under stage 0. Its direct physical attempts first rejected compound row projections and arithmetic call operands. After those were removed, composition reached the imported call inside the UTF-8 loop and still published no artifact. The range owner remains unselected.

## Physical owner profile

Artifact 129 exhausted the 128-word physical-owner column before the first product compiled. The closure fixture now allocates 256 owner rows, adds exactly 1,024 bytes to their region, and raises only the physical-product traversal limit to 256. Product, callable, symbol, function, instruction, and archive bounds remain unchanged.

`NativeCompilerPhysicalClosureExampleTest` requires the selected count to exceed 128 and remain at most 256. This proves the raised profile instead of leaving spare capacity unexercised.

## Evidence

`NativeCompilerPackageManifestSelectorStatePhysicalProductExampleTest` executes every length kind and preserved and failed equality. WIP-0446 carries completion cases. The state physical case compares the complete current artifact byte for byte with stage 0.

`NativeCompilerPackageManifestSelectorsExampleTest` executes the unselected range owner. Manifest and archive examples parse complete source selectors through the split path.

The selected set contains 104 comparable products and 25 callable products. The linked closure retains 109 non-empty module products, 417 functions, and 14,813 forward-plus-inverse instructions. It contains 351,632 code bytes, 11,449 local-type rows, 675 source strings, and 547 unique strings. The 446,264-byte executable closure has SHA-256 `6ce93b04b6ea829dbc5108b2e4a665bfc51ace12e9bfaf2b2895f8186c555701`.

## Bootstrap identities

The compiler graph contains 407 modules, two externals, and 1,955 imports. Its 188,055-byte canonical manifest has SHA-256 `6f74b2ba229fdaf5ca467b9fa87efb64cad9c4739bceca34f50d82494246f24d`. Native validation halts after 79,055,342 transitions. The explicit validation budget rises from 79,000,000 to 80,000,000 transitions. Wheeler SHA-256 consumes the same bytes in 35,993,526 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,247,329-byte compiler archive has SHA-256 `cfd33f4e1a8b84c21e49a6e01ed56aa935ae716146bc4e2ee1131462f4cad248`. Every dependent lock names that archive.

## Failure boundary

Reject a selector longer than its root, mismatched prefix, nonseparator boundary, unnamed token coordinate, stale physical owner profile, product count above 256, failed range-loop artifact, stale graph identity, archive mismatch, or closure mismatch before publication.

## Acceptance

- [x] Selector length, equality, and completion state have one scalar owner.
- [x] The package parser contains no duplicate selector loop.
- [x] Range and state behavior execute under stage 0.
- [x] The state artifact matches stage 0 byte for byte.
- [x] The range-loop failure publishes no artifact.
- [x] The closure executes its 129th product under a checked 256-product profile.
- [x] The linked closure contains 417 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Raise every closure bound

Only the owner row and traversal limit were exhausted. Widening unrelated products would weaken reviewed ceilings without evidence.

### Keep two selector loops

One prefix traversal handles equal and directory-prefix forms. Scalar state closes the policy without duplicate UTF-8 mechanics.

### Select the failed range owner

Stage execution and normalized coordinates do not prove imported calls inside the loop compose byte for byte.

### Stop at 128 products

The next retained owner is valid evidence. A bookkeeping ceiling must not become a semantic limit.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0442](WIP-0442-retained-package-manifest-key-product.md)
