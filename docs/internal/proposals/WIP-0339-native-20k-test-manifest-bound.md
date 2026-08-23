# WIP-0339: Native 20 KiB test-manifest bound

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, package, and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Native testing, manifests, package execution |
| Depends on | WIP-0331, WIP-0338 |
| Supersedes | Native 16,384-byte test-manifest bound |
| Superseded by | WIP-0340 local less-than, then WIP-0345 native 24 KiB manifests |

## Summary

Raise the canonical native package-test manifest limit from 16,384 to 20,480 bytes.

The compiler manifest reached 15,980 bytes with twenty-eight native targets. The next physical classifier target produces a 16,469-byte manifest, exceeding the old bound by eighty-five bytes. Locks, source plans, archives, cases, coverage, and reports retain independent capacity.

## Authorities

Three runtime checks share the 20,480-byte value:

- `TestRunner.w` validates framing,
- `TestManifest.w` validates package and target structure, and
- `TestPackageDependencies.w` validates dependency rows.

All three consume the complete canonical manifest. No transport truncates, repairs, or partially parses it.

## Boundary evidence

`NativePackageTestRunnerTest.enforcesNativeManifestByteLimit` constructs a canonical manifest of exactly 20,480 bytes. Native validation, discovery, compilation, execution, and report publication succeed. A second host-valid manifest of 20,481 bytes traps before publication.

The two fixtures differ by one path byte. Host parsing accepts both. The canonical workspace checks 134 targets.

## Acceptance

- [x] Framing accepts manifest byte 20,480.
- [x] Native manifest parsing accepts the exact bound.
- [x] Native dependency parsing accepts the exact bound.
- [x] One selected test compiles and executes from the exact-bound manifest.
- [x] Manifest byte 20,481 rejects before report publication.
- [x] Locks remain bounded to 4,096 bytes.
- [x] Source plans remain bounded to 32,768 bytes and eight sources.
- [x] Cases remain bounded to 128 and coverage to 255 transitions.
- [x] Focused runtime, package, documentation, and file policy gates pass.

The runtime archive contains 437,954 bytes with SHA-256 `69f6ded977312391a2e5966ca970494094bba971975657a86c51dbe97de529c6`. Its root manifest identity remains `42011c887d887364ca16bc2255bc28374882559192e9ab6dbf5f674ce0ae1f49`.

## Rejected alternatives

### Rename existing targets

Rejected. Target names enter canonical case identities. Shortening them would hide exhaustion by changing published evidence.

### Add one exceptional oversize path

Rejected. Every native package command uses one manifest authority and one bound.

### Raise adjacent transports

Rejected. Their capacities are not exhausted.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0331](WIP-0331-native-16k-test-manifest-bound.md)
- [WIP-0338](WIP-0338-native-compiler-resolved-local-loop-kind-suite.md)
- [WIP-0340](WIP-0340-native-compiler-resolved-local-less-than-suite.md)
- [WIP-0345](WIP-0345-native-24k-test-manifest-bound.md)
