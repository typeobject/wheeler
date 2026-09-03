# WIP-0472: Retained package-manifest row ordering

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-02 |
| Updated | 2026-09-02 |
| Area | Self-hosting, package manifests, collection rows |
| Depends on | WIP-0049, WIP-0420, WIP-0455, WIP-0458, WIP-0460 |
| Supersedes | Direct target, dependency, and capability ordering in `PackageManifest.w` |
| Superseded by | None |

## Summary

Assign canonical collection order to the field owners that define each key. Target and dependency names require strict token-text order. Capabilities require name order with path order as the equal-name tie-break.

## Ordering policy

`manifestTargetNamesOrdered` and `manifestDependencyNamesOrdered` compare adjacent quoted tokens and accept only a negative result. Equal and descending names reject.

Capability order has two scalar products. `manifestCapabilityNameOrder` returns the three-way token comparison. For equal names, `manifestCapabilityPathsOrdered` requires a negative path comparison. Splitting the seven-input composition keeps each callable inside the bounded physical-source profile while leaving the name-plus-path decision explicit at the parser boundary.

The parser owns previous-row state and diagnostics. It no longer calls generic token comparison directly for collection rows.

## Physical route

The three existing field products retain four additional functions and four additional call relocations. Target name and dependency name each close one new token-comparison target. Capability path closes two. The selected product count and source routes do not change.

## Evidence

The target-name, dependency-name, and capability-path physical-product tests compare retained functions and instructions with stage 0 and close four, four, and five relocations respectively. `NativeManifestExampleTest` rejects descending target names, descending dependency names, and equal capability names with descending paths.

The selected set contains 112 comparable products and 42 callable products. It retains 134 non-empty module products, 470 functions, and 16,304 forward-plus-inverse instructions. The linked closure contains 388,512 code bytes, 12,997 local-type rows, 778 source strings, and 625 unique strings. Its 496,672-byte executable has SHA-256 `362c190bb1b716a70e02fae85c919c5b76a79c3bcd076c7b057c35ad4eaf58ee`.

## Bootstrap identities

The compiler graph contains 431 modules, two externals, and 2,017 imports. Its 197,486-byte canonical manifest has SHA-256 `16d31c2e37e6ba31e14aebc22d67974c287cb3a1d9d0c2c9f3c31378048a693b`. Native validation halts after 83,741,348 transitions under the 84,000,000-transition evidence ceiling. Wheeler SHA-256 consumes the same bytes in 37,793,504 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,275,793-byte compiler archive has SHA-256 `30ff98b43667316077ef0ad15a83540220fafcfb5016908b265e3c010037796d`. Every dependent lock names that archive.

## Failure boundary

Reject an equal or descending target or dependency name before publication. Reject a descending capability name, or equal names with equal or descending paths, before publication. Reject an unresolved comparison call, stage-0 mismatch, stale graph identity, archive mismatch, linked-closure mismatch, or lock mismatch before bootstrap publication.

## Acceptance

- [x] Target and dependency names each have one strict-order owner.
- [x] Capability names expose three-way order and paths expose the strict tie-break.
- [x] The parser retains previous-row state and diagnostics only.
- [x] All thirteen field-product relocations resolve exactly.
- [x] Descending and duplicate-key rows execute through the composed parser.
- [x] The retained libraries match stage 0 byte for byte.
- [x] The linked closure contains 154 products and 470 functions.
- [x] Manifest, archive, executable, SHA-256, and locks name the completed field owners.

## Rejected alternatives

### Sort rows after parsing

Canonical input order is part of the accepted language. Sorting would silently accept a noncanonical manifest and move diagnostics after mutation.

### Put all order policy in one collection helper

Target names, package names, and capability name-plus-path keys are different schema contracts. A shared helper would return ordinals the parser could interpret inconsistently.

### Use a seven-input capability predicate

That shape exceeds the currently retained callable-source composition exercised by this path. Two scalar products are simpler and expose the tie-break without allocating a pair.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0420](WIP-0420-retained-package-manifest-token-product.md)
- [WIP-0455](WIP-0455-retained-package-manifest-dependency-name-product.md)
- [WIP-0458](WIP-0458-retained-package-manifest-capability-path-product.md)
- [WIP-0460](WIP-0460-retained-package-manifest-target-name-product.md)
