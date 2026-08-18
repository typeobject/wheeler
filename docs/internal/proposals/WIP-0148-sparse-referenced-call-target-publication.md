# WIP-0148: Sparse referenced call-target publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, source calls, qualifiers, bounded publication |
| Depends on | WIP-0059, WIP-0061, WIP-0146, WIP-0147 |
| Supersedes | Full-capacity qualifier and referenced-target copies |
| Superseded by | None |

## Summary

Publish only active qualifier and referenced target rows. Two source-call stages still copied fixed capacities after computing exact counts:

- imported qualifier products copied three 4,096-row columns
- referenced target products copied 1,024 call words, four 4,096-row target columns, and 16,384 parameter rows

Both products now publish exact active rows and preserve their existing layouts.

## Qualifiers

For `t` imported targets, `ImportedCallQualifierProducts.w` publishes `t` name starts, `t` name lengths, and `t` dependency ranks.

Canonical module-name bytes already used an exact prefix and remain unchanged. Duplicate rank and owner checks still complete in private staging before publication.

## Referenced targets

For `c` source calls, `ReferencedSourceCallTargets.w` publishes `c` rows from each of four call columns:

- source call start
- source call name length
- source arity
- compact referenced target row

For `t` retained local plus imported targets, it publishes `t` parameter starts, parameter counts, result types, and effects. For `p` retained parameters, it publishes `p` canonical local type rows.

Target identities already used an exact active prefix. Unreferenced imported targets remain absent by design.

## Atomicity

Both stages validate and assemble complete private products before caller mutation. Active writes use validated fixed-capacity coordinates and cannot fail. Active rows replace prior contents while untouched rows retain prior contents.

Malformed names, ranks, owners, target rows, call coordinates, parameter windows, effects, types, or identities publish nothing.

## Bounds

No capacity changes:

- 256 source calls
- 4,096 source targets
- 16,384 retained parameters
- 1 MiB qualifier names
- 131,072 target identity bytes

Worst-case work remains identical. Small direct imported modules no longer copy unrelated capacity.

## Evidence

`NativeCompilerImportedCallQualifierProductsExampleTest` checks target-aligned names, ranks, deterministic publication, and malformed owner rejection.

`NativeCompilerStructuredCallSourceProductExampleTest` exercises compact local and imported target selection, call remapping, exact signatures and identities, qualified targets, and malformed call rejection.

`NativeCompilerPhysicalClosureExampleTest` compares every comparable artifact, validates every retained prefix and relocation, links the exact 97-product subset twice, and rejects malformed footer and relocation products. It passes in 19 minutes and 24 seconds under the unchanged twenty-minute deadline. All container counts and the linked identity `2d078ef722d6cc916a7a8649492f9f0871efeb507d96abd32e1bf971497268ca` remain unchanged.

The compiler archive contains 3,002,325 bytes with SHA-256 `e0d6fcd2df6a24f48debcb25ddd4fb4a2e5ce3f34c5c8a7934b6a8b28cb17294`. Exact dependent locks name that archive.

## Acceptance

- [x] Qualifier columns publish exactly `targetCount` rows.
- [x] Four call columns publish exactly `callCount` rows.
- [x] Four retained target columns publish exactly retained target count rows.
- [x] Parameter types publish exactly retained parameter count rows.
- [x] Name and identity prefix publication remains exact.
- [x] Every focused qualifier and structured-call test passes.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The 97-product linked subset publishes twice with identical bytes.
- [x] The complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Merge qualifier and target tables

Rejected. Qualification is dependency spelling evidence. Target retention is call reachability evidence.

### Retain every imported target

Rejected. Unreferenced targets must not affect local artifact identity or limits.

### Clear untouched rows

Rejected. Active counts define each product and callers own unrelated rows.

### Raise the evidence deadline

Rejected. Inactive capacity carries no call fact.

## References

- [WIP-0059](WIP-0059-imported-source-call-target-products.md)
- [WIP-0061](WIP-0061-qualified-imported-source-calls.md)
- [WIP-0146](WIP-0146-sparse-imported-target-publication.md)
- [WIP-0147](WIP-0147-sparse-source-call-target-table-publication.md)
