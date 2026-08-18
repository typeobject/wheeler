# WIP-0147: Sparse source-call target-table publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, source calls, bounded publication |
| Depends on | WIP-0057, WIP-0059, WIP-0146 |
| Supersedes | Full-capacity combined source-call target table copies |
| Superseded by | None |

## Summary

Publish exact active rows from the combined local and imported source-call target table. The product formerly copied six complete 4,096-row columns, one complete 16,384-row parameter column, and both complete 4,096-row dependency columns.

The product already computes exact target, parameter, name, identity, and imported counts in private staging. Publication now uses those counts.

## Active products

For `t` local plus imported targets, the product publishes `t` rows from:

- name starts
- name lengths
- parameter starts
- parameter counts
- result types
- effects

For `p` parameters, it publishes `p` canonical local type rows. For `i` imported targets, it publishes `i` dependency-rank rows and `i` mapped-target rows.

Name bytes and target identities already used exact active prefixes and remain unchanged.

## Atomicity

All source range, type, effect, name, identity, dependency, target, parameter, and capacity checks finish in private staging. Active writes use validated fixed-capacity coordinates and cannot fail.

Active output rows replace prior contents. Untouched rows retain prior contents. Malformed imported result types and every earlier validation failure leave all caller outputs unchanged.

## Bounds

No capacity changes:

- 4,096 total targets
- 16,384 parameters
- 4,096 imported dependency products
- 1 MiB target names
- 131,072 target identity bytes

Worst-case work remains identical. Small source modules no longer publish unused capacity.

## Evidence

`NativeCompilerSourceCallTargetTableExampleTest` checks local and imported joining, names, parameter types, result types, identities, dependency ranks, active-row replacement, and atomic malformed-result rejection.

`NativeCompilerEarlyComparisonFormsPhysicalProductExampleTest` traverses the combined target table through direct imported compilation.

`NativeCompilerPhysicalClosureExampleTest` compares every comparable artifact, validates every retained prefix and relocation, links the exact 97-product subset twice, and rejects malformed footer and relocation products. It passes in 19 minutes and 39 seconds under the unchanged twenty-minute deadline. All container counts and the linked identity `2d078ef722d6cc916a7a8649492f9f0871efeb507d96abd32e1bf971497268ca` remain unchanged.

The compiler archive contains 3,002,032 bytes with SHA-256 `af8098f0ade6131abc5a9f04479d8e9ec5afae05739cce32e4cab005bae7a213`. Exact dependent locks name that archive.

## Acceptance

- [x] Six target columns publish exactly `targetCount` rows.
- [x] Parameter types publish exactly `parameterCount` rows.
- [x] Dependency columns publish exactly `importedCount` rows.
- [x] Active rows replace prior contents after complete validation.
- [x] Untouched rows retain prior contents.
- [x] Name and identity prefix publication remains exact.
- [x] Every focused target-table test passes.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The 97-product linked subset publishes twice with identical bytes.
- [x] The complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Change the fixed table layout

Rejected. Downstream call layout uses direct column indexing.

### Publish while validating targets

Rejected. A later malformed imported target would expose partial state.

### Clear untouched rows

Rejected. Callers own those rows and active counts define this product.

### Raise the evidence deadline

Rejected. Inactive rows carry no target fact.

## References

- [WIP-0057](WIP-0057-source-call-relocation-and-ownership-coordinate-products.md)
- [WIP-0059](WIP-0059-imported-source-call-target-products.md)
- [WIP-0146](WIP-0146-sparse-imported-target-publication.md)
