# WIP-0484: Retained package-manifest target source sequence

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-02 |
| Updated | 2026-09-04 |
| Area | Self-hosting, package manifests, source selectors |
| Depends on | WIP-0467, WIP-0483 |
| Supersedes | Inline first-row and adjacent-row ordering dispatch |
| Superseded by | None |
| Follow-up | WIP-0486 |

## Summary

Retain one physical owner for source-selector sequence admission. The first valid selector needs no predecessor. Each later selector must follow its predecessor in strict lexical order.

## Contract

`manifestTargetSourceFollows` returns true for the first selector, represented by a negative previous-token coordinate. For every later selector it delegates strict quoted-token order to the retained source policy. Equality and reversal fail.

The aggregate parser still owns the previous-token state because that state advances only after source-table publication. It delegates the sequence verdict before testing root coverage or mutating any row.

## Physical evidence

The successor `NativeCompilerPackageManifestTargetSourceCollectionPhysicalProductExampleTest` compiles the retained policy from the canonical archive and compares its function and instruction totals with stage 0. Its one imported-call relocation resolves to strict source-selector ordering.

`NativeManifestExampleTest` accepts a canonical two-selector sequence and rejects the reversed pair. The first-row path executes without reading a predecessor.

The selected physical set is now 112 comparable products and 51 callable products. A fresh closure run retained 143 non-empty module products, 482 functions, and 16,755 forward-plus-inverse instructions. The linked closure contains 399,496 code bytes, 13,455 local-type rows, 808 source strings, and 646 unique strings. Its 511,216-byte executable has SHA-256 `bb0102b56028986cb196bf0f2279e46d3aaa953243f6a78b78415a973caf8701`. The closure checksum is `3_137_405_621L`.

## Bootstrap identities

The compiler graph contains 440 modules, two externals, and 2,037 imports. Its 200,974-byte canonical manifest has SHA-256 `cca81a814f7f902ab754da19435bd10f0b4873dbfd3830d964f2e324587c1966`. Native validation halts after 85,702,673 transitions under the 86,000,000-transition evidence ceiling. Wheeler SHA-256 halts after 38,467,290 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,284,219-byte compiler archive contains 517 entries and has SHA-256 `dc2978193afcbae0ebc2035480839f1a76de0e6e697c015547468cd12b303b0d`. Every dependent lock names that archive.

## Failure boundary

Reject equal or reversed adjacent selectors before coverage checks or row publication. Reject an unresolved ordering call, stale graph identity, archive mismatch, or lock mismatch before execution.

## Acceptance

- [x] First-row admission is explicit and predecessor-free.
- [x] Later rows require strict lexical order.
- [x] The aggregate parser delegates sequence policy before publication.
- [x] One imported call resolves exactly in the physical product.
- [x] Canonical and reversed two-row fixtures execute.
- [x] Complete closure evidence includes the retained owner.
- [x] Manifest, archive, SHA-256, and dependent locks reflect the new source.

## Rejected alternatives

### Read a sentinel row

A negative coordinate is control state, not an address. The first-row branch must return before any predecessor read.

### Move previous-row state into scalar policy

The parser publishes source rows and advances the previous coordinate atomically. Duplicating that state would obscure the mutation boundary.

### Permit equal selectors

Canonical package archives and manifests require strict order. Equality is duplication, not stable ordering.

## References

- [WIP-0467](WIP-0467-retained-package-manifest-target-source-policy.md)
- [WIP-0483](WIP-0483-retained-package-manifest-target-source-row.md)
