# WIP-0412: Preselected compiler package shards

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler testing, compiler package, build, and CI maintainers |
| Created | 2026-08-26 |
| Updated | 2026-08-26 |
| Area | Native testing, deterministic sharding, compiler package, CI |
| Depends on | WIP-0018, WIP-0194, WIP-0213, WIP-0279, WIP-0348 |
| Supersedes | One forty-seven-minute native compiler package invocation |
| Superseded by | None |

## Summary

CI executes the 243-case native compiler package as sixteen complete case-identity shards. Every job selects its shard before source copying, lowering, compilation, verification, execution, and report publication. The sixteen jobs cover indexes zero through fifteen exactly once.

The ordinary `tools:test` task still excludes the compiler package integration class. `nativeCompilerPackageTest` now executes one selected shard. Gradle properties bind the index and the fixed count of sixteen into task inputs and JVM properties.

## Motivation

The former serial method exhausted its forty-seven-minute deadline in hosted runs `32939796754` and `32944970747`. Both ordinary build matrices, all eight example shards, bootstrap output comparison, documentation, and CodeQL had already passed. Raising the fifty-minute job ceiling would keep one fragile serial witness and conceal the test runner's established sharding authority.

The native runner already assigns each complete case identity to one shard before expensive work. CI should use that authority instead of executing a nominally bounded selector with a shard count of one.

## Selection contract

The task accepts:

```text
-PnativeCompilerPackageShard=<index>
-PnativeCompilerPackageShardCount=16
```

The test rejects a negative index, an index outside the supplied count, or any count other than sixteen. Defaults select shard zero for an explicit local smoke run. A local command that claims the complete suite must enumerate all sixteen indexes.

Case assignment remains the canonical digest remainder from WIP-0194 and WIP-0213. No Java filter, test-name list, source-path partition, or target-order heuristic participates.

Each selected case receives one fresh retained artifact attempt and one fresh storage lifetime. The native runner publishes its JSON, terminal, and JUnit adapters from the same canonical report. The host test checks all three byte projections and the selected, passed, and failed counts. It does not duplicate the Wheeler-owned inventory of case names.

## CI topology

The `native-compiler-package` job is a sixteen-row matrix with fail-fast disabled. Every row:

1. checks out the same commit.
2. installs Temurin JDK 26.
3. restores only Gradle infrastructure.
4. invokes one shard with the fixed count of sixteen.
5. performs no retry and writes no shared result storage.

A method has a twelve-minute deadline. The job has an eighteen-minute process deadline. Local endpoint evidence completes shard zero in 4 minutes and 46 seconds and shard fifteen in 5 minutes and 26 seconds on the maintained host.

The matrix still waits for both ordinary build variants. A package failure cannot starve example shards, and an example failure cannot hide a package shard.

## Deletion

`NativeCompilerPackageTest` no longer carries the 600-line Java inventory of expected case names. The package manifest, native discovery, and Wheeler report rows already own that information. Repeating it in Java added no semantic witness and made every case addition a two-file ceremony.

The explicit forty-seven-minute JUnit annotation, one-shard invocation, fifty-minute CI deadline, and serial-suite prose are removed together.

## Failure behavior

A malformed shard configuration fails before package loading. An empty selected result fails rather than publishing a vacuous success. Any native compile, verification, execution, report, or adapter mismatch fails its matrix row. Fail-fast remains disabled so one failure does not erase evidence from the other fifteen rows.

No row merges report bytes with another row. Completeness comes from the exhaustive fixed matrix and the canonical disjoint assignment law, not from a host-side aggregate report.

## Evidence

Local endpoint runs prove both admitted index bounds, nonempty selection, native execution, and all three report adapters. The ordinary tools test continues to exclude the integration class. Hosted run `32985905791` passes all sixteen package rows, both build matrices, all eight example shards, and byte-identical bootstrap output comparison. The slowest package row completes in 10 minutes and 15 seconds.

The compiler archive lock in every dependent workspace named SHA-256 `4a4d2b612afaf874528712b7de080e1e075fcb63a444a5563ab5e6b9dd618582` for this evidence run. WIP-0413 replaces that source archive without changing shard assignment. Package loading rejects either superseded identity before any shard executes.

## Acceptance

- [x] Shard selection occurs before all expensive native work.
- [x] The fixed matrix names every index from zero through fifteen once.
- [x] Each task invocation accepts only the fixed shard count.
- [x] Shards zero and fifteen pass locally with fresh storage.
- [x] JSON, terminal, and JUnit adapters match the canonical shard report.
- [x] Ordinary tools tests exclude the integration class.
- [x] The duplicate Java case inventory is deleted.
- [x] Every dependent workspace lock names the current compiler archive.
- [x] All sixteen hosted matrix rows pass for one commit.
- [x] Documentation, style, source, and file-length checks pass on that commit.

## Rejected alternatives

### Raise the serial timeout

Rejected. The serial witness already crossed its deadline twice. More wall time would not improve isolation or fault localization.

### Shard by target or source path

Rejected. Targets contain unequal case counts and can change shape without changing case identity. The native case digest is already the public assignment authority.

### Merge reports in Java

Rejected. Canonical report reduction belongs to Wheeler. CI needs exhaustive pass evidence, not a second host report format.

### Retry failed rows

Rejected. Fresh storage and one attempt are part of the evidence boundary. A retry would publish availability folklore instead of a deterministic result.

## References

- [WIP-0018: Integrated deterministic testing](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0194: Native test shard assignment](WIP-0194-native-test-shard-assignment.md)
- [WIP-0213: Native runner shard selection](WIP-0213-native-runner-shard-selection.md)
- [WIP-0279: Native compiler package suite](WIP-0279-native-compiler-package-suite.md)
- [WIP-0348: Native 255-case test profile](WIP-0348-native-255-case-test-profile.md)
