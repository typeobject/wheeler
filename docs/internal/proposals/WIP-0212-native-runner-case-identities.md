# WIP-0212: Native runner case identities

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and conformance maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, case discovery, identity composition |
| Depends on | WIP-0018, WIP-0197, WIP-0211 |
| Supersedes | Hard-coded case identities in the two-case native runner |
| Superseded by | None |

## Summary

Derive the two-case runner's semantic case identities inside Wheeler from manifest identity, selected target name, and source identity.

`NativeTwoCaseTestRunner.w` now frames the WIP-0197 runtime operation before case execution. Raw digest bytes become canonical lowercase text through the new `TestIdentityText.w` utility. The resulting values enter artifact case rows and final report ordering.

## Identity inputs

The conformance profile fixes one manifest identity and target `test`. Each artifact carries a distinct source identity. The case transcript remains:

1. `wheeler.test-case/1`
2. manifest identity
3. target name
4. source identity

The runner stores the exact 134-byte identity frame once, changes only its 64-byte source field, and invokes the runtime derivation for each case.

The passing artifact arrives first and derives an identity beginning `b178`. The failing artifact arrives second and derives an identity beginning `74c7`. Canonical reduction must therefore reverse physical order.

## Hexadecimal text

`TestIdentityText.w` owns raw 32-byte to lowercase 64-byte hexadecimal conversion. It supports a caller-selected output cursor and a complete-output wrapper.

`TestArtifactReport.w` now uses the same operation for artifact, execution, and coverage identities. The private duplicate encoder is deleted.

## Ownership

The two-case runner adds one 134-byte case transcript and one 32-byte raw digest to its region. Its bound is 88,166 bytes in 17 allocations. The two 64-byte textual case identities remain separate because both rows outlive the second derivation.

## Evidence

`NativeCoverageRunExampleTest` independently hashes both case transcripts in Java and uses the resulting text in the expected profile-2 report. The Wheeler runner reproduces all 32 report bytes.

The existing one-case runner continues through the shared artifact report encoder. It imports no unreachable case-identity source.

The runtime archive contains 173,870 bytes with SHA-256 `1753fe7a2cd9d3f55e8e8ad67c5283c78db6b729f6cea0a18bd74d061e94002f`. Its schema-3 lock retains root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 137,459 bytes with SHA-256 `d885c991388a1fc0dd8586b5bc6c321ace81fa45a9e29d6c743b187c77e6e531`. Its lock retains root manifest identity `8e8fe8757e7729a9399b59b2d7ec53170b8828434e9e0268405a1652c3bf3048` and names the rebuilt runtime archive exactly.

## Acceptance

- [x] Both case identities derive inside Wheeler.
- [x] Manifest, target, and source bytes match the stage-0 transcript.
- [x] Raw digest text has one runtime implementation.
- [x] Derived ordering still reverses physical artifact order.
- [x] One-case composition remains byte-identical.
- [x] Runtime and conformance archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Keep identity constants in the runner

Rejected. Discovery cannot become native while semantic identities arrive from the host.

### Encode digest text separately in each consumer

Rejected. Artifact reports and discovery require the same lowercase bytes.

### Sort by source identity

Rejected. WIP-0018 orders semantic results by derived case identity.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0197](WIP-0197-runtime-test-selection-authority.md)
- [WIP-0211](WIP-0211-native-two-case-test-runner.md)
