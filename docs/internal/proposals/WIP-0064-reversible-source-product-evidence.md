# WIP-0064: Reversible source-product evidence

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler compiler, ownership, proof, and bootstrap maintainers |
| Created | 2026-08-15 |
| Updated | 2026-08-15 |
| Area | Self-hosting compiler, reversible source, ownership, proofs |
| Depends on | WIP-0041, WIP-0054, WIP-0057, WIP-0063 |
| Supersedes | Ownership, proof, and physical adoption split from WIP-0063 |
| Superseded by | None |

## Summary

Carry reversible effects, inverse ownership evidence, and generated-inverse proof rows through the native structured source-product compiler. The compiler shall publish a reversible source artifact directly from closed source products and shall not require a forward artifact assembled by stage 0.

## Problem

WIP-0063 publishes inverse code, inverse call relocations, reversible function descriptors, and byte-identical complete artifacts from forward products. The current `StructuredSourceModuleCompiler.w` API does not retain local callable effects. It therefore emits only ordinary forward descriptors, even when module products classify a callable as reversible.

The admitted straight-line inverse profile has no allocation, drop, move, loan, or release operation. That zero-event ownership fact still needs an explicit gate. A generated-inverse theorem also needs a canonical proof product tied to the same callable and final artifact. Neither fact may be inferred from a reversible descriptor bit.

## Invariants

- Local callable effects come from WIP-0045 signature products and survive archive source freezing.
- A reversible callable uses the exact WIP-0055 forward rows and WIP-0063 inverse rows.
- The straight-line profile publishes zero ownership events in both directions. Any storage event rejects before artifact publication.
- Local and imported inverse call relocations retain exact target identities and owner-local coordinates.
- A generated-inverse proof row names one exact reversible function and enters section 10 before final verification.
- The final artifact verifier checks descriptors, instruction pairs, payloads, proof subjects, and section framing before publication.
- Dependency source and stage-0 artifacts remain outside the transaction lifetime.

## Bounds

- 64 source-local callables
- 256 calls per callable
- 8,192 ownership events per source-local artifact
- 4,096 proof products per closure
- 32,768-byte source-local artifact

## Implementation

`ArchiveStructuredSourceModuleCompiler.w` copies each owner-local effect mask beside its rebased body and signature rows. `StructuredSourceModuleCompiler.w` now requires the complete 4,096-row effect view before allocating product storage. The ordinary path accepts only mask zero. A reversible mask traps while artifact and identity outputs retain their sentinels.

## Plan

1. [x] Carry local callable effect rows into `StructuredSourceModuleCompiler.w`.
2. [ ] Select reversible callables before forward composition and reject mixed unsupported effects.
3. [ ] Require zero forward ownership events for the admitted straight-line inverse profile.
4. [ ] Generate inverse code and inverse relocation rows from completed callable coordinates.
5. [ ] Publish one generated-inverse proof row per declared theorem subject.
6. [ ] Emit forward, inverse, proof, and identity bytes under one atomic artifact boundary.
7. [ ] Match signed, Boolean, void, local-call, imported-call, and result-slot stage-0 artifacts byte for byte.
8. [ ] Execute forward, clear history, execute inverse, and restore exact global and owned state.
9. [ ] Route the first physical reversible compiler module through direct products.
10. [ ] Remove its stage-0 source projection and signature-scaffolding path.

## Acceptance

- A missing effect, ownership, relocation, or proof product leaves artifact and identity outputs untouched.
- Generated-inverse proof rows survive closure linking with exact final function and string IDs.
- Shuffled callable, call, proof, and archive storage does not change bytes.
- The independent verifier accepts every published artifact without dependency source.
- The physical source-product route compiles admitted reversible functions without stage 0.

## Rejected alternatives

### Infer reversibility from an inverse byte window

Rejected. Callable effect products authorize inverse generation before bytes exist.

### Treat an empty ownership table as implicit evidence

Rejected. The producer must publish an exact zero count under the same transaction.

### Add proof rows after artifact verification

Rejected. The proof section is part of the verified and hashed artifact.

## References

- [WIP-0041](WIP-0041-reversible-result-slots-and-explicit-presence-values.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0057](WIP-0057-source-call-relocation-and-ownership-coordinate-products.md)
- [WIP-0063](WIP-0063-generated-inverse-coordinate-products.md)
