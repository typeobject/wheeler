# WIP-0268: Native package test-report identity

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler package, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, package testing, report reduction |
| Depends on | WIP-0265 |
| Supersedes | Unreduced lists of native target report identities |
| Superseded by | Full native package case-row publication |

## Summary

Reduce native target test reports into one bounded package evidence identity.

`TestPackageReportIdentity.w` consumes one through 64 rows. Each row contains:

```text
bytes target_report_identity[32]
u16 selected
u16 passed
u16 failed
```

The reducer validates each summary, sorts rows by raw target report identity, rejects duplicate identities, aggregates counts with a 65,535 ceiling, and hashes one domain-separated package frame.

Output contains the raw 32-byte package identity followed by aggregate selected, passed, and failed counts.

## Identity frame

The hashed frame is:

```text
"wheeler.test-package-report/1"
u8 target_count
repeat target_count in sorted identity order {
  bytes row[38]
}
u16 total_selected
u16 total_passed
u16 total_failed
```

All integers are little-endian where they enter rows or output. The one-byte target bound fixes the frame shape. Capacity bytes never enter the hash.

Sorting removes manifest traversal and worker arrival order from package evidence. Strict identity order rejects duplicate target reports rather than accepting double-counted cases.

This package identity is not profile-2 case-report identity. It commits to complete native target report identities and summaries under its own domain. Full case-row publication remains required before Java rendering can be removed.

## Runtime and conformance

`wheeler.runtime.testing.test_package_report_identity` owns validation, ordering, aggregation, and hashing. `RuntimeLibrary.w` imports it into the reachable package closure.

The `nativetestpackagereportidentity` conformance target is a thin 38-byte publisher. It receives canonical input and delegates all semantics to runtime.

`NativePackageTestRunner.java` sends exact target output prefixes to this target after all target runs. It checks that native package totals equal its checked aggregate and exposes the lowercase package identity beside the ordered target identities.

The host does not hash target identities.

## Evidence

`invokesEveryNativePackageTestTarget` runs two tagged package targets. The native package adapter retains two target identities, invokes the package reducer, checks two selected and two passed cases, and exposes one 64-digit package identity.

`reducesPackageTargetsIndependentOfArrivalOrder` supplies two target rows in both orders and requires byte-identical output. It also supplies a duplicate identity and requires native rejection.

Single-target and local-import package tests pass through the same reducer with one target row. Unknown-tag metadata probes do not enter package report reduction.

Runtime and conformance package checks prove that the new authority is reachable through exact package sources and lock provenance.

## Acceptance

- [x] One through 64 target report rows are admitted.
- [x] Each target summary requires `selected == passed + failed`.
- [x] Rows sort by raw target identity.
- [x] Duplicate target identities reject.
- [x] Aggregate counts stay below 65,536.
- [x] A fixed domain separates package evidence from case reports.
- [x] The host does not hash target reports.
- [x] A thin conformance target publishes the runtime result.
- [x] Package invocation exposes one native package identity.
- [x] Metadata-only probes do not enter report reduction.
- [x] Runtime and conformance archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

The runtime archive contains 336,603 bytes with SHA-256 `bad1411df36f9e823fbec12e7034fa1fb9fbf7f08d0aacd111a9a33d9c0b0fe9` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 132,064 bytes with SHA-256 `6e266b64bacfe415c957fcaae5f697656a708af06d2e8f271b25d0417778341e` and root manifest identity `e15c8483d406c7367d5c5e38867909304aeee418444112f0de10dab47a6a9e11`. Its lock names the runtime archive exactly.

## Rejected alternatives

### Hash target reports in Java

Rejected. Package evidence needs one native reduction authority.

### Preserve arrival order

Rejected. Worker scheduling cannot enter evidence identity.

### Deduplicate identical target reports

Rejected. Duplicate terminal products are malformed input.

### Call this a profile-2 case report

Rejected. It commits to target reports, not complete package case rows.

## References

- [WIP-0265](WIP-0265-native-multi-target-package-test-gate.md)
- [WIP-0201](WIP-0201-bounded-native-multi-case-reports.md)
