# WIP-0430: Retained semantic-version release comparison product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-29 |
| Updated | 2026-08-29 |
| Area | Self-hosting, semantic versions, precedence |
| Depends on | WIP-0048, WIP-0049, WIP-0428, WIP-0429 |
| Supersedes | Unretained release comparison source |
| Superseded by | None |

## Summary

Retain `SemverReleaseComparison.w` as the 118th physical compiler product. Resolve core and prerelease comparison calls to their retained owners, and select core precedence before prerelease precedence.

## Boundary

`semverCompareReleases` calls `semverCompareCore` and `semverComparePrerelease` over the same source and coordinate windows. Its local selector returns a nonzero core result. Only equal cores admit the prerelease result.

The owner contains no scanner, validator, coordinate traversal, or identifier policy. Those remain under WIP-0424, WIP-0426, WIP-0427, and WIP-0429.

The artifact retains two functions and 46 forward-plus-inverse instructions. It emits exactly two imported relocations. Local selection consumes no relocation row.

## Evidence

`NativeCompilerSemverReleaseComparisonPhysicalProductExampleTest` compares retained function and instruction totals with stage 0, requires exactly two imported relocations, and requires every relocation to resolve.

`NativeCompilerSemverPrecedenceCorePhysicalProductExampleTest` executes the complete release owner over major, minor, patch, stable, the canonical prerelease sequence, and equality cases.

The selected set reaches 118 products at this boundary. WIP-0431 immediately retains the public facade and records the combined linked identity.

## Bootstrap identities

The source graph is unchanged from WIP-0429 at 394 modules, two externals, and 1,940 imports. Its 184,153-byte manifest retains SHA-256 `b320fbaa59b73df10edf4fdbeb35768fd32445cfe1d1519705d83cf835fb62b5`. Native validation halts after 77,042,073 transitions. Wheeler SHA-256 consumes the bytes in 35,246,504 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The compiler archive remains 3,227,522 bytes with SHA-256 `142267f4be0ff446bf0ac40f8f70db91ea059c40f92740547dd07db5bd1fc4e5`. Dependent locks already name that archive.

## Failure boundary

Reject an unresolved core or prerelease owner, signature mismatch, duplicate target, wrong first-result selection, invalid artifact, coordinate above 255, or stale source identity before publication. Equal core versions are the only path to prerelease precedence.

## Acceptance

- [x] Complete release precedence has one focused owner.
- [x] Core precedence always wins when nonzero.
- [x] Exactly two imported relocations resolve.
- [x] The retained extent matches stage 0.
- [x] Complete release precedence executes.
- [x] Manifest and archive identities remain stable.

## Rejected alternatives

### Merge the owner into the public facade

The release selector is reusable compiler policy. The facade also owns validation entry points and should remain a thin API boundary.

### Recompute prerelease order only when core is equal

Both products are pure bounded calls. Computing both before selecting keeps control flow flat and leaves first-result policy explicit.

### Import lower-level coordinate helpers

That would bypass the retained core and prerelease policy owners.

## References

- [WIP-0048](WIP-0048-canonical-native-product-linker.md)
- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0428](WIP-0428-retained-semver-core-comparison-product.md)
- [WIP-0429](WIP-0429-retained-semver-prerelease-comparison-product.md)
