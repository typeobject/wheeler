# WIP-0226: Native root lock provenance

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and package maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Native testing, package locks, provenance |
| Depends on | WIP-0009, WIP-0018, WIP-0220, WIP-0225 |
| Supersedes | Native test transports without lock provenance |
| Superseded by | None |
| Follow-up | WIP-0227 source selection and WIP-0269 dependency lock structure |

## Summary

Bind a dependency-free native test run to the canonical schema-3 package lock whose root is the exact manifest identity.

The runner now accepts one bounded lock frame between the manifest and target-source frames. After hashing the canonical manifest, `TestPackageLock.w` validates exact dependency-free lock bytes and compares all 64 lowercase manifest-identity bytes to `root`.

## Canonical lock

The first supported native lock profile is:

```yaml
schema: 3
root: "<64 lowercase manifest identity bytes>"
packages: []
```

The 96-byte form is exact. Spelling, whitespace, quote placement, line endings, final newline, and empty package syntax cannot vary.

This profile closes provenance for packages whose manifest declares `dependencies: []`. It does not claim dependency-entry parity. A subsequent WIP must admit nonempty canonical package sets and validate each repository, snapshot, archive, manifest, and dependency edge before package execution.

## Runner changes

The transport adds a little-endian 32-bit lock length followed by exact lock bytes. The runner bounds the frame at 4,096 bytes and proves its boundary during complete descriptor preflight.

The runner materializes manifest identity text once. Lock validation and every case-identity transcript borrow the same owned 64-byte value. The old per-case hexadecimal conversion is gone.

## Failure behavior

A missing, oversized, malformed, noncanonical, or root-mismatched lock traps before source-plan hashing, descriptor identity, shard assignment, artifact verification, execution, or output publication.

## Evidence

`NativeCoverageRunExampleTest` constructs the canonical dependency-free lock from an independent SHA-256 implementation and sends its exact bytes to the native runner. The accepted two- and three-case reports remain byte-identical.

The test changes one root nibble without changing frame lengths. Native validation rejects the transport and leaves the 39-byte output untouched.

The runtime archive contains 205,746 bytes with SHA-256 `571cee3804ad3d36023f5dc74946b87e6a0b892472da002b5f6150e6cb026d9d` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1`. Its lock names the new runtime archive exactly and retains root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`.

## Acceptance

- [x] One bounded lock frame accompanies each native run.
- [x] Native code validates exact dependency-free schema-3 lock bytes.
- [x] Lock root equals the native manifest SHA-256 text.
- [x] Manifest identity text is materialized once per run.
- [x] A root-mismatch fixture publishes no output.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Trust a caller-supplied root field

Rejected. The runner has the canonical manifest bytes and derives their identity itself.

### Hash the lock without parsing it

Rejected. A lock digest would bind bytes but would not prove schema, root meaning, or package-set shape.

### Admit nonempty package lists without validating entries

Rejected. Partial entry parsing would claim provenance it does not establish.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0220](WIP-0220-native-runner-manifest-hashing.md)
- [WIP-0225](WIP-0225-native-case-discovery-order.md)
- [WIP-0227](WIP-0227-native-single-source-selection.md)
- [WIP-0269](WIP-0269-native-dependency-lock-structure.md)
