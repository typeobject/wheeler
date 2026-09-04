# WIP-0331: Native 16 KiB test-manifest bound

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, package, and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-09-04 |
| Area | Native testing, manifests, package execution |
| Depends on | WIP-0318, WIP-0330 |
| Supersedes | Native 12,288-byte test-manifest bound |
| Superseded by | None |
| Follow-up | WIP-0332 local equality, then WIP-0339 native 20 KiB manifests |

## Summary

Raise the canonical native package-test manifest limit from 12,288 to 16,384 bytes.

The compiler package reached 12,448 bytes when the first physical 256-constant owner joined its native suite. The old bound rejected the complete manifest before target selection. Source plans, locks, archives, cases, reports, and execution limits still had capacity.

## Authorities

Three runtime checks share the 16,384-byte value:

- `TestRunner.w` validates the framed manifest length,
- `TestManifest.w` validates package and target structure, and
- `TestPackageDependencies.w` validates declared dependency rows.

No adapter truncates or repairs the bytes. The manifest remains one exact canonical input to target selection, source planning, case identity, and package evidence.

## Boundary evidence

`NativePackageTestRunnerTest.enforcesNativeManifestByteLimit` constructs a canonical manifest of exactly 16,384 bytes. Native validation, discovery, compilation, execution, and report publication succeed. A second canonical manifest of 16,385 bytes traps before publication.

The accepted and rejected fixtures differ by one path byte. Both pass host manifest parsing, so the result measures the native boundary rather than a host parser limit. The canonical workspace checks 126 targets.

## Acceptance

- [x] Transport framing accepts manifest byte 16,384.
- [x] Native manifest parsing accepts the exact bound.
- [x] Native dependency parsing accepts the exact bound.
- [x] One selected test compiles and executes from the exact-bound manifest.
- [x] Manifest byte 16,385 rejects before report publication.
- [x] Locks remain bounded to 4,096 bytes.
- [x] Source plans remain bounded to 32,768 bytes and eight sources.
- [x] Cases remain bounded to 128 and coverage to 255 transitions.
- [x] Focused runtime, package, documentation, and file policy gates pass.

The runtime archive contains 437,954 bytes with SHA-256 `ec98edd777269388e6a1a7b061a31119de2f72a2c5603cec96619fd5de0b4a9d`. Its root manifest identity remains `42011c887d887364ca16bc2255bc28374882559192e9ab6dbf5f674ce0ae1f49`.

## Rejected alternatives

### Shorten physical target names

Rejected. Renaming canonical test targets hides exhaustion, changes case identities, and postpones the same failure.

### Raise source and lock limits with the manifest

Rejected. Neither transport is exhausted. Independent limits keep malformed input failures local.

### Permit partial manifest parsing

Rejected. Target selection and dependency evidence require the complete canonical manifest.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0318](WIP-0318-native-test-manifest-bound.md)
- [WIP-0330](WIP-0330-native-256-constant-owner-profile.md)
- [WIP-0332](WIP-0332-native-compiler-resolved-local-equality-suite.md)
- [WIP-0339](WIP-0339-native-20k-test-manifest-bound.md)
