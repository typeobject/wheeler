# WIP-0303: Native test manifest bound

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, package, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Self-hosting, package tests, transport limits |
| Depends on | WIP-0302 |
| Supersedes | 4,096-byte native test manifest transport |
| Superseded by | None |
| Follow-up | WIP-0318 12,288-byte native test manifest bound |

## Summary

Raise the native package-test manifest ceiling from 4,096 to 8,192 bytes.

The compiler package is approaching the old transport boundary as physical source partitions enter its checked-in suite. Manifest framing and semantic validation must share one explicit bound before another partition can be admitted. The runner now accepts canonical manifests through byte 8,192 and rejects byte 8,193 before hashing, lock validation, discovery, compilation, or output publication.

This change does not widen locks, source plans, source files, source counts, case counts, or archives.

## Boundary

Three runtime checks own the affected limit:

- `TestRunner.w` rejects an oversized framed manifest before copying it.
- `TestManifest.w` bounds selected-target and root-source validation.
- `TestPackageDependencies.w` bounds direct dependency and version traversal.

All three use 8,192 bytes. The schema-3 lock remains limited to 4,096 bytes. The complete source plan remains limited to 32,768 bytes and eight source entries. A larger manifest therefore carries package metadata only. It does not create source or execution capacity.

Canonical parsing remains stage-0 framing work at the physical command boundary. Wheeler still checks the package name, version, selected target, exact target source set, root module, manifest SHA-256, dependency names, version constraints, lock graph, and source plan before discovery.

## Evidence

`enforcesNativeManifestByteLimit` constructs a canonical package with one physical test source and two long capability rows. Its 4,149-byte manifest crosses the former ceiling. Native framing validates it, then discovers, compiles, executes, and publishes one passing case.

The same fixture with five capability rows exceeds 8,192 bytes. Native framing traps on the declared manifest length before allocation or publication. The manifest remains syntactically canonical, so the rejection pins transport capacity rather than parser behavior.

## Acceptance

- [x] Native runner framing accepts at most 8,192 manifest bytes.
- [x] Selected-target validation uses the same bound.
- [x] Manifest-to-lock dependency validation uses the same bound.
- [x] Lock, source-plan, source-count, archive, and case limits remain unchanged.
- [x] A canonical manifest above 4,096 bytes executes one native case.
- [x] A canonical manifest above 8,192 bytes traps before publication.
- [x] Runtime archive and conformance lock are rebuilt exactly.
- [x] Runtime, package, conformance, tools, documentation, workspace, and file-length policy pass.

The runtime archive contains 435,911 bytes with SHA-256 `c149c46183fbadf5643ed99f479ae0fccd13dfc3bf75c337a8172e2e18029e29` and root manifest identity `42011c887d887364ca16bc2255bc28374882559192e9ab6dbf5f674ce0ae1f49`.

The conformance archive remains 148,423 bytes with SHA-256 `d59402f860dfcdab293921586004e84987e37f436a0729e5914860004dbbaf8e` and root manifest identity `ab202adc76b1b66cebe525b30e464a30cc2f3ad9e09a4796916643a78601702f`.

## Rejected alternatives

### Remove the manifest limit

Rejected. Canonical input still needs a reviewed allocation and traversal ceiling.

### Raise source-plan capacity with the manifest

Rejected. Metadata size and compilation input size are separate resources. No current source graph requires another plan entry or byte.

### Let each validator choose its own bound

Rejected. A transport accepted by framing must not fail later because another authority retained an accidental smaller ceiling.

### Shorten package metadata to stay below 4,096 bytes

Rejected. Renaming targets and omitting exact sources would hide the boundary rather than establish it.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0220](WIP-0220-native-runner-manifest-hashing.md)
- [WIP-0302](WIP-0302-native-transitive-archive-closure.md)
- [WIP-0318](WIP-0318-native-test-manifest-bound.md)
