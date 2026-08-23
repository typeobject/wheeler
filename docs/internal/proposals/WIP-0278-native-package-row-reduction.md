# WIP-0278: Native package row reduction

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, package, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, package testing, reports |
| Depends on | WIP-0277 |
| Supersedes | Java combination of canonical native target rows |
| Superseded by | Native external import source binding |

## Summary

Reduce all eligible package case rows into one canonical native report.

WIP-0277 sorted rows inside each target. Target concatenation still left package-wide ordering and combined report identity to Java. `TestReportRows.w` now accepts up to 64 complete rows, validates every boundary, sorts the complete case-identity set, derives the profile-2 report identity with the native runner identity, and publishes the canonical rows.

The package adapter parses only that reduced output. It no longer combines target case lists into semantic order.

## Runtime authority

`TestReportRows.w` owns row framing and ordering shared by `TestRunner.w` and package-wide reduction. The runner's private duplicate implementation is deleted.

The package reducer input contains:

1. One little-endian 16-bit total case count.
2. One little-endian 32-bit row byte length.
3. Concatenated canonical target rows.

The output contains 32 raw report-identity bytes, one little-endian 32-bit row byte length, and rows in strict global case-identity order.

The reducer reconstructs the canonical profile-2 identity frame with the native runner identity and invokes `TestReportIdentity.w`. Row identity and row publication therefore consume the same complete transport.

## Bounds

The first package-wide profile admits 64 selected cases total and 342,080 row bytes. A package whose metadata-only count exceeds 64 remains on the migration path rather than entering a partial native execution.

The reducer owns bounded row, identity-frame, span, length, and order storage and drops all of it before publication. Package invocation uses committed host transitions and exact output capacity.

## Source layout

Runtime report authorities moved under `runtime/testing/reports`. Conformance report publishers moved under `testing/reports`. Both parent directories had reached the ten-file ceiling.

No forwarding files remain at the old paths. Module identities are unchanged.

The conformance manifest is now checked in byte-for-byte canonical target order. The compiler manifest now carries its source selectors in canonical byte order. Their prior source spellings decoded to canonical bytes but did not equal them. Lock root identities now bind physical canonical manifests instead of relying on re-emission. Every checked-in package manifest equals its canonical codec output.

## Evidence

`invokesEveryNativePackageTestTarget` executes two targets, feeds their native rows to `nativetestreportrows`, and accepts only the globally ordered package rows whose reconstructed identity matches the native reducer output.

`publishesTargetRowsInCaseIdentityOrder` retains the two-row single-target boundary. Passing, failing, tagged, locked, and local-import package fixtures all pass through the package reducer.

The adapter rejects malformed lengths, row counts, target row identities, target-local order, package-global order, and package report identity disagreement.

## Acceptance

- [x] One runtime module owns row framing and ordering.
- [x] Private runner row-order code is deleted.
- [x] Package-wide rows sort by exact case identity natively.
- [x] Package-wide profile-2 identity is derived natively.
- [x] The adapter consumes only globally reduced rows.
- [x] Duplicate case identities reject before publication.
- [x] The initial package-wide profile has an explicit 64-case ceiling.
- [x] Report authorities obey the ten-file directory ceiling.
- [x] No old source-path shims remain.
- [x] Every checked-in package manifest is physically canonical.
- [x] Runtime and conformance archives and locks are rebuilt exactly.
- [x] Focused runtime, conformance, examples, tools, documentation, package, workspace, and file-length policy pass.

The runtime archive contains 378,530 bytes with SHA-256 `45e54dbf4aa49f19c36d25c9134d0b8ab5ff2e3c34bbc00d62295af0c0a560db` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 132,872 bytes with SHA-256 `1beb2c57f29a587e5d05ed20152204d38769556d3a63550fce3c0d01b21d82be` and root manifest identity `b9beb8697bb55c654a74476b69a5a21fbcded9791e04f771ab4b25186d2d1349`. Its lock names the runtime archive exactly.

## Rejected alternatives

### Merge target rows in Java

Rejected. Global row order and report identity are semantic reduction.

### Hash target report identities as the combined report

Rejected. WIP-0268 package evidence and a profile-2 case report are distinct products.

### Admit more cases than bounded row storage

Rejected. The runner must enlarge storage and evidence together.

### Keep forwarding source files

Rejected. Source layout is not a compatibility API.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0268](WIP-0268-native-package-test-report-identity.md)
- [WIP-0277](WIP-0277-canonical-native-target-rows.md)
- [WIP-0328](WIP-0328-native-128-case-test-profile.md)
