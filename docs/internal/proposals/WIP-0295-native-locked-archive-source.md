# WIP-0295: Native locked archive source projection

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler package, compiler, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, package archives, external source provenance |
| Depends on | WIP-0294 |
| Supersedes | Locked archive validation without entry projection |
| Superseded by | Native external test-source plan composition |

## Summary

Project one exact path and source range from a natively validated locked package archive.

`ArchiveProvenance.w` now returns `LockedArchiveEntry` only after repeating complete archive and lock validation. The result carries offsets and lengths into the borrowed archive. It does not copy, normalize, decode, or repair source bytes. The caller chooses one bounded ordinal and receives exactly the entry named and digested by the archive.

This closes the archive-entry boundary. Test-plan composition remains separate: the native test runner still accepts only package-local imports until dependency entry paths gain an unambiguous package-qualified plan frame.

## Projection

The canonical archive inspector accepts one or two ordered entries. After it validates outer framing, canonical manifest bytes, target source selection, paths, and entry digests, the provenance authority binds the archive to its lock row. Only then does `validatedLockedArchiveEntry` read the selected entry coordinates.

The returned coordinates cover:

- the exact archive path bytes.
- the exact source bytes following that path's checked entry digest.

The function asserts ordinal bounds against the archive's committed entry count. There is no fallback to another entry or filesystem source.

## Conformance

`nativelockedarchivesource` consumes the same root identity, lock, package name, and archive frame as WIP-0294 plus one entry ordinal. It publishes:

```text
u32 path_length
byte[path_length] path
u32 source_length
byte[source_length] source
```

Lengths use canonical little-endian framing. Publication occurs only after lock validation, archive provenance validation, and ordinal selection.

The focused fixture selects ordinal zero from a one-source archive and compares both path and all four source octets. Ordinal one traps before publication.

## Acceptance

- [x] Canonical package code owns locked entry selection.
- [x] Entry coordinates are returned only after complete archive provenance validation.
- [x] The conformance target copies path bytes without normalization.
- [x] The conformance target copies source bytes without decoding or normalization.
- [x] The package authority bounds selection by the committed archive entry count.
- [x] One exact path and binary source payload publish natively.
- [x] An absent ordinal traps before publication.
- [x] Package and conformance archives and locks are rebuilt exactly.
- [x] Focused package, conformance, example, documentation, workspace, and file-length policy pass.

The package archive contains 71,775 bytes with SHA-256 `53a8b719fc41c8eb37c005a75771daf2eb9f63024dea6317e3863bba92ca5f08` and root manifest identity `4321af51a08dbad7c95cfc255398f2ffe822084352fbe70a7a4b441e3e46e2c9`.

The conformance archive contains 144,708 bytes with SHA-256 `b0d4503aaa96652ee57abdbd2779ed95b05157ca5707b7b6276a57ecf08e38e4` and root manifest identity `e5ec8cf3c26f28fc6570f5a9201ddb0f6357373def12365e5e2239bc2abc6cd9`.

## Rejected alternatives

### Return copied mutable source storage from package authority

Rejected. Coordinates preserve archive ownership and make copying policy explicit at the transport boundary.

### Select by a host path

Rejected. Only paths committed inside the validated archive are admissible.

### Merge dependency entries directly into the local source plan

Rejected. Package qualification and root-manifest source selection must be defined before plan composition.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0294](WIP-0294-native-locked-archive-provenance.md)
