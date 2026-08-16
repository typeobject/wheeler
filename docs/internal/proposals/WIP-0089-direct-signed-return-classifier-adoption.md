# WIP-0089: Direct signed return-classifier adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, migration |
| Depends on | WIP-0049, WIP-0054, WIP-0073, WIP-0087, WIP-0088 |
| Supersedes | Parser projection for `NamedSignedReturnKinds.w` |
| Superseded by | None |

## Summary

Route `NamedSignedReturnKinds.w` through direct source products. Its three functions and 33 instructions produce a 1,608-byte artifact that matches stage 0 byte for byte.

The module separately classifies signed equality, inequality, and less-than returns. Each function contains one exact conditional Boolean return followed by one final signed equality over the opcode parameter and an imported statement constant.

## Problem

Each helper has the same closed source shape:

```wheeler
if (opcode == STATEMENT_RETURN_SIGNED_EQ_LITERAL_NAMED) {
  return true;
}

return opcode == STATEMENT_RETURN_SIGNED_EQ_LOCAL_NAMED;
```

Parser projection duplicated source block selection, imported constant lookup, local coordinates, branch targets, result types, instruction order, and string products. Direct products already owned every required semantic coordinate.

## Product path

Each callable owns one preserved signed parameter. Its conditional consumes an imported signed statement constant and a Boolean-literal child return. The conditional contributes seven instructions.

The final equality consumes the same parameter and a second imported constant. It contributes four instructions across two signed operand locals and one Boolean result local. Each function therefore contributes 11 instructions, for 33 instructions across the module.

The three callables retain distinct source identities, names, constant products, local windows, and result products. Callable composition never merges their common shape.

## Boundaries

The classifier recognizes statement forms. It does not execute the signed equality, inequality, or less-than operations described by those statement identities.

The module has no calls, loops, aggregates, declarations, mutations, ownership effects, inverses, proofs, or result slots. Imported constants remain the only authority for statement values.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module after `NamedReturnComparisonOperands.w`. The ordered list remains the sole callable-bearing migration authority in Java evidence.

No production package source or package lock changes. The migration changes only the tested physical product route.

## Evidence

`NativeCompilerNamedSignedReturnKindsPhysicalProductExampleTest` compiles the module with stage 0 and its native physical product program. It requires atomic publication and compares all 1,608 bytes.

The focused evidence passes in 4 minutes and 47 seconds. The complete physical closure compares every selected artifact, validates retained functions and relocations, links the exact 96-product subset, repeats the linker, and rejects malformed footer and relocation products. It passes in 15 minutes and 56 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] `NamedSignedReturnKinds.w` uses direct source products.
- [x] Its three functions and 33 instructions match the 1,608-byte stage-0 artifact.
- [x] Each conditional owns one exact Boolean child and branch window.
- [x] Each final equality follows its child without duplication.
- [x] Imported constants resolve without dependency-source reads.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Merge the three helpers

Rejected. Equality, inequality, and ordering classifiers have distinct callable identities and consumers.

### Derive local forms from literal forms

Rejected. Statement constants remain independent stable products rather than arithmetic relations.

### Keep these small helpers on parser projection

Rejected. Their complete artifacts close under existing direct products.

### Route the Boolean classifier with this module

Rejected. Its final helper call requires a separate conditional and call-product acceptance boundary.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0087](WIP-0087-bounded-direct-product-publication.md)
- [WIP-0088](WIP-0088-direct-comparison-operand-classifier-adoption.md)
