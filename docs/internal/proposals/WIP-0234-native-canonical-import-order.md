# WIP-0234: Native canonical import order

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, compiler, and package maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, source plans, module graph |
| Depends on | WIP-0009, WIP-0018, WIP-0233 |
| Supersedes | Unordered native local import declarations |
| Superseded by | WIP-0235 native import cycle rejection |

## Summary

Require local source imports to be strictly increasing by complete module bytes.

WIP-0233 resolved each import but admitted repeated and descending declarations. `TestSourceModules.w` now compares each import with its predecessor after syntax validation and before graph resolution. Equality and descending order reject.

## Canonical order

Imports compare by complete unsigned UTF-8 bytes. The accepted module alphabet is ASCII, so this relation also matches canonical textual order.

Strict order provides:

- duplicate edge rejection
- deterministic direct-dependency rank
- source-order independence from parser maps
- one stable import transcript for later graph and compiler products

The validator does not sort or deduplicate. Source bytes must already be canonical.

## Module authority split

Module and import logic moved from `TestSourcePlan.w` into `TestSourceModules.w`.

`TestSourcePlan.w` now owns framing, path syntax, path order, UTF-8, source boundaries, and pass sequencing. `TestSourceModules.w` owns module preambles, root matching, uniqueness, imports, and local resolution. `TestManifest.w` imports module authority directly for root comparison.

This split leaves both modules well below 1,000 lines and avoids turning transport framing into a second source-language parser.

## Bounds

The import pass retains only the preceding import range. It allocates no storage and stays under the existing 64-import and 255-byte name limits.

Canonical-order failure occurs before source hashing, lock validation, descriptor identity, shard selection, artifact verification, execution, or publication.

## Evidence

The resolved one-import zero-case fixture still publishes the canonical empty report.

Two additional fixtures preserve valid framing, source paths, UTF-8, modules, and local resolution:

- two identical `pkg.fail` imports
- descending `pkg.runtime`, `pkg.fail` imports

Both reject without output. The unresolved `pkg.xail` fixture remains.

The runtime archive contains 223,414 bytes with SHA-256 `94eb9a2d3da983ef08d0bb2a67891b9d6179e4c7613e6fe31d112f166f585e47` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1`. Its lock names the new runtime archive exactly and retains root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`.

## Acceptance

- [x] Imports compare by complete unsigned module bytes.
- [x] Every import must be strictly greater than its predecessor.
- [x] Duplicate and descending declarations reject.
- [x] The validator does not repair source order.
- [x] Module graph authority is split from source framing.
- [x] All affected code files remain below 1,000 lines.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Sort imports in the runtime

Rejected. Repair would hide noncanonical package source and change compiler dependency ranks.

### Deduplicate equal imports

Rejected. Duplicate source declarations are invalid graph input, not redundant hints.

### Keep module parsing in the framing module

Rejected. Framing and module-graph policy have distinct change boundaries.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0233](WIP-0233-native-local-import-resolution.md)
- [WIP-0235](WIP-0235-native-import-cycle-rejection.md)
