# WIP-0425: Retained semantic-version prerelease validation product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-28 |
| Updated | 2026-08-28 |
| Area | Self-hosting, semantic versions, imported call products |
| Depends on | WIP-0048, WIP-0049, WIP-0424 |
| Supersedes | Unretained prerelease validation source |
| Superseded by | None |

## Summary

Retain `SemverPrereleaseValidation.w` as the 113th physical compiler product. Resolve its imported scalar and core-validation calls against `SemverCoreValidation.w`, retain only its 18 owned functions, and close every relocation before linking.

## Problem

WIP-0424 split prerelease policy to keep the core artifact under the verifier's 24-function bound. The new owner was byte-exact under stage 0 but remained outside the physical set because it imports scalar and core helpers.

Treating those calls as local would assign wrong function coordinates. Copying core source into a generated stub would restore the duplicate authority removed by WIP-0424.

## Prerelease state

Prerelease validation tracks valid or invalid mode, current identifier length, first scalar, and numeric or mixed identifier kind. Dot closes one identifier and resets its fields. Empty identifiers fail. A numeric identifier beginning with zero is valid only at length one. Letters and dash convert the identifier to mixed kind.

Release validation scans to the first dash with one cursor product. It records core length, prerelease start, and a found state from the same prior row. Core and prerelease validators run separately. One helper combines their Boolean results with the found state.

Constraint validation admits exact, caret, and tilde prefixes. It removes one prefix scalar and delegates to release validation. Unprefixed input follows the same release path.

## Imported calls

The physical callable path emits signature products for `semverDigit`, `semverIdentifierScalar`, and `semverValidCore`. It resolves each imported call identity against the already retained core product. Local calls among prerelease helpers remain owner-local and produce no relocation frame.

The product retains 18 functions and 522 forward-plus-inverse instructions. Focused evidence requires at least one imported relocation and requires the resolved target count to equal the relocation count.

## Evidence

`NativeCompilerSemverPrereleasePhysicalProductExampleTest` compiles the callable source product, measures its exact stage-0 owned prefix, resolves imported core calls, and compares retained function and instruction counts.

The selected set contains 95 comparable products and 18 callable products. The linked closure retains 93 non-empty module products, 351 functions, and 13,089 forward-plus-inverse instructions. It contains 310,008 code bytes, 9,862 local-type rows, 577 source strings, and 465 unique strings. The 390,488-byte executable closure has SHA-256 `9a91bc4b32452c0248627b6b3c7973390e3efdb2f527aa834b64e29aef854c95`.

## Bootstrap identities

The source graph is unchanged from WIP-0424 at 389 modules, two externals, and 1,934 imports. Its 182,575-byte canonical manifest retains SHA-256 `3c8fd97fcca0c2694bb03916622b88372380afa09e0aae5021729df8a9933875`. Native validation still halts after 76,374,912 transitions. Wheeler SHA-256 still consumes the bytes in 34,940,178 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The compiler archive remains 3,216,437 bytes with SHA-256 `43eba0d40c8c1a8ddbf1f6c9bd6d13c1eb59af2fb663ee81ae056e177d5d7296`. Dependent locks already name that archive.

## Failure boundary

Reject an empty prerelease identifier, numeric leading zero, invalid identifier scalar, malformed prefix, unresolved imported identity, signature mismatch, duplicate target, nonlocal relocation to an unretained owner, invalid artifact, or stale source identity before closure publication. Local calls never consume relocation rows.

## Acceptance

- [x] Prerelease and constraint validation have one owner below 24 functions.
- [x] Numeric and mixed identifier state is explicit.
- [x] Core helper calls resolve to the retained core product.
- [x] Local helper calls remain local.
- [x] Every imported relocation resolves exactly once.
- [x] Retained function and instruction counts match stage 0.
- [x] The executable closure passes the independent reader and verifier.
- [x] The physical set contains 113 products and 351 retained functions.

## Rejected alternatives

### Merge prerelease validation back into the core owner

The combined artifact has 35 functions and fails the bounded native verifier before publication.

### Copy core helpers into generated source

That would restore duplicate scalar and overflow policy under a synthetic owner.

### Retain every call as an imported relocation

Calls between functions in the prerelease owner are local. Relocating them would make source order affect external target tables.

### Raise the artifact function bound

The split already satisfies the existing bound and yields clearer ownership. No global memory increase is justified.

## References

- [WIP-0048](WIP-0048-canonical-native-product-linker.md)
- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0424](WIP-0424-retained-semver-core-validation-product.md)
