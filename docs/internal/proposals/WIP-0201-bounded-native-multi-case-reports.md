# WIP-0201: Bounded native multi-case reports

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and conformance maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, semantic reports, canonical reduction |
| Depends on | WIP-0018, WIP-0199, WIP-0200 |
| Supersedes | Separate empty and one-case report frames |
| Superseded by | None |

## Summary

Derive profile-2 semantic report identities for zero through 64 complete case results inside Wheeler.

`TestReportIdentity.w` now parses one counted frame, validates every row, sorts by case identity, rejects duplicates, and hashes the exact stage-0 transcript. The former frame-shape dispatch is gone.

The 64-case bound is the native bootstrap report profile. Stage 0 retains its wider 65,535-case package ceiling until native reduction scales without weakening memory bounds.

## Input

The report frame contains:

1. two-byte runner-identity length and 64 lowercase hexadecimal bytes
2. two-byte little-endian case count
3. exactly that many case rows

Each case row carries ten two-byte-length-prefixed fields: package, version, selected case name, case identity, source identity, artifact identity, diagnostic code, diagnostic message, execution identity, and coverage identity. Status, assertion count, and workflow steps follow as defined by WIP-0199.

No trailing bytes are accepted. Zero rows use the same frame and parser as nonempty reports.

## Canonical order

The parser stores field ranges without copying payloads. A bounded index table uses insertion sort over complete 64-byte case identities. At most 2,016 comparisons are required for 64 rows.

Duplicate identities reject after sorting. Arrival order therefore changes neither transcript nor identity.

## Transcript

The digest begins with `wheeler.test-report/2`, runner identity, and the exact case count. Sorted rows then enter in stage-0 `CaseResult.digestInto` order.

The maximum transcript contains 354,925 bytes. Private staging owns 367,277 bytes in eight allocations, including 1,280 field ranges, status offsets, order, transcript, and SHA-256 state.

## Failure behavior

Malformed rows, invalid pass or fail combinations, duplicate identities, negative counters, excess cases, transcript overflow, trailing bytes, or wrong output capacity trap before publication.

No compatibility parser accepts the superseded WIP-0199 or WIP-0200 physical frames.

## Evidence

`NativeTestReportIdentityExampleTest` retains empty, passing, failing, Unicode diagnostic, malformed, and untouched-output evidence.

A new fixture supplies two cases in reverse identity order and matches an independently sorted Java transcript. A nonadjacent duplicate rejects before publication.

The runtime archive contains 138,926 bytes with SHA-256 `801f04ab064aa9a9635dd31e85dbdc802672a1ea1bf8941e16afab6affeeca1a`. Its schema-3 lock retains root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 122,817 bytes with SHA-256 `d8f2075a9a4e33a278280904a40b602615769725a11a8163a2e4d1d0a7c87c76`. Its lock retains root manifest identity `3b6a16a57c3701eec9d5fd0813761e07bee30027706251348fa7b6d4dcdf281f` and names the rebuilt runtime archive exactly.

## Acceptance

- [x] One counted frame covers zero through 64 cases.
- [x] Arrival order does not affect report identity.
- [x] Duplicate identities reject after canonical ordering.
- [x] Empty, passing, failing, and malformed evidence remains exact.
- [x] Superseded frame dispatch is deleted.
- [x] Runtime and conformance archives are rebuilt and locked exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Keep separate frame shapes

Rejected. Shape-based dispatch was transitional code with no semantic value.

### Retain arrival order

Rejected. Worker completion order cannot enter report identity.

### Claim the stage-0 package ceiling

Rejected. This bootstrap profile accepts 64 cases and reports that bound plainly.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0199](WIP-0199-native-one-case-report-identity.md)
- [WIP-0200](WIP-0200-native-empty-report-identity.md)
- [Package testing reference](../../public/reference/packages.md#tests)
