# WIP-0228: Native multi-source selection

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and package maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, package manifests, source selection |
| Depends on | WIP-0009, WIP-0018, WIP-0227 |
| Supersedes | One-entry native source selection |
| Superseded by | Native directory-selector expansion |

## Summary

Bind every entry in a canonical target-source plan to the selected manifest target's ordered exact-file selectors.

WIP-0227 closed the first one-entry profile. `TestManifest.w` now walks the complete validated source plan while it walks the selected target's `sources:` block. Every manifest path must equal the corresponding plan path. The validator accepts `test: true` only after consuming every plan entry and reaching its exact end.

## Accepted profile

The native runner accepts one to 64 exact-file selectors:

```yaml
    sources:
      - "src/Fail.w"
      - "src/Pass.w"
      - "src/Runtime.w"
    test: true
```

The source plan carries the same paths in strict lexical order. WIP-0223 separately proves path syntax, order, uniqueness, entry lengths, and the complete frame boundary. This WIP proves authorization by the selected target.

The accepted fixture now transports each source as its own modular entry. Concatenating unrelated classes into `src/Test.w` is gone.

## Validation

After source-plan validation, the manifest validator retains:

- total source count
- current plan cursor
- selected source count
- selected target and source-block state

For each canonical source line it reads the next bounded plan path, compares complete bytes, skips that entry's framed source payload, and advances the count. `test: true` requires the selected count to equal the plan count and the plan cursor to equal the plan end.

A target boundary resets all source state. Missing, additional, reordered, duplicated, or mismatched paths reject. Work is allocation-free and bounded by the 4,096-byte manifest and 32,768-byte source-plan limits.

Directory selectors remain outside this profile. Their expansion requires canonical prefix, overlap, deduplication, and complete source-tree rules rather than exact path equality.

## Evidence

`NativeCoverageRunExampleTest` carries three independently framed modules selected by three exact manifest paths. The test computes expected source, case, shard, report, and summary identities independently. Dynamic shard evidence derives its requested indices from the changed complete source identity rather than preserving stale fixture numbers.

The normalized `xrc/Fail.w` substitution still proves cross-structure rejection. Empty counts, absolute paths, malformed UTF-8, duplicates, descending case names, malformed locks, and corrupted artifacts retain their existing no-publication evidence.

The runtime archive contains 208,157 bytes with SHA-256 `a28521ad2a414f05b69eabed081c065dde9441d28a1d3e037fa771d386de2643` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1`. Its lock names the new runtime archive exactly and retains root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`.

## Acceptance

- [x] Native validation consumes every selected exact-file source path.
- [x] Manifest and plan paths agree entry for entry.
- [x] Acceptance requires exact plan exhaustion.
- [x] Target boundaries reset all source-selection state.
- [x] The fixture carries three separate modular source entries.
- [x] Independent shard evidence follows the complete changed source identity.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Concatenate selected modules

Rejected. Concatenation destroys path identity, module boundaries, and independent package selection.

### Compare only source counts

Rejected. Equal cardinality does not authorize paths or order.

### Sort or repair the plan inside the runner

Rejected. The producer must provide canonical package order. The runtime only validates it.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0227](WIP-0227-native-single-source-selection.md)
