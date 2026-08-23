# WIP-0348: Native 255-case test profile

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, testing, and package maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Native testing, reports, package execution |
| Depends on | WIP-0328, WIP-0347 |
| Supersedes | Native 128-case test profile |
| Superseded by | WIP-0349 native compiler named return suite |

## Summary

Raise the complete native test and report profile from 128 to 255 cases.

The compiler package filled the old bound with 128 independently selected artifacts. The compact runner frame carries selected, passed, and failed counts in one byte, so 255 is the terminal representable profile. Case 256 is not truncated or wrapped. It traps before publication.

## Authority

`TestLimits.w` owns the shared bound and complete row capacities:

| Capacity | Bytes |
| --- | ---: |
| One result row | 5,345 |
| 255 result rows | 1,362,975 |
| Published report | 1,363,018 |
| Summary identity rows | 8,160 |

Discovery, lowering, execution, reduction, identity, and rendering import this authority. The Java package boundary admits the same 255 cases and does not publish a competing semantic limit.

The widened runtime arenas retain complete inputs:

| Arena | Bytes |
| --- | ---: |
| Source discovery | 135,160 |
| Each complete-source lowering pass | 131,072 |
| Runner staging | 3,205,000 |
| Row reduction | 2,726,150 |
| Identity message | 1,413,829 |
| Identity staging | 1,459,797 |

The lowering arena now matches the 32,768-byte source profile instead of the former incidental 8,192-byte source prefix.

## Boundary evidence

`NativeCompiledTestRunnerExampleTest` discovers and publishes exactly 255 parameterless tests, discovers 255 parameter rows, compiles and executes 255 fresh artifacts, and rejects case 256 with untouched output.

`NativeTestReportBoundExampleTest` reduces, identifies, and renders 255 complete rows through JSON, terminal, and JUnit adapters. Row 256 rejects before publication.

`NativeTestReportIdentityExampleTest` derives the stage-0-compatible identity for 255 rows and rejects row 256. The canonical workspace checks 145 targets.

## Acceptance

- [x] Discovery admits exactly 255 cases.
- [x] Parameter-row discovery admits exactly 255 cases.
- [x] Compilation and fresh execution admit exactly 255 artifacts.
- [x] JSON, terminal, and JUnit adapters publish all 255 rows.
- [x] Canonical row reduction and report identity admit all 255 rows.
- [x] Case 256 rejects before publication with untouched output.
- [x] Java package framing admits the same bound.
- [x] Source lowering retains the complete 32,768-byte source profile.
- [x] Locks, manifests, source plans, archives, and coverage retain independent bounds.
- [x] Runtime, package, workspace, documentation, and file policy gates pass.

The runtime archive contains 437,958 bytes with SHA-256 `71c50dab57f582d2d710e36f96d3111887208a459bda88758a4758956d8d3bb2`. Its root manifest identity remains `42011c887d887364ca16bc2255bc28374882559192e9ab6dbf5f674ce0ae1f49`.

## Rejected alternatives

### Raise the profile to 256

Rejected. Compact report counts are one byte. Admitting 256 would wrap successful evidence to zero.

### Keep the smaller lowering arena

Rejected. Case-count evidence exposed an unrelated 8,192-byte incidental prefix below the canonical 32,768-byte source bound.

### Test only host admission

Rejected. The terminal profile must pass native discovery, lowering, compilation, execution, reduction, identity, and all report adapters.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0328](WIP-0328-native-128-case-test-profile.md)
- [WIP-0347](WIP-0347-native-compiler-terminal-return-profile.md)
- [WIP-0349](WIP-0349-native-compiler-named-return-suite.md)
