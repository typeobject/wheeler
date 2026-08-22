# WIP-0204: Native test execution identity

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and conformance maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, execution results, semantic identity |
| Depends on | WIP-0018, WIP-0203 |
| Supersedes | Java-only execution identity derivation |
| Superseded by | None |

## Summary

Reproduce the complete profile-2 execution-result identity inside the Wheeler runtime.

`TestExecutionIdentity.w` validates one normalized result, sorts globals by canonical name, rejects duplicates, and hashes the exact stage-0 transcript. Classical, quantum, and hybrid kinds share one operation.

## Input

The counted frame contains program identity text, kind code, globals, measurements, quantum job identities, workflow steps, and output bytes.

The bootstrap profile admits 64 globals, 1,024 measurements, 64 jobs, 255 bytes per name or job identity, and 65,535 output bytes. Global names use the source identifier alphabet plus qualification dots. Program and job payloads remain UTF-8 bytes.

Signed scalars enter as little-endian frame values and are hashed as canonical eight-byte big-endian two's-complement values.

## Canonical reduction

Global rows retain ranges into the caller input. A bounded insertion sort orders their ASCII names exactly as the stage-0 `TreeMap` does for the admitted alphabet. Equal names reject before hashing.

Measurements and jobs retain declared semantic order. They are not maps and must not be sorted.

The maximum transcript occupies 108,255 bytes. Private staging owns 111,391 bytes in eight allocations, including global ranges, values, order, transcript, and SHA-256 state.

## Failure behavior

Unknown kinds, empty or invalid global names, duplicate globals, excess counts, negative workflow steps, truncated fields, oversized output, trailing bytes, or wrong output capacity trap before publication.

## Evidence

`NativeTestExecutionIdentityExampleTest` independently hashes complete classical, quantum, and hybrid fixtures. The fixtures include reverse global order, a negative global, negative and positive measurements, UTF-8 job text, workflow steps, and binary output.

Duplicate globals, negative workflow steps, and a truncated frame reject with all 32 output bytes untouched.

The runtime archive contains 151,509 bytes with SHA-256 `7510bda1411ba67300555c9d3d6ab5736bdd8defc90ffcd305af5ea17f474972`. Its schema-3 lock retains root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 122,498 bytes with SHA-256 `48c39835831d0a9388797c04997ce3eb158747d9932255a6f17e3b34a94a5b02`. Its lock names root manifest identity `fc364183d3d85e4be4418214bff1553eabada787618ad43f821100caff6ff789` and the rebuilt runtime archive exactly.

## Acceptance

- [x] All three program kinds match the stage-0 transcript.
- [x] Global arrival order does not affect identity.
- [x] Signed values preserve exact two's-complement bytes.
- [x] Measurements, jobs, workflow steps, and output are bound.
- [x] Duplicate and malformed inputs reject atomically.
- [x] Runtime and conformance archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Hash interpreter steps alone

Rejected. Stage-0 execution identity binds the complete `ExecutionResult` value.

### Sort measurements or jobs

Rejected. Their list order is semantic.

### Keep Java as the execution hash authority

Rejected. Native report construction cannot depend on a host-private identity.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0203](WIP-0203-native-test-artifact-outcomes.md)
- [WIP-0205](WIP-0205-native-test-coverage-identity.md)
