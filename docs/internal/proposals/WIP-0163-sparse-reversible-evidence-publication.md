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

`NativeCompilerPhysicalClosureExampleTest` now compares all 137 selected artifacts, retained prefixes, and relocations. WIP-0411 adds the direct assignment-syntax product and closes the wide-local dependency named by `CallForms.w`. WIP-0413 adds the guarded UTF-8 call owner without a broad token-module edge. WIP-0414 retains separate statement, decoder, signed, and nonsigned result owners. WIP-0415 retains the manifest assertion classifier. WIP-0416 retains the profile classifier after admitting Boolean source children. WIP-0420 retains the package-manifest token product, WIP-0421 retains the package-name validators, WIP-0422 retains the package-path validators, WIP-0424 retains semantic-version scalar and core validation, WIP-0425 retains prerelease validation with imported core calls, WIP-0426 retains semantic-version coordinates, WIP-0427 retains identifier precedence, WIP-0428 retains core precedence, WIP-0429 retains prerelease sequence order, WIP-0430 retains release precedence, WIP-0431 closes the semantic-version facade, WIP-0432 retains package-canonical coordinates, WIP-0433 retains canonical line kinds, WIP-0435 retains canonical section and indent policy, WIP-0436 retains canonical framing and completion, WIP-0437 retains canonical token-window state, WIP-0438 retains package-manifest kind policy with five resolved token-owner calls, WIP-0439 retains its four fixed row-capacity products, WIP-0440 isolates package brackets, WIP-0441 retains them through direct structured source products, WIP-0442 retains mapping-key composition with two resolved token-policy calls, WIP-0443 retains selector scalar state beyond the former 128-product owner bound, WIP-0444 retains quoted package-range coordinates, WIP-0445 retains call-free selector-prefix traversal, WIP-0446 retains selector completion, WIP-0447 retains their facade, WIP-0448 retains manifest-header scalar state, WIP-0449 retains the format preamble, WIP-0450 retains header name validation, and WIP-0451 retains header release validation. Each fresh test run links 426 functions and 15,161 instructions, retains 11,789 local types and 360,216 code bytes, and reproduces SHA-256 `45534e46c1a1ba82b02033b901ac1073865b5343468f8f4bf79f173681492c2d`. Complete evidence remains bounded by the forty-five-minute method deadline.

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
- [x] Complete evidence remains below twenty-four minutes.
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
- [WIP-0411](WIP-0411-closed-assignment-and-wide-call-products.md)
