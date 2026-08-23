# WIP-0318: Native test manifest bound

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, package, and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Self-hosting, package tests, transport limits |
| Depends on | WIP-0303, WIP-0317 |
| Supersedes | WIP-0303 8,192-byte native test manifest transport |
| Superseded by | WIP-0331 native 16 KiB test-manifest bound |

## Summary

Raise the native package-test manifest ceiling from 8,192 to 12,288 bytes.

The physical compiler suite reached 8,303 canonical bytes when its twelfth native test target entered the manifest. Execution, source, lock, archive, case, and report bounds still fit. Refusing the manifest at framing would protect no downstream resource.

The new ceiling admits another exact 4 KiB page. Byte 12,289 remains malformed input, not a request for truncation or fallback.

## Boundary

Three runtime checks own the limit:

- `TestRunner.w` rejects oversized transport before manifest hashing.
- `package/TestManifest.w` bounds line scanning and selected-target validation.
- `package/TestPackageDependencies.w` bounds dependency parsing and lock binding.

All three use 12,288 bytes. The adapter does not carry a fourth shadow limit.

The change does not widen canonical locks, source plans, source files, selected source counts, test cases, external archives, transition coverage, execution limits, or report rows.

## Evidence

`NativePackageTestRunnerTest.enforcesNativeManifestByteLimit` constructs a canonical manifest above 8,192 bytes and below 12,289 bytes. Native discovery, compilation, execution, and report publication succeed. A second canonical manifest above 12,288 bytes traps before publication.

The checked-in compiler manifest contains 8,303 bytes. Its thirty-four native cases pass through the same runtime path.

## Acceptance

- [x] Transport framing accepts canonical manifest byte 12,288.
- [x] Manifest semantic validation uses the same bound.
- [x] Dependency parsing uses the same bound.
- [x] A synthetic manifest above 8,192 bytes executes natively.
- [x] Byte 12,289 traps before report publication.
- [x] The 8,303-byte compiler manifest executes natively.
- [x] Runtime, package, workspace, documentation, and file policy gates pass.

The runtime archive contains 435,973 bytes with SHA-256 `d50d30d2ce0077adad0b36386d20791d4b9273db73dca672617ee5c2e3e25592`. Its root manifest identity remains `42011c887d887364ca16bc2255bc28374882559192e9ab6dbf5f674ce0ae1f49`.

## Rejected alternatives

### Shorten canonical target names

Rejected. Target and module names enter case identity and reports. Transport pressure does not authorize renaming semantic subjects.

### Parse only the selected target prefix

Rejected. Complete manifest validation precedes target selection and hashing.

### Remove test targets from the package manifest

Rejected. The package manifest is the authority for native package-test discovery.

### Raise unrelated bounds

Rejected. Capacity remains local to the exhausted transport.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0303](WIP-0303-native-test-manifest-bound.md)
- [WIP-0317](WIP-0317-native-compiler-void-call-source-form-suite.md)
- [WIP-0331](WIP-0331-native-16k-test-manifest-bound.md)
