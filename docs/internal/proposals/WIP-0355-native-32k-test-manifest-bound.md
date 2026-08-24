# WIP-0355: Native 32 KiB test-manifest bound

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, package, and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Native testing, manifests, package execution |
| Depends on | WIP-0350, WIP-0354 |
| Supersedes | Native 28,672-byte test-manifest bound |
| Superseded by | WIP-0356 local updates, then WIP-0358 native 36 KiB manifests |

## Summary

Raise the canonical native package-test manifest limit from 28,672 to 32,768 bytes.

The compiler manifest contains 27,933 bytes after WIP-0354. The next coherent scalar-owner suite needs several targets and cannot fit under the remaining 739 bytes. Splitting that suite to consume incidental slack would make manifest capacity dictate semantic ownership.

## Authorities

`TestRunner.w`, `TestManifest.w`, and `TestPackageDependencies.w` share the 32,768-byte value. Framing, package structure, target selection, and dependency rows consume the same complete canonical bytes.

No source, lock, archive, case, coverage, artifact, or report bound changes.

## Boundary evidence

`NativePackageTestRunnerTest.enforcesNativeManifestByteLimit` constructs a host-valid canonical manifest of exactly 32,768 bytes. Native validation, discovery, compilation, execution, and publication succeed. A second manifest differs by one capability-path byte. Its 32,769 bytes trap before report publication.

Both manifests contain seventeen bounded capability rows. No single logical pattern crosses the package format's independent limit. The canonical workspace checks 157 targets.

## Acceptance

- [x] Framing accepts manifest byte 32,768.
- [x] Native package and target parsing accept the exact bound.
- [x] Native dependency parsing accepts the exact bound.
- [x] One selected test compiles and executes from the exact-bound manifest.
- [x] Manifest byte 32,769 rejects before publication.
- [x] Locks remain bounded to 4,096 bytes.
- [x] Complete source plans remain bounded to 40,960 bytes and eight sources.
- [x] Individual sources and artifacts remain bounded to 32,768 bytes.
- [x] Cases and coverage remain bounded to 255.
- [x] Focused runtime, package, documentation, and file policy gates pass.

The runtime archive contains 438,017 bytes with SHA-256 `767c6752ed5067d7b250da798747657c3b74b13482f7f3ee614341981218bdca`. Its root manifest identity remains `42011c887d887364ca16bc2255bc28374882559192e9ab6dbf5f674ce0ae1f49`.

## Rejected alternatives

### Add one target at a time

Rejected. Proposal boundaries follow semantic authority, not leftover transport bytes.

### Shorten published target names

Rejected. Target names enter canonical case identities.

### Raise adjacent transports

Rejected. Their capacities are not exhausted.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0350](WIP-0350-native-28k-test-manifest-bound.md)
- [WIP-0354](WIP-0354-native-compiler-conditional-mapping-suite.md)
- [WIP-0356](WIP-0356-native-compiler-local-update-suite.md)
- [WIP-0358](WIP-0358-native-36k-test-manifest-bound.md)
