# WIP-0455: Retained package-manifest dependency-name product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-31 |
| Updated | 2026-08-31 |
| Area | Self-hosting, package manifests, dependency rows |
| Depends on | WIP-0049, WIP-0052, WIP-0421, WIP-0454 |
| Supersedes | Dependency name validation in `PackageManifest.w` |
| Superseded by | None |

## Summary

Split dependency name-field validation into `PackageManifestDependencyName.w`. Retain the owner as physical artifact 141 with three resolved policy calls.

## Dependency name

`manifestDependencyNameValid` checks the cursor-relative `name` key, requires a quoted value, projects its interior range through named locals, and calls canonical package-name validation. It fails after the first rejected condition.

The key coordinate and hash and the name-token coordinate bind before imported calls. `PackageManifest.w` composes this owner after dependency prefix validation and before version-constraint validation.

The retained module contains one function and 74 forward-plus-inverse instructions. Three relocations resolve key, quoted-token, and package-name policy.

## Evidence

`NativeCompilerPackageManifestDependencyNamePhysicalProductExampleTest` retains the owner, resolves all three call targets, and compares function and instruction counts with stage 0. Manifest behavior and identity examples validate accepted and malformed dependency names through the split path.

The selected set contains 108 comparable products and 33 callable products. The linked closure retains 121 non-empty module products, 430 functions, and 15,451 forward-plus-inverse instructions. It contains 367,352 code bytes, 12,071 local-type rows, 712 source strings, and 572 unique strings. The 466,360-byte executable closure has SHA-256 `861ca9f0a2b860630ec23f105a0e6b18217c59fb921586cf4050f77253531c23`.

## Bootstrap identities

The compiler graph contains 418 modules, two externals, and 1,982 imports. Its 192,232-byte canonical manifest has SHA-256 `fad1cf4bcab967b8ac8a21fa2662365cc2c1669954fe8026dabf468c16b1d3db`. Native validation halts after 81,074,974 transitions. The explicit closure budget rises from 81,000,000 to 82,000,000 transitions. Wheeler SHA-256 consumes the same bytes in 36,789,380 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,257,332-byte compiler archive has SHA-256 `d2a8f4789301a5f46e6edfddd02b4978aa692944a2636191a11efad031c54332`. Every dependent lock names that archive.

## Failure boundary

Reject the wrong name key, a nonquoted value, or an invalid package name. Reject unnamed imported-call operands, unresolved policy targets, stale graph identity, archive mismatch, or closure mismatch before publication.

## Acceptance

- [x] Dependency name validation has one callable owner.
- [x] Token coordinates and hash bind before imported calls.
- [x] Key, quoted-token, and package-name calls resolve.
- [x] Complete dependency behavior executes through the split path.
- [x] Retained function and instruction counts match stage 0.
- [x] The physical set contains 141 products and 430 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Leave package-name projection in the nominal parser

The field has a scalar verdict and no need to own the dependency result record.

### Duplicate package-name validation

The retained names owner remains canonical. Dependency validation supplies its bounded interior range.

### Merge the version field

Name and version fields resolve distinct validators and have independent failure boundaries.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0421](WIP-0421-retained-package-name-product.md)
- [WIP-0454](WIP-0454-retained-package-manifest-dependency-prefix-product.md)
