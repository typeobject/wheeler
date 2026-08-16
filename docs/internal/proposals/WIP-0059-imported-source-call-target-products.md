# WIP-0059: Imported source call target products

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, package, and linker maintainers |
| Created | 2026-08-14 |
| Updated | 2026-08-14 |
| Area | Self-hosting compiler, imported calls, relocation |
| Depends on | WIP-0045, WIP-0048, WIP-0057 |
| Supersedes | Imported call integration in WIP-0057 |
| Superseded by | WIP-0060 for artifact stubs and final relocation, WIP-0061 for qualified spelling |

## Summary

Feed imported callable products into structured source compilation without reopening dependency source. Match unqualified calls against closed names and signatures, retain package-bound target identities, and publish external relocations beside local call products. WIP-0061 owns qualified spelling.

## Problem

`SourceCallProducts.w` already resolves packed imported names after local shadowing. The structured compiler currently builds its target table from local function strings and signatures. It therefore has no imported parameter table, result kind, target identity, dependency rank, or final relocation class.

Copying dependency source into the structured pass would create a second frontend authority. Treating a closure-table ordinal as an identity would make package storage order observable.

## Products

An imported target view contains:

- canonical callable name range
- ordered parameter types and loan modes
- result kind and effects
- package-bound stable callable identity
- dependency rank used during target admission

The module call scanner checks locals first. It checks only admitted dependency products after local matching fails. Call rows retain the selected product identity through code emission.

## Invariants

- Dependency source never enters the API.
- A local callable shadows an equal imported name and arity.
- Equal unqualified imported products remain ambiguous.
- Target identity, not packed row order, authorizes relocation.
- Parameter and result products validate before call widths publish.
- Missing identities and malformed signatures publish no call artifact.

## Bounds

- 4,096 callable products in the closure view
- 64 local callables per module
- 256 calls per module
- seven parameters per admitted call
- 32 identity bytes per target

## Implementation

`ImportedSourceCallTargets.w` now consumes the direct callable-dependency product and closure-wide callable metadata. It copies names, ordered parameter types and loan modes, result kinds, effects, and callable identities into one bounded view. Dependency rank and callable identity establish output order, so packed row order owns nothing. Negative external rows, duplicate identities, malformed ranges, and overlong signatures preserve every caller buffer.

The archive compiler imports this product as the sole target-view boundary. `SourceCallTargetTable.w` joins local products and the ordered imported view into one dense name, parameter, result, identity, and dependency-rank table. It stages the complete table and leaves every output unchanged on a malformed range, type, or result. `SourceModuleCallProducts.w` scans that shape in one retained callable-body pass. Local matches shadow dependency rows before exact statement binding. `SourceCallLayoutProducts.w` validates arity, parameter types, and result kinds through the same table instead of reconstructing local signatures. `compileStructuredSourceModuleWithTargets` now carries an admitted imported view through discovery, statement binding, typed layout, code windows, and identity relocations. The local-only entry point lives in `LocalStructuredSourceModuleCompiler.w` and supplies an explicit empty view. `ImportedStructuredArchiveModuleCompiler.w` materializes the bounded imported view from direct dependency rows and closure-wide callable products before the archive compiler freezes its selected local source range. Dependency source never enters either lifetime. WIP-0060 supplies verifier-safe stub rows before standalone source-local publication.

## Plan

- [x] Define the closed imported target view accepted by the archive compiler.
- [x] Carry copied qualified names, signatures, effects, and identities into structured compilation.
- [x] Resolve local and imported calls through one source scanner.
- [x] Build one local-plus-imported parameter and identity table.
- [x] Hand referenced targets to WIP-0060 without changing call code windows.
- [x] Preserve package-bound callable identity through the handoff and use dependency rank before selection.

## Acceptance

- [x] An imported call compiles with no dependency source in memory.
- [x] A local callable shadows an equal imported target.
- [x] Missing, duplicate, or mismatched imported products publish nothing.
- [x] Shuffled dependency and target rows do not change target or artifact products.
- [x] Package identity participates in the stable callable identity.
- [x] WIP-0061 makes qualified calls select one exact imported product.

## Rejected alternatives

### Reparse dependency source

Rejected. Closed products are the dependency interface.

### Use callable table indices as identities

Rejected. Table packing is not semantic order.

## References

- [WIP-0045](WIP-0045-counted-native-module-symbol-products.md)
- [WIP-0048](WIP-0048-canonical-native-product-linker.md)
- [WIP-0057](WIP-0057-source-call-relocation-and-ownership-coordinate-products.md)
- [WIP-0060](WIP-0060-imported-call-stub-and-relocation-products.md)
- [WIP-0061](WIP-0061-qualified-imported-source-calls.md)
