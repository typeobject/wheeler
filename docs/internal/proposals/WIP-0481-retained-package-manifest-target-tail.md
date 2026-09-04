# WIP-0481: Retained package-manifest target tail

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-02 |
| Updated | 2026-09-04 |
| Area | Self-hosting, package manifests, target rows |
| Depends on | WIP-0463, WIP-0464, WIP-0480 |
| Supersedes | Inline composition of the required target test field |
| Superseded by | None |
| Follow-up | WIP-0495 target-row publication |

## Summary

Retain one physical owner for the required `test` field at the tail of every package-manifest target row. The aggregate parser now receives either a canonical Boolean value or one negative malformed-row verdict.

## Contract

`manifestTargetTestValue` requires the canonical `test` key at the caller's tail coordinate, projects its value coordinate, decodes only `true` or `false`, and applies target-kind policy. It returns zero or one for an admitted row and minus one for a missing key, malformed Boolean, or enabled library test.

`PackageManifest.w` delegates the complete verdict before constructing `TargetParse`. It retains target coordinates only to advance beyond an admitted tail. Key presence, Boolean decoding, and kind policy no longer form nested parser branches.

WIP-0495 extends this owner with separate modular and nonmodular tail-publication products. The split keeps optional module projection out of direct conditional lowering.

## Physical evidence

`NativeCompilerPackageManifestTargetTailPhysicalProductExampleTest` compiles the retained owner from the canonical archive and compares its function and instruction totals with stage 0. Four imported-call relocations resolve: key presence, value coordinates, Boolean decoding, and test policy.

`NativeManifestExampleTest` executes true and false test fields through modular and nonmodular rows. It rejects a misspelled key, a non-Boolean scalar, and an enabled library test through the same delegated path.

The selected physical set is now 112 comparable products and 48 callable products. A fresh closure run retained 140 non-empty module products, 479 functions, and 16,646 forward-plus-inverse instructions. The linked closure contains 396,840 code bytes, 13,343 local-type rows, 799 source strings, and 640 unique strings. Its 507,616-byte executable has SHA-256 `3aeabd2d4f81ab0dd78c4cf9638c40981d8fcba451a4797b0f842d1097df90da`. The closure checksum is `988_462_381L`.

## Bootstrap identities

The compiler graph contains 437 modules, two externals, and 2,028 imports. Its 199,602-byte canonical manifest has SHA-256 `dea1e52d8f23bb213b275e480c1d39a4d3997258b3028e0bd26d90a5692755f0`. Native validation halts after 84,723,801 transitions under the 85,000,000-transition evidence ceiling. Wheeler SHA-256 halts after 38,197,590 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,281,677-byte compiler archive contains 514 entries and has SHA-256 `2785e894fb2dd0f603b07c5cd3312d1a58b35a0883563cac815ffde80a1b0e4f`. Every dependent lock names that archive.

## Failure boundary

Reject a missing test key, a malformed Boolean, or an enabled library test before target publication. Reject unresolved or multiply resolved retained calls before linking. Reject stale graph identities, archive mismatches, or lock mismatches before execution.

## Acceptance

- [x] The required test tail has one retained composer.
- [x] Missing, malformed, and disallowed values share one negative verdict.
- [x] The parser delegates key, value, and policy composition.
- [x] Four imported calls resolve exactly in the physical product.
- [x] Valid modular and nonmodular rows preserve their test value.
- [x] Complete closure evidence includes the retained owner.
- [x] Manifest, archive, SHA-256, and dependent locks reflect the new source.

## Rejected alternatives

### Keep nested parser checks

That duplicates final-field composition in the aggregate parser and leaves no physical owner for the complete target tail.

### Return a Boolean validity flag

The parser must also retain the admitted test value. A signed scalar carries both results without caller-owned scratch state.

### Treat a missing test key as false

Canonical package syntax requires the field. Defaulting it would admit a second wire representation.

## References

- [WIP-0463](WIP-0463-retained-package-manifest-target-row-coordinates.md)
- [WIP-0464](WIP-0464-retained-package-manifest-target-test-product.md)
- [WIP-0480](WIP-0480-retained-package-manifest-target-head.md)
