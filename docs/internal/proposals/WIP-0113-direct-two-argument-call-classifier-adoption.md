# WIP-0113: Direct two-argument call-classifier adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, call syntax |
| Depends on | WIP-0049, WIP-0054, WIP-0056, WIP-0073, WIP-0099, WIP-0110 |
| Supersedes | Parser projection for `TwoArgumentCallKinds.w` |
| Superseded by | None |

## Summary

Route `TwoArgumentCallKinds.w` through direct source products. Its four functions and 156 instructions produce a 4,808-byte artifact that matches stage 0 byte for byte.

The module classifies every bounded two-argument scalar call by result type, argument type, and whether each argument names a prior local.

## Product path

`twoArgumentCallStatement` checks eleven statement identities before one final equality. Its 81 instructions cover all twelve forms.

The three family classifiers each check three identities before one final equality. Each consumes 25 instructions and selects one exact four-member family:

- signed-result calls with signed arguments
- Boolean-result calls with Boolean arguments
- Boolean-result calls with signed arguments

Every family includes constant-or-literal arguments, first-local arguments, second-local arguments, and two-local arguments. The products retain those identities instead of deriving source positions from numeric opcode relationships.

## Boundaries

The module classifies syntax identities only. It does not bind arguments, resolve callable targets, validate signatures, allocate result locals, or emit relocations.

One-argument and wider calls remain separate products. WIP-0110 owns first-local and second-local queries for these exact identities.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module after `ThreeArgumentCalls.w`. The list remains the sole callable-bearing direct-route authority in Java evidence.

No production source or package lock changes belong to this migration. The route consumes existing direct equality, conditional, Boolean literal, and final return products only after complete-artifact parity passes.

## Evidence

`NativeCompilerTwoArgumentCallKindsPhysicalProductExampleTest` compiles the module with stage 0 and its native product program. It requires atomic publication and compares all 4,808 bytes. Focused physical evidence passes in 5 minutes and 3 seconds.

`NativeCompilerPhysicalClosureExampleTest` compares every selected artifact, validates retained functions and imported relocations, links the exact 96-product subset, repeats publication, and rejects malformed footer and relocation products. It passes in 17 minutes and 38 seconds under the unchanged twenty-minute deadline.

The linked container remains byte-identical with SHA-256 `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] `TwoArgumentCallKinds.w` uses direct source products.
- [x] Its four functions and 156 instructions match the 4,808-byte stage-0 artifact.
- [x] All twelve statement identities remain exact products.
- [x] Signed-result and Boolean-result families remain distinct.
- [x] Boolean-argument and signed-argument Boolean calls remain distinct.
- [x] Constant-or-literal, first-local, second-local, and two-local forms remain distinct.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Compress families into opcode ranges

Rejected. The statement registry does not expose a range contract for these named identities.

### Infer argument locality from numeric differences

Rejected. WIP-0110 classifies exact identities without host arithmetic.

### Merge Boolean-argument and signed-argument calls

Rejected. Their parameter signatures and statement identities remain distinct.

### Keep the classifier on parser projection

Rejected. Existing direct equality and Boolean return products close the artifact.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0099](WIP-0099-exact-boolean-literal-return-products.md)
- [WIP-0110](WIP-0110-direct-call-argument-source-classifier-adoption.md)
