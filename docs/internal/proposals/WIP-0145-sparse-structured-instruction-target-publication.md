# WIP-0145: Sparse structured instruction-target publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, relocation, bounded publication |
| Depends on | WIP-0057, WIP-0062, WIP-0139, WIP-0144 |
| Supersedes | Full-capacity publication in `SourceCallRelocationLinkProducts.w` |
| Superseded by | None |

## Summary

Publish only validated source-call instruction targets. The relocation linker formerly copied all 131,072 rows from a staged dense table even though one module admits at most 256 relocations and at most one inverse target per relocation.

The linker now stages at most 512 touched instruction rows, validates the matching caller rows are zero, and publishes only those rows.

## Staging

Relocation validation still uses one dense private target table. Dense indexing keeps target lookup exact while the linker checks owner-local instruction ordinals, call opcodes, inverse correspondence, and duplicate relocation coordinates.

A new 512-word row list records each forward and inverse instruction selected during validation. The staging arena grows by 4,096 bytes and one allocation.

After every relocation validates, the linker performs two bounded sparse passes:

1. require every selected caller row to be zero
2. copy each selected target from private staging

The zero preflight preserves atomic publication for active rows. Callers provide a new zero-owned target table, as both production and focused evidence already do. Untouched rows remain zero without 131,072 writes.

## Bounds

The relation follows directly from existing limits:

- at most 256 imported relocations
- at most one forward target per relocation
- at most one inverse target per relocation
- at most 512 published instruction rows

No artifact, relocation, function, instruction, or target-table capacity changes. The output remains a 131,072-row dense lookup for downstream code emission.

## Evidence

`NativeCompilerSourceCallRelocationLinkProductsExampleTest` checks forward and inverse publication, stub exclusion, final execution, owner rejection, and stale identity rejection. All focused cases pass.

`NativeCompilerEarlyComparisonFormsPhysicalProductExampleTest` traverses sparse publication with two imported calls. Its focused run passes in 4 minutes and 1 second under Java 26 with exact retained and relocation products.

`NativeCompilerPhysicalClosureExampleTest` compares every comparable artifact, validates every retained prefix and relocation, links the exact 97-product subset twice, and rejects malformed footer and relocation products. It passes in 19 minutes and 35 seconds under the unchanged twenty-minute deadline. All container counts and the linked identity `2d078ef722d6cc916a7a8649492f9f0871efeb507d96abd32e1bf971497268ca` remain unchanged.

The compiler archive contains 3,001,357 bytes with SHA-256 `f098e959ace43e1427cb07f1ed573b0ba1c268d681602a49aa26ba0a23538c5c`. Exact dependent locks name that archive.

## Acceptance

- [x] Forward and inverse target rows are recorded during complete validation.
- [x] At most 512 caller rows are preflighted and published.
- [x] Active caller rows must be zero before the first write.
- [x] Untouched rows remain zero by owner construction.
- [x] Malformed owner and stale identity paths publish nothing.
- [x] Focused linked execution retains exact forward and inverse behavior.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The 97-product linked subset publishes twice with identical bytes.
- [x] The complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Shrink the downstream target table

Rejected. Final code emission uses instruction-row direct indexing.

### Publish while validating each relocation

Rejected. A later malformed relocation would expose a partial table.

### Clear a reused dense table

Rejected. Production callers allocate a fresh zero owner and transfer it once.

### Raise the evidence deadline

Rejected. Empty-row writes carry no semantics.

## References

- [WIP-0057](WIP-0057-source-call-relocation-and-ownership-coordinate-products.md)
- [WIP-0062](WIP-0062-atomic-source-call-link-publication.md)
- [WIP-0139](WIP-0139-structured-imported-call-product-foundations.md)
- [WIP-0144](WIP-0144-private-structured-instruction-target-staging.md)
