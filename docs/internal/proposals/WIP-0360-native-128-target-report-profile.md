# WIP-0360: Native 128-target report profile

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, package, and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-09-04 |
| Area | Native testing, package reports, package commands |
| Depends on | WIP-0268, WIP-0359 |
| Supersedes | Native 64-target package report profile |
| Superseded by | None |
| Follow-up | WIP-0361 native compiler early-return kind suite |

## Summary

Raise native package report reduction from 64 to 128 test targets.

The compiler package reaches sixty-four native targets in WIP-0359. The next coherent early-return suite adds two targets. The old reducer accepts discovery and execution, then rejects the complete package row set. Target capacity now fails in package preflight instead of after case execution.

## Authority

`TestPackageReportIdentity.w` owns target-row validation, ordering, summary reduction, and the package evidence identity. It admits one through 128 complete 38-byte target rows. Its 16,384-byte arena retains the full row table, domain-separated hash frame, output identity, and SHA-256 work storage.

`NativePackageTestRunner` applies the same target count before source planning, discovery, compilation, or execution. Cases retain their independent terminal count of 255. One target may publish many cases. One case count does not stand in for target count.

## Boundary evidence

`NativePackageTestRunnerTest.enforcesNativePackageTargetLimit` submits exactly 128 unique canonical target rows. Native reduction sorts all rows, publishes selected count 8,256, passed count 128, and failed count 8,128, and returns one package identity.

Row 129 traps before output. The focused test executes without retaining rewind history. The canonical workspace checks 170 targets. Bubble-sort snapshots are not package evidence.

## Acceptance

- [x] Exactly 128 unique target rows reduce successfully.
- [x] Target row 129 rejects before output.
- [x] Duplicate target identities still reject.
- [x] Summary equality is checked on every row.
- [x] Aggregate counts retain their 65,535 ceiling.
- [x] The package adapter rejects target 129 before source planning.
- [x] Case and report limits remain 255.
- [x] Focused runtime, package, documentation, and file policy gates pass.

The runtime archive contains 438,019 bytes with SHA-256 `f1ba3d2bd00b83da09ce04cf38730cac97c7edbea2a182454a8e77190e512c10`. Its root manifest identity remains `42011c887d887364ca16bc2255bc28374882559192e9ab6dbf5f674ce0ae1f49`.

## Rejected alternatives

### Reduce targets in batches of 64

Rejected. Batch identities would introduce a second reduction tree and make package identity depend on chunking.

### Reuse case capacity

Rejected. Target rows and case rows have distinct identities, summaries, and bounds.

### Retain VM rewind history in the boundary test

Rejected. Package reduction is single-pass authority. Persistent snapshots exhaust host heap without proving another semantic property.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0268](WIP-0268-native-package-test-report-identity.md)
- [WIP-0359](WIP-0359-native-compiler-call-classifier-suite.md)
- [WIP-0361](WIP-0361-native-compiler-early-return-kind-suite.md)
