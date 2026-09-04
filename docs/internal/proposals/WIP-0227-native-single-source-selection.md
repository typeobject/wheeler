# WIP-0227: Native single-source selection

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and package maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Native testing, package manifests, source selection |
| Depends on | WIP-0009, WIP-0018, WIP-0223, WIP-0226 |
| Supersedes | Independently validated manifest and source-plan paths |
| Superseded by | None |
| Follow-up | WIP-0228 native multi-source selection |

## Summary

Bind the canonical one-entry target-source plan to the selected manifest target's exact source selector.

Earlier native checks proved that the manifest selected a test target and that the source plan was internally canonical. They did not prove that the plan path came from that target. A caller could substitute another normalized `.w` path and obtain a different source identity under a manifest that never selected it.

`TestManifest.w` now compares the validated first plan path with the selected target's single canonical source line before accepting `test: true`.

## Accepted profile

This WIP closes the exact-file profile:

```yaml
    sources:
      - "src/Test.w"
    test: true
```

The source plan must contain one entry whose complete path bytes equal `src/Test.w`. The manifest and plan retain their existing independent canonical framing checks.

Directory selectors and multiple selectors remain assigned to native source-tree expansion. They require prefix matching, overlap rejection, deduplication, and complete lexical source enumeration. This WIP does not silently treat a directory selector as one file.

## Implementation

Source-plan validation runs first. It proves a nonempty plan and bounded first path, then publishes the first path length through a read-only operation. The manifest validator borrows that range from the shared runner input.

Within the selected target block, the validator requires the canonical `sources:` line, one exact source line, and the subsequent canonical `test: true` line. Target boundaries clear all pending source-selection state.

Comparison is allocation-free and bounded by the existing 255-byte path limit.

## Failure behavior

A normalized path that is absent from the selected target rejects before manifest hashing, source hashing, lock validation, descriptor identity, shard assignment, artifact verification, execution, or output publication.

## Evidence

The accepted fixture carries `src/Test.w` in both canonical structures and retains byte-identical two- and three-case reports.

`NativeCoverageRunExampleTest` changes the plan path to `xrc/Test.w`. The path remains normalized, ordered, `.w`-suffixed, and correctly framed. Only manifest selection fails, proving that the new cross-structure check owns the rejection.

The runtime archive contains 207,538 bytes with SHA-256 `c752403059984a53084fd5f5cf9222e5ab3f6ab6ee8a27ac1da23ab271afd526` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1`. Its lock names the new runtime archive exactly and retains root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`.

## Acceptance

- [x] Native validation compares the selected manifest source with the plan path.
- [x] Comparison uses exact complete path bytes.
- [x] Target boundaries clear pending selection state.
- [x] Validation remains bounded and allocation-free.
- [x] A normalized unselected path publishes no output.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Trust a separately valid source plan

Rejected. Canonical bytes do not prove target authorization.

### Match only the manifest root

Rejected. The root must be in the selected source set, but it does not define the complete set.

### Interpret directory selectors as exact paths

Rejected. Directory expansion needs its own complete lexical and deduplication contract.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0223](WIP-0223-native-target-source-plan-validation.md)
- [WIP-0226](WIP-0226-native-root-lock-provenance.md)
- [WIP-0228](WIP-0228-native-multi-source-selection.md)
