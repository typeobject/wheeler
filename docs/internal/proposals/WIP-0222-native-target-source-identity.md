# WIP-0222: Native target source identity

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and package maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Native testing, target sources, case discovery |
| Depends on | WIP-0009, WIP-0018, WIP-0195, WIP-0221 |
| Supersedes | Per-descriptor source identity inputs |
| Superseded by | None |
| Follow-up | WIP-0223 native source-plan validation |

## Summary

Bind every discovered case to one canonical package target source-set identity.

Stage 0 computes `sourceIdentity` once from `TargetSourceSet.canonicalInput` and uses that digest for every case selected from the target. The transitional native frame instead carried source bytes in every descriptor, which allowed sibling cases to claim unrelated source sets.

`TestRunner.w` now receives one target source plan after the manifest. Wheeler hashes it once. Descriptors carry only complete case name and artifact bytes.

## Target source plan

The accepted modular fixture uses the canonical package encoding:

1. four-byte big-endian source count
2. four-byte big-endian logical-path length
3. exact UTF-8 logical path
4. four-byte big-endian source length
5. exact source bytes

The runtime treats the source plan as a bounded opaque canonical package product and hashes all bytes. The stage-0 package layer still owns selector expansion, logical-path sorting, strict UTF-8 checks, and canonical framing.

The plan contains 1 to 32,768 bytes. The descriptor count follows its exact framed range.

## Case descriptors

Each descriptor now contains:

- one-byte complete case-name length
- complete case-name bytes
- four-byte artifact length
- exact artifact bytes

Complete case names distinguish `test::pass`, `test::fail`, and `test::runtime`. The same name enters both WIP-0195 case identity and the profile-2 report row. The selected package target name remains the manifest authorization boundary and no longer substitutes for discovered case name.

## Identity closure

The runner derives one SHA-256 source identity before descriptor processing and writes its lowercase hexadecimal text into every case transcript and result row.

One run therefore binds:

- canonical manifest bytes
- selected target policy
- canonical target source plan
- complete discovered case names
- per-case artifacts and outcomes

A descriptor cannot supply a private source digest or source text that disagrees with its siblings.

## Bounds

Removing per-case source bytes reduces maximum transport size by almost two MiB at 64 cases. Runtime retains one 32-byte raw source digest and one 64-byte text identity.

One dynamic case-name buffer lets the result row publish the discovered name. The existing 700,000-byte and 32-allocation outer bounds remain sufficient.

## Evidence

`NativeCoverageRunExampleTest` independently builds the canonical one-file modular target plan with big-endian framing. Java hashes that complete plan and uses the result in every expected case identity and report row.

The three distinct case names produce canonical order `fail`, `pass`, `runtime` and distinct `1/5` shard assignments. Empty, two-case, three-case, assertion, verifier, interpreter, and malformed-input products remain byte-identical.

The runtime archive contains 191,854 bytes with SHA-256 `523defae2642b157065cd91cb8cc5997e72edad4d7edf056c7bfd6f90103cdff` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1`. Its lock names the new runtime archive exactly and retains root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`.

## Acceptance

- [x] One target source plan supplies every case source identity.
- [x] Wheeler hashes the exact canonical plan once.
- [x] Descriptors no longer carry source bytes or source digests.
- [x] Complete discovered case names enter identities and report rows.
- [x] Independent source-plan and report transcripts match byte for byte.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Keep source bytes in each case descriptor

Rejected. Source selection belongs to the target and must not differ between sibling cases.

### Hash concatenated source text without logical paths

Rejected. Modular package identity binds canonical logical paths and boundaries.

### Use the target name as every case name

Rejected. Parameter rows and multiple declarations require complete distinct discovered names.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0195](WIP-0195-native-test-case-identity.md)
- [WIP-0221](WIP-0221-native-test-manifest-selection.md)
- [WIP-0223](WIP-0223-native-target-source-plan-validation.md)
