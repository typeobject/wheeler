# WIP-0468: Retained package-manifest target-source coordinates

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-02 |
| Updated | 2026-09-02 |
| Area | Self-hosting, package manifests, target rows |
| Depends on | WIP-0049, WIP-0444, WIP-0467 |
| Supersedes | Inline source-row coordinate publication in `PackageManifest.w` |
| Superseded by | None |

## Summary

Retain the two quoted-interior projections used to publish target source rows. `PackageManifestTargetSourceCoordinates.w` owns the start and length arithmetic. `PackageManifest.w` stores only the returned coordinates.

## Coordinates

`manifestTargetSourceStart` reads the quoted token start and advances over the opening quote. `manifestTargetSourceLength` reads the token length and removes both quotes. Each intermediate value has a name. Neither function validates token grammar, allocates storage, or mutates a row.

WIP-0467 proves selector validity before these projections run. The parser computes a source-table base, requests the two interior coordinates, stores them, and advances aggregate state. This keeps token framing out of the publication path without moving caller-owned storage into scalar policy.

## Physical route

The coordinate owner has no imports and takes the direct structured-source path. It is retained as comparable artifact 111. The prior 110 comparable artifacts keep their order. The target-source policy advances to callable artifact 152. Physical source routing names the coordinate module explicitly, so no signature-only source replaces it.

## Evidence

`NativeCompilerPackageManifestTargetSourceCoordinatesPhysicalProductExampleTest` compares the retained library with stage 0 and executes both projections against caller-owned word tables. `NativeCompilerPackageManifestTargetSourcePhysicalProductExampleTest` continues to close the four path, token, order, and coverage relocations. `NativeManifestExampleTest` executes publication through valid and malformed target source lists.

The selected set contains 111 comparable products and 41 callable products. It retains 132 non-empty module products, 453 functions, and 16,118 forward-plus-inverse instructions. The linked closure contains 383,936 code bytes, 12,759 local-type rows, 757 source strings, and 606 unique strings. Its 488,904-byte executable has SHA-256 `db1f11c3b67babc78a0d642768a85b0597fbda6925cc0c9b982301b20aff7739`.

## Bootstrap identities

The compiler graph contains 429 modules, two externals, and 2,012 imports. Its 196,653-byte canonical manifest has SHA-256 `d7a58e85f5343d197a1f8c5fa3dcf5c9a4709899a73bab5f1175171ea4f131bf`. Native validation halts after 83,611,146 transitions under the 84,000,000-transition evidence ceiling. Wheeler SHA-256 consumes the same bytes in 37,634,314 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,268,639-byte compiler archive has SHA-256 `7a1c0da4fc1acb3fe15ce2b0dcf0e37bd7bd6304f8453c4bf3da03657e092c8d`. Every dependent lock names that archive.

## Failure boundary

Reject an invalid quoted selector before coordinate projection. Reject a stage-0 mismatch, stale graph identity, archive mismatch, linked-closure mismatch, or lock mismatch before publication.

## Acceptance

- [x] Source-row start and length each have one scalar owner.
- [x] Both owners use named token and interior coordinates.
- [x] The parser no longer performs quote arithmetic at publication.
- [x] The coordinate owner executes against caller-owned word tables.
- [x] The retained library matches stage 0 byte for byte.
- [x] The linked closure contains 152 products and 453 functions.
- [x] Manifest, archive, executable, SHA-256, and locks name the split owner.

## Rejected alternatives

### Return a record

The publication site already owns two scalar stores. A record would add construction and field-projection machinery without expressing a stronger invariant.

### Pass raw token coordinates

The token table is the canonical source of parser coordinates. Passing copied values would duplicate the framing boundary in each caller.

### Publish the source row inside the owner

The parser owns table capacity, row base, count, and mutation order. A scalar coordinate owner keeps that boundary visible.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0444](WIP-0444-retained-package-manifest-range-product.md)
- [WIP-0467](WIP-0467-retained-package-manifest-target-source-policy.md)
