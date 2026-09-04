# WIP-0362: Native 40 KiB test-manifest bound

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, package, and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-09-04 |
| Area | Native testing, manifests, package execution |
| Depends on | WIP-0358, WIP-0361 |
| Supersedes | Native 36,864-byte test-manifest bound |
| Superseded by | None |
| Follow-up | WIP-0363 native compiler borrowed-intrinsic shape suite |

## Summary

Raise the canonical native package-test manifest limit from 36,864 to 40,960 bytes.

The compiler manifest contains 35,162 bytes after WIP-0361. The next cohesive ABI owner group needs more than the remaining 1,702 bytes. Keeping the ABI owner group in one evidence increment avoids a partition based on target-name length.

## Authorities

`TestRunner.w`, `TestManifest.w`, and `TestPackageDependencies.w` share the 40,960-byte boundary. Each validates the complete canonical manifest before discovery, compilation, execution, hashing, or publication.

All adjacent transport and report limits remain unchanged.

## Boundary evidence

`NativePackageTestRunnerTest.enforcesNativeManifestByteLimit` constructs a host-valid canonical manifest of exactly 40,960 bytes. Native framing, package parsing, dependency parsing, target selection, discovery, compilation, execution, and publication succeed. A second manifest differs by one capability-path byte. Its 40,961 bytes trap before publication.

Both fixtures use twenty-one bounded capability rows. Every logical pattern remains below the independent package-format ceiling. The canonical workspace checks 172 targets.

## Acceptance

- [x] Framing accepts manifest byte 40,960.
- [x] Native package, target, and dependency parsing accept the exact bound.
- [x] One selected test compiles and executes from the exact-bound manifest.
- [x] Manifest byte 40,961 rejects before publication.
- [x] Locks remain bounded to 4,096 bytes.
- [x] Complete source plans remain bounded to 40,960 bytes and eight sources.
- [x] Individual sources and artifacts remain bounded to 32,768 bytes.
- [x] Target reports remain bounded to 128.
- [x] Cases and coverage remain bounded to 255.
- [x] Focused runtime, package, documentation, and file policy gates pass.

The runtime archive contains 438,019 bytes with SHA-256 `03248fbf6ab2a9359a5fa88bf7b64d9a68542ec2a812f8ea7382ad5f84052ad4`. Its root manifest identity remains `42011c887d887364ca16bc2255bc28374882559192e9ab6dbf5f674ce0ae1f49`.

## Rejected alternatives

### Split the next owner group

Rejected. Manifest capacity is transport policy, not source architecture.

### Shorten established targets

Rejected. Target names bind published case identities.

### Raise source or report capacity

Rejected. Those boundaries are not exhausted by this change.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0358](WIP-0358-native-36k-test-manifest-bound.md)
- [WIP-0361](WIP-0361-native-compiler-early-return-kind-suite.md)
- [WIP-0363](WIP-0363-native-compiler-borrowed-intrinsic-shape-suite.md)
