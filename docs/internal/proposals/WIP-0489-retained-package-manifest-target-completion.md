# WIP-0489: Retained package-manifest target completion

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-04 |
| Updated | 2026-09-04 |
| Area | Self-hosting, package manifests, targets |
| Depends on | WIP-0481, WIP-0486, WIP-0488 |
| Supersedes | Aggregate-parser target completion branch |
| Superseded by | None |

## Summary

Make the retained target-tail product consume the source-collection verdict. The aggregate parser now computes the verdict and passes it to target completion; it no longer owns the branch between source traversal and the required test tail.

## Contract

`manifestTargetTestValue` accepts `sourceCollectionComplete` as its eighth and final argument. A false verdict returns the negative invalid marker before probing the test key, token, Boolean value, or target-kind policy. A true verdict admits the existing required-tail checks unchanged.

The caller returns a target only when the resulting test value is nonnegative. Nonmodular targets continue to receive a positive absent-collection verdict. Present empty collections, present collections without root coverage, malformed test keys, malformed Boolean values, and disallowed library-test combinations all return the same closed invalid product.

## Physical evidence

`NativeCompilerPackageManifestTargetTailPhysicalProductExampleTest` compiles the complete target-tail owner from the canonical archive and compares its full function and instruction prefixes with stage 0. Its four imported-call relocations still resolve exactly. The new completion gate is owner-local and precedes every imported call.

`NativeManifestExampleTest` executes modular and nonmodular success paths. Its malformed portfolio rejects an explicit empty source list and a source list without root coverage through the completion gate. Existing malformed and disallowed test-tail cases remain rejected.

The physical set remains 112 comparable products and 51 callable products. A fresh closure run retained 143 non-empty module products, 486 functions, and 16,845 forward-plus-inverse instructions. The linked closure contains 401,656 code bytes, 13,546 local-type rows, 812 source strings, and 650 unique strings. Its 514,296-byte executable has SHA-256 `3ea72b137fab88589960add2cee8d178bd20f0b2a99af15ba3753b4b2e72e5c4`; the closure checksum is `1_051_142_931L`.

## Bootstrap identities

The compiler graph contains 440 modules, two externals, and 2,038 imports. Its 201,035-byte canonical manifest has SHA-256 `9fd7b04102d94122d58774b1f1c1e02fe30ee2448272e47b3036aeb608126969`. Native validation halts after 85,730,961 transitions under the 86,000,000-transition evidence ceiling. Wheeler SHA-256 halts after 38,479,560 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,286,019-byte compiler archive contains 517 entries and has SHA-256 `c35221cd5e46fcd0aff2900f02fd476f4713c9cf7ce376fecc6d312b02879e53`. Every dependent lock names that archive.

## Failure boundary

Reject an incomplete source collection before reading any required-tail field. Reject a negative retained completion product before constructing or publishing a target row. Reject a stale closure identity, graph identity, archive identity, or dependent lock before execution.

## Acceptance

- [x] Target-tail composition consumes the source-collection verdict.
- [x] An incomplete collection fails before tail parsing.
- [x] Complete modular and absent nonmodular collections reach tail parsing.
- [x] Empty and non-covering source collections remain malformed.
- [x] Required-test and target-kind policy remain fail-closed.
- [x] The physical target-tail product matches stage 0 and closes four imports.
- [x] Complete closure evidence includes the completion gate.
- [x] Manifest, archive, SHA-256, and dependent locks reflect the change.

## Rejected alternatives

### Keep the branch in the aggregate parser

That leaves target acceptance split across aggregate and retained owners after every scalar tail policy has moved.

### Parse the tail before checking source completion

A malformed source collection is already terminal. Reading later fields broadens the failure path and obscures the retained boundary.

### Add a wrapper around the old tail function

No caller needs the weaker contract. Extending the sole function avoids a legacy entry point and another owner-local call.

## References

- [WIP-0481](WIP-0481-retained-package-manifest-target-tail.md)
- [WIP-0486](WIP-0486-retained-package-manifest-target-source-collection.md)
- [WIP-0488](WIP-0488-retained-package-manifest-target-source-coverage-composition.md)
