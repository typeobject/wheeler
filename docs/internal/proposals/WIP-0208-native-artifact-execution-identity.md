# WIP-0208: Native artifact execution identity

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and conformance maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, artifact execution, identity composition |
| Depends on | WIP-0018, WIP-0204, WIP-0206, WIP-0207 |
| Supersedes | Host composition of native artifact execution identities |
| Superseded by | None |

## Summary

Compose a byte-identical profile-2 execution identity directly from one successful native artifact outcome.

`TestArtifactExecutionIdentity.w` joins WIP-0206 values with WIP-0207 artifact metadata, builds the normalized WIP-0204 frame in private storage, and invokes the runtime execution-identity operation. No host reconstructs the global map.

## Admitted execution profile

The current Wheeler interpreter admits one classical artifact result with:

- verified manifest program name and kind
- zero through eight named signed globals
- no measurements
- no quantum jobs
- zero workflow steps
- empty program output

These are restrictions on native artifact execution, not omissions from the identity schema. `TestExecutionIdentity.w` continues to cover nonempty measurements, jobs, workflow steps, output, and all three kinds when those values are available.

## Composition

The operation first validates outcome success, global capacity, artifact kind, metadata lengths, and agreement between artifact and outcome global counts. It measures an exact normalized frame, allocates only that frame inside a 2,396-byte region, then emits:

1. program text and kind
2. each descriptor-order global name and signed outcome value
3. empty measurement and job lists
4. zero workflow steps
5. empty output

WIP-0204 canonicalizes the global map, rejects duplicate names, and hashes the stage-0 transcript. The intermediate frame never reaches host output.

## Failure behavior

A failed execution, inconsistent global count, unsupported kind, oversized name, malformed metadata, wrong identity output capacity, or WIP-0204 validation failure traps before publication.

The conformance executable executes exactly once, retains its private trace until identity publication, then drops trace storage.

## Evidence

`NativeCoverageRunExampleTest` compiles `GlobalSubject` with signed globals `first = 7` and `second = -4`. Java independently hashes the complete stage-0 transcript for program `GlobalSubject`, kind `CLASSICAL`, both sorted globals, empty measurement and job lists, zero workflow steps, and empty output.

The native artifact path reproduces all 32 bytes.

The runtime archive contains 160,586 bytes with SHA-256 `8d5eedeb34c82dab9aa0d9eb5f9a4bc3f850bfad5663244210b258688a8f5fb5`. Its schema-3 lock retains root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 128,136 bytes with SHA-256 `df2e6a1daeafc072e9c9472fc3a49ba85eb50da9d8f6803991e9c2a9d702435f`. Its lock names root manifest identity `14299ac5fff725c1c193d66020c9f2ede0adc4b497575c9b267cf3babe56610d` and the rebuilt runtime archive exactly.

## Acceptance

- [x] Artifact metadata and runtime values compose without host fields.
- [x] Signed globals match the complete stage-0 transcript.
- [x] The normalized frame remains private and exactly sized.
- [x] Native execution occurs once per identity operation.
- [x] Runtime and conformance archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Return metadata and values to Java

Rejected. Java would remain the execution identity authority.

### Hash descriptor-order globals directly

Rejected. WIP-0204 owns canonical map order and duplicate rejection.

### Claim unsupported result fields are implemented

Rejected. The composition profile records only values produced by the current native interpreter.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0204](WIP-0204-native-test-execution-identity.md)
- [WIP-0206](WIP-0206-complete-native-artifact-outcomes.md)
- [WIP-0207](WIP-0207-native-test-artifact-metadata.md)
- [WIP-0209](WIP-0209-native-one-case-test-runner.md)
