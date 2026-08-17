# WIP-0110: Direct call-argument source-classifier adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, call arguments |
| Depends on | WIP-0049, WIP-0054, WIP-0056, WIP-0073, WIP-0099 |
| Supersedes | Parser projection for `CallArgumentSources.w` |
| Superseded by | None |

## Summary

Route `CallArgumentSources.w` through direct source products. Its two functions and 78 instructions produce a 2,592-byte artifact that matches stage 0 byte for byte.

The module classifies whether the first or second argument of a bounded two-argument scalar call names a prior local.

## Product path

`twoArgumentCallFirstNamed` checks five source-ordered statement identities before one final equality. It covers signed scalar calls, Boolean-result Boolean-argument calls, and Boolean-result signed-argument calls whose first or both arguments are locals.

`twoArgumentCallSecondNamed` mirrors that shape for second-local and both-local forms.

Each callable has five seven-instruction conditional windows and one four-instruction final equality, for 39 instructions. Every condition child returns exact Boolean `true`. The complete module contains 78 instructions.

The classifier retains each statement constant independently. It does not decode an argument, read a local type, infer a call signature, or compute identities from argument-position bits.

## Boundaries

The module classifies two-argument source forms only. It does not cover zero, one, three, four, or variadic calls. It does not distinguish borrowed and owned modes or emit call bytecode.

Call argument binding, target signatures, local coordinates, and relocation identities remain separate source products.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module after `BooleanTokens.w`. The list remains the sole callable-bearing direct-route authority in Java evidence.

No production source or package lock changes belong to this migration. The route consumes existing direct equality, conditional, Boolean literal, and final return products only after complete-artifact parity passes.

## Evidence

`NativeCompilerCallArgumentSourcesPhysicalProductExampleTest` compiles the module with stage 0 and its native product program. It requires atomic publication and compares all 2,592 bytes. Focused physical evidence passes in 4 minutes and 53 seconds.

`NativeCompilerPhysicalClosureExampleTest` compares every selected artifact, validates retained functions and imported relocations, links the exact 96-product subset, repeats publication, and rejects malformed footer and relocation products. It passes in 16 minutes and 33 seconds under the unchanged twenty-minute deadline.

The linked container remains byte-identical with SHA-256 `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] `CallArgumentSources.w` uses direct source products.
- [x] Its two functions and 78 instructions match the 2,592-byte stage-0 artifact.
- [x] First-argument classification retains all six exact statement identities.
- [x] Second-argument classification retains all six exact statement identities.
- [x] Signed and Boolean-result call families remain distinct products.
- [x] No argument-position or opcode arithmetic is inferred.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Decode argument position from opcode bits

Rejected. Statement identities are registry products, not a host bitfield contract.

### Merge signed and Boolean-result call forms

Rejected. Their target result types and statement identities remain distinct.

### Bind arguments in this classifier

Rejected. Binding requires callable signatures and physical local coordinates owned elsewhere.

### Keep the classifier on parser projection

Rejected. Existing direct equality and Boolean return products close the artifact.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0099](WIP-0099-exact-boolean-literal-return-products.md)
