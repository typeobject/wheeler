# WIP-0301: Native archive dependency binding

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler package, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Self-hosting, package archives, dependency graphs |
| Depends on | WIP-0300 |
| Supersedes | Archive identity without archive-to-lock edge binding |
| Superseded by | None |
| Follow-up | WIP-0302 native transitive archive closure |

## Summary

Bind the dependency names in a locked archive manifest to the dependency edges in that archive's schema-3 lock row.

Archive and manifest identities already prevent either byte sequence from changing unnoticed. They do not prove that the lock row's graph edges describe the dependencies named by those manifest bytes. Native external source authority must establish that relation before a second archive can satisfy an import from the first.

`ArchiveProvenance.w` now compares the two canonical ordered sequences. The package test runner invokes that authority for every transported archive before discovery, lowering, compilation, or execution.

## Bounded profile

The first profile accepts canonical normal dependencies only. The manifest sequence starts at `dependencies:` and contains exact `kind`, `name`, and version rows. The lock sequence starts at the selected package row's `dependencies` field. Empty forms must agree. Nonempty names must agree byte-for-byte and in canonical order, with no missing or trailing lock edge.

Build and development dependency kinds remain outside native external test source visibility. An archive carrying either kind cannot enter this profile by relabeling its edge as normal.

The comparison runs only inside the existing 4,096-byte lock and 32,768-byte archive bounds. Archive structure, package name, complete archive SHA-256, and embedded manifest SHA-256 remain the responsibility of `validLockedArchive`. Dependency matching neither repairs nor reorders either input.

## Evidence

`nativelockedarchiveprovenance` now requires both provenance and dependency binding before its one-byte publication.

The example fixture carries `demo.archive -> demo.base` in both its canonical manifest and lock. It changes the edge and target package name together, preserving a structurally valid lock while disagreeing with the committed manifest. It also removes the selected row's edge while retaining the target row. Both mutations trap before publication.

The native package tests retain empty dependency sequences on their direct external archives. Those size-zero cases pass through the same authority.

## Acceptance

- [x] Canonical package code owns archive-to-lock dependency binding.
- [x] Empty manifest and lock dependency sequences agree exactly.
- [x] Nonempty normal dependency names agree byte-for-byte and in order.
- [x] Missing, changed, and trailing lock edges reject.
- [x] The conformance publisher checks dependency binding after archive provenance.
- [x] Native external source validation checks every transported archive.
- [x] A structurally valid changed lock edge rejects before publication.
- [x] A removed lock edge rejects before publication.
- [x] Package, runtime, conformance, example, documentation, workspace, and file-length policy pass.

The package archive contains 77,653 bytes with SHA-256 `117a0fb2f82ee78ca5178a83b83fdf44497d9c5615c05eb92ced270f848634bd` and root manifest identity `4321af51a08dbad7c95cfc255398f2ffe822084352fbe70a7a4b441e3e46e2c9`.

The runtime archive contains 435,911 bytes with SHA-256 `556819d5f48d4cfbbb945d9ded434be760bada98eba99c45911df35bf88dbf46` and root manifest identity `42011c887d887364ca16bc2255bc28374882559192e9ab6dbf5f674ce0ae1f49`.

The conformance archive contains 148,423 bytes with SHA-256 `d59402f860dfcdab293921586004e84987e37f436a0729e5914860004dbbaf8e` and root manifest identity `ab202adc76b1b66cebe525b30e464a30cc2f3ad9e09a4796916643a78601702f`.

## Rejected alternatives

### Trust the manifest identity

Rejected. The identity proves which manifest was archived. It does not prove that a separately transported lock graph describes that manifest.

### Trust stage-0 graph construction

Rejected. Java may frame canonical bytes, but it cannot remain the semantic authority for source visibility after native validation begins.

### Compare unordered sets

Rejected. Both formats are canonical. Accepting a reordered sequence would weaken canonical lock evidence and require unnecessary storage.

### Admit every dependency kind

Rejected. Native package tests compile against normal runtime dependencies. Build and development visibility require separate command and target policy.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0294](WIP-0294-native-locked-archive-provenance.md)
- [WIP-0300](WIP-0300-native-two-package-import.md)
- [WIP-0302](WIP-0302-native-transitive-archive-closure.md)
