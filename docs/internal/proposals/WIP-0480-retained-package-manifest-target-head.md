# WIP-0480: Retained package-manifest target head

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-02 |
| Updated | 2026-09-04 |
| Area | Self-hosting, package manifests, target rows |
| Depends on | WIP-0462, WIP-0469, WIP-0478, WIP-0479 |
| Supersedes | Inline composition of required target head fields |
| Superseded by | None |
| Follow-up | WIP-0495 target-row publication |

## Summary

Retain one physical owner for the required `kind`, `name`, and `root` fields at the head of a package-manifest target row. This is the first compiler source admitted beyond the former 512-entry archive ceiling.

## Contract

`manifestTargetHeadKind` returns the positive target kind only when all three required fields validate at their canonical token coordinates. It returns zero for a truncated prefix, an unknown target kind, a malformed or unordered name, or an invalid logical root path.

`PackageManifest.w` delegates that verdict before inspecting optional module, source, or test fields. It retains the target-name policy import only for ordering complete target rows. Prefix and root field composition belong exclusively to `PackageManifestTargetHead.w`.

WIP-0495 extends the same owner with publication of the kind, name range, and root range after complete-row admission.

## Physical evidence

`NativeCompilerPackageManifestTargetHeadPhysicalProductExampleTest` selects the retained owner from the canonical compiler graph, compiles it from the 513-entry package archive, and compares its function and instruction totals with stage 0. The product closes three imported-call relocations: target prefix, target name, and target root.

`NativeManifestExampleTest` exercises modular and nonmodular rows and rejects unknown kinds, unordered names, escaping roots, malformed optional fields, and over-capacity collections through the delegated parser path.

The selected physical set is now 112 comparable products and 47 callable products. A fresh closure run retained 139 non-empty module products, 478 functions, and 16,589 forward-plus-inverse instructions. The linked closure contains 395,440 code bytes, 13,288 local-type rows, 796 source strings, and 638 unique strings. Its 505,856-byte executable has SHA-256 `44e503b4acba2b6bb606fe6fa0699e74332911f2a478e2981dc4585e387199ff`. The closure checksum is `1_155_859_380L`.

## Bootstrap identities

The compiler graph contains 436 modules, two externals, and 2,025 imports. Its 199,184-byte canonical manifest has SHA-256 `fa4118aa4afedecebfb5a0fea872ddfc58075051c7487db5c6c848255c0319ee`. Native validation halts after 84,498,437 transitions under the 85,000,000-transition evidence ceiling. Wheeler SHA-256 halts after 38,124,386 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,280,663-byte compiler archive contains 513 entries and has SHA-256 `09594514d959b9c5588891c46af1f341fca57763a329a7ce6ddfb5039316f2be`. Every dependent lock names that archive.

## Failure boundary

Reject a malformed required head before optional-field inspection or row publication. Reject an unresolved or multiply resolved retained call before linking. Reject stale graph identities, an archive outside the 1,024-entry native bound, archive mismatches, or lock mismatches before execution.

## Acceptance

- [x] Required target head fields have one retained composer.
- [x] The parser delegates kind, name, and root composition to that owner.
- [x] Target-name ordering remains explicit at the complete-row layer.
- [x] Three imported calls resolve once in the physical product.
- [x] Existing malformed-head cases still fail closed.
- [x] The 513-entry compiler archive reaches physical product compilation.
- [x] Complete closure evidence includes the retained owner.
- [x] Manifest, archive, SHA-256, and dependent locks reflect the new source.

## Rejected alternatives

### Keep the nested parser branches

That leaves required-field composition inside the aggregate parser and prevents physical selection of the complete target head.

### Move target ordering into the head owner

Ordering compares adjacent complete rows. It does not determine whether one row's required fields are valid.

### Merge optional module policy

Modular and nonmodular rows diverge after the root field. Keeping that policy separate preserves a small, unconditional head contract.

## References

- [WIP-0462](WIP-0462-retained-package-manifest-target-coordinate-product.md)
- [WIP-0469](WIP-0469-retained-package-manifest-target-field-keys.md)
- [WIP-0478](WIP-0478-expanded-native-archive-source-index.md)
- [WIP-0479](WIP-0479-widened-native-archive-module-binding.md)
