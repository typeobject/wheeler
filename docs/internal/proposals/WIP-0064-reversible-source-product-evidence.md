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
| Superseded by | WIP-0065 owns the wider call and result portfolio |

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

`ArchiveStructuredSourceModuleCompiler.w` copies each owner-local effect mask beside its rebased body and signature rows. `StructuredSourceModuleCompiler.w` now requires the complete 4,096-row effect view before allocating product storage. It admits only homogeneous ordinary or reversible local callable sets and rejects every other mask before forward composition.

The reversible branch stages the complete forward artifact and identity privately, adapts composed callable rows to WIP-0063 inverse coordinates, and accepts only the ownership-free reversible opcode set. `ReversibleSourceProductArtifact.w` requires an explicit zero ownership-event count. Unsupported structured bodies trap before caller artifact or identity mutation. The ordinary branch copies its staged artifact only after the same product pipeline succeeds.

`SourceGeneratedInverseProofs.w` recognizes the exact `theorem name proves inverse(callable);` form, binds each subject through the closed callable string products, rejects duplicate names and subjects, and publishes no partial name table. Reversible artifact publication merges theorem names into canonical lexical string order, rewrites every affected manifest, type, variant, and function string ID, emits section 10 with the final subject IDs, and verifies the complete artifact before publication.

`ReversibleResultComposition.w` replaces the ordinary terminal move and value return with `RESULT_FILL_SOURCE` and `RETURN_RESULT_SLOT`. It changes the former return temporary into the Boolean presence local, appends the exact signed payload local, and rebases later callable type starts before forward artifact staging. The native function verifier now accepts canonical non-reversible result-slot staging descriptors and applies the same forward slot checks that it applies before inverse publication. The complete signed identity fixture matches stage 0 byte for byte through `StructuredSourceModuleCompiler.w`.

## Plan

1. [x] Carry local callable effect rows into `StructuredSourceModuleCompiler.w`.
2. [x] Select reversible callables before forward composition and reject mixed unsupported effects.
3. [x] Require zero forward ownership events for the admitted straight-line inverse profile.
4. [x] Generate inverse code and inverse relocation rows from completed callable coordinates.
5. [x] Publish one generated-inverse proof row per declared theorem subject.
6. [x] Emit staged forward, inverse, proof, and identity bytes under one atomic artifact boundary.
7. [x] Match the admitted void and signed result-slot stage-0 artifacts byte for byte. WIP-0065 owns Boolean and call profiles.
8. [x] Execute forward, clear history, execute inverse, and restore exact state for the ownership-free profile.
9. [ ] Route the first physical reversible compiler module through direct products.
10. [ ] Remove its stage-0 source projection and signature-scaffolding path.

## Acceptance

- A missing effect, ownership, relocation, or proof product leaves artifact and identity outputs untouched.
- Generated-inverse proof rows survive closure linking with exact final function and string IDs.
- Shuffled callable, proof, and archive storage does not change bytes. WIP-0065 owns call storage.
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
- [WIP-0065](WIP-0065-reversible-call-and-result-portfolio.md)
