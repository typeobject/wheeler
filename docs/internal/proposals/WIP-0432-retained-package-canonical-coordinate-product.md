# WIP-0432: Retained package-canonical coordinate product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-29 |
| Updated | 2026-08-29 |
| Area | Self-hosting, package manifests, bounded coordinates |
| Depends on | WIP-0049, WIP-0052, WIP-0417, WIP-0420 |
| Supersedes | Private line and indentation loops in `PackageCanonical.w` |
| Superseded by | None |

## Summary

Split line-end and exact-indent projection into `PackageCanonicalCoordinates.w`. Retain it as the 120th physical compiler product and route `PackageCanonical.w` through the new owner.

## Problem

Canonical package-manifest layout mixed coordinate traversal with line grammar. `lineEnd` returned from inside a UTF-8 loop. `exactIndent` returned at the first width or scalar mismatch. Both are small state products needed by every canonical line, but neither had independent physical evidence.

A first line cursor sent newline directly to the source end and returned that cursor. It stopped correctly but lost the newline coordinate. Stop state and projected result need separate fields.

## Line state

`canonicalLineEnd` carries cursor, source end, and a projected end initialized to the source end. Each iteration projects one scalar and width. Newline sends the cursor to the source end and records the prior cursor as the projected result. Other scalars advance by their UTF-8 width and preserve the projection.

The loop has no early return and no duplicate scalar or width read. A line without newline returns the source end.

## Indentation state

`canonicalExactIndent` first compares `tokenStart` with `lineStart + expected`. Signed state one means valid and zero means invalid. It then scans at most six prefix bytes. Space preserves one. Any other scalar or an initial width mismatch makes zero absorbing.

The public Boolean result is derived once after traversal. The canonical grammar remains responsible for admitting only zero-, two-, four-, and six-space expectations.

`PackageCanonical.w` deletes both private loops. Plain and dashed line checks call the same retained indentation authority. The root line loop calls the retained line-end authority.

## Evidence

`NativeCompilerPackageCanonicalCoordinatesPhysicalProductExampleTest` compares the complete native artifact byte for byte with stage 0. Its executable fixture checks two newline coordinates, source-end fallback, zero and two spaces, a width mismatch, and a nonspace prefix.

The selected set contains 97 comparable products and 23 callable products. The linked closure retains 100 non-empty module products, 394 functions, and 14,225 forward-plus-inverse instructions. It contains 337,744 code bytes, 10,942 local-type rows, 634 source strings, and 515 unique strings. The 427,520-byte executable closure has SHA-256 `b13046fbfee56c8e9eb11617705c67af0e48b8dd7464696eba26b7905abfa57e`.

## Bootstrap identities

The compiler graph contains 395 modules, two externals, and 1,941 imports. Its 184,457-byte canonical manifest has SHA-256 `1904e5d0fa6d9531cfd3efdd052d8ad74bef0b63c776168ee3cf440417d72d8b`. Native validation halts after 77,212,157 transitions. Wheeler SHA-256 consumes the same bytes in 35,307,862 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,229,115-byte compiler archive has SHA-256 `999251478e7ce21e59f7aec860a7fb316500d7b712b95bdd5a6e9479adf26bc2`. Every dependent lock names that archive.

## Failure boundary

Reject a source above 262,144 bytes at the canonical caller, malformed UTF-8 projection, line cursor above the source end, indent above six bytes, token coordinate inconsistent with expected width, nonspace prefix, unresolved coordinate call, invalid artifact, or stale graph identity before publication.

## Acceptance

- [x] Line and indentation coordinates have one focused owner.
- [x] `PackageCanonical.w` contains no private coordinate loop.
- [x] Stop cursor and projected line end are separate state.
- [x] Indent failure is absorbing.
- [x] Focused coordinate cases execute.
- [x] The native artifact matches stage 0 byte for byte.
- [x] The physical set contains 120 products and 394 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Return the stop cursor

Newline uses the source end to stop traversal. Returning that cursor discards the delimiter coordinate.

### Re-scan indentation in plain and dashed owners

Both line shapes require the same exact prefix contract. Duplicate loops would create two layout authorities.

### Count spaces without checking token start

A valid prefix is not enough. The first token must begin at the exact expected coordinate.

### Retain all canonical-line policy at once

Coordinate mechanics and line grammar have different invariants. This WIP keeps the first physical step small.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0417](WIP-0417-utf8-loop-projection-products.md)
- [WIP-0420](WIP-0420-retained-package-manifest-token-product.md)
