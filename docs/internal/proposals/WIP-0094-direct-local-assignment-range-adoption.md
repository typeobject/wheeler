# WIP-0094: Direct local-assignment range adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, migration |
| Depends on | WIP-0049, WIP-0054, WIP-0069, WIP-0073, WIP-0087 |
| Supersedes | Parser projection for `ResolvedLocalAssignments.w` |
| Superseded by | None |

## Summary

Route `ResolvedLocalAssignments.w` through direct source products. Its four functions and 78 instructions produce a 2,912-byte artifact that matches stage 0 byte for byte.

The module classifies signed and Boolean assignment columns, identifies assignments whose source is a prior local, and decodes the exact target local from four resolved opcode ranges.

## Problem

The resolved assignment helpers use only bounded signed range guards, final less-than returns, and source-constant subtraction:

```wheeler
if (opcode < STATEMENT_LOCAL_ASSIGN_SIGNED_LITERAL_BASE) {
  return false;
}

return opcode < ASSIGNMENT_END;
```

```wheeler
return opcode - STATEMENT_LOCAL_ASSIGN_BOOLEAN_LOCAL_BASE;
```

Parser projection duplicated imported constants, block and statement coordinates, Boolean child results, subtraction results, local types, branch targets, and callable order. Direct products already own every required product.

## Product path

The four callables retain one preserved signed `opcode` parameter each.

- `resolvedLocalAssignment` uses one guard and one final less-than return.
- `resolvedLocalAssignmentNamed` uses three guards and one final less-than return.
- `resolvedLocalAssignmentBoolean` uses one guard and one final less-than return.
- `resolvedLocalAssignmentTarget` uses three guards whose signed children subtract exact column bases, followed by one final subtraction.

Boolean guard children use seven-instruction conditional windows. Signed subtraction children use nine-instruction windows because they retain two operands and one result before returning. Final less-than and subtraction returns use four instructions each.

Imported range bases and ends preserve package, module, dependency, symbol, type, and value identities. The target decoder never masks opcode bits or infers storage adjacency.

## Boundaries

The module classifies and decodes resolved assignment statement identities. It does not execute an assignment, read its source local, mutate its target, or validate a target type.

The module has no calls, loops, aggregates, declarations, mutations, ownership effects, inverses, proofs, or result slots.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module before the resolved local copy and comparison authorities. The ordered list remains the sole callable-bearing direct-route authority in Java evidence.

No production source or package lock changes. The migration changes only physical closure routing after complete-artifact parity passes.

## Evidence

`NativeCompilerResolvedLocalAssignmentsPhysicalProductExampleTest` compiles the module with stage 0 and its native product program. It requires atomic publication and compares all 2,912 bytes.

The focused evidence passes in 4 minutes and 51 seconds. The complete physical closure compares every selected artifact, validates retained functions and relocations, links the exact 96-product subset, repeats the linker, and rejects malformed footer and relocation products. It passes in 17 minutes and 8 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] `ResolvedLocalAssignments.w` uses direct source products.
- [x] Its four functions and 78 instructions match the 2,912-byte stage-0 artifact.
- [x] Signed and Boolean range guards retain exact constant identities.
- [x] Conditional subtraction children retain exact target bases.
- [x] Final less-than and subtraction returns retain exact result types.
- [x] Imported constants resolve without dependency-source reads.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Decode assignment targets by masking

Rejected. Resolved column bases and source-local indices are semantic products, not a bit-layout contract.

### Merge signed and Boolean assignment ranges

Rejected. The helpers preserve distinct source categories and range constants.

### Execute assignment semantics here

Rejected. This module only classifies and decodes statement identities. Lowering owns target mutation and source types.

### Keep target decoding on parser projection

Rejected. Existing direct conditional and scalar products close every function.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0069](WIP-0069-exact-scalar-return-expression-products.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0087](WIP-0087-bounded-direct-product-publication.md)
