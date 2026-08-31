# WIP-0447: Retained package-manifest selector product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-31 |
| Updated | 2026-08-31 |
| Area | Self-hosting, package manifests, callable products |
| Depends on | WIP-0049, WIP-0052, WIP-0443, WIP-0445, WIP-0446 |
| Supersedes | Unselected `PackageManifestSelectors.w` range facade |
| Superseded by | None |

## Summary

Retain `PackageManifestSelectors.w` as physical artifact 133. Resolve its length, prefix, and completion calls against the three retained selector-policy owners.

## Selector facade

`manifestSelectorRangeCoversRoot` first classifies lengths and rejects a selector longer than its root. It then calls the bounded prefix owner and rejects mismatch. The completion owner accepts exact equality or requires slash after a proper prefix.

WIP-0445 removed imported calls from UTF-8 traversal. WIP-0446 moved conditional next-root projection behind one completion call. The facade now contains only named imported call assignments, fail-closed literal returns, and one final local return. No policy is duplicated.

The retained module contains one function and 42 forward-plus-inverse instructions. Its three call relocations resolve to length state, prefix traversal, and completion.

## Evidence

`NativeCompilerPackageManifestSelectorsPhysicalProductExampleTest` executes equal, directory-prefix, longer, mismatched, and nonseparator forms. Its physical case retains the owner, resolves all three callable targets, and compares function and instruction counts with stage 0.

The selected set contains 107 comparable products and 26 callable products. The linked closure retains 113 non-empty module products, 421 functions, and 14,925 forward-plus-inverse instructions. It contains 354,408 code bytes, 11,560 local-type rows, 687 source strings, and 555 unique strings. The 450,072-byte executable closure has SHA-256 `44ca8c542a6699231a1b089438f3fac61d68e3486c3f01d7f74cb4ecaa78787c`.

## Bootstrap identities

Physical selection does not alter the source graph. The compiler graph remains 410 modules, two externals, and 1,958 imports. Its 188,974-byte canonical manifest has SHA-256 `85fb0c04a34e2ff36f183fd83f71b5ab2eaa9efc74044ab78d577df8158623a6`. Native validation halts after 79,464,145 transitions. Wheeler SHA-256 consumes the same bytes in 36,164,786 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,249,331-byte compiler archive remains SHA-256 `a7674a7e3bc9cb9ce372d4ee07af20e7cf8a39c3908bd1cc0536f9263e2ae4b1`. Every dependent lock names that archive.

## Failure boundary

Reject a selector longer than its root, any prefix mismatch, or a nonseparator boundary before publication. Reject an unresolved policy target, unexpected relocation count, stale closure identity, or artifact mismatch.

## Acceptance

- [x] The selector facade contains no UTF-8 loop or duplicated policy.
- [x] Equal, directory-prefix, longer, mismatch, and nonseparator forms execute.
- [x] All three imported policy calls resolve.
- [x] Retained function and instruction counts match stage 0.
- [x] The physical set contains 133 products and 421 retained functions.
- [x] The executable closure names the retained facade.

## Rejected alternatives

### Retain the original combined loop

Imported equality calls inside UTF-8 traversal failed physical composition.

### Project completion in the facade

Conditional next-root projection followed by an imported result call also failed. WIP-0446 gives that composition one direct owner.

### Inline retained policy

Length, prefix, and completion already have exact physical owners. Duplicating them would weaken relocation evidence.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0443](WIP-0443-retained-package-manifest-selector-state-product.md)
- [WIP-0445](WIP-0445-retained-package-manifest-selector-prefix-product.md)
- [WIP-0446](WIP-0446-retained-package-manifest-selector-completion-product.md)
