# WIP-0476: Retained package-manifest dependency rows

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-02 |
| Updated | 2026-09-02 |
| Area | Self-hosting, package manifests, dependency rows |
| Depends on | WIP-0049, WIP-0434, WIP-0470 |
| Supersedes | Direct dependency prefix, name, and version composition in `PackageManifest.w` |
| Superseded by | None |

## Summary

Retain complete dependency-row validation outside the package-manifest parser. `PackageManifestDependency.w` composes prefix, name, and semantic-version policy and returns the validated dependency kind.

## Row contract

`manifestDependencyRowKind` returns zero for a malformed row. A positive result is the canonical dependency kind supplied by prefix policy after both quoted fields pass their dedicated validators.

The parser keeps row iteration, capacity, ordering, coordinate projection, publication, and diagnostics. It no longer imports dependency prefix or version policy directly. It retains the name owner only for adjacent-row ordering.

## Physical route

The row owner has one function and three imported calls. It takes the direct imported structured-source path and enters the callable product suffix. Prefix, name, and version calls resolve to their retained products.

## Evidence

`NativeCompilerPackageManifestDependencyPhysicalProductExampleTest` compares the retained function and instructions with stage 0 and closes all three relocations. `NativeManifestExampleTest` executes canonical dependency rows and rejects malformed names, semantic versions, prefixes, and ordering through the composed verdict.

The selected set contains 112 comparable products and 45 callable products. It retains 137 non-empty module products, 476 functions, and 16,480 forward-plus-inverse instructions. The linked closure contains 392,800 code bytes, 13,182 local-type rows, 790 source strings, and 634 unique strings. Its 502,504-byte executable has SHA-256 `01ecdbc24e7452b8ef14bf8d7931e9d4862c4473ab3a17708952e4609b83340a`.

## Bootstrap identities

The compiler graph contains 434 modules, two externals, and 2,021 imports. Its 198,458-byte canonical manifest has SHA-256 `267cfacd53394d44670717198566114cdc4e7f51adb54f03fdcfa60eff1dccfa`. Native validation halts after 84,329,890 transitions under the 85,000,000-transition evidence ceiling. Wheeler SHA-256 consumes the same bytes in 37,990,918 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,279,474-byte compiler archive has SHA-256 `282dde50871003a01f66a529fb8fcb12b24c720420db29fc086d54558b99c659`. Every dependent lock names that archive.

## Failure boundary

Reject the row before extracting coordinates when its prefix, name, or version fails. Reject an unresolved field-policy call, stage-0 mismatch, stale graph identity, archive mismatch, linked-closure mismatch, or lock mismatch before bootstrap publication.

## Acceptance

- [x] Complete dependency-row validation has one owner.
- [x] The parser no longer imports dependency prefix or version policy.
- [x] A positive verdict preserves the dependency kind.
- [x] All three imported policy calls resolve exactly.
- [x] Valid and malformed dependency rows execute through the owner.
- [x] The retained library matches stage 0 byte for byte.
- [x] The linked closure contains 157 products and 476 functions.
- [x] Manifest, archive, executable, SHA-256, and locks name the row owner.

## Rejected alternatives

### Return only a Boolean

The parser must publish the dependency kind. A Boolean would require a second prefix-policy call or duplicate kind derivation.

### Move ordering into row validation

Ordering compares adjacent rows and belongs to collection policy. One-row validation has no previous coordinate.

### Move publication into the validator

Caller-owned tables and counters are parser state. Mutating them would couple reusable row grammar to storage layout.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0434](WIP-0434-isolated-package-canonical-row-projections.md)
- [WIP-0470](WIP-0470-retained-package-manifest-dependency-coordinates.md)
- [WIP-0475](WIP-0475-retained-package-manifest-empty-sections.md)
