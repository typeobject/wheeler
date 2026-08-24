# WIP-0350: Native 28 KiB test-manifest bound

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, package, and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Native testing, manifests, package execution |
| Depends on | WIP-0345, WIP-0349 |
| Supersedes | Native 24,576-byte test-manifest bound |
| Superseded by | WIP-0351 conditional values, then WIP-0355 native 32 KiB manifests |

## Summary

Raise the canonical native package-test manifest limit from 24,576 to 28,672 bytes.

The compiler manifest reached 23,039 bytes with forty-two native targets. The next three-owner conditional suite produces a 24,643-byte manifest, exceeding the old bound by sixty-seven bytes. Locks, source plans, archives, cases, coverage, and reports retain independent capacity.

## Authorities

Three runtime checks share the 28,672-byte value:

- `TestRunner.w` validates framing,
- `TestManifest.w` validates package and target structure, and
- `TestPackageDependencies.w` validates dependency rows.

All three consume the complete canonical manifest. No transport truncates, repairs, or partially parses it.

## Boundary evidence

`NativePackageTestRunnerTest.enforcesNativeManifestByteLimit` constructs a canonical manifest of exactly 28,672 bytes. Native validation, discovery, compilation, execution, and report publication succeed. A second host-valid manifest of 28,673 bytes traps before publication.

The fixtures differ by one path byte. Host parsing accepts both. The canonical workspace checks 148 targets.

## Acceptance

- [x] Framing accepts manifest byte 28,672.
- [x] Native manifest parsing accepts the exact bound.
- [x] Native dependency parsing accepts the exact bound.
- [x] One selected test compiles and executes from the exact-bound manifest.
- [x] Manifest byte 28,673 rejects before report publication.
- [x] Locks remain bounded to 4,096 bytes.
- [x] Source plans remain bounded to 32,768 bytes and eight sources.
- [x] Cases remain bounded to 255 and coverage to 255 transitions.
- [x] Focused runtime, package, documentation, and file policy gates pass.

The runtime archive contains 437,958 bytes with SHA-256 `dc4b8c1f11116cf7439a6a333c0d8aaf266bf437e351fc681de2d54d2316ab67`. Its root manifest identity remains `42011c887d887364ca16bc2255bc28374882559192e9ab6dbf5f674ce0ae1f49`.

## Rejected alternatives

### Rename existing targets

Rejected. Target names enter canonical case identities. Renaming published targets rewrites evidence instead of extending transport.

### Admit one oversized compiler manifest

Rejected. Package tests use one canonical framing and validation authority.

### Raise adjacent transports

Rejected. Their capacities are not exhausted.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0345](WIP-0345-native-24k-test-manifest-bound.md)
- [WIP-0349](WIP-0349-native-compiler-named-return-suite.md)
- [WIP-0351](WIP-0351-native-compiler-conditional-value-suite.md)
- [WIP-0355](WIP-0355-native-32k-test-manifest-bound.md)
