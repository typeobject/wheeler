# WIP-0449: Retained package-manifest header-preamble product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-31 |
| Updated | 2026-09-05 |
| Area | Self-hosting, package manifests, callable products |
| Depends on | WIP-0049, WIP-0052, WIP-0448 |
| Supersedes | Format preamble composition in `PackageManifest.w` |
| Superseded by | None |

## Summary

Split format and package-map preamble validation into `PackageManifestHeaderPreamble.w`. Retain the owner as physical artifact 135 with five resolved policy calls.

## Preamble validation

`manifestHeaderPreambleValid` checks token capacity, the `schema` key, schema
version `1`, and the `package` opener. It fails after the first rejected condition.
WIP-0049 replaced hash comparisons with exact word codes. Other retained owners
now validate name, release, profile, and complete target admission.

Every token coordinate and word code binds to a named local before an imported call. The first physical attempt passed literals directly to the seven-argument key call and failed before publication. Named operands use the established imported-call source form and preserve exact stage-0 code.

The original artifact contained one function and 83 instructions. Five relocations
now resolve to header count, two key checks, exact token classification, and
format-version policy. The following identities record the original milestone.

## Evidence

`NativeCompilerPackageManifestHeaderPreamblePhysicalProductExampleTest` retains the owner, resolves all five call targets, and compares its function and instruction counts with stage 0. Manifest examples accept the canonical preamble and reject malformed documents through the split path.

The selected set contains 108 comparable products and 27 callable products. The linked closure retains 115 non-empty module products, 424 functions, and 15,021 forward-plus-inverse instructions. It contains 356,744 code bytes, 11,651 local-type rows, 694 source strings, and 560 unique strings. The 453,184-byte executable closure has SHA-256 `84d9db22e05bc0bae4391cc87d3f409a22a50fa39ac55ea10ff37ea63b3fb12a`.

## Bootstrap identities

The compiler graph contains 412 modules, two externals, and 1,962 imports. Its 189,693-byte canonical manifest has SHA-256 `66c1089731b1f1318db3dac0c6491e340a92d71ff3f1e0690d115f6a6978ad07`. Native validation halts after 80,248,236 transitions. The explicit closure budget rises from 80,000,000 to 81,000,000 transitions. Wheeler SHA-256 consumes the same bytes in 36,313,192 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,251,312-byte compiler archive has SHA-256 `05e474b60709194919c4e164fae8845e51a4322efd8705b103052e24cf0b0cb7`. Every dependent lock names that archive.

## Failure boundary

Reject insufficient tokens, the wrong format key, a format scalar other than `1`, or the wrong package opener. Reject literal imported-call operands, unresolved policy targets, stale graph identity, archive mismatch, or closure mismatch before publication.

## Acceptance

- [x] Format preamble policy has one callable owner.
- [x] Imported call operands are named before resolution.
- [x] All five policy calls resolve.
- [x] Complete manifest behavior executes through the split path.
- [x] Retained function and instruction counts match stage 0.
- [x] The physical set contains 135 products and 424 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Move the complete header at once

Thirteen imported calls combined literal operands, token projections, and value validation. The direct product failed closed before identifying an exact owner.

### Pass literal call operands

Stage 0 accepts them, but the physical imported-call source profile requires named prior locals. Naming coordinates and word codes closes the exact product.

### Duplicate word classification

The token owner identifies exact spellings. The preamble resolves that product
instead of copying its policy.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0448](WIP-0448-retained-package-manifest-header-state-product.md)
