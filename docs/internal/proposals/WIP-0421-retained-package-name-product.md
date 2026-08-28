# WIP-0421: Retained package-name product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-28 |
| Updated | 2026-08-28 |
| Area | Self-hosting, package names, bounded state machines |
| Depends on | WIP-0049, WIP-0052, WIP-0417, WIP-0419, WIP-0420 |
| Supersedes | Stage-0-only `Names.w` product evidence |
| Superseded by | None |

## Summary

Retain `wheeler.compiler.packages.names` as the 110th physical compiler product. Replace nested loop control with explicit total state machines for module, workspace, and package names. Match the verified stage-0 artifact byte for byte.

## Problem

The package parser calls three bounded name validators. Their former implementation returned from nested loop blocks and mixed calls, punctuation branches, and UTF-8 updates in one control tree. The physical source path rejects such a tree rather than inventing an instruction order.

The scalar helpers also used literal-left ranges such as `96 < scalar`. Direct conditional products require a resolved local on the left. Bare Boolean guards such as `if (lower)` were outside the exact equality form retained by the root conditional product.

## State machines

Every machine uses signed state zero as an absorbing invalid state. State one requests a segment value. State two records a complete value.

The module machine accepts ASCII letters or underscore at segment start. It accepts those scalars plus digits while following a value. A dot returns to state one.

The package machine accepts a lowercase letter at segment start. It accepts lowercase letters and digits while following a value. A dot returns to state one.

The workspace machine uses state three for the first scalar. That state accepts only a lowercase letter, preserving the old final lowercase check without a Boolean conjunction. Later segment starts accept lowercase letters or digits. Dash and dot return to state one.

Each transition helper returns one of the closed states. Invalid input cannot recover because every dispatcher returns zero immediately when its prior state is zero. The public loop performs one scalar projection, one width projection, one transition call, one signed assignment, and one cursor update per iteration. It accepts only final state two.

## Conditional shape

Lowercase, uppercase, and digit ranges now put `scalar` on the left of each comparison. Boolean call results use explicit equality with `true`. Every root conditional has exactly one return child.

Dispatchers name start and following transition results before selecting one. Calls remain pure. The structure makes source order, result ownership, and physical local width visible without a second parser path.

## Evidence

`NativeCompilerPackageNamesPhysicalProductExampleTest` compiles the archive source through the native physical pipeline. The produced container passes the Wheeler verifier and matches every stage-0 byte.

The selected set contains 93 comparable products and 17 callable products. The linked closure retains 90 non-empty module products, 305 functions, and 11,696 forward-plus-inverse instructions. It contains 276,472 code bytes, 8,651 local-type rows, 525 source strings, and 416 unique strings. The 347,064-byte executable closure has SHA-256 `013a36b669707f89add1c615558cdeb593460ebdc24e264caff6d37fb8b8877f`.

## Bootstrap identities

The compiler graph remains at 387 modules, two externals, and 1,931 imports. Its 181,926-byte canonical manifest has SHA-256 `cadb45f0ed252dc778d4b62346abedef1146419f9880e56da47e4ac238e30709`. Native validation halts after 75,749,024 transitions. Wheeler SHA-256 consumes the same bytes in 34,817,790 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,206,518-byte compiler archive has SHA-256 `e0522ec57904c44cbc4dcf1b41f7084b71d8f4802a720f491703cb2987f122ed`. Every dependent lock names that archive.

## Failure boundary

Reject an empty name, malformed UTF-8 projection, unresolved call result, unsupported local type, coordinate above 255, invalid transition state, failed physical mapping, over-bound loop frame, invalid artifact, or stale source identity before publication. An invalid state remains invalid for the rest of its bounded loop.

## Acceptance

- [x] Module, workspace, and package validation use closed total state machines.
- [x] Invalid state is absorbing.
- [x] Every loop iteration has one named scalar and width product.
- [x] Root conditionals use local-left comparisons or Boolean literal equality.
- [x] The native artifact passes the Wheeler verifier.
- [x] The complete artifact matches stage 0 byte for byte.
- [x] The physical set contains 110 products and 305 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the new source.

## Rejected alternatives

### Teach loop emission to flatten arbitrary control trees

That would turn a bounded product into a second general compiler. Explicit transition functions are smaller and reviewable.

### Recover after an invalid scalar

A later valid segment cannot repair an earlier grammar violation. State zero is absorbing by construction.

### Recheck the first workspace scalar after the loop

The dedicated first state expresses the rule once and avoids combining two Boolean results at return time.

### Preserve literal-left range tests

Swapping the syntax without changing the relation is not possible for ordered comparisons. The helpers use equivalent half-open local-left ranges.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0417](WIP-0417-utf8-loop-projection-products.md)
- [WIP-0419](WIP-0419-local-right-nested-loop-guards.md)
- [WIP-0420](WIP-0420-retained-package-manifest-token-product.md)
