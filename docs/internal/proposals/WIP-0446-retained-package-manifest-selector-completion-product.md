# WIP-0446: Retained package-manifest selector-completion product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-31 |
| Updated | 2026-08-31 |
| Area | Self-hosting, package manifests, selector boundaries |
| Depends on | WIP-0049, WIP-0052, WIP-0443, WIP-0445 |
| Supersedes | Selector-completion policy in `PackageManifestSelectorState.w` |
| Superseded by | None |

## Summary

Split equal-range and directory-prefix completion into `PackageManifestSelectorCompletion.w`. Retain the call-free owner as physical artifact 132 and reduce scalar state to length and equality policy.

## Completion policy

`manifestSelectorRangeComplete` accepts an equal selector without reading beyond the range. For a proper prefix it projects the next root scalar through a named coordinate and requires slash. The range owner calls it only after length classification and prefix equality succeed.

The earlier completion function accepted a caller-projected scalar. That forced the range owner to mix conditional UTF-8 projection with an imported result call. Moving coordinate projection and completion policy together removes that composition and leaves no duplicate slash policy.

The completion owner contains one function and no imports, loops, calls, or relocations. Removing the former state function keeps the selected closure at 420 functions while adding eight forward-plus-inverse instructions.

## Evidence

`NativeCompilerPackageManifestSelectorCompletionPhysicalProductExampleTest` executes equal, slash-prefix, and nonseparator forms and compares the complete artifact byte for byte with stage 0. Selector-state evidence now covers length and equality only. The complete selector example executes all forms through the split owners.

The selected set contains 107 comparable products and 25 callable products. The linked closure retains 112 non-empty module products, 420 functions, and 14,883 forward-plus-inverse instructions. It contains 353,376 code bytes, 11,519 local-type rows, 684 source strings, and 553 unique strings. The 448,728-byte executable closure has SHA-256 `e8e6deaf102751653e8e55a370926012ff0cb63128a464aaddea5428f4894a42`.

## Bootstrap identities

The compiler graph contains 410 modules, two externals, and 1,958 imports. Its 188,974-byte canonical manifest has SHA-256 `85fb0c04a34e2ff36f183fd83f71b5ab2eaa9efc74044ab78d577df8158623a6`. Native validation halts after 79,464,145 transitions. Wheeler SHA-256 consumes the same bytes in 36,164,786 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,249,331-byte compiler archive has SHA-256 `a7674a7e3bc9cb9ce372d4ee07af20e7cf8a39c3908bd1cc0536f9263e2ae4b1`. Every dependent lock names that archive.

## Failure boundary

Reject a nonseparator after a proper prefix. Reject speculative projection after an equal range, unnamed coordinates, stale identity, archive mismatch, or closure mismatch before publication. The complete range owner remains unselected until its three imported policy calls compose exactly.

## Acceptance

- [x] Equal and directory-prefix completion have one owner.
- [x] Equal completion performs no out-of-range projection.
- [x] Scalar selector state contains no duplicate completion policy.
- [x] Equal, prefix, and nonseparator forms execute.
- [x] The retained artifact matches stage 0 byte for byte.
- [x] The physical set contains 132 products and 420 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Keep caller-projected completion state

Conditional projection followed by an imported result call failed physical composition and split coordinate ownership.

### Read the next scalar for equal ranges

Equal ranges have no next root scalar. Speculative projection would widen the caller's valid source window.

### Duplicate slash policy in the range owner

One completion owner keeps physical and stage-0 behavior identical.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0443](WIP-0443-retained-package-manifest-selector-state-product.md)
- [WIP-0445](WIP-0445-retained-package-manifest-selector-prefix-product.md)
