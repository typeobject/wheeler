# WIP-0265: Native multi-target package test gate

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler package, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, package testing, target selection |
| Depends on | WIP-0262, WIP-0264 |
| Supersedes | Single-test-target native package gating |
| Superseded by | Package-wide native tag selection and report reduction |

## Summary

Invoke every eligible test-selected target in one package command.

The package adapter previously required exactly one test target. It now validates the complete target set before native work, then invokes mode 254 once per test-selected target in canonical manifest order. The adapter aggregates selected, passed, and failed counts with checked arithmetic and requires parity with the complete stage-0 rendering adapter.

Each target retains its own canonical native report identity. The adapter does not invent a package report identity by hashing target reports on the host.

## Eligibility

Every test-selected target must fit the WIP-0264 fixed local-import profile. If one target falls outside it, the package does not claim partial native evidence.

The first multi-target profile accepts only empty selected-tag sets. Source tags remain valid metadata and all cases remain selected. Package-wide tag selection needs one global known-tag set. Running target-local unknown-tag rejection independently would reject a tag that legitimately exists only on another target.

Shards remain package-command inputs. Each target receives the same exact shard index and count. Case identity includes target and module qualification, so assignments remain disjoint without a host scheduler.

## Reduction

`NativePackageTestRunner.Result` retains the ordered list of native target report identities and aggregate counts.

The adapter uses `Math.addExact` for each count. It compares aggregate selected, passed, and failed values with the stage-0 report. A mismatch rejects rendering.

Target report identities are evidence, not an ad hoc package identity. A future native package reducer must frame and hash complete target reports under an explicit domain before one package identity can be published.

## Evidence

`invokesEveryNativePackageTestTarget` creates a dependency-free package with two tool targets, two root modules, and one test in each source.

Direct native invocation returns two ordered report identities, two selected cases, two passes, and zero failures. `PackageProject.test` repeats both native runs, requires aggregate parity, and renders two passing stage-0 rows.

The single-target tagged profile and the two-source local-import profile remain green beside multi-target invocation.

## Acceptance

- [x] Every eligible test-selected target receives one native invocation.
- [x] Eligibility covers the complete target set before invocation.
- [x] Canonical manifest target order determines result identity order.
- [x] Every target receives the same shard input.
- [x] Aggregate counts use checked arithmetic.
- [x] Aggregate counts must match the stage-0 rendering adapter.
- [x] Native target report identities remain separate evidence.
- [x] Multi-target selected tags reject from this initial profile.
- [x] Two targets execute and pass through direct and command paths.
- [x] Runtime and conformance archives and locks remain exact.
- [x] Package, workspace, documentation, source, and layout policy pass.

The runtime archive remains 330,739 bytes with SHA-256 `70a04c8b16f70d57d4b81e7cb088a1f9df729864d6d3c30000f9a1dcf8f0e30a` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,221 bytes with SHA-256 `c8225a24f2dc0c2d9cffe708b25e1fa662ba6a771d1a85fbc63d188c0ffc7ea5` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the runtime archive exactly.

## Rejected alternatives

### Gate only eligible targets

Rejected. Partial native evidence cannot describe a complete package command.

### Hash target report identities in Java

Rejected. Package reduction needs a native canonical framing contract.

### Apply selected tags independently to each target

Rejected. Unknown tags have package scope.

### Let Java assign target shards

Rejected. Case identity already provides canonical native assignment.

## References

- [WIP-0262](WIP-0262-native-one-source-package-test-gate.md)
- [WIP-0264](WIP-0264-native-fixed-import-package-test-gate.md)
- [WIP-0213](WIP-0213-native-runner-shard-selection.md)
