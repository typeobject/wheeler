# WIP-0197: Runtime test-selection authority

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and conformance maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, runtime library, conformance cutover |
| Depends on | WIP-0018, WIP-0194, WIP-0195 |
| Supersedes | Conformance-owned test identity and shard semantics |
| Superseded by | None |

## Summary

Move test-case identity derivation and deterministic shard assignment into the canonical Wheeler runtime library.

`TestCaseIdentity.w` and `TestShard.w` now own the semantic operations. `NativeTestCaseIdentity.w` and `NativeTestShard.w` are thin executable publication boundaries.

## Boundary

The runtime library owns pure, bounded derivation:

- `deriveTestCaseIdentity` validates one canonical profile-2 frame and writes the raw 32-byte digest.
- `assignedToShard` validates one canonical identity and shard frame and reports membership.

The conformance package owns host effects. Its entry points call one runtime operation, publish the returned extent or Boolean, and do nothing else.

No semantic rule is duplicated between the library and executable targets.

## Package graph

`RuntimeLibrary.w` imports both testing modules. They therefore ship in the canonical `wheeler.runtime` library archive rather than hiding behind executable conformance roots.

`wheeler.conformance` continues to export `nativetestcaseidentity` and `nativetestshard`. Its exact lock names the rebuilt runtime archive.

## Failure behavior

Validation remains inside the runtime operation. A malformed identity, frame, case name, shard count, or shard index traps before the conformance entry point publishes output.

The case transcript and SHA-256 state remain private. Shard assignment allocates no semantic storage.

## Evidence

The existing WIP-0194 and WIP-0195 differential suites now compile the runtime modules and thin conformance wrappers together. Their valid, maximum-bound, malformed, and no-publication fixtures are unchanged.

Package checks prove that consumers resolve the operations from the locked runtime archive.

The runtime archive contains 124,160 bytes with SHA-256 `19833b9323f5b86a6de50fd39693350ab7ed3f8f176e5ec89d26783e4ddbf308`. Its schema-3 lock retains root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 127,178 bytes with SHA-256 `2ba2ef65ed0eb629f301ccbbc1bf6175d7aeb3c7b047cf8dc2c2e552dfb18154`. Its lock retains root manifest identity `222af1d3f845c82713bfb26842f676fa29fcea5bd666d2a09c8ed63ac598b4d2` and names the rebuilt runtime archive exactly.

## Acceptance

- [x] Canonical runtime modules own case identity and shard assignment.
- [x] Conformance entry points contain no duplicate derivation logic.
- [x] `RuntimeLibrary.w` exports both operations.
- [x] Existing differential evidence passes through the new boundary.
- [x] Runtime and conformance archives are rebuilt and locked exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Keep semantics in deployable targets

Rejected. Conformance executables test library authority. They do not become that authority.

### Copy helpers into the runtime package

Rejected. One semantic operation gets one implementation.

### Expose stage-0 Java utilities as the library

Rejected. Java remains the differential oracle during native cutover.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0194](WIP-0194-native-test-shard-assignment.md)
- [WIP-0195](WIP-0195-native-test-case-identity.md)
