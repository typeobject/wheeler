# WIP-0221: Native test manifest selection

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and package maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, package manifests, target selection |
| Depends on | WIP-0009, WIP-0018, WIP-0220 |
| Supersedes | Unchecked runner package and target header fields |
| Superseded by | WIP-0222 canonical target source identity |

## Summary

Validate runner package metadata and test-target selection against the exact canonical manifest before hashing or execution.

`wheeler.runtime.testing.runners.test_manifest` checks the schema-1 header, package name, version, bootstrap profile, target section, selected target name, and `test: true` policy. `TestRunner.w` rejects disagreement before deriving the manifest identity or processing descriptors.

## Accepted manifest boundary

The validator admits canonical schema-1 package text with:

- `schema: 1`
- exact `package`, `name`, `version`, and `profile` lines
- profile `bootstrap-1`
- a canonical `targets` section
- a selected target row whose `name` matches the runner header
- `test: true` in that same target row
- a following `dependencies` section

It rejects carriage returns, missing final newline, malformed header order, package or version mismatch, absent target, a non-test target, and a target match that crosses into the next target row.

The stage-0 package parser still validates target kind, root, module, source paths, dependencies, capabilities, ordering, and all remaining schema constraints. This slice moves the fields that authorize native test selection across the self-hosting boundary without claiming a second complete package parser.

## Implementation

The validator scans at most 4,096 bytes. Fixed canonical keys use bounded 32-bit polynomial hashes. Dynamic package, version, and target values compare byte for byte against the runner header. Hashes identify only fixed syntax tokens. No semantic field relies on collision-prone lookup.

Target selection resets at every `- kind` row. A matching name authorizes execution only when `test: true` appears before the next row or the dependencies boundary.

## Failure behavior

Validation completes before manifest hashing, source hashing, shard assignment, artifact verification, or artifact execution. Failure leaves the 39-byte host output untouched.

The validator borrows the manifest and header fields. It allocates no storage and changes no runner bound.

## Evidence

`NativeCoverageRunExampleTest` independently round-trips the fixture through `PackageManifestParser`. The native runner accepts the canonical bytes.

The test then changes only the framed version while retaining the manifest and separately changes only the manifest package name while retaining the framed package. Both mismatches trap before publication. Existing empty, multi-case, shard, diagnostic, and malformed-frame products remain exact.

The runtime archive contains 191,658 bytes with SHA-256 `8a11bfef4e3a656e85202e63450673e571368b4781ec810cc52b8a526a988654` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1`. Its lock names the new runtime archive exactly and retains root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`.

## Acceptance

- [x] Native code validates schema, package, version, and bootstrap profile.
- [x] The selected target exists and carries `test: true` in its own row.
- [x] Header and manifest mismatches reject before identity derivation or execution.
- [x] Validation stays bounded and allocation-free.
- [x] Stage 0 independently proves complete fixture canonicality.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Search for the target name as an arbitrary substring

Rejected. Capability names, paths, and later target rows cannot authorize execution.

### Trust header metadata after hashing the manifest

Rejected. A valid digest says which bytes arrived, not which package or target they describe.

### Duplicate the complete stage-0 package parser in runtime

Rejected. This slice validates the fields needed for test selection. The canonical package library remains the home for full schema parsing.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0220](WIP-0220-native-runner-manifest-hashing.md)
- [WIP-0222](WIP-0222-native-target-source-identity.md)
