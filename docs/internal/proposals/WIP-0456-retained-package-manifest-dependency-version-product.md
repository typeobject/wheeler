# WIP-0456: Retained package-manifest dependency-version product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-31 |
| Updated | 2026-08-31 |
| Area | Self-hosting, package manifests, dependency rows |
| Depends on | WIP-0049, WIP-0052, WIP-0431, WIP-0455 |
| Supersedes | Dependency version validation in `PackageManifest.w` |
| Superseded by | None |

## Summary

Split dependency version-field validation into `PackageManifestDependencyVersion.w`. Retain the owner as physical artifact 142 with three resolved policy calls.

## Dependency version

`manifestDependencyVersionValid` checks the cursor-relative `version` key, requires a quoted value, projects its interior range through named locals, and calls canonical semantic-version constraint validation. It fails after the first rejected condition.

The key coordinate and hash and the version-token coordinate bind before imported calls. `PackageManifest.w` composes this owner after retained prefix and name products, then constructs the nominal dependency result.

The retained module contains one function and 74 forward-plus-inverse instructions. Three relocations resolve key, quoted-token, and semantic-version policy.

## Evidence

`NativeCompilerPackageManifestDependencyVersionPhysicalProductExampleTest` retains the owner, resolves all three call targets, and compares function and instruction counts with stage 0. Manifest behavior and identity examples validate accepted and malformed constraints through the split path.

The selected set contains 108 comparable products and 34 callable products. The linked closure retains 122 non-empty module products, 431 functions, and 15,525 forward-plus-inverse instructions. It contains 369,200 code bytes, 12,145 local-type rows, 715 source strings, and 574 unique strings. The 468,672-byte executable closure has SHA-256 `c535de6e7fbde7f8fa98416eb8b727ef051b899e0eea827642b68ff1094e6756`.

## Bootstrap identities

The compiler graph contains 419 modules, two externals, and 1,986 imports. Its 192,705-byte canonical manifest has SHA-256 `cc975d7a662602c328fbf6db06694d91e6f9c1ed2e3ac69509c6f795d8ba87e6`. Native validation halts after 81,309,996 transitions. Wheeler SHA-256 consumes the same bytes in 36,887,660 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,258,682-byte compiler archive has SHA-256 `8741246c091b2d20a4b6ea734b6ad157e9f5f8cde727d7aeb3c332f54bc6f775`. Every dependent lock names that archive.

## Failure boundary

Reject the wrong version key, a nonquoted value, or an invalid semantic-version constraint. Reject unnamed imported-call operands, unresolved policy targets, stale graph identity, archive mismatch, or closure mismatch before publication.

## Acceptance

- [x] Dependency version validation has one callable owner.
- [x] Token coordinates and hash bind before imported calls.
- [x] Key, quoted-token, and constraint calls resolve.
- [x] Complete dependency behavior executes through the split path.
- [x] Retained function and instruction counts match stage 0.
- [x] The physical set contains 142 products and 431 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Keep version projection in the nominal parser

The field has a scalar verdict and no need to own the dependency result record.

### Validate only semantic releases

Dependency rows carry constraints. The retained semantic-version facade owns that distinct grammar.

### Merge the dependency facade immediately

The nominal result record remains private to the parser. Prefix, name, and version leaves now have exact independent evidence.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0431](WIP-0431-retained-semver-facade-product.md)
- [WIP-0455](WIP-0455-retained-package-manifest-dependency-name-product.md)
