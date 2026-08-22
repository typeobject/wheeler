# WIP-0203: Native test artifact outcomes

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and conformance maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, artifact execution, terminal outcomes |
| Depends on | WIP-0018, WIP-0202 |
| Supersedes | None |
| Superseded by | None |

## Summary

Classify one test artifact through the Wheeler-owned execution seam without a Java VM or exception deciding the terminal result.

`NativeTestArtifactRun.w` is a thin conformance entry point over `executeBoundedArtifact`. It publishes the closed runtime outcome in a fixed 25-byte frame. This is the first runner slice that treats verifier failure as data rather than trapping in the host harness.

## Output

The frame contains:

1. one status byte: zero for an execution value, one for an error
2. eight-byte little-endian committed step count
3. eight-byte little-endian final global zero
4. eight-byte little-endian verifier or interpreter error offset

Success sets the error offset to zero. Failure sets steps and final global zero to zero. Status disambiguates a failure at byte zero from success.

The frame is an internal bootstrap product. It is not the profile-2 semantic report and carries no package, case, source, artifact, execution, or coverage identity. Those remain report-reduction inputs owned by WIP-0018.

## Execution

The entry point allocates only the exact opcode trace required by `ArtifactExecution.w`. Fresh machine storage and teardown stay in the runtime library. The wrapper neither verifies independently nor reconstructs interpreter arrays.

The output length is exact. A wrong host capacity rejects before execution.

## Evidence

`NativeCoverageRunExampleTest` compiles the same source artifact used by native coverage and executes it through `NativeTestArtifactRun.w`. The output records success, three committed steps, final global zero, and no error.

The fixture then corrupts the artifact magic. Runtime verification returns an error at byte zero. Native classification publishes status one with zero steps, zero final global, and error offset zero. No Java exception defines that failure.

The fixture's shared module builder now owns interpreter closure assembly for both coverage and test execution. No second Java source list was added.

The conformance archive contains 121,691 bytes with SHA-256 `b44241c007731ce4dde9febc813ded4edd8a7b9e320da86f987a33249f60fa87`. Its schema-3 lock names root manifest identity `72a7af445a745853a02a41df7af065ff4033300da5ea095e83ed709f49456ae9` and runtime archive `c832599c628cb1695889dfc5b90de20c29c1deab9d383b556738e0437a0099bb` exactly.

## Acceptance

- [x] A successful artifact becomes a closed native outcome frame.
- [x] A verifier error becomes data rather than a host trap.
- [x] Success and error fields are exact and unambiguous.
- [x] Coverage and test fixtures share one interpreter closure builder.
- [x] Conformance archive and dependency locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Map verifier errors through Java exceptions

Rejected. Host exception type is not Wheeler test semantics.

### Publish a partial profile-2 report

Rejected. A report requires canonical package and case metadata plus execution and coverage identities. This WIP owns only terminal execution classification.

### Copy interpreter storage into the wrapper

Rejected. WIP-0202 made the runtime library authoritative for that storage.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0202](WIP-0202-runtime-artifact-execution-authority.md)
- [WIP-0204](WIP-0204-native-test-execution-identity.md)
