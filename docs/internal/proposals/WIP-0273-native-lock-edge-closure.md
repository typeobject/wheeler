# WIP-0273: Native lock edge closure

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler package, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Self-hosting, package locks, native testing |
| Depends on | WIP-0272 |
| Supersedes | Native lock dependency names without package targets |
| Superseded by | None |
| Follow-up | WIP-0274 lock graph validation |

## Summary

Require every dependency edge in a native schema-3 lock to name another package entry in the same lock.

WIP-0269 validated edge syntax and order. It did not prove that an edge target existed. The native runner now scans the complete bounded package set for each dependency name and rejects a dangling edge before source discovery.

## Rule

For every line under a package's nonempty `dependencies:` field, the exact quoted name must equal one package `name` field in the same lock transport.

The lock remains strictly sorted at both levels. Name matching compares the original byte ranges. It does not allocate strings, case-fold, normalize, or consult a repository.

A package may still be unreachable from the root manifest, and a closed edge set may still contain a cycle. Those are separate graph properties and remain follow-up work. This WIP establishes total edge targets first.

## Failure boundary

Edge closure is part of `validPackageLock`. It follows root framing and field validation and precedes manifest dependency binding, source discovery, identities, sharding, lowering, compilation, verification, execution, and publication.

A dangling edge invalidates the complete transport. No partial report or package identity is available.

## Evidence

`validatesNativeDependencyLockEntries` now supplies a direct `demo.dep` package with an edge to `demo.transitive` and a matching transitive package entry. Native lock validation, direct manifest binding, version policy, discovery, compilation, execution, and one passing report succeed.

The fixture then removes only the transitive package entry while retaining the edge. Native lock validation traps and all 39 output bytes remain zero.

The same test retains direct-name mismatch and incompatible-version failures. Dependency-free and one-package empty-edge locks continue through the same operation.

## Acceptance

- [x] Every nonempty lock dependency list is parsed completely.
- [x] Every dependency edge names one package entry.
- [x] Matching uses exact original name bytes.
- [x] A valid direct-to-transitive edge reaches a passing native report.
- [x] A dangling edge publishes no output.
- [x] No caller-supplied package index or repair path exists.
- [x] Documentation keeps reachability, cycles, and source provenance open.
- [x] Runtime and conformance locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

The runtime archive contains 362,872 bytes with SHA-256 `67d350b66e63b297f25a232b39b38fe49a708f59d81506ac2b8b13be23490420` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 132,064 bytes with SHA-256 `6e266b64bacfe415c957fcaae5f697656a708af06d2e8f271b25d0417778341e` and root manifest identity `e15c8483d406c7367d5c5e38867909304aeee418444112f0de10dab47a6a9e11`. Its lock names the runtime archive exactly.

## Rejected alternatives

### Trust a sorted edge name

Rejected. Sorting proves canonical order, not existence.

### Drop missing edges

Rejected. A lock is immutable package evidence, not resolver input.

### Fetch an edge target

Rejected. Test execution consumes an exact offline lock. It does not resolve one.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0272](WIP-0272-native-prerelease-dependency-versions.md)
- [WIP-0274](WIP-0274-native-lock-graph-validation.md)
