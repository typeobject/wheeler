# WIP-0471: Retained package-manifest capability coordinates

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-02 |
| Updated | 2026-09-02 |
| Area | Self-hosting, package manifests, capability rows |
| Depends on | WIP-0049, WIP-0444, WIP-0457, WIP-0458, WIP-0470 |
| Supersedes | Inline capability token and quoted-range arithmetic in `PackageManifest.w` |
| Superseded by | None |

## Summary

Split capability row coordinates from parser control flow. `PackageManifestCapabilityCoordinates.w` owns the name token, path token, next token, quoted value start, and quoted value length.

## Coordinates

The three token projections are fixed offsets from a validated capability row cursor. The two value projections read a caller-owned token table and remove quote framing through named scalar locals. They do not validate row grammar, allocate a value, mutate a row, or advance parser state.

`parseCapability` runs the retained prefix and path verdicts before requesting token coordinates. `parseManifest` requests quoted ranges only after capacity and strict name-plus-path order succeed, then publishes the four-word row and advances aggregate state.

## Physical route

The owner has five call-free functions and takes the direct structured-source path. It follows the dependency-coordinate owner in the comparable prefix. `NativeCompilerPhysicalProductSource` names its source explicitly; signature synthesis cannot stand in for the file.

## Evidence

`NativeCompilerPackageManifestCapabilityCoordinatesPhysicalProductExampleTest` compares the retained library with stage 0 and executes all five projections against caller-owned word tables. `NativeManifestExampleTest` executes nonempty and empty capability collections through the split owner.

The selected set contains 112 comparable products and 42 callable products. It retains 134 non-empty module products, 466 functions, and 16,242 forward-plus-inverse instructions. The linked closure contains 386,968 code bytes, 12,915 local-type rows, 774 source strings, and 621 unique strings. Its 494,312-byte executable has SHA-256 `c6058c98df2ec5f1cefb5afe61ee32d6e01800f96ca0d2602b59868ed0c0c76a`.

## Bootstrap identities

The compiler graph contains 431 modules, two externals, and 2,017 imports. Its 197,486-byte canonical manifest has SHA-256 `755caddc198450433870dfb5355bae315ee08ddebee6a1903a58e04f88f85b6a`. Native validation halts after 83,741,288 transitions under the 84,000,000-transition evidence ceiling. Wheeler SHA-256 consumes the same bytes in 37,793,504 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,274,220-byte compiler archive has SHA-256 `16ffad697f44d8fd1006d386f84f784eed42e4e8cf29b13fb933490e532b6dad`. Every dependent lock names that archive.

## Failure boundary

Reject malformed capability grammar before projection and exhausted row storage before publication. Reject a stage-0 mismatch, stale graph identity, archive mismatch, linked-closure mismatch, or lock mismatch before bootstrap publication.

## Acceptance

- [x] Capability name, path, and next-token coordinates have one owner.
- [x] Quoted capability start and length use named scalar projections.
- [x] The parser carries no capability row-offset arithmetic.
- [x] All five projections execute against caller-owned tables.
- [x] The retained library matches stage 0 byte for byte.
- [x] The linked closure contains 154 products and 466 functions.
- [x] Manifest, archive, executable, SHA-256, and locks name both coordinate owners.

## Rejected alternatives

### Reuse dependency token offsets

Dependency and capability rows have different widths and field positions. Coupling their offsets would turn coincidental arithmetic into a schema dependency.

### Return a capability record

The parser already owns the validated parse record and destination row. Scalar projections keep publication authorization explicit.

### Move row mutation into the owner

Capacity, composite ordering, count, and storage belong to parser state. Scalar projection does not require a second mutation boundary.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0444](WIP-0444-retained-package-manifest-range-product.md)
- [WIP-0457](WIP-0457-retained-package-manifest-capability-prefix-product.md)
- [WIP-0458](WIP-0458-retained-package-manifest-capability-path-product.md)
- [WIP-0470](WIP-0470-retained-package-manifest-dependency-coordinates.md)
