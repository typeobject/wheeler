# WIP-0252: Native artifact row binding

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, compiler, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Self-hosting, native testing, artifact authorization |
| Depends on | WIP-0249, WIP-0250, WIP-0251 |
| Supersedes | Function-only authorization for parameterized artifacts |
| Superseded by | None |
| Follow-up | WIP-0253 native parameterless test compilation |

## Summary

Bind every transported test artifact to the exact native-discovered parameter row before interpretation.

WIP-0251 bound module and declaration names. Two artifacts for the same parameterized declaration still shared that function name. A caller could swap `flags[0]` and `flags[1]` artifacts while retaining valid descriptors. Both artifacts verified and passed function authorization, but the synthetic entries installed the wrong source values.

The runner now carries source-discovered case kind and scalar value by canonical descriptor ordinal. Artifact authorization checks the verified synthetic entry against those values.

## Discovery product

`TestSourceTests.w::discoverRootTests` receives two caller-owned 64-word tables:

- case kind: parameterless, `long`, or `boolean`
- canonical signed scalar value

When a declaration or row matches one complete descriptor, discovery writes its product at that descriptor ordinal. Duplicate names, duplicate values, unsupported rows, missing descriptors, and extra descriptors still reject before the tables can authorize execution.

The tables do not create another ordering rule. Strict descriptor name order remains canonical. Declaration order and source row values select table entries only through exact descriptor matching.

## Synthetic entry profile

After one verifier attempt, `ArtifactMetadata.w::artifactTestEntryMatches` checks the entry function selected by the artifact manifest.

A parameterless artifact must contain exactly:

```text
CALL_VOID <declared-function>, 0, 0
HALT
```

A parameterized artifact must contain exactly:

```text
LOCAL_CONST 0, <source-row-value>
LOCAL_MOVE 1, 0
CALL_VOID <declared-function>, 1, 1
HALT
```

Instruction opcodes, operand counts, encoded lengths, local coordinates, call target, argument window, signed value, total entry length, and terminal halt must all match. Boolean rows use canonical signed values zero and one.

The declared function remains function zero in the current transported test profile. WIP-0251 proves its exact qualified name before entry validation.

## Execution boundary

`ArtifactExecution.w::executeBoundedNamedArtifact` accepts the expected function, case kind, and case value. Verification runs once. Function and entry authorization then run over the accepted immutable bytes. The interpreter runs only when both checks succeed.

Authorization failure performs no transition and publishes no case row or summary. Malformed artifacts still retain `WTEST004` without metadata projection.

Unselected descriptors retain no artifact copy, verifier, metadata, or interpreter attempt. Their discovered row products remain inert bounded words.

## Evidence

`rejectsArtifactsWithTheWrongParameterRow` independently compiles five mixed Boolean and long row artifacts. It retains every canonical descriptor name but swaps the two Boolean artifacts.

The first selected artifact verifies and matches `pkg.test::flags`. Its synthetic entry installs `true` while native source discovery requires `false`. Authorization traps before interpretation, and all 39 output bytes remain zero.

`discoversCanonicalLongAndBooleanParameterRows` proves positive authorization for `false`, `true`, `-1`, `0`, and `2`. Parameterless and counted cases prove the two-instruction entry profile.

The runtime archive contains 277,818 bytes with SHA-256 `e10215c91a5191b58065e8c39709adef2a9190b5296222b633b6d1473eaf61c0` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,094 bytes with SHA-256 `b866164f0216db3c6b2e0662e0c36510863a4324a0481b4a4831b3890c0d5a3b` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the new runtime archive exactly.

## Acceptance

- [x] Native discovery publishes case kind and value by descriptor ordinal.
- [x] Parameterless entries bind exact call target and zero arguments.
- [x] Parameterized entries bind exact signed source value.
- [x] Boolean rows use canonical zero and one values.
- [x] Entry opcodes, lengths, locals, argument windows, and halt are exact.
- [x] Verification precedes entry projection.
- [x] Authorization precedes interpretation and publication.
- [x] Unselected artifacts consume no attempt.
- [x] Swapped valid row artifacts trap with untouched output.
- [x] Positive mixed scalar rows retain canonical summaries.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Trust the descriptor ordinal

Rejected. A name does not prove which value the artifact installs.

### Hash the artifact beside the row

Rejected. No source-owned expected artifact hash exists yet.

### Inspect Java test-case metadata

Rejected. Java is not native authorization authority.

### Accept equivalent entry instruction sequences

Rejected. The first profile has one canonical stage-0 synthetic entry.

## References

- [WIP-0249](WIP-0249-native-parameter-row-discovery.md)
- [WIP-0250](WIP-0250-single-pass-artifact-verification.md)
- [WIP-0251](WIP-0251-native-artifact-function-binding.md)
- [WIP-0253](WIP-0253-native-parameterless-test-compilation.md)
