# WIP-0118: Direct void-call source-classifier adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, call syntax |
| Depends on | WIP-0049, WIP-0054, WIP-0056, WIP-0073, WIP-0099 |
| Supersedes | Parser projection for `VoidCallSourceKinds.w` |
| Superseded by | None |

## Summary

Route `VoidCallSourceKinds.w` through direct source products. Its one function and 25 instructions produce a 1,128-byte artifact that matches stage 0 byte for byte.

The module classifies the bounded unresolved zero- through three-argument ordinary void-call forms.

## Product path

`voidCallSourceStatement` checks the zero-, one-, and two-argument statement identities in three seven-instruction conditional windows. Its final four-instruction equality accepts the three-argument identity.

Each child returns exact Boolean `true`. All four source identities remain public module-local constants and enter the artifact in source order.

The public four- through seven-argument identities remain outside this classifier. Their wide source forms use separate syntax and operand products.

## Boundaries

The module classifies unresolved statement identities only. It does not measure argument tokens, bind prior locals, resolve callable targets, validate signatures, emit call code, or publish relocations.

Resolved void-call identities remain under `VoidCallKinds.w`. Source and resolved identities do not share an inferred arithmetic mapping.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module before `WideReturnSources.w`. The list remains the sole callable-bearing direct-route authority in Java evidence.

No production source or package lock changes belong to this migration. The route consumes existing direct equality, conditional, Boolean literal, and final return products only after complete-artifact parity passes.

## Evidence

`NativeCompilerVoidCallSourceKindsPhysicalProductExampleTest` compiles the module with stage 0 and its native product program. It requires atomic publication and compares all 1,128 bytes. Focused physical evidence passes in 4 minutes and 22 seconds.

`NativeCompilerPhysicalClosureExampleTest` compares every selected artifact, validates retained functions and imported relocations, links the exact 96-product subset, repeats publication, and rejects malformed footer and relocation products. It passes in 16 minutes and 58 seconds under the unchanged twenty-minute deadline.

The linked container remains byte-identical with SHA-256 `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] `VoidCallSourceKinds.w` uses direct source products.
- [x] Its one function and 25 instructions match the 1,128-byte stage-0 artifact.
- [x] Zero- through three-argument source identities remain exact products.
- [x] Four- through seven-argument wide forms remain outside this classifier.
- [x] Source and resolved identities remain separate authorities.
- [x] No target, signature, argument, code, or relocation product is inferred.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Include wide source forms in this classifier

Rejected. Wide calls own different syntax, measurement, and packed operand products.

### Infer resolved identities from source constants

Rejected. Resolution owns a separate canonical identity family.

### Resolve targets in the syntax classifier

Rejected. Target binding requires owner-scoped callable and signature products.

### Keep the classifier on parser projection

Rejected. Existing direct equality and Boolean return products close the artifact.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0099](WIP-0099-exact-boolean-literal-return-products.md)
