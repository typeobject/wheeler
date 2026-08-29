# WIP-0429: Retained semantic-version prerelease comparison product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-29 |
| Updated | 2026-08-29 |
| Area | Self-hosting, semantic versions, precedence |
| Depends on | WIP-0048, WIP-0049, WIP-0426, WIP-0427, WIP-0428 |
| Supersedes | Unretained prerelease-sequence comparison source |
| Superseded by | None |

## Summary

Retain `SemverPrereleaseComparison.w` as the 117th physical compiler product. Keep the identifier loop owner-local, move imported coordinate and identifier calls behind root wrappers, and resolve four dependency relocations before linking.

## Problem

WIP-0428 split release precedence after a combined artifact failed verification. The prerelease owner still called `semverIdentifierEnd` and `semverCompareIdentifier` directly inside its loop. Source composition measured the expected function and instruction extents, but the generated artifact did not pass verification.

The loop needs variable-length identifier traversal. Unrolling is not an option. The source product already supports owner-local calls inside loops and imported calls at root statements. The boundary, not the policy, needed to move.

## Call boundary

`projectedIdentifierEnd` delegates one root call to `semverIdentifierEnd`. `identifierComparison` delegates one root call to `semverCompareIdentifier`. The loop calls those local wrappers with three and five arguments. Its call targets are now owner-local coordinates and consume no relocation rows.

The public function retains two root calls to `semverPrereleaseStart`. Together with the two wrapper calls, the artifact emits exactly four imported relocations. Each identity resolves to the retained coordinate or identifier owner.

This split is not a source stub. The wrappers are retained functions with ordinary local call targets. They keep imported ownership outside the loop without copying dependency policy.

## Sequence state

Stable releases have kind one. Releases with prerelease text have kind zero. Kind comparison establishes stable-versus-prerelease order before identifier traversal.

The loop tracks left and right starts, one comparison, and an active left bound. A nonzero comparison closes the active bound. Exhausting the right sequence also closes it. Each successful equal pair advances both starts by one delimiter scalar and recomputes the bound from the new prior row.

Tail selection preserves an earlier nonzero result. Otherwise, remaining left identifiers sort later, remaining right identifiers sort earlier, and simultaneous exhaustion is equal.

## Evidence

`NativeCompilerSemverPrereleaseComparisonPhysicalProductExampleTest` retains seven functions and 228 forward-plus-inverse instructions. It requires exactly four imported relocations and an equal resolved-target count.

The executable fixture covers the canonical sequence `alpha`, `alpha.1`, `alpha.beta`, `beta`, `beta.2`, `beta.11`, `rc.1`, then stable release. It also checks stable-versus-prerelease order and equality.

The selected set contains 96 comparable products and 21 callable products. The linked closure retains 97 non-empty module products, 382 functions, and 14,008 forward-plus-inverse instructions. It contains 332,472 code bytes, 10,722 local-type rows, 616 source strings, and 500 unique strings. The 420,040-byte executable closure has SHA-256 `35c6345ec836a7b5c35ef63a67170218ba579a2d6d160a5c60cfa9dfc93b5695`.

## Bootstrap identities

The compiler graph remains at 394 modules, two externals, and 1,940 imports. Its 184,153-byte canonical manifest has SHA-256 `b320fbaa59b73df10edf4fdbeb35768fd32445cfe1d1519705d83cf835fb62b5`. Native validation still halts after 77,042,073 transitions. Wheeler SHA-256 still consumes the bytes in 35,246,504 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,227,522-byte compiler archive has SHA-256 `142267f4be0ff446bf0ac40f8f70db91ea059c40f92740547dd07db5bd1fc4e5`. Every dependent lock names that archive.

## Failure boundary

Reject an imported call directly owned by the identifier loop, unavailable sequence coordinate, empty identifier, invalid identifier scalar, unresolved wrapper dependency, wrong signature, unmatched relocation, coordinate above 255, invalid artifact, or stale source identity before closure publication. Owner-local loop calls never enter the relocation table.

## Acceptance

- [x] Prerelease sequence policy has one owner below 24 functions.
- [x] The identifier loop contains only owner-local calls.
- [x] Four root imported call sites resolve exactly once.
- [x] Stable, sequence, tail, and equality order execute.
- [x] The retained function and instruction extents match stage 0.
- [x] The physical set contains 117 products and 382 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the retained owner.

## Rejected alternatives

### Unroll identifier traversal

Canonical releases are byte-bounded, not identifier-count-fixed. Unrolling would encode an arbitrary policy bound in precedence.

### Copy coordinate or identifier policy into the owner

That would duplicate owners retained by WIP-0426 and WIP-0427.

### Retain direct imported calls in the loop

The composed instruction count was correct, but the artifact failed verification. Root wrappers preserve ownership and produce a verifiable local loop target.

### Pack both next coordinates into one scalar return

Packing adds a codec and coordinate-width policy. Two wrapper calls remain explicit and bounded.

## References

- [WIP-0048](WIP-0048-canonical-native-product-linker.md)
- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0426](WIP-0426-retained-semver-coordinate-product.md)
- [WIP-0427](WIP-0427-retained-semver-identifier-comparison-product.md)
- [WIP-0428](WIP-0428-retained-semver-core-comparison-product.md)
