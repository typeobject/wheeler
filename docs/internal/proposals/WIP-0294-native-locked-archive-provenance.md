# WIP-0294: Native locked archive provenance

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler package, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Self-hosting, package archives, package locks |
| Depends on | WIP-0275 |
| Supersedes | Structural lock evidence without native archive evidence |
| Superseded by | None |
| Follow-up | WIP-0295 native locked archive source projection |

## Summary

Bind one bounded canonical package archive to the exact package, archive, and manifest identities recorded by a native-validated schema-3 lock.

`ArchiveProvenance.w` composes the canonical archive inspector with SHA-256 and lock-row lookup. It does not duplicate archive framing. The authority accepts an already canonical lock, one exact package name, and one complete archive. It rejects a name absent from the lock, malformed archive framing, bad outer or entry digests, a different full archive identity, a different manifest identity, or a package-name mismatch.

This slice establishes native archive evidence before external source selection. It does not yet append dependency sources to a test compilation plan. WIP-0275 therefore continues to admit only package-local test imports.

## Boundary

The first profile accepts one archive of at most 32,768 bytes. The canonical archive authority inside `wheeler.packages.archive` already limits this executable profile to one or two ordered source entries, checks the payload digest, checks each entry digest, validates canonical paths and manifest bytes, and requires the manifest source selectors to name every entry.

The provenance authority adds three bindings:

1. SHA-256 over the complete archive must equal the selected lock row's `archive` identity.
2. SHA-256 over the archive's canonical manifest bytes must equal that row's `manifest` identity.
3. The manifest package name must equal the lock row name used for selection.

Repository and snapshot identities remain lock and resolver evidence. They do not substitute for archive bytes.

## Transport fixture

`nativelockedarchiveprovenance` accepts one root manifest identity, one physical schema-3 lock, one package name, and one complete archive. It validates the lock before invoking package provenance authority. Success publishes one byte only after every check succeeds.

The conformance test constructs the archive with the canonical stage-0 codec, then executes the Wheeler authority. It also changes the archive bytes, archive identity, and manifest identity independently. Each mutation traps before publication.

## Acceptance

- [x] Canonical package code owns archive-to-lock provenance.
- [x] Full archive bytes are hashed natively.
- [x] Canonical manifest bytes are hashed natively.
- [x] The archive manifest name binds to the selected lock package name.
- [x] Canonical archive framing, ordering, paths, and entry digests remain authoritative.
- [x] A valid one-source locked archive passes.
- [x] Changed archive bytes reject.
- [x] Changed lock archive identity rejects.
- [x] Changed lock manifest identity rejects.
- [x] The conformance target publishes only after success.
- [x] Package and conformance archives and locks are rebuilt exactly.
- [x] Focused package, conformance, example, documentation, workspace, and file-length policy pass.

The package archive contains 70,289 bytes with SHA-256 `5aabb4a3c8f51513fc1c5541ee313714bc347c47d346204db521966bc7526854` and root manifest identity `4321af51a08dbad7c95cfc255398f2ffe822084352fbe70a7a4b441e3e46e2c9`.

The conformance archive contains 140,493 bytes with SHA-256 `055f1d8c198102ed470a5b8fbd8f6da46ad2cbf07fd27884f9cdcf9a71277b28` and root manifest identity `67ec7664d956967a470eb7f59ec7534a5dbe2d6fa4f65eb66bc61ad7fe78c1f0`.

## Rejected alternatives

### Trust a transported archive identity

Rejected. A host-supplied digest does not prove the transported bytes.

### Hash extracted source only

Rejected. Source bytes alone do not bind the package manifest, entry names, omitted entries, or archive envelope.

### Parse the archive again in the test runner

Rejected. `wheeler.packages.archive` already owns canonical archive structure.

### Admit external imports in the same change

Rejected. Source-plan composition and archive entry projection are separate authorities. Combining them would hide the provenance boundary under compiler changes.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0275](WIP-0275-native-locked-package-test-gate.md)
- [WIP-0295](WIP-0295-native-locked-archive-source.md)
