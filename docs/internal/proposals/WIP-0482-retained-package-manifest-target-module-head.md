# WIP-0482: Retained package-manifest target module head

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-02 |
| Updated | 2026-09-05 |
| Area | Self-hosting, package manifests, target rows |
| Depends on | WIP-0463, WIP-0465, WIP-0466, WIP-0480 |
| Supersedes | Inline composition of a present module value and sources key |
| Superseded by | None |

## Summary

Retain one physical owner for the module value and required `sources` key of a
modular package target. Malformed present fields share one modular-head verdict.
WIP-0049 now checks optional-field presence inside complete target admission.

## Contract

`manifestTargetModuleHeadValid` receives caller-projected module-value and sources-key coordinates after the optional module key is known to be present. It requires a canonical quoted module name and the adjacent canonical `sources` key. Failure of either check rejects the row before source-selector scanning.

The absent branch remains distinct: a nonmodular target proceeds directly from the optional module coordinate to its required test tail. This keeps omission separate from invalid presence without a signed transport or caller-owned state.

The target directory had reached its ten-file layout ceiling. `PackageManifestTargetModule.w` and the new composer now live under `target/module/`. Module names and public contracts remain unchanged.

## Physical evidence

The module head closes two imported calls: module-name validation and sources-key
presence. [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md#manifest-composition)
compares its complete body in the combined target pass. The standalone
module-head fixture is gone.

`NativeManifestExampleTest` executes modular and nonmodular targets. It rejects a misspelled module key, invalid module grammar, a misspelled sources key, invalid selectors, unsorted selectors, and selectors that do not cover the target root.

The selected physical set is now 112 comparable products and 49 callable products. A fresh closure run retained 141 non-empty module products, 480 functions, and 16,688 forward-plus-inverse instructions. The linked closure contains 397,856 code bytes, 13,386 local-type rows, 802 source strings, and 642 unique strings. Its 508,976-byte executable has SHA-256 `9663e2cd91d976e5233c74bb47eece950e9d8d4a56a1276eb17c4ca00e5e2710`. The closure checksum is `2_523_128_525L`.

## Bootstrap identities

The compiler graph contains 438 modules, two externals, and 2,031 imports. Its 200,057-byte canonical manifest has SHA-256 `76e5fcb14a6dbc343281a34f31b0faa7be8111c505c44450e23fec4fcf44fd24`. Native validation halts after 85,024,211 transitions under the 86,000,000-transition evidence ceiling. Wheeler SHA-256 halts after 38,297,076 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,282,483-byte compiler archive contains 515 entries and has SHA-256 `e40245f9e7ab3130cd3892046d07130ec2fe1da3aba9e912512a317e17b3d36b`. Every dependent lock names that archive.

## Failure boundary

Reject a malformed present module value or missing sources key before selector reads or row publication. Reject unresolved or multiply resolved retained calls before linking. Reject a stale source path, stale graph identity, archive mismatch, or lock mismatch before execution.

## Acceptance

- [x] A present modular head has one retained composer.
- [x] Optional absence remains a caller decision.
- [x] Module and sources coordinates come from the retained coordinate owner.
- [x] Two imported calls resolve exactly in the physical product.
- [x] Modular and nonmodular parser behavior remains distinct.
- [x] The target source directory remains below ten files.
- [x] Complete closure evidence includes the retained owner.
- [x] Manifest, archive, SHA-256, and dependent locks reflect the new source and path.

## Rejected alternatives

### Collapse absence and malformed presence

A nonmodular target is valid. A present malformed module field is not. One Boolean cannot represent both decisions at the parser boundary.

### Recompute coordinates inside field policy

The coordinate owner already defines the target-row layout. Passing its values keeps offset policy out of validation and produces the smallest retained call surface.

### Leave eleven files in one directory

The source layout gate is deliberate. Grouping both modular-field owners by concern avoids a one-off exemption.

## References

- [WIP-0463](WIP-0463-retained-package-manifest-target-row-coordinates.md)
- [WIP-0465](WIP-0465-retained-package-manifest-target-module-product.md)
- [WIP-0466](WIP-0466-retained-package-manifest-target-source-product.md)
- [WIP-0480](WIP-0480-retained-package-manifest-target-head.md)
