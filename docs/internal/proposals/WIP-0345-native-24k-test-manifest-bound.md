# WIP-0345: Native 24 KiB test-manifest bound

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, package, and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Native testing, manifests, package execution |
| Depends on | WIP-0339, WIP-0344 |
| Supersedes | Native 20,480-byte test-manifest bound |
| Superseded by | WIP-0346 return calls, then WIP-0350 native 28 KiB manifests |

## Summary

Raise the canonical native package-test manifest limit from 20,480 to 24,576 bytes.

The compiler manifest reached 20,094 bytes with thirty-six native targets. The next physical return-call target produces a 20,571-byte manifest, exceeding the old bound by ninety-one bytes. Locks, source plans, archives, cases, coverage, and reports retain independent capacity.

## Authorities

Three runtime checks share the 24,576-byte value:

- `TestRunner.w` validates framing,
- `TestManifest.w` validates package and target structure, and
- `TestPackageDependencies.w` validates dependency rows.

All three consume the complete canonical manifest. No transport truncates, repairs, or partially parses it.

## Boundary evidence

`NativePackageTestRunnerTest.enforcesNativeManifestByteLimit` constructs a canonical manifest of exactly 24,576 bytes. Native validation, discovery, compilation, execution, and report publication succeed. A second host-valid manifest of 24,577 bytes traps before publication.

The fixtures differ by one path byte. Host parsing accepts both. The canonical workspace checks 142 targets.

## Acceptance

- [x] Framing accepts manifest byte 24,576.
- [x] Native manifest parsing accepts the exact bound.
- [x] Native dependency parsing accepts the exact bound.
- [x] One selected test compiles and executes from the exact-bound manifest.
- [x] Manifest byte 24,577 rejects before report publication.
- [x] Locks remain bounded to 4,096 bytes.
- [x] Source plans remain bounded to 32,768 bytes and eight sources.
- [x] Cases remain bounded to 128 and coverage to 255 transitions.
- [x] Focused runtime, package, documentation, and file policy gates pass.

The runtime archive contains 437,954 bytes with SHA-256 `e2f8795d271c9bda11a9f1c8c0fd6f93d1e803a155b667be5a7475aaac9bad3c`. Its root manifest identity remains `42011c887d887364ca16bc2255bc28374882559192e9ab6dbf5f674ce0ae1f49`.

## Rejected alternatives

### Shorten target identities

Rejected. Target names enter canonical case identities. Renaming published cases would hide exhaustion by rewriting evidence.

### Grant one compiler-only exception

Rejected. Every package command uses one native manifest authority.

### Raise adjacent transports

Rejected. Their capacities are not exhausted.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0339](WIP-0339-native-20k-test-manifest-bound.md)
- [WIP-0344](WIP-0344-native-compiler-resolved-early-result-suite.md)
- [WIP-0346](WIP-0346-native-compiler-resolved-return-call-suite.md)
- [WIP-0350](WIP-0350-native-28k-test-manifest-bound.md)
