# WIP-0269: Native dependency lock structure

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler package, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, package locks, native testing |
| Depends on | WIP-0226 |
| Supersedes | Dependency-free-only native lock parsing |
| Superseded by | WIP-0270 direct dependency binding |

## Summary

Validate canonical schema-3 dependency entries inside the native test runner.

`TestPackageLock.w` now admits both `packages: []` and bounded nonempty package lists. It binds the root identity to the exact manifest, parses every lock field in canonical order, validates lowercase 64-digit identities, requires sorted unique package names and dependency names, and rejects malformed or trailing bytes.

The old `validEmptyPackageLock` interface is deleted. `validPackageLock` is the sole runtime authority.

## Grammar

A nonempty entry contains exact lines in this order:

```yaml
  - name: "package.name"
    version: "1.0.0"
    repository: "<64 lowercase hex>"
    snapshot: "<64 lowercase hex>"
    archive: "<64 lowercase hex>"
    manifest: "<64 lowercase hex>"
    dependencies: []
```

A nonempty dependency list replaces the final line with `dependencies:` and one or more sorted quoted names.

Names and versions are bounded printable quoted ASCII in this profile. Package and dependency lists are strictly byte-sorted. Duplicate names therefore reject without a second set representation.

The complete lock remains below 4,097 bytes and 64 package entries. Every line uses LF. CR, missing final LF, malformed indentation, unknown fields, uppercase hexadecimal, reordered fields, and trailing bytes reject.

## Scope

This WIP proves lock structure and exact root binding. It does not yet compare manifest dependency constraints with lock names and versions. It does not bind external imported module source to a locked archive.

Those boundaries remain explicit follow-up work. Structural acceptance cannot authorize an external import by itself.

## Refactoring

The previous empty-lock parser spelled every fixed byte as a branch. The new parser uses bounded line, range-hash, quoted-field, hexadecimal, and lexical-range helpers.

The empty lock remains an exact 96-byte fast path under the same public operation. No compatibility alias retains the old authority.

## Evidence

`validatesNativeDependencyLockEntries` supplies a manifest with one library dependency and a complete one-entry schema-3 lock. Native manifest selection, root binding, lock structure, source discovery, compilation, and one passing report all succeed without an empty-lock substitution.

The existing dependency-free runner matrix remains green through the same `validPackageLock` operation.

## Acceptance

- [x] Exact dependency-free locks remain valid.
- [x] Nonempty canonical package lists are parsed natively.
- [x] Root identity binds exact manifest bytes.
- [x] Repository, snapshot, archive, and manifest identities require lowercase hexadecimal.
- [x] Package names and dependency names require strict order.
- [x] Empty and nonempty dependency lists are distinct exact forms.
- [x] Unknown fields and trailing bytes reject.
- [x] The empty-only public parser is deleted.
- [x] One nonempty lock reaches a passing native test report.
- [x] Documentation does not claim external import provenance.
- [x] Runtime and conformance archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

The runtime archive contains 341,715 bytes with SHA-256 `fe46326413b9bb20727d789e856cff4147c8976d73d27fa1e039625c96b3d9bb` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 132,064 bytes with SHA-256 `6e266b64bacfe415c957fcaae5f697656a708af06d2e8f271b25d0417778341e` and root manifest identity `e15c8483d406c7367d5c5e38867909304aeee418444112f0de10dab47a6a9e11`. Its lock names the runtime archive exactly.

## Rejected alternatives

### Keep separate empty and nonempty parsers

Rejected. Lock grammar needs one root and framing authority.

### Accept uppercase hexadecimal

Rejected. Canonical lock identities are lowercase.

### Sort lock entries natively

Rejected. A canonical lock is not a repair request.

### Treat structural parsing as import authorization

Rejected. Manifest constraints and archive source provenance remain unbound.

## References

- [WIP-0226](WIP-0226-native-root-lock-provenance.md)
- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0270](WIP-0270-native-direct-dependency-binding.md)
