# WIP-0235: Native import cycle rejection

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, compiler, and package maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, source plans, module graph |
| Depends on | WIP-0009, WIP-0018, WIP-0234 |
| Supersedes | Resolved native import graphs without acyclicity proof |
| Superseded by | WIP-0236 native source test execution |

## Summary

Reject cycles in the complete native package-local import graph before source identity or execution.

WIP-0234 established unique modules and canonical resolved edges. `TestSourceModules.w` now computes bounded reachability from every source. Any edge returning to the current root proves a cycle and rejects the plan.

## Algorithm

The source bound is 64, so the validator represents visited and frontier sets as two 32-bit lanes held in ordinary `long` locals. It allocates no graph rows.

For each root source:

1. put the root in the initial frontier and visited set
2. rescan all source entries
3. for every frontier module, resolve each already validated import to its source index
4. reject an edge back to the root
5. add unseen targets to the next frontier
6. stop when the frontier is empty

Each target enters a root's visited set once. The validator bounds outer depth to 64. Exact source and import rescans remain under the existing 32,768-byte plan limit.

Self imports already reject during edge validation. The reachability pass owns cycles of length two through 64.

## Atomicity

Cycle validation runs after complete framing, UTF-8, module syntax, module uniqueness, canonical import order, and exact local resolution. It runs before source hashing, manifest hashing, lock validation, descriptor identity, shard selection, artifact verification, execution, or output publication.

No partial topological order or reachable prefix is published. The source plan remains one transaction.

## Evidence

The accepted zero-case graph contains `pkg.pass -> pkg.fail` and publishes the canonical empty report.

The cycle fixture adds `pkg.fail -> pkg.pass` without changing module names, path order, source framing, or import resolution. Both import lists remain canonical. Native reachability rejects the two-node cycle and leaves output untouched.

The runtime archive contains 228,786 bytes with SHA-256 `8b35683e27f1d60bacafb8f5a30feab8aa8475a6f3aa1840cab42d81a4a4208c` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1`. Its lock names the new runtime archive exactly and retains root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`.

## Acceptance

- [x] Native code checks reachability from every local source.
- [x] Two 32-bit lanes cover all 64 admitted sources.
- [x] Each target enters one root traversal at most once.
- [x] Self and multi-module cycles reject.
- [x] Validation allocates no graph rows.
- [x] An otherwise valid two-node cycle publishes no output.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Rely on compiler recursion failure

Rejected. Package graph validity precedes compilation and must have a stable failure boundary.

### Allocate a 64-by-64 matrix

Rejected. Two bounded bit lanes and exact rescans suffice for validation.

### Require imports to point to earlier source paths

Rejected. Canonical path order is not dependency order.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0234](WIP-0234-native-canonical-import-order.md)
- [WIP-0236](WIP-0236-native-source-test-execution.md)
