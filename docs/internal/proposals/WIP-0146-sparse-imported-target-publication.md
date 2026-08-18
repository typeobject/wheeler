# WIP-0146: Sparse imported-target publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, imported targets, bounded publication |
| Depends on | WIP-0059, WIP-0139, WIP-0145 |
| Supersedes | Full-capacity imported target and parameter row copies |
| Superseded by | None |

## Summary

Publish only active imported target and parameter rows. `ImportedSourceCallTargets.w` formerly copied all 32,768 target words and all 32,768 parameter words after validating a bounded dependency view.

A module admits at most 4,096 targets and 16,384 parameters. Physical compiler modules use far smaller active prefixes. The product now publishes exact active rows by column.

## Row layout

The target table has eight 4,096-row columns:

- callable product row
- dependency rank
- name start
- name length
- first parameter
- parameter count
- result type
- effects

The parameter table has two 16,384-row columns for canonical local type and source loan mode.

The product already tracks exact `targetCount` and `parameterCount`. Publication now iterates eight target columns through `targetCount` and two parameter columns through `parameterCount`.

## Atomicity

All dependency, identity, type, mode, name, parameter, and capacity checks finish in private staging. Active publication then uses validated fixed-capacity coordinates and cannot fail.

Active rows replace their prior contents. Untouched rows retain their prior contents. Names and identities retain their existing exact-prefix publication.

Malformed dependency products, duplicate identities, unsupported loan conversion, name overflow, or parameter overflow still fail before any caller mutation.

## Bounds

No public limit changes:

- 4,096 imported targets
- 16,384 imported parameters
- eight target columns
- two parameter columns
- 1 MiB target-name storage
- 131,072 target-identity bytes

Worst-case work is unchanged. Small modules no longer pay the worst-case publication cost.

## Evidence

`NativeCompilerImportedSourceCallTargetsExampleTest` exercises deterministic dependency ordering, replacement of active rows, preservation of malformed-output sentinels, exact names, parameter types, modes, effects, and identities. Both focused cases pass.

`NativeCompilerEarlyComparisonFormsPhysicalProductExampleTest` traverses sparse target publication with its direct dependency view. Its focused run passes in 4 minutes and 1 second under Java 26.

`NativeCompilerPhysicalClosureExampleTest` compares every comparable artifact, validates every retained prefix and relocation, links the exact 97-product subset twice, and rejects malformed footer and relocation products. It passes in 19 minutes and 36 seconds under the unchanged twenty-minute deadline. All container counts and the linked identity `2d078ef722d6cc916a7a8649492f9f0871efeb507d96abd32e1bf971497268ca` remain unchanged.

The compiler archive contains 3,001,954 bytes with SHA-256 `dcdfeff3b4068a2acb44a5d0b2440ae5ae03498214b410bddd1d0dcb5471e4f5`. Exact dependent locks name that archive.

## Acceptance

- [x] Eight target columns publish only active target rows.
- [x] Two parameter columns publish only active parameter rows.
- [x] Active rows replace prior contents only after complete validation.
- [x] Untouched rows retain their prior contents.
- [x] Exact name and identity prefix publication remains unchanged.
- [x] Every focused imported target and relocation test passes.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The 97-product linked subset publishes twice with identical bytes.
- [x] The complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Shrink target tables per module

Rejected. Downstream tables retain fixed-column direct indexing.

### Copy one contiguous prefix

Rejected. Column gaps are capacity-sized and are not active rows.

### Raise the closure deadline

Rejected. Inactive capacity carries no semantics.

## References

- [WIP-0059](WIP-0059-imported-source-call-target-products.md)
- [WIP-0139](WIP-0139-structured-imported-call-product-foundations.md)
- [WIP-0145](WIP-0145-sparse-structured-instruction-target-publication.md)
