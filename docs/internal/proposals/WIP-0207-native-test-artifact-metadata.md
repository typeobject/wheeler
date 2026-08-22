# WIP-0207: Native test artifact metadata

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and conformance maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, verified artifacts, report composition |
| Depends on | WIP-0018, WIP-0204, WIP-0206 |
| Supersedes | Host-only execution-result name recovery |
| Superseded by | None |

## Summary

Project program kind, program name, and ordered global names from a verified artifact inside the Wheeler runtime.

`ArtifactMetadata.w` reads canonical manifest, string, function, and type sections. WIP-0251 moved the implemented authority from the old test-scoped module into `wheeler.runtime.artifact_metadata` and deleted the old name. It returns borrowed ranges into the artifact rather than copying or allocating names. The native runner can now pair WIP-0206 values with their exact names before invoking WIP-0204 execution identity derivation.

## Verification boundary

The projection API accepts a verified canonical artifact. It does not duplicate `Verifier.w`.

`NativeTestArtifactMetadata.w` demonstrates the required call order: execute the artifact through WIP-0202, require a successful outcome, then project metadata. A failed verification never reaches section projection.

Canonical section order fixes manifest, strings, and types at directory indices zero, one, and two. Manifest and global descriptors provide string-table identifiers. Bounded string lookup scans at most 65,535 entries without host maps.

## Conformance frame

The conformance entry publishes:

1. two-byte program-name length and bytes
2. one-byte program kind code
3. one-byte active global count
4. each two-byte global-name length and bytes in descriptor order

Program and global names are capped at 255 bytes for the native test profile. Active globals are capped at the interpreter's eight slots. The output buffer is exactly 4,096 bytes and is shortened only after complete validation.

The wrapper owns one 32,768-byte trace plus two eight-word range tables. Runtime projection itself borrows the artifact and allocates nothing.

## Evidence

`NativeCoverageRunExampleTest` compiles a classical `GlobalSubject` artifact with globals `first` and `second`. Native projection publishes the exact program name, kind zero, count two, names in descriptor order, and no trailing byte.

Corrupting the artifact magic rejects during native execution and leaves all 4,096 output bytes untouched.

The runtime archive contains 156,365 bytes with SHA-256 `036a5b83ffaa5a2fedd62df0628518f84ebf3461eaeb54b05e19eb76e5bd0acd`. Its schema-3 lock retains root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 126,870 bytes with SHA-256 `ab663c4785d4c487bf729dfe53c7b1406f7f9af18f3795b49b3bbdd5bf93fcb5`. Its lock names root manifest identity `4958bccb6a2b381128b8c27feb92bf6d9d00fe42b8f855561c34768f7841007c` and the rebuilt runtime archive exactly.

## Acceptance

- [x] Program name and kind come from the verified manifest.
- [x] Global names come from verified type and string sections.
- [x] Name ranges remain borrowed from the artifact.
- [x] Active count matches the native execution outcome.
- [x] Invalid artifacts cannot reach projection or publication.
- [x] Runtime and conformance archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Supply names from the host

Rejected. Host metadata could disagree with the artifact whose values were executed.

### Copy names into runtime-owned storage

Rejected. Verified canonical ranges remain valid for the caller's artifact lifetime.

### Parse before verification

Rejected. Projection relies on canonical section and string-table bounds established by the verifier.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0204](WIP-0204-native-test-execution-identity.md)
- [WIP-0206](WIP-0206-complete-native-artifact-outcomes.md)
- [WIP-0251](WIP-0251-native-artifact-function-binding.md)
- [WIP-0208](WIP-0208-native-artifact-execution-identity.md)
