# WIP-0437: Retained package-canonical token-state product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-29 |
| Updated | 2026-08-29 |
| Area | Self-hosting, package manifests, token windows |
| Depends on | WIP-0049, WIP-0052, WIP-0433, WIP-0436 |
| Supersedes | Nested token-window break logic in `PackageCanonical.w` |
| Superseded by | None |

## Summary

Split canonical line token traversal into `PackageCanonicalTokenWindow.w` and scalar state into `PackageCanonicalTokenState.w`. Retain the two state products as the 124th physical compiler artifact. Keep the row-backed traversal owner outside the physical set until local calls inside that loop verify.

## Token state

`canonicalProjectedToken` advances to the named next coordinate while the current token starts before the line end. Otherwise it preserves the current coordinate.

`canonicalProjectedTokenLimit` preserves the count limit while traversal remains active. At the first token outside the line it closes the limit at the current coordinate. The loop then terminates without `break` or early return.

Both functions consume one Boolean and two signed values. They have no imports, loops, buffers, or mutable state. Together they retain two functions and 18 forward-plus-inverse instructions.

## Token window

`canonicalLineTokenEnd` carries cursor and mutable limit. Each iteration reads one named row start, names the next coordinate, computes `start < lineEnd`, and calls both state products. The caller rejects an empty `[first, end)` window.

`PackageCanonical.w` deletes its nested token loop and three separate preconditions. One token-window call now distinguishes exhaustion, an out-of-line first token, and a nonempty line window.

The row-backed token-window owner executes correctly under stage 0. Its physical attempt fails before artifact publication when the loop calls its local row and state helpers. It remains unselected. This WIP retains only the closed state owner.

## Evidence

`NativeCompilerPackageCanonicalTokenStatePhysicalProductExampleTest` compares the complete state artifact byte for byte with stage 0. Its executable fixture covers advance, stop, limit preservation, and limit closure.

`NativeCompilerPackageCanonicalTokenWindowExampleTest` executes a three-token line window, an out-of-line first token, and an exhausted token set through the split traversal owner.

The selected set contains 101 comparable products and 23 callable products. The linked closure retains 104 non-empty module products, 404 functions, and 14,443 forward-plus-inverse instructions. It contains 342,784 code bytes, 11,113 local-type rows, 652 source strings, and 529 unique strings. The 434,496-byte executable closure has SHA-256 `0736b1f337ad31755c222f970ccc9bb956b3233cf49464291c999a5742bd1bef`.

## Bootstrap identities

The compiler graph contains 401 modules, two externals, and 1,947 imports. Its 186,227-byte canonical manifest has SHA-256 `e798863f66e42ce58a7e3d3e83ba85dd93d5967c375d82b33e0e77640d7f6778`. Native validation halts after 78,057,365 transitions. The explicit closure budget rises from 78,000,000 to 79,000,000 transitions. Wheeler SHA-256 consumes the same bytes in 35,638,168 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,239,142-byte compiler archive has SHA-256 `8ebb91bed7c4c8cf3c7b14451d469c7d42cf7862bb128eb07a8fa7fcd1dffc0c`. Every dependent lock names that archive.

## Failure boundary

Reject token exhaustion, an out-of-line first token, invalid row coordinate, unresolved state call, row-backed loop artifact failure, stale graph identity, or archive mismatch before publication. The failed token-window artifact never enters the selected set.

## Acceptance

- [x] Token advance and stop state have one scalar owner.
- [x] The canonical root contains no nested token loop.
- [x] Advance and stop states execute.
- [x] The split token window executes all terminal cases.
- [x] The state artifact matches stage 0 byte for byte.
- [x] The row-backed owner remains unselected after physical failure.
- [x] The physical set contains 124 products and 404 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Preserve `break` in the root loop

Mutable cursor and limit state expresses the same boundary without abrupt control flow.

### Claim the row-backed window is retained

Stage execution and fail-closed physical behavior are not artifact equality.

### Scan the complete token set for every line

Closing the limit at the first outside token preserves the original monotonic traversal.

### Widen loop-call limits

The scalar split fits existing limits. Local row-backed loop calls remain a focused compiler boundary.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0433](WIP-0433-retained-package-canonical-line-kind-product.md)
- [WIP-0436](WIP-0436-retained-package-canonical-profile-product.md)
