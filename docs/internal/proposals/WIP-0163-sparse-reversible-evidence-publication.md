# WIP-0163: Sparse reversible-evidence publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, reversible artifacts, proofs, relocations, bounded publication |
| Depends on | WIP-0063, WIP-0064, WIP-0065, WIP-0159 |
| Supersedes | Full-capacity reversible result, inverse, relocation, and proof copies |
| Superseded by | None |

## Summary

Publish reversible source products through measured counts instead of table capacities. Four stages formerly copied inactive rows after complete validation:

- reversible result local types
- generated inverse callable windows
- generated inverse relocations
- generated inverse proof names and subjects

Each stage now publishes only rows and bytes named by its result plan.

## Result local types

`ReversibleResultComposition.w` inserts explicit result-slot presence and payload locals where needed. Three type columns publish through the rebuilt `stagedTypeCount`:

- callable owner
- callable-local index
- canonical type code

Callable type starts and local counts still publish through `callableCount`. Reversible result opcodes change only after the type plan succeeds.

## Inverse windows

`GeneratedInverseProducts.w` validates every forward instruction boundary, derives exact inverse opcodes in reverse order, retains terminal returns, and checks complete code coverage.

Three inverse columns publish through `callableCount`:

- inverse code start
- inverse code length
- inverse instruction count

Inverse code bytes remain bounded by measured forward code length.

## Inverse relocations

`GeneratedInverseRelocations.w` sorts inverse call sites by owner and inverse instruction coordinate. It publishes three relocation columns, one owner column, and 32 identity bytes through `relocationCount`.

No inactive relocation row or identity block is part of the product.

## Proofs

`SourceGeneratedInverseProofs.w` requires one exact theorem per reversible callable and rejects missing, duplicate, unknown, or malformed subjects.

Proof starts, lengths, and subject rows publish through `proofCount`. Name bytes publish through `proofNameCursor`.

## Atomicity

Each stage retains private staging and publishes only after complete count, order, type, opcode, identity, and source validation. Untouched caller rows retain prior contents. A failed stage publishes no row or byte.

## Bounds

No capacity changes:

- 64 reversible callables and proofs
- 4,096 local types
- 32,768 instructions
- 262,144 inverse code bytes
- 256 relocations
- 8,192 relocation identity bytes
- 16,384 proof-name bytes

Worst-case work remains identical.

## Evidence

Focused suites cover result-slot local rebuilding, inverse opcode generation, inverse call ordering and identity retention, exact theorem publication, malformed relations, duplicate subjects, and atomic failure.

`NativeCompilerReversibleSourceProductArtifactExampleTest` checks final reversible artifact bytes through all four stages.

The compiler archive contains 3,008,259 bytes with SHA-256 `0909abc6008e399ff067fecae04594b22b1369f8eebf98ac2b27e5e18a60b78f`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `9a3fb81e4d75ad52d0ff22deefe636d58d56827ea1de80c1e87a2d96c8c60be9`. Complete evidence passes in 15 minutes and 10 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] Rebuilt type columns publish through `stagedTypeCount`.
- [x] Inverse callable columns publish through `callableCount`.
- [x] Relocation rows, owners, and identities publish through `relocationCount`.
- [x] Proof rows publish through `proofCount` and names through `proofNameCursor`.
- [x] Inverse code remains bounded by measured forward length.
- [x] Untouched caller rows and bytes retain prior contents.
- [x] Focused reversible evidence and artifact tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The linked physical subset publishes twice with identical bytes.
- [x] Complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Merge proof and inverse generation

Rejected. Source theorem evidence and generated instruction products have separate authorities.

### Publish relocations in forward order

Rejected. Inverse instruction coordinates define canonical inverse order.

### Clear inactive tails

Rejected. Measured counts define every reversible product.

### Trust theorem count without subjects

Rejected. Each theorem remains bound to one exact callable identity.

## References

- [WIP-0063](WIP-0063-generated-inverse-coordinate-products.md)
- [WIP-0064](WIP-0064-reversible-source-product-evidence.md)
- [WIP-0065](WIP-0065-reversible-call-and-result-portfolio.md)
- [WIP-0159](WIP-0159-sparse-callable-composition-publication.md)
