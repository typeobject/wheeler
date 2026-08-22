# WIP-0270: Native direct dependency binding

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler package, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, package locks, native testing |
| Depends on | WIP-0269 |
| Supersedes | Structurally valid but manifest-unbound native lock package names |
| Superseded by | WIP-0271 stable version constraints, then archive-source binding |

## Summary

Require every direct manifest dependency to name one package in the native runner lock.

The runner now parses the canonical dependency tail after target selection. It accepts only `normal`, `development`, and `build` dependency kinds, exact quoted name and version fields, and strict byte order. Empty manifest dependencies require the exact empty lock. Nonempty dependencies require a nonempty lock, and each direct name must occur as a package entry.

This closes a substitution hole left by structural lock parsing. A caller cannot pair a manifest naming `demo.dep` with a rooted, well-formed lock naming `demo.bad` and proceed to discovery.

## Authority split

`TestManifest.w` retains package, target, root, module, and source-selection checks. `TestPackageLock.w` retains schema-3 framing and entry structure. New `TestPackageDependencies.w` owns the relation between those transports.

Manifest and lock code moved under `runtime/testing/runners/package`. The runner directory had reached its ten-file ceiling. Package metadata now has a focused home instead of forcing another concern into `TestRunner.w`.

No compatibility module remains at the old paths. Module identities remain unchanged, so imports name semantic authorities rather than source layout.

## Canonical manifest profile

After targets, the runner admits either:

```yaml
dependencies: []
```

or one or more entries:

```yaml
dependencies:
  - kind: "normal"
    name: "demo.dep"
    version: "^1.0.0"
capabilities: []
```

Entries must be strictly sorted by dependency name. Duplicate or reordered names reject. Kind, name, and version lines cannot be missing, reordered, or extended.

A direct dependency need not be the only lock package. Transitive lock packages remain valid. This WIP checks direct-name inclusion, not the version constraint or transitive edge graph.

## Failure boundary

Dependency binding follows complete manifest selection, source framing, manifest hashing, and lock structural validation. It precedes source test discovery, identity, sharding, lowering, compilation, verification, interpretation, and publication.

A mismatch traps with untouched output. No empty-lock substitution or caller-supplied dependency list exists.

## Evidence

`validatesNativeDependencyLockEntries` sends one canonical normal dependency and a one-package lock. Native code selects the target, binds the manifest root, validates lock structure, matches `demo.dep`, discovers and compiles one source test, and publishes one passing report.

The same fixture changes only the lock package name to `demo.bad`. Native binding rejects the complete transport and leaves all 39 output bytes zero.

The dependency-free native runner matrix continues through the same binding operation. An empty manifest paired with a nonempty lock cannot pass.

## Acceptance

- [x] Empty manifest dependencies require the exact empty lock.
- [x] All three manifest dependency kinds have exact native grammar.
- [x] Direct dependency names are nonempty quoted printable ASCII.
- [x] Direct dependency names are strictly byte-sorted and unique.
- [x] Every direct dependency name occurs in the lock package set.
- [x] Transitive lock packages are not mistaken for direct manifest entries.
- [x] Mismatched names fail before discovery or publication.
- [x] Manifest and lock authorities live in a focused package directory.
- [x] No old source-path shim remains.
- [x] Documentation does not claim version or external-source provenance.
- [x] Runtime and conformance archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

The runtime archive contains 348,907 bytes with SHA-256 `b951205a29a85c045e5202e7ae7f5f73db48aaf06d9055a2cf473c2fe013dccc` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 132,064 bytes with SHA-256 `6e266b64bacfe415c957fcaae5f697656a708af06d2e8f271b25d0417778341e` and root manifest identity `e15c8483d406c7367d5c5e38867909304aeee418444112f0de10dab47a6a9e11`. Its lock names the runtime archive exactly.

## Rejected alternatives

### Trust stage-0 manifest parsing

Rejected. The native runner must reject a forged transport without a Java semantic decision.

### Require lock and manifest package counts to match

Rejected. A lock includes transitive packages. A manifest does not.

### Repair dependency order

Rejected. Canonical metadata arrives canonical or fails.

### Claim version satisfaction from name inclusion

Rejected. Constraint parsing is a separate semantic boundary.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0269](WIP-0269-native-dependency-lock-structure.md)
- [WIP-0271](WIP-0271-native-stable-dependency-versions.md)
