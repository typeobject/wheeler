# WIP-0117: Direct early-return result-classifier adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, guard returns |
| Depends on | WIP-0049, WIP-0054, WIP-0056, WIP-0073, WIP-0099 |
| Supersedes | Parser projection for `EarlyReturnResultKinds.w` |
| Superseded by | None |

## Summary

Route `EarlyReturnResultKinds.w` through direct source products. Its six functions and 80 instructions produce a 3,184-byte artifact that matches stage 0 byte for byte.

The module classifies result type and arithmetic shape for bounded helper-call and comparison guard returns.

## Product path

`helperGuardResultSigned` retains one exact statement-identity equality in four instructions.

`comparisonGuardResultSigned` checks five signed comparison-result identities before one final equality. Its 39 instructions include plain signed results and add, subtract, remainder, and division results.

`comparisonGuardResultComputed` checks three arithmetic identities before one final equality in 25 instructions.

The addition, remainder, and division selectors each retain one exact statement-identity equality in four instructions. Subtraction remains the computed form selected when the broader computed classifier accepts it and the three focused selectors reject it.

## Boundaries

The module classifies unresolved result forms only. It does not decode condition operands, bind result sources, execute arithmetic, resolve helper calls, or emit branch and return instructions.

Signed and Boolean results remain distinct. Computed signed results remain separate from plain signed-local results.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module after `CoreParsing.w`. The list remains the sole callable-bearing direct-route authority in Java evidence.

No production source or package lock changes belong to this migration. The route consumes existing direct equality, conditional, Boolean literal, and final return products only after complete-artifact parity passes.

## Evidence

`NativeCompilerEarlyReturnResultKindsPhysicalProductExampleTest` compiles the module with stage 0 and its native product program. It requires atomic publication and compares all 3,184 bytes. Focused physical evidence passes in 4 minutes and 38 seconds.

`NativeCompilerPhysicalClosureExampleTest` compares every selected artifact, validates retained functions and imported relocations, links the exact 96-product subset, repeats publication, and rejects malformed footer and relocation products. It passes in 17 minutes and 10 seconds under the unchanged twenty-minute deadline.

The linked container remains byte-identical with SHA-256 `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] `EarlyReturnResultKinds.w` uses direct source products.
- [x] Its six functions and 80 instructions match the 3,184-byte stage-0 artifact.
- [x] Helper-call and comparison signed-result identities remain distinct.
- [x] Plain and computed signed result forms remain distinct.
- [x] Add, subtract, remainder, and division identities remain exact products.
- [x] Boolean result forms remain outside the signed classifiers.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Treat every early return as signed

Rejected. Boolean literal children remain a separate typed result family.

### Derive arithmetic kinds from opcode order

Rejected. Named statement identities remain the source authority.

### Emit arithmetic in this classifier

Rejected. Classification and resolved code generation own separate products.

### Keep the classifier on parser projection

Rejected. Existing direct equality and Boolean return products close the artifact.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0099](WIP-0099-exact-boolean-literal-return-products.md)
