# WIP-0466: Retained package-manifest target-source product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-01 |
| Updated | 2026-09-01 |
| Area | Self-hosting, package manifests, target rows |
| Depends on | WIP-0049, WIP-0422, WIP-0463, WIP-0465 |
| Supersedes | Source-selector path validation in `PackageManifest.w` |
| Superseded by | None |

## Summary

Split one target source-selector verdict into `PackageManifestTargetSource.w`. The owner requires a quoted logical path and is retained as physical artifact 151 with two resolved policy calls.

## Source selector

`manifestTargetSourceValid` accepts a caller-projected selector token. It checks quoted-token grammar, names the token start and length, derives the interior range, and applies canonical logical-path grammar. It owns no loop cursor, source-row table, ordering state, or root-coverage state.

`PackageManifest.w` obtains each selector coordinate from WIP-0463 and calls the focused owner before row capacity, ordering, coverage, or publication. The broad path import leaves the parser facade. A malformed selector terminates row scanning and cannot be mistaken for the trailing test field.

## Physical route

The source owner uses the direct imported structured-source path. Its explicit route entry prevents signature-only source synthesis. Quoted-token and logical-path relocations resolve against retained physical owners before the complete artifact is archived.

## Evidence

`NativeCompilerPackageManifestTargetSourcePhysicalProductExampleTest` compares retained function and instruction counts with stage 0 and closes both policy relocations. `NativeManifestExampleTest` executes two ordered selectors and rejects an escaping selector, wrong root coverage, reversed order, and excess target rows through the composed parser.

The selected set contains 110 comparable products and 41 callable products. It retains 131 non-empty module products, 449 functions, and 16,036 forward-plus-inverse instructions. The linked closure contains 381,864 code bytes, 12,663 local-type rows, 751 source strings, and 601 unique strings. Its 485,896-byte executable has SHA-256 `4a96f6d0204dc6a27958e519e8b2a79410002128a0d4e116b9d8288a7b70b41d`.

## Bootstrap identities

The compiler graph contains 428 modules, two externals, and 2,011 imports. Its 196,306-byte canonical manifest has SHA-256 `74c6fdc15c13f76a66243a24087414aa9e6b2fe444bdf707f8f167b8ca11f296`. Native validation halts after 83,467,781 transitions under the 84,000,000-transition evidence ceiling. Wheeler SHA-256 consumes the same bytes in 37,573,300 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,266,954-byte compiler archive has SHA-256 `76854d972a4d601b33ec69c604a32b1f650636bfcbb7e442b1d276d3656ee862`. Every dependent lock names that archive.

## Failure boundary

Reject an unquoted or invalid logical-path selector before capacity, ordering, coverage, or row publication. Reject unresolved token or path policy, a stage-0 mismatch, stale graph identity, archive mismatch, or linked-closure mismatch before bootstrap publication.

## Acceptance

- [x] Source-selector path validity has one callable owner.
- [x] The owner takes one caller-projected token coordinate.
- [x] The parser no longer imports broad path policy.
- [x] Quoted-token and logical-path calls resolve exactly.
- [x] Valid and malformed selector lists execute through the split owner.
- [x] The retained library matches stage 0 byte for byte.
- [x] The linked closure contains 151 products and 449 functions.
- [x] Manifest, archive, executable, SHA-256, and locks name the split owner.

## Rejected alternatives

### Move selector iteration into the owner

Iteration also owns row capacity, strict ordering, root coverage, and publication. Combining those concerns would create a second manifest parser rather than a source-path authority.

### Pass raw start and length

The package schema owns quoted token framing. Passing the token keeps that framing and logical-path validation under one verdict.

### Keep direct path calls in the facade

The facade should compose row policy. It should not implement path grammar.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0422](WIP-0422-retained-package-path-product.md)
- [WIP-0463](WIP-0463-retained-package-manifest-target-row-coordinates.md)
- [WIP-0465](WIP-0465-retained-package-manifest-target-module-product.md)
