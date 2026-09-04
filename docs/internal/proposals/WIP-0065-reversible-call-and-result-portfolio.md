# WIP-0065: Reversible call and result portfolio

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, linker, and reversible runtime maintainers |
| Created | 2026-08-15 |
| Updated | 2026-09-04 |
| Area | Self-hosting compiler, reversible calls, result slots |
| Depends on | WIP-0041, WIP-0057, WIP-0060, WIP-0064 |
| Supersedes | Broad call and result portfolio split from WIP-0064 |
| Superseded by | None |
| Follow-up | WIP-0066 owns Boolean reversible result slots |

## Summary

Extend the direct reversible source-product path from the admitted void and signed source-result profiles to local calls, imported calls, and result relations with two sources. Preserve exact call identities and reject every unsupported effect before artifact publication.

## Problem

WIP-0064 establishes closed effect selection, zero-event ownership evidence, generated inverse code, source theorem products, canonical proof strings, signed result slots, and atomic artifact publication. The remaining call and result matrix crosses source parsing, argument coordinates, imported target retention, inverse relocation rebasing, result-slot type layout, and final linking. Keeping that matrix in WIP-0064 would hide the physical cutover behind an unrelated language-profile expansion.

Stage 0 currently admits only the first reversible result-slot profile, which returns `long`. The native compiler must not invent a Boolean profile or claim byte parity before the source authority publishes it. Local and imported inverse calls also need final linked-target evidence rather than verifier stubs.

## Invariants

- Every reversible call resolves through the same source-ordered call product as its forward call.
- Inverse call operands retain the final linked function target and stable 32-byte identity.
- Imported signature stubs never enter a published inverse body.
- A result slot ends with one Boolean presence local followed by one exact payload local.
- Boolean and signed payloads remain distinct in descriptors, local types, and proof subjects.
- A missing result, call, relocation, or target product leaves artifact, identity, and relocation outputs untouched.
- Dependency source remains closed throughout inverse generation and final linking.

## Bounds

- 64 source-local callables
- 256 calls per callable
- Seven arguments per call
- 256 inverse call relocations per source-local body
- 4,096 retained imported targets
- 32,768-byte source-local artifact

## Implementation

`SourceReversibleResultRelations.w` accepts only an identifier, identifier-immediate, or two-identifier return relation with one exact semicolon. It maps the seven admitted checked operations to canonical local opcodes and rejects malformed or trailing tokens. `DirectStatementProducts.w` resolves each source through the existing source-ordered value products and writes the result-slot instruction pair directly. `ReversibleResultComposition.w` accepts either that completed pair or the older one-source move, inserts the presence and payload types once, and leaves completed relation bytes unchanged.

The source-immediate and two-source fixtures pass through `StructuredSourceModuleCompiler.w`, proof publication, inverse generation, final verification, and hashing. Their complete artifacts match stage 0 byte for byte.

`SourceCallTargetTable.w` and `ReferencedSourceCallTargets.w` now retain exact local and imported effect rows through referenced-target filtering. The artifact emitter gives an admitted reversible void verifier stub matching forward and inverse `RETURN` windows. Reversible publication preserves that private stub while generating the local inverse body. A local recursive call matches stage 0 byte for byte, and an imported call publishes the exact stable identity relocation with `CALL` and `UNCALL` bound to the same filtered target row.

`SourceCallRelocationLinkProducts.w` counts forward and inverse instruction directions independently after verifier-stub filtering. It maps the forward source coordinate through the stable target identity, derives the inverse coordinate from the generated inverse order, checks the exact call/uncall opcode pair, and publishes both final targets together. The linked-code fixture excludes both suffix functions and rewrites the retained forward and inverse operands to the same final function ID.

The native proof verifier accepts a bounded dense proof section instead of one hard-coded row. A two-callable native artifact matches stage 0 byte for byte, executes a local call forward, clears history at an effect boundary, and executes `UNCALL` to restore exact global state. The imported-link fixture executes the same sequence through its two native-linked target operands. Stale identities and mismatched owners fail before publication.

## Plan

1. [x] Match the admitted signed one-source result artifact byte for byte.
2. [x] Match admitted source-immediate and two-source result relations byte for byte.
3. [x] Generate local `CALL` and inverse `UNCALL` products from one target identity.
4. [x] Rebase imported inverse call relocations after referenced-target filtering.
5. [x] Rewrite forward and inverse call operands to final linked function IDs atomically.
6. [x] Prove verifier stubs are absent from retained forward, inverse, function, and proof products.
7. [x] Cover shuffled call storage, shared targets, duplicate coordinates, and stale identities.
8. [x] Execute forward and inverse local and imported call chains after clearing history.

## Acceptance

- The native and stage-0 artifacts match for every admitted signed result relation and call shape.
- The final verifier accepts linked forward and inverse bodies without dependency source.
- Shuffled product storage does not change artifact or relocation bytes.
- Unsupported Boolean, call, target, or result forms fail before one caller-visible byte changes.
- Focused closure evidence covers one local call chain and one direct-dependency call chain.

## Rejected alternatives

### Treat Boolean payloads as signed words

Rejected. Result descriptors and local type rows are semantic products, not storage-width hints.

### Retain imported verifier stubs in inverse bodies

Rejected. A stub has no final target identity and cannot authorize inverse execution.

### Reconstruct inverse call targets from packed order

Rejected. Referenced-target filtering changes storage order. Stable identities and source coordinates select targets.

## References

- [WIP-0041](WIP-0041-reversible-result-slots-and-explicit-presence-values.md)
- [WIP-0057](WIP-0057-source-call-relocation-and-ownership-coordinate-products.md)
- [WIP-0060](WIP-0060-imported-call-stub-and-relocation-products.md)
- [WIP-0064](WIP-0064-reversible-source-product-evidence.md)
- [WIP-0066](WIP-0066-boolean-reversible-result-slots.md)
