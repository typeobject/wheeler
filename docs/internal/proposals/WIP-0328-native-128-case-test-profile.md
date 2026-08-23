# WIP-0328: Native 128-case test profile

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, package, and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Native testing, reports, package execution |
| Depends on | WIP-0327 |
| Supersedes | The 64-case native test and package profile |
| Superseded by | WIP-0329 native compiler resolved local-return suite |

## Summary

Raise the complete native test, report, adapter, and package profile from 64 to 128 cases after the compiler package fills the former bound.

The count remains one byte on input and two bytes in report frames. Values 252 through 255 remain framing sentinels. This WIP changes no descriptor mode, source count, archive count, manifest bound, transition bound, tag bound, or execution policy.

## Authority

`TestLimits.w` owns the shared profile:

| Limit | Value |
| --- | ---: |
| Complete cases | 128 |
| Bytes per profile-2 row | 5,345 |
| Concatenated report rows | 684,160 |
| Published identity, summary, length, and rows | 684,203 |
| Raw summary identities | 4,096 |

The runner, discovery, report identity, row reducer, and all presentation adapters derive their case and row bounds from that module. Java accepts the same 128-case package ceiling and remains outside discovery, compilation, execution, outcome, ordering, and identity semantics.

## Storage

The larger bound has explicit storage:

- `TestRunner.w` uses a 1,802,240-byte staging region.
- `TestSourceTests.w` uses 109,568 bytes. Only the parameter-row column grows. Tag columns remain at the independent 64-tag bound.
- `TestReportIdentity.w` reserves 709,741 message bytes and 733,357 staging bytes.
- `TestReportRows.w` reserves 1,368,520 staging bytes.

Parameterized names now encode ordinals 100 through 127 as three decimal digits. Matching and construction use the same closed spelling.

## Evidence

`NativeCompiledTestRunnerExampleTest` performs metadata-only discovery over 128 parameterless declarations and one 128-row parameterized declaration. Both publish count 128. It then compiles and executes all 128 parameterless cases once through fresh storage and reports 128 passes. A 129th selected declaration traps before publication.

`NativeTestReportIdentityExampleTest` reproduces the stage-0 digest for 128 complete rows and rejects row 129.

`NativeTestReportBoundExampleTest` reduces 128 complete rows from reverse input order, checks first and last canonical identities, and rejects row 129. JSON, JUnit XML, and terminal adapters then render the same 128 canonical rows and publish matching selected and passed counts.

The checked-in compiler package remains a sixty-four-case integration regression. All cases pass through the widened runner, row reducer, JSON adapter, terminal adapter, and JUnit adapter with unchanged report identity `c8f7bb1cbcf6d424cc3ef0ae451852df7f08b96c104ff0d86800000cd80b9b50`. The canonical workspace checks 125 targets.

## Acceptance

- [x] One runtime module owns the complete case and row transport bounds.
- [x] Metadata discovery accepts exactly 128 parameterless cases.
- [x] Metadata discovery accepts exactly 128 parameter rows.
- [x] Ordinals 100 through 127 use exact three-digit names.
- [x] All 128 selected source cases compile and execute exactly once.
- [x] Discovery rejects case 129 before publication.
- [x] Report identity accepts 128 complete rows and rejects row 129.
- [x] Package row reduction accepts 128 complete rows and rejects row 129.
- [x] JSON, JUnit XML, and terminal adapters render the same 128 rows.
- [x] The existing sixty-four-case compiler package remains byte-identical.
- [x] Source formatting, documentation, workspace, lock, archive, and file policy gates pass.

The runtime archive contains 437,954 bytes with SHA-256 `086a31f34a656167eda6ddb68778e82cb6a7c9d12465b4705b0bf33d0ee9ab30`. Its root manifest identity remains `42011c887d887364ca16bc2255bc28374882559192e9ab6dbf5f674ce0ae1f49`.

## Rejected alternatives

### Add case 65 without widening the report path

Rejected. Discovery capacity without report, summary, row, and adapter capacity is a partial transport.

### Reuse the case bound for tags

Rejected. Case count and tag count are separate resource domains. Increasing one does not grant more of the other.

### Move the count to sixteen-bit input framing

Rejected. One byte already represents 128 while preserving the four descriptor-mode sentinels.

### Publish only the first 128 rows

Rejected. The runner accepts the complete selected set or none of it. Truncation is not bounded execution.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0218](WIP-0218-bounded-native-descriptor-runner.md)
- [WIP-0248](WIP-0248-native-counted-test-discovery.md)
- [WIP-0255](WIP-0255-native-counted-test-compilation.md)
- [WIP-0278](WIP-0278-native-package-row-reduction.md)
- [WIP-0327](WIP-0327-native-single-imported-helper-ownership.md)
- [WIP-0329](WIP-0329-native-compiler-resolved-local-return-suite.md)
