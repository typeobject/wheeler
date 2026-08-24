# WIP-0358: Native 36 KiB test-manifest bound

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, package, and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Native testing, manifests, package execution |
| Depends on | WIP-0355, WIP-0357 |
| Supersedes | Native 32,768-byte test-manifest bound |
| Superseded by | WIP-0359 native compiler call classifier suite |

## Summary

Raise the canonical native package-test manifest limit from 32,768 to 36,864 bytes.

The compiler manifest contains 31,924 bytes after WIP-0357. The next coherent owner group needs more than the remaining 844 bytes. The group stays whole. Transport slack does not define semantic boundaries.

## Authorities

`TestRunner.w`, `TestManifest.w`, and `TestPackageDependencies.w` share the 36,864-byte limit. Each consumes the complete canonical manifest. No parser truncates, repairs, or partially admits it.

Locks, source plans, individual sources, archives, artifacts, cases, coverage, and reports retain independent bounds.

## Boundary evidence

`NativePackageTestRunnerTest.enforcesNativeManifestByteLimit` constructs a host-valid canonical manifest of exactly 36,864 bytes. Native framing, package parsing, target selection, discovery, compilation, execution, and report publication succeed. A second manifest differs by one capability-path byte. Its 36,865 bytes trap before publication.

Both fixtures use nineteen bounded capability rows. Every logical pattern remains within the package format's separate limit. The canonical workspace checks 165 targets.

## Acceptance

- [x] Framing accepts manifest byte 36,864.
- [x] Native package, target, and dependency parsing accept the exact bound.
- [x] One selected test compiles and executes from the exact-bound manifest.
- [x] Manifest byte 36,865 rejects before publication.
- [x] Locks remain bounded to 4,096 bytes.
- [x] Complete source plans remain bounded to 40,960 bytes and eight sources.
- [x] Individual sources and artifacts remain bounded to 32,768 bytes.
- [x] Cases and coverage remain bounded to 255.
- [x] Focused runtime, package, documentation, and file policy gates pass.

The runtime archive contains 438,017 bytes with SHA-256 `1f9e42f827062fc5a4d4bc0d298696fb4134455b343660bf1f7a1aa737661657`. Its root manifest identity remains `42011c887d887364ca16bc2255bc28374882559192e9ab6dbf5f674ce0ae1f49`.

## Rejected alternatives

### Consume the final 844 bytes first

Rejected. Small unrelated targets do not belong in the next owner group merely because their names fit.

### Shorten target identities

Rejected. Published target names bind canonical case identities.

### Raise another transport

Rejected. No adjacent capacity is exhausted.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0355](WIP-0355-native-32k-test-manifest-bound.md)
- [WIP-0357](WIP-0357-native-compiler-comparison-suite.md)
- [WIP-0359](WIP-0359-native-compiler-call-classifier-suite.md)
