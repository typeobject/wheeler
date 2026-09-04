# WIP-0200: Native empty-report identity

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and conformance maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Native testing, semantic reports, zero-case execution |
| Depends on | WIP-0018, WIP-0199 |
| Supersedes | One-case-only report identity dispatch |
| Superseded by | None |
| Follow-up | WIP-0201 counted multi-case report framing |

## Summary

Reproduce the profile-2 semantic identity for an empty selected test set inside Wheeler.

`deriveTestReportIdentity` now accepts either an empty-report frame or the WIP-0199 one-case frame. The conformance executable uses one dispatcher and one publication boundary.

## Input and transcript

The empty frame is one two-byte little-endian length followed by the 64-byte lowercase hexadecimal runner identity. No trailing byte is accepted.

The digest consumes:

1. field `wheeler.test-report/2`
2. runner identity field
3. eight-byte big-endian case count zero

The transcript contains exactly 109 bytes. Private staging owns 1,197 bytes in four allocations, including SHA-256 state.

## Semantics

An empty report is successful in the stage-0 model. Its selected, passed, and failed counts are all zero. Report identity still binds the exact runner.

The identity operation publishes only the digest. WIP-0198 retains summary ownership.

## Failure behavior

A wrong runner length, noncanonical identity, trailing input, or wrong output capacity traps before publication.

Empty and one-case dispatch depends on exact physical frame length. A malformed one-case frame cannot fall through as empty.

## Evidence

`NativeTestReportIdentityExampleTest` independently hashes the stage-0 empty-report transcript and compares all 32 bytes. Existing passing, failing, malformed, and untouched-output fixtures continue through the same dispatcher.

The runtime archive contains 137,041 bytes with SHA-256 `1614987b11113d7ab10e51d88e6451aa7c4a046542f741b02d22f1e4c50d5ab9`. Its schema-3 lock retains root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 122,817 bytes with SHA-256 `d8f2075a9a4e33a278280904a40b602615769725a11a8163a2e4d1d0a7c87c76`. Its lock retains root manifest identity `3b6a16a57c3701eec9d5fd0813761e07bee30027706251348fa7b6d4dcdf281f` and names the rebuilt runtime archive exactly.

## Acceptance

- [x] Empty report identity matches stage 0 byte for byte.
- [x] Runner identity remains mandatory and canonical.
- [x] Empty and one-case frames share one public runtime operation.
- [x] Existing one-case evidence remains unchanged.
- [x] Runtime and conformance archives are rebuilt and locked exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Treat no cases as no report

Rejected. Stage 0 emits a canonical successful report for an empty selection.

### Reuse the one-case count

Rejected. Case count participates directly in report identity.

### Add a second executable target

Rejected. Frame dispatch belongs inside the runtime authority.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0198](WIP-0198-runtime-test-summary-authority.md)
- [WIP-0199](WIP-0199-native-one-case-report-identity.md)
- [WIP-0201](WIP-0201-bounded-native-multi-case-reports.md)
