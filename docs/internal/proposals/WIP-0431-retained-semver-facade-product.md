# WIP-0431: Retained semantic-version facade product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-29 |
| Updated | 2026-08-29 |
| Area | Self-hosting, semantic versions, package API |
| Depends on | WIP-0048, WIP-0049, WIP-0425, WIP-0430 |
| Supersedes | Unretained semantic-version facade source |
| Superseded by | None |

## Summary

Retain `Semver.w` as the 119th physical compiler product. Close canonical release validation, constraint validation, and release comparison through three imported calls. This completes the semantic-version package slice as a callable physical closure.

## Facade

`validRelease` delegates to `semverValidRelease`. `validConstraint` delegates to `semverValidConstraint`. Both targets belong to the retained prerelease-validation owner from WIP-0425. `compareReleases` delegates to the retained release-comparison owner from WIP-0430.

The facade owns no duplicated scanner, validation, coordinate, identifier, or precedence state. Its three public functions form the package API.

The artifact retains three functions and 28 forward-plus-inverse instructions. It emits exactly three imported relocations, one for each public call site.

## Evidence

`NativeCompilerSemverFacadePhysicalProductExampleTest` compares exact retained totals with stage 0, requires three relocations, and requires three resolved targets. Earlier semantic-version fixtures execute validation, constraints, coordinates, identifier order, prerelease order, and complete release order through the same retained owners.

The selected set contains 96 comparable products and 23 callable products. The linked closure retains 99 non-empty module products, 387 functions, and 14,082 forward-plus-inverse instructions. It contains 334,288 code bytes, 10,808 local-type rows, 625 source strings, and 507 unique strings. The 422,744-byte executable closure has SHA-256 `9906585f7d46df682949ba4dc1add7a3bf85800caa33a488a4feb87d1271acc7`.

## Bootstrap identities

The compiler graph remains at 394 modules, two externals, and 1,940 imports. Its 184,153-byte canonical manifest retains SHA-256 `b320fbaa59b73df10edf4fdbeb35768fd32445cfe1d1519705d83cf835fb62b5`. Native validation halts after 77,042,073 transitions. Wheeler SHA-256 consumes the bytes in 35,246,504 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The compiler archive remains 3,227,522 bytes with SHA-256 `142267f4be0ff446bf0ac40f8f70db91ea059c40f92740547dd07db5bd1fc4e5`. Dependent locks already name that archive.

## Failure boundary

Reject an unresolved validation or comparison target, signature mismatch, duplicate target, unexpected local call, invalid facade artifact, coordinate above 255, or stale source identity before publication. The facade does not admit unvalidated input to comparison. Callers retain that precondition.

## Acceptance

- [x] The public facade contains exactly three policy-free delegates.
- [x] Every target belongs to a retained semantic-version owner.
- [x] Exactly three imported relocations resolve.
- [x] The retained function and instruction extents match stage 0.
- [x] The physical set contains 119 products and 387 retained functions.
- [x] The linked executable passes the independent reader and verifier.
- [x] The semantic-version package slice is physically callable end to end.

## Rejected alternatives

### Reintroduce private policy helpers

The split owners are the authority. Private facade copies would make physical closure and package behavior diverge.

### Export the split helpers instead of a facade

Package consumers need stable validation and comparison entry points, not compiler implementation topology.

### Retain only validation

Package resolution also depends on deterministic precedence. A validation-only product would leave the package API incomplete.

## References

- [WIP-0048](WIP-0048-canonical-native-product-linker.md)
- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0425](WIP-0425-retained-semver-prerelease-validation-product.md)
- [WIP-0430](WIP-0430-retained-semver-release-comparison-product.md)
