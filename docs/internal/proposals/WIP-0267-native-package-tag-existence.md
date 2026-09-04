# WIP-0267: Native package tag existence

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler package, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Self-hosting, package testing, tag authority |
| Depends on | WIP-0266 |
| Supersedes | Stage-0 package-wide unknown-tag authority for the native profile |
| Superseded by | None |
| Follow-up | Native package report reduction |

## Summary

Reject package-wide unknown selected tags through native metadata discovery before stage-0 rendering.

Mode 252 is a metadata-only package probe. It performs complete manifest, lock, source-plan, module, declaration, row, tag, and limit validation. It constructs and sorts module-qualified selected descriptors, publishes their count in summary position, and returns before case identity, sharding, lowering, compilation, verification, execution, or report hashing.

The package adapter probes each selected tag independently across every eligible test target. At least one target must discover a case carrying that tag. Otherwise `wheeler test` rejects the tag before invoking the stage-0 test compiler.

## Probe transport

Mode 252 uses the same manifest, source plan, target, and one-tag selection frame as ordinary mode 253. It permits target-local tag absence so the adapter can form the package union.

The 39-byte probe output contains zero report-identity bytes and a little-endian discovered-case count at bytes 32 and 33. Remaining summary bytes stay zero. Probe output is metadata evidence, not a semantic test report.

A probe never consumes a case attempt. Actual mode-253 execution still compiles, verifies, and interprets each selected and assigned case exactly once.

## Package algorithm

For each selected tag in canonical order:

1. Invoke mode 252 for every eligible test target.
2. Sum only the predicate `discovered_count > 0` across targets.
3. Reject if no target reports the tag.

After every selected tag exists, invoke ordinary mode 253 once per target with the complete conjunctive tag set. Aggregate native summaries and compare them with the stage-0 rendering adapter.

Tag existence ignores command sharding because it is package metadata. The probe receives the command shard frame for transcript consistency, but mode 252 returns before assignment.

## Ordering

For selected-tag commands, `PackageProject.test` runs native package validation and execution before stage-0 test discovery. The existing Java unknown-tag check remains as a differential assertion after native acceptance. It is no longer the first authority for an eligible package.

Commands without selected tags retain the prior order so stage-0 compile diagnostics remain report rows while the native fixed compiler profile continues to grow.

## Evidence

`invokesEveryNativePackageTestTarget` declares `fast` only on `alpha` and `slow` only on `beta`.

A `fast` package command runs two metadata probes. The `alpha` probe discovers one case, and the `beta` probe discovers zero without failing target-local validation. Ordinary execution then selects one aggregate case.

Both direct native invocation and `PackageProject.test` reject `missing`. The command reaches native metadata authority before the redundant stage-0 package check. No test artifact, compiler attempt, verifier attempt, or interpreter attempt enters the unknown-tag decision.

## Acceptance

- [x] Mode 252 performs metadata-only native discovery.
- [x] Probe output carries no report identity.
- [x] Probe execution stops before identity, shard, compiler, verifier, and interpreter work.
- [x] Every selected tag is probed across every eligible target.
- [x] Target-local absence remains valid during package probing.
- [x] Package-wide absence rejects before stage-0 discovery.
- [x] Actual selected cases still execute exactly once.
- [x] Direct and command paths reject an unknown multi-target tag.
- [x] Runtime and conformance archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

The runtime archive contains 331,650 bytes with SHA-256 `cdee28e6efee2b18b8bbfca8214ffcc088f795dfcd3a3116f474cedcd438c95b` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,221 bytes with SHA-256 `c8225a24f2dc0c2d9cffe708b25e1fa662ba6a771d1a85fbc63d188c0ffc7ea5` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the runtime archive exactly.

## Rejected alternatives

### Compile probe cases and inspect summaries

Rejected. Tag existence must not create an execution attempt.

### Probe the complete conjunction only

Rejected. A zero-case conjunction cannot identify which tag is unknown.

### Use shard-selected probe counts

Rejected. Package metadata cannot depend on shard assignment.

### Delete the Java differential check immediately

Rejected. It remains useful until native package rows replace the rendering model.

## References

- [WIP-0266](WIP-0266-native-multi-target-tag-gate.md)
- [WIP-0197](WIP-0197-runtime-test-selection-authority.md)
