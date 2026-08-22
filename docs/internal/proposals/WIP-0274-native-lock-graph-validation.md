# WIP-0274: Native lock graph validation

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler package, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, package locks, native testing |
| Depends on | WIP-0273 |
| Supersedes | Edge-closed but unchecked native lock graphs |
| Superseded by | Native archive-source binding |

## Summary

Require the complete native lock graph to be acyclic and reachable from direct manifest dependencies.

`TestPackageGraph.w` builds one bounded adjacency matrix from exact lock names and edges. It computes transitive closure, rejects a diagonal reachability bit, marks direct manifest dependencies as roots, and rejects every package not reachable from one of those roots.

A structurally sound lock can no longer smuggle an unrelated package into test evidence or hide a dependency cycle behind sorted names.

## Bounds and ownership

The lock transport remains below 4,097 bytes and 64 packages. Graph validation owns four bounded byte arrays:

- 128 bytes for package-name offsets.
- 64 bytes for package-name lengths.
- 4,096 bytes for the adjacency matrix.
- 64 bytes for direct-root marks.

All storage is dropped before return. Name offsets refer to the original bounded transport. No package strings are copied.

Floyd-Warshall closure runs over the admitted package count with fixed 64-element loop bounds. The package byte ceiling makes the physical graph much smaller in current transports, but the semantic bound remains explicit.

## Rules

An empty manifest and empty lock form one valid empty graph.

For a nonempty graph:

1. Every direct manifest dependency maps to one lock package.
2. Every lock edge maps to one lock package.
3. No package reaches itself through one or more edges.
4. Every lock package is a direct dependency or is reachable from one.

Strict name order and edge order remain the framing authority's job. Version compatibility remains the version authority's job.

## Failure boundary

Graph validation follows manifest-to-lock name and version checks. It precedes source discovery, identity, sharding, lowering, compilation, verification, execution, and publication.

An unreachable package or cycle invalidates the transport. The runner does not prune or topologically repair the graph.

## Evidence

`validatesNativeDependencyLockEntries` retains the valid direct-to-transitive lock from WIP-0273 and publishes one passing native report.

The fixture adds a sorted `demo.extra` package with no incoming path. Native graph policy rejects it with untouched output.

A second fixture makes `demo.dep` and `demo.transitive` depend on each other. Every edge target exists, but transitive closure reaches a diagonal bit. Native graph policy again rejects with all 39 output bytes zero.

## Acceptance

- [x] Direct manifest dependencies seed native graph roots.
- [x] Exact lock edges populate one bounded adjacency matrix.
- [x] Transitive closure rejects direct and indirect cycles.
- [x] Every lock package must be root-reachable.
- [x] An unreachable sorted package publishes no output.
- [x] An edge-closed cycle publishes no output.
- [x] A valid transitive graph reaches a passing native report.
- [x] Graph storage has explicit ownership and teardown.
- [x] No pruning, sorting, or topological repair path exists.
- [x] Documentation leaves external archive-source binding open.
- [x] Runtime and conformance locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

The runtime archive contains 371,507 bytes with SHA-256 `fbbda03c93c410201c38711b20dd7936703fc609dcd989fea0824a9df75ce019` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 132,064 bytes with SHA-256 `6e266b64bacfe415c957fcaae5f697656a708af06d2e8f271b25d0417778341e` and root manifest identity `e15c8483d406c7367d5c5e38867909304aeee418444112f0de10dab47a6a9e11`. Its lock names the runtime archive exactly.

## Rejected alternatives

### Accept unreachable lock packages

Rejected. Unused package identities are not root dependency evidence.

### Detect only direct self-edges

Rejected. A two-package cycle is still a cycle.

### Topologically sort the lock

Rejected. A canonical lock arrives canonical and acyclic or fails.

### Let Java validate the graph

Rejected. The native execution boundary must stand on the transported bytes itself.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0273](WIP-0273-native-lock-edge-closure.md)
