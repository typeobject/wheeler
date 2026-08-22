# WIP-0206: Complete native artifact outcomes

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and conformance maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, artifact execution, result composition |
| Depends on | WIP-0018, WIP-0202, WIP-0203, WIP-0204 |
| Supersedes | WIP-0203 single-global outcome frame |
| Superseded by | None |

## Summary

Preserve the complete bounded global result vector when native artifact execution crosses into test policy.

The first outcome slice retained only global zero. That was enough for coverage conformance but insufficient for the stage-0 execution identity, which binds every named global. `ArtifactOutcome` now carries the interpreter's global count and all eight bounded slots.

## Runtime outcome

A successful outcome contains:

- committed step count
- active global count
- global slots zero through seven
- zero error offset

An error outcome contains status and error offset. Steps, global count, and every global slot remain zero.

`NativeCoverageRun.w` reads global zero explicitly. It does not depend on the expanded conformance frame.

## Conformance frame

`NativeTestArtifactRun.w` replaces the transitional 25-byte frame with one 89-byte frame:

1. one status byte
2. committed steps
3. active global count
4. eight signed global values
5. error offset

Every scalar is eight-byte little-endian two's complement. The output size is exact.

## Evidence

`NativeCoverageRunExampleTest` compiles a stage-0 artifact with two globals initialized to 7 and -4. Native execution publishes one committed `HALT`, active count two, the exact signed values, zero in all inactive slots, and no error.

Corrupting that artifact's magic publishes one error outcome with every execution field zero. Existing native compiler, coverage reduction, and coverage identity fixtures continue unchanged.

The runtime archive contains 153,961 bytes with SHA-256 `82ef4c57583f686adddce61c12a40899a06db6dc59a39375f5f256e88fb1b56a`. Its schema-3 lock retains root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 123,915 bytes with SHA-256 `998cf8ac8655f5885c899cbff1b28781b9b6c60042b11f435fe1df31a11ce0fb`. Its lock retains root manifest identity `90843d43b350acd5ae5945dfaa01df26702c003edba9993b896235d7a774b39d` and names the rebuilt runtime archive exactly.

## Acceptance

- [x] Runtime execution retains all eight bounded globals.
- [x] Active count distinguishes live slots from zero values.
- [x] Signed global values survive the conformance frame exactly.
- [x] Error outcomes expose no stale execution state.
- [x] Coverage consumes the named global-zero field.
- [x] Runtime and conformance archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Derive execution identity from global zero

Rejected. Stage 0 hashes the complete canonical global map.

### Return the interpreter storage array

Rejected. Machine storage is private and must be dropped before the outcome crosses the runtime boundary.

### Add globals only to the conformance wrapper

Rejected. The runtime operation must not discard semantic result data.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0202](WIP-0202-runtime-artifact-execution-authority.md)
- [WIP-0203](WIP-0203-native-test-artifact-outcomes.md)
- [WIP-0204](WIP-0204-native-test-execution-identity.md)
- [WIP-0207](WIP-0207-native-test-artifact-metadata.md)
