# WIP-0464: Retained package-manifest target-test product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-01 |
| Updated | 2026-09-01 |
| Area | Self-hosting, package manifests, target rows |
| Depends on | WIP-0049, WIP-0463 |
| Supersedes | Inline target test policy in `PackageManifest.w` |
| Superseded by | None |

## Summary

Split target test policy into `PackageManifestTargetTest.w`. The owner admits tests on deployable and tool targets and rejects an enabled test on a library target. It is retained as physical artifact 149.

## Test policy

`manifestTargetTestAllowed` accepts a decoded target kind and canonical Boolean value. It first derives whether testing is disabled. A library returns that value. Every other admitted kind returns true. The manifest parser has already rejected unknown kinds and malformed Boolean tokens.

This form removes the nested kind-and-value branch from `PackageManifest.w`. More importantly, it states the policy without a comparison expression in a conditional return. The source-product profile retains one Boolean declaration, one signed equality guard, one preserved Boolean return, and one final Boolean literal return. No package-specific lowering rule is involved.

## Evidence

`NativeCompilerPackageManifestTargetTestPhysicalProductExampleTest` executes all six admitted kind/value pairs. Its closure-evidence case compiles the owner from the canonical archive and compares the complete emitted library byte for byte with stage 0. `NativeManifestExampleTest` continues to accept tested tools and deployables and to reject malformed target rows through the composed parser.

The selected set contains 110 comparable products and 39 callable products. It retains 129 non-empty module products, 447 functions, and 15,954 forward-plus-inverse instructions. The linked closure contains 379,800 code bytes, 12,577 local-type rows, 745 source strings, and 597 unique strings. Its 483,192-byte executable has SHA-256 `2e0e7465bc53bcd384f6c69ce964aa053b0f422a4d256d2884520024deddac4e`.

## Bootstrap identities

The compiler graph contains 426 modules, two externals, and 2,007 imports. Its 195,584-byte canonical manifest has SHA-256 `9790d70a6d6bbc16a320cd485c045d331c4edc10b0baf95d7fca8410c31dbbad`. Native validation halts after 82,983,710 transitions. Wheeler SHA-256 consumes the same bytes in 37,438,731 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,265,114-byte compiler archive has SHA-256 `ddb6ee0b69e0821acb5091f9eec7676c91dc0d135534ff5cd0ea3195194797e2`. Every dependent lock names that archive.

## Failure boundary

Reject an unknown kind or malformed Boolean before policy dispatch. Reject an enabled library test before target publication. Reject a source-product mismatch, stale graph identity, archive mismatch, or linked-closure mismatch before bootstrap publication.

## Acceptance

- [x] Target test policy has one scalar owner.
- [x] All admitted kind/value pairs execute.
- [x] Libraries reject enabled tests and accept disabled tests.
- [x] The parser contains no duplicate kind/test branch.
- [x] The retained library matches stage 0 byte for byte.
- [x] The linked closure contains 149 products and 447 functions.
- [x] Manifest, archive, executable, SHA-256, and locks name the split owner.

## Rejected alternatives

### Keep the nested parser branch

The rule is independent of token storage and nominal target construction. Keeping it inline leaves no physical owner for policy review or reuse.

### Return a comparison from inside the guard

The structured source profile does not retain comparison-valued conditional returns. Naming the disabled state yields the same policy through ordinary preserved-value products.

### Admit tests on library targets

A library has no runnable test selection. Package test targets remain deployables or tools with explicit test enablement.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0463](WIP-0463-retained-package-manifest-target-row-coordinates.md)
