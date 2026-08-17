# WIP-0111: Direct one-argument call-classifier adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, call syntax |
| Depends on | WIP-0049, WIP-0054, WIP-0056, WIP-0073, WIP-0099 |
| Supersedes | Parser projection for `OneArgumentCalls.w` |
| Superseded by | None |

## Summary

Route `OneArgumentCalls.w` through direct source products. Its four functions and 79 instructions produce a 2,840-byte artifact that matches stage 0 byte for byte.

The module classifies the bounded one-argument scalar call forms by argument source type and result type.

## Product path

`oneArgumentCallStatement` checks five statement identities before one final equality. Its 39 instructions recognize every signed-result and Boolean-result one-argument family.

`oneArgumentCallNamed` checks the three prior-local forms in 18 instructions. `oneArgumentBooleanCall` and `oneArgumentBooleanSignedCall` each check one conditional identity before one final equality in 11 instructions.

Each condition returns exact Boolean `true`. Every final return compares the preserved signed opcode with one named statement-identity product. The module retains all signed, Boolean, literal-or-constant, and prior-local distinctions.

## Boundaries

The module classifies syntax identities only. It does not resolve callable targets, bind argument locals, validate signatures, select result locals, or emit relocation rows.

Zero-argument and wider call families remain separate products. Boolean-result calls with Boolean and signed arguments remain distinct even though both functions return Boolean.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module after the named return classifiers. The list remains the sole callable-bearing direct-route authority in Java evidence.

No production source or package lock changes belong to this migration. The route consumes existing direct equality, conditional, Boolean literal, and final return products only after complete-artifact parity passes.

## Evidence

`NativeCompilerOneArgumentCallsPhysicalProductExampleTest` compiles the module with stage 0 and its native product program. It requires atomic publication and compares all 2,840 bytes. Focused physical evidence passes in 4 minutes and 48 seconds.

`NativeCompilerPhysicalClosureExampleTest` compares every selected artifact, validates retained functions and imported relocations, links the exact 96-product subset, repeats publication, and rejects malformed footer and relocation products. It passes in 16 minutes and 53 seconds under the unchanged twenty-minute deadline.

The linked container remains byte-identical with SHA-256 `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] `OneArgumentCalls.w` uses direct source products.
- [x] Its four functions and 79 instructions match the 2,840-byte stage-0 artifact.
- [x] Signed-result and Boolean-result statement identities remain distinct.
- [x] Literal-or-constant and prior-local argument forms remain distinct.
- [x] Boolean-argument and signed-argument Boolean calls remain distinct.
- [x] No target, signature, result-local, or relocation product is inferred.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Infer result type from one broad call range

Rejected. The statement registry keeps signed and Boolean results in separate identities.

### Infer prior-local arguments from opcode arithmetic

Rejected. Named identities are products, not a host bitfield contract.

### Resolve targets in the syntax classifier

Rejected. Target resolution requires owner-scoped callable products and signatures.

### Keep the classifier on parser projection

Rejected. Existing direct equality and Boolean return products close the artifact.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0099](WIP-0099-exact-boolean-literal-return-products.md)
