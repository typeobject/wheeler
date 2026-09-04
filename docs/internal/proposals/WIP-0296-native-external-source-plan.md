# WIP-0296: Native external source-plan composition

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler package, runtime, compiler, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Self-hosting, external imports, source plans |
| Depends on | WIP-0295 |
| Supersedes | Locked archive entry projection without plan composition |
| Superseded by | None |
| Follow-up | WIP-0297 native external import compilation |

## Summary

Compose one validated locked archive entry with one canonical package-local source plan.

`TestExternalSourcePlan.w` owns the composition. It qualifies the archive path as `dependencies/<package>/<path>`, merges that entry with the local plan under bytewise path order, rejects a duplicate qualified path, and validates the complete result with canonical `TestSourcePlan` authority.

The composer never reads the filesystem. It receives the complete lock, package name, archive, entry ordinal, and local plan. Archive provenance and entry selection run before any external byte reaches the result.

## Qualified paths

A bare archive path is ambiguous across dependencies. The composed plan uses one closed prefix:

```text
dependencies/<locked-package-name>/<archive-entry-path>
```

The prefix is plan metadata. It does not change the source module declaration or archive entry identity. The package and archive path remain visible and cannot collide with package-local `src/...` paths.

The complete qualified path must satisfy the existing 255-byte canonical path profile. The composed plan remains bounded to 32,768 bytes and 64 sources. Composition rejects overflow instead of truncating a name, path, or source.

## Reduction

The composer validates the local plan first. It then validates archive provenance, selects one committed entry, constructs the qualified path, and merges exactly once. It copies each existing framed source entry unchanged.

The result contains the old source count plus one. Bytewise order decides insertion before, between, or after local entries. A path equality is a duplicate and rejects. Final `validTargetSourcePlan` validation covers count, path grammar, path order, UTF-8 source bytes, and exact plan boundary.

## Conformance

`nativeexternalsourceplan` transports one root identity, lock, package name, archive, ordinal, and local plan. It publishes only the composed canonical plan.

The focused fixture composes `src/Root.w` with archive entry `src/Main.w` from package `demo.archive`. The result orders `dependencies/demo.archive/src/Main.w` before `src/Root.w` and preserves both source byte sequences exactly.

## Acceptance

- [x] Runtime code owns external source-plan composition.
- [x] Canonical package code validates archive provenance before composition.
- [x] External paths carry locked package qualification.
- [x] The composer preserves local entry frames exactly.
- [x] The composer preserves external source bytes exactly.
- [x] Bytewise canonical order decides insertion.
- [x] Duplicate, oversized, malformed, and non-UTF-8 plans reject.
- [x] The final plan passes canonical source-plan validation.
- [x] Runtime, package, and conformance archives and locks are rebuilt exactly.
- [x] Focused runtime, package, conformance, example, documentation, workspace, and file-length policy pass.

The package archive remains 71,775 bytes with SHA-256 `53a8b719fc41c8eb37c005a75771daf2eb9f63024dea6317e3863bba92ca5f08` and root manifest identity `4321af51a08dbad7c95cfc255398f2ffe822084352fbe70a7a4b441e3e46e2c9`.

The runtime archive contains 421,555 bytes with SHA-256 `af740f2313f2d60d19e4b6d45992846b85c5fce0c3c0388c538fdc26d401a342` and root manifest identity `42011c887d887364ca16bc2255bc28374882559192e9ab6dbf5f674ce0ae1f49`.

The conformance archive contains 148,351 bytes with SHA-256 `5f30ba02abe7eb01b41d7151143cfb62550dfbc68ea85518ea9f342492fbfcc4` and root manifest identity `ab202adc76b1b66cebe525b30e464a30cc2f3ad9e09a4796916643a78601702f`.

## Rejected alternatives

### Use bare archive paths

Rejected. Two dependencies may commit the same source path.

### Append external source after local source

Rejected. Arrival and source class cannot enter canonical order.

### Rewrite imports to qualified paths

Rejected. Imports name modules. Plan paths identify provenance and storage.

### Compile in the same change

Rejected. Manifest-local source selection and external module authorization still need an explicit boundary in the test runner.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0295](WIP-0295-native-locked-archive-source.md)
- [WIP-0297](WIP-0297-native-external-import-compilation.md)
