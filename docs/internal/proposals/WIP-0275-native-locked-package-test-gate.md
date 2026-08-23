# WIP-0275: Native locked package test gate

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler package, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, package testing, package locks |
| Depends on | WIP-0274 |
| Supersedes | Dependency-free-only native package test invocation |
| Superseded by | WIP-0276 native case rows and WIP-0294 native locked archive provenance |

## Summary

Invoke the native package test gate for packages with exact nonempty locks when the selected test source graph uses only package-local imports.

`NativePackageTestRunner` no longer rejects a package merely because its manifest declares dependencies. It transports the physical `wheeler.package.lock.yaml` unchanged. The runtime then validates root identity, structure, names, versions, edge closure, reachability, and cycles before discovering tests.

This slice admits a dependency that is not imported by the selected test target. External module source is not smuggled into the local source plan and remains a separate provenance boundary.

## Eligibility

Every selected test target still requires one through eight physical source files under the fixed native compiler profile. Nonroot local imports remain constant-only.

The adapter now derives the selected source module set and requires every source `import` to resolve inside that set. A target importing a dependency module remains outside this gate until the transport carries locked archive source provenance.

Dependency-free packages retain the exact synthesized empty lock derived from the physical manifest. Packages with dependencies require a physical, nonsymbolic package lock. Missing locks do not fall back to empty provenance.

## Transport

The adapter reads manifest and lock bytes from the package root and frames both without re-emission. The runtime owns every semantic lock decision.

Java checks only physical path eligibility and whether imports are package-local. It does not parse the lock, choose a version, reduce the graph, or authorize a package identity.

## Evidence

`invokesNativeTestsWithAnUnusedLockedDependency` creates a physical package with one normal dependency, one complete schema-3 lock entry, and one local test target that does not import the dependency.

The adapter sends the physical lock. Native code validates the complete manifest-to-lock graph, discovers and compiles the test, executes it once, and returns one selected and one passed case.

`invokesNativeDiscoveryAcrossCanonicalLocalImports` retains the dependency-free local-import profile. Existing multi-target, tag, package report, and stage-0 parity fixtures remain unchanged.

## Acceptance

- [x] Declaring a dependency no longer disables native package invocation.
- [x] Nonempty package invocation transports the physical lock bytes.
- [x] A missing or symbolic nonempty lock has no empty-lock fallback.
- [x] Every eligible source import resolves inside the selected local source set.
- [x] One package with an unused locked dependency reaches a passing native report.
- [x] Dependency-free local-import package tests remain eligible.
- [x] External imported module source remains explicitly unsupported.
- [x] No Java lock parser or version decision enters the native adapter.
- [x] Documentation matches the expanded package profile.
- [x] Focused tools, documentation, source, and file-length policy pass.

The runtime archive remains 371,507 bytes with SHA-256 `fbbda03c93c410201c38711b20dd7936703fc609dcd989fea0824a9df75ce019` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 132,064 bytes with SHA-256 `6e266b64bacfe415c957fcaae5f697656a708af06d2e8f271b25d0417778341e` and root manifest identity `e15c8483d406c7367d5c5e38867909304aeee418444112f0de10dab47a6a9e11`. Its lock names the runtime archive exactly.

## Rejected alternatives

### Continue rejecting every dependency

Rejected. Native lock authority now proves complete metadata and graph policy.

### Send an empty lock for an unused dependency

Rejected. Source reachability does not erase package provenance.

### Include dependency source without archive binding

Rejected. A module name alone does not prove which locked archive supplied its bytes.

### Parse lock semantics in the adapter

Rejected. Java transports physical bytes. Wheeler decides their meaning.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0274](WIP-0274-native-lock-graph-validation.md)
- [WIP-0276](WIP-0276-native-package-case-rows.md)
- [WIP-0294](WIP-0294-native-locked-archive-provenance.md)
