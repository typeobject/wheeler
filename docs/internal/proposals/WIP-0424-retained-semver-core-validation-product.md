# WIP-0424: Retained semantic-version core validation product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-28 |
| Updated | 2026-08-28 |
| Area | Self-hosting, semantic versions, bounded validation |
| Depends on | WIP-0049, WIP-0052, WIP-0417, WIP-0418, WIP-0423 |
| Supersedes | WIP-0423 scalar-only semantic-version owner |
| Superseded by | None |

## Summary

Extend the retained semantic-version scalar owner into `SemverCoreValidation.w`. Validate major, minor, and patch components with one total bounded state machine. Split prerelease and constraint validation into a separate owner before it exceeds the native verifier's 24-function artifact bound.

## Problem

Core validation formerly combined numeric classification, leading-zero policy, signed overflow checks, component resets, UTF-8 traversal, and loop-body returns. The scalar-only WIP proved the character authority but left this state in `Semver.w`.

A first combined validation owner produced a byte-exact 35-function artifact. Stage 0 accepted it, but the native verifier rejected it because the bounded interpreter profile admits at most 24 functions per artifact. Raising that bound would enlarge every verifier and interpreter table to avoid a source split.

## Ownership split

`SemverCoreValidation.w` owns scalar classification and core-triplet validation. It contains 16 retained functions plus its library entry and stays below the verifier bound.

`SemverPrereleaseValidation.w` owns prerelease, release, and constraint validation. It imports the core owner. `Semver.w` remains the public facade and imports both validation and comparison authorities. The old scalar-only file and the rejected combined owner are deleted.

The compiler graph gains one module because prerelease validation now has an explicit owner. No duplicate scalar predicate remains.

## Core state

Core validation tracks mode, dot count, digit count, first scalar, and current component value. Mode zero is invalid and absorbing. Mode one is valid.

Numeric transitions reject a leading zero after the first digit. Overflow checks compare the accumulated value with `922337203685477580` and admit a final digit no larger than seven. Dot transitions require a nonempty component, admit only two separators, and reset digit, first-scalar, and value state.

Every loop iteration computes all next fields from the same prior row. Multiplication and addition are named arithmetic products. The final predicate requires valid mode, exactly two dots, and a nonempty patch component.

Prerelease validation uses a separate state owner. Its byte-exact product is not retained by this WIP because imported-call closure and its own artifact bound remain separate review units.

## Evidence

`NativeCompilerSemverCorePhysicalProductExampleTest` compiles the core owner through the native physical pipeline. The Wheeler verifier accepts the result and every byte matches stage 0.

The selected set remains at 95 comparable products and 17 callable products because the core product replaces the scalar product. The linked closure retains 92 non-empty module products, 333 functions, and 12,567 forward-plus-inverse instructions. It contains 297,352 code bytes, 9,380 local-type rows, 557 source strings, and 446 unique strings. The 373,752-byte executable closure has SHA-256 `267f7873478bfb267d17a9255df99bf745b12b91a8a57c79d3707d3272e6b930`.

## Bootstrap identities

The compiler graph contains 389 modules, two externals, and 1,934 imports. Its 182,575-byte canonical manifest has SHA-256 `3c8fd97fcca0c2694bb03916622b88372380afa09e0aae5021729df8a9933875`. Native validation halts after 76,374,912 transitions. Wheeler SHA-256 consumes the same bytes in 34,940,178 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,216,437-byte compiler archive has SHA-256 `43eba0d40c8c1a8ddbf1f6c9bd6d13c1eb59af2fb663ee81ae056e177d5d7296`. Every dependent lock names that archive.

## Failure boundary

Reject a non-digit core scalar, empty component, extra dot, leading zero, signed overflow, malformed UTF-8 projection, unresolved transition call, coordinate above 255, artifact above 24 functions, invalid artifact, or stale source identity before publication. Invalid mode cannot recover.

## Acceptance

- [x] Scalar and core validation have one owner.
- [x] Core mode is total and invalid state is absorbing.
- [x] Leading-zero and signed-overflow policy is explicit.
- [x] All next fields consume one prior state row.
- [x] Every physical artifact stays within 24 functions.
- [x] The native core artifact passes the Wheeler verifier.
- [x] The complete core artifact matches stage 0 byte for byte.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split graph.

## Rejected alternatives

### Raise the interpreter function bound

The 35-function artifact was already too broad for useful review. Raising a global bound to retain it would spend memory instead of separating concerns.

### Keep scalar predicates in a second owner

Core validation calls them on every scalar. Co-location avoids imported relocations and keeps one ASCII authority.

### Accumulate with unchecked arithmetic

Canonical release components remain signed values. The transition checks the exact final prefix and digit before multiplication commits.

### Pack all state into one integer

Packing would require another codec and obscure overflow review. Five signed locals remain well inside the frame bound.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0417](WIP-0417-utf8-loop-projection-products.md)
- [WIP-0418](WIP-0418-focused-loop-arithmetic-declarations.md)
- [WIP-0423](WIP-0423-retained-semver-scalar-product.md)
