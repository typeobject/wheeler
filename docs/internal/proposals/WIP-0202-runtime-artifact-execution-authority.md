# WIP-0202: Runtime artifact execution authority

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and conformance maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native execution, test runners, coverage |
| Depends on | WIP-0008, WIP-0018, WIP-0020 |
| Supersedes | Conformance-owned interpreter storage |
| Superseded by | None |

## Summary

Move bounded artifact execution and its storage ownership into the canonical runtime.

`ArtifactExecution.w` allocates one fresh interpreter machine, executes one artifact, releases every owned array, and returns a closed `ArtifactOutcome`. Conformance coverage now consumes this operation instead of maintaining a private copy of interpreter storage layout.

This is the execution seam required by the Wheeler-written test runner. Coverage, tests, and later package tools may attach different reducers without creating different machines.

## Interface

`executeBoundedArtifact(artifact, traceOpcodes)` accepts one artifact and a caller-owned trace buffer with the exact interpreter capacity. It returns:

- whether execution reached a value
- committed interpreter steps
- final global zero on success
- verifier or interpreter error offset on failure

The result does not publish host output and does not classify an interpreter error as a test diagnostic. Test policy remains with WIP-0018.

## Ownership

The operation allocates globals, locals, return frames, aggregate metadata, storage metadata, and storage words in one 24,000-byte private region. The caller owns only the opcode trace because coverage and test reducers consume it after machine teardown.

All machine arrays and the region are dropped on either result variant. No state survives between calls.

## Coverage cutover

`NativeCoverageRun.w` now owns only coverage policy:

1. allocate the trace and fragment buffers
2. call runtime artifact execution
3. require a successful bounded fixture
4. derive source fragments
5. reduce and publish the report

Nineteen duplicated storage allocations and the result-unwrapping match were deleted from conformance.

## Failure behavior

Artifact verification or execution failure returns an error outcome after storage teardown. A consumer decides whether that outcome is expected, reportable, or fatal.

The coverage consumer still rejects failed and unsupported fixtures before publication. Its untouched-output evidence remains authoritative.

## Evidence

`NativeCoverageRunExampleTest` compiles the runtime operation into the native coverage executable. Its supported compiler artifact produces the byte-identical profile-1 report. Its unsupported trace traps before publication and leaves output untouched.

The runtime archive contains 142,831 bytes with SHA-256 `c832599c628cb1695889dfc5b90de20c29c1deab9d383b556738e0437a0099bb`. Its schema-3 lock retains root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 120,014 bytes with SHA-256 `86ee47f4785a986b176f6a9f9312e7b1aff5a2f2e35b46024990a96e759daab5`. Its lock retains root manifest identity `3b6a16a57c3701eec9d5fd0813761e07bee30027706251348fa7b6d4dcdf281f` and names the rebuilt runtime archive exactly.

## Acceptance

- [x] Fresh interpreter storage belongs to the runtime library.
- [x] Success and error variants become a closed runtime value.
- [x] Trace ownership remains explicit at the caller boundary.
- [x] Native coverage deletes its duplicate machine allocation path.
- [x] Existing coverage report and atomic-failure evidence pass.
- [x] Runtime and conformance archives are rebuilt and locked exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Leave execution in conformance

Rejected. Test and coverage runners would duplicate a private machine layout.

### Hide the trace in the execution operation

Rejected. Coverage needs the complete measured trace after execution storage is gone.

### Convert errors to assertions in the runtime

Rejected. Runtime execution reports mechanism. Test and coverage consumers own policy.

## References

- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0020](WIP-0020-semantic-coverage-and-evidence-accounting.md)
