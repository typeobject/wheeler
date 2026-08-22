# WIP-0199: Native one-case report identity

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and conformance maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, semantic reports, Java-free execution |
| Depends on | WIP-0018, WIP-0195, WIP-0198 |
| Supersedes | None |
| Superseded by | None |

## Summary

Reproduce complete profile-2 semantic report identities for the one-case vertical slice inside Wheeler.

`TestReportIdentity.w` validates one case result, constructs the exact stage-0 digest transcript, and writes the raw SHA-256 report identity. `NativeTestReportIdentity.w` publishes the returned 32-byte extent.

This closes report identity for one case. Multi-case row ordering and transcript assembly remain separate WIP-0018 work.

## Input

The frame contains eleven two-byte-length-prefixed UTF-8 byte fields:

1. runner identity
2. package name
3. package version
4. target or selected case name
5. case identity
6. source identity
7. optional artifact identity
8. diagnostic code
9. diagnostic message
10. optional execution identity
11. optional coverage identity

One status byte follows: zero is pass and one is fail. Two little-endian signed 64-bit fields then carry assertion count and workflow steps. The physical input ends there.

Runner, case, and source identities are mandatory lowercase hexadecimal SHA-256 text. Artifact, execution, and coverage identities are either empty or the same 64-byte canonical form.

Package, version, target, and diagnostic-code fields contain at most 255 bytes. Diagnostic text contains at most 4,096 bytes.

## Result validity

A passing row requires artifact and execution identities and forbids diagnostic code or text.

A failing row requires a diagnostic code. Artifact, execution, and coverage identities remain optional because compile rejection and runtime failure close at different boundaries.

Assertion count and workflow steps are nonnegative. Unknown status values reject.

## Transcript

The digest consumes:

1. field `wheeler.test-report/2`
2. runner identity field
3. eight-byte big-endian case count one
4. the exact `CaseResult.digestInto` field order

Every string field uses an eight-byte big-endian length. Assertion count and workflow steps use the same eight-byte big-endian integer representation as stage 0. Status hashes as `PASS` or `FAIL`.

The implementation hashes only the active transcript prefix. Private staging owns 6,917 bytes in six allocations, including SHA-256 work state.

## Failure behavior

Malformed framing, identity text, field bounds, status combinations, negative counters, output capacity, or private storage traps before publication.

The conformance wrapper contains no transcript or validation rule.

## Evidence

`NativeTestReportIdentityExampleTest` independently constructs the Java `TestReport` transcript for one passing and one failing case. The failing diagnostic contains non-ASCII UTF-8. Both 32-byte identities match.

A passing row with diagnostics, a failure without a code, and a negative assertion count leave all output bytes unchanged.

The runtime archive contains 135,743 bytes with SHA-256 `7a168b465b138c0abf277a3efa0af9bcb87acb452874a4659537ad85fca9d695`. Its schema-3 lock retains root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 122,820 bytes with SHA-256 `9b0934a18ab1417dee2e5ccb1336a09497e40b990d5922e54305218136ec2265`. Its lock binds root manifest identity `3b6a16a57c3701eec9d5fd0813761e07bee30027706251348fa7b6d4dcdf281f` and names the rebuilt runtime archive exactly.

## Acceptance

- [x] Passing and failing one-case reports match stage 0 byte for byte.
- [x] Every profile-2 case field participates in canonical order.
- [x] Pass and fail invariants reject before hashing authority publishes.
- [x] UTF-8 diagnostic bytes survive the transcript unchanged.
- [x] Focused differential and failure evidence passes.
- [x] Runtime and conformance archives are rebuilt and locked exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Hash a reduced summary

Rejected. Summary counts do not bind case evidence.

### Accept a host-built digest transcript

Rejected. Field framing and ordering are semantic report rules.

### Claim multi-case parity

Rejected. This slice fixes the case count at one and says so.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0195](WIP-0195-native-test-case-identity.md)
- [WIP-0198](WIP-0198-runtime-test-summary-authority.md)
- [Package testing reference](../../public/reference/packages.md#tests)
