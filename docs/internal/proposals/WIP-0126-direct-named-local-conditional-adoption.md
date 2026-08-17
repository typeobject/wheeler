# WIP-0126: Direct named local-conditional adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-17 |
| Updated | 2026-08-17 |
| Area | Self-hosting compiler, physical closure, conditionals |
| Depends on | WIP-0049, WIP-0054, WIP-0056, WIP-0073, WIP-0099, WIP-0114 |
| Supersedes | Parser projection for `NamedLocalConditionalKinds.w` |
| Superseded by | None |

## Summary

Route `NamedLocalConditionalKinds.w` through direct source products. Its four functions and 198 instructions produce a 5,912-byte artifact that matches stage 0 byte for byte.

The module classifies unresolved Boolean-local conditional statements, negation, assignment, and assignment from another local.

## Product path

`namedLocalConditional` checks fifteen exact statement identities before one final equality. It covers add, subtract, XOR, assignment, and prior-local-value forms under positive and negated Boolean conditions. The function uses 109 instructions.

`namedLocalConditionalNegated` checks seven negated identities before its final equality and uses 53 instructions.

`namedLocalConditionalAssignment` checks three assignment identities before its final equality and uses 25 instructions.

`namedLocalConditionalAssignmentValue` checks one positive identity before its final negated-form equality and uses 11 instructions.

Every condition child returns exact Boolean `true`. No numeric interval or bit assignment replaces the named statement products.

## Boundaries

The module classifies unresolved identities only. It does not resolve the Boolean source, decode an assigned value, select an update opcode, allocate locals, or emit branch code.

Positive and negated forms remain distinct. Immediate-value and prior-local-value forms remain distinct. WIP-0114 owns the resolved range classifier.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module between the named assignment and conditional-value classifiers. The list remains the sole callable-bearing direct-route authority in Java evidence.

No production source or package lock changes belong to this migration. The route consumes existing direct equality, conditional, Boolean literal, and final return products only after complete-artifact parity passes.

## Evidence

`NativeCompilerNamedLocalConditionalKindsPhysicalProductExampleTest` compiles the module with stage 0 and its native product program. It requires atomic publication and compares all 5,912 bytes. Focused physical evidence passes in 4 minutes and 37 seconds.

`NativeCompilerPhysicalClosureExampleTest` compares every selected artifact, validates retained functions and imported relocations, links the exact 96-product subset, repeats publication, and rejects malformed footer and relocation products. It passes in 18 minutes and 1 second under the unchanged twenty-minute deadline.

The linked subset remains byte-identical with SHA-256 `5fc2ddaec2835c516d52d1e8b1254aeaf50789c72d7b42cd0060b026b880ec25`.

## Acceptance

- [x] `NamedLocalConditionalKinds.w` uses direct source products.
- [x] Its four functions and 198 instructions match the 5,912-byte stage-0 artifact.
- [x] All sixteen general conditional identities remain exact products.
- [x] All eight negated identities remain exact products.
- [x] All four assignment identities remain exact products.
- [x] Positive and negated assignment-value identities remain distinct.
- [x] No numeric interval or host bitfield becomes semantic authority.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Classify named forms through resolved ranges

Rejected. Unresolved identities are explicit registry products, not packed local columns.

### Infer negation from one numeric bit

Rejected. The statement registry publishes distinct stable identities.

### Merge assignment and update forms

Rejected. Assignment, add, subtract, and XOR retain different resolution and code products.

### Keep the classifier on parser projection

Rejected. Existing direct equality and Boolean return products close the artifact.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0099](WIP-0099-exact-boolean-literal-return-products.md)
- [WIP-0114](WIP-0114-direct-resolved-local-conditional-classifier-adoption.md)
