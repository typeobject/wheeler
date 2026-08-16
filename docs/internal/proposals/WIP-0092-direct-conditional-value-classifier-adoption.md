# WIP-0092: Direct conditional-value classifier adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, migration |
| Depends on | WIP-0049, WIP-0054, WIP-0073, WIP-0087 |
| Supersedes | Parser projection for `NamedLocalConditionalValues.w` |
| Superseded by | None |

## Summary

Route `NamedLocalConditionalValues.w` through direct source products. Its one function and 53 instructions produce a 1,848-byte artifact that matches stage 0 byte for byte.

The module classifies eight unresolved Boolean-local condition forms that read a prior signed value. Seven one-arm conditional returns precede one final equality return.

## Problem

The classifier owns a complete source-ordered statement identity set:

```wheeler
if (opcode == STATEMENT_IF_LOCAL_ASSIGN_VALUE_NAMED) {
  return true;
}

return opcode == STATEMENT_IF_NOT_LOCAL_XOR_VALUE_NAMED;
```

Parser projection rebuilt every imported constant, source block, Boolean child, local type, instruction window, branch target, and final result. Existing direct products already close the complete callable.

## Product path

The callable owns one preserved signed `opcode` parameter. Each condition compares that parameter with one imported signed statement constant. Each exact Boolean-literal child returns `true`.

Seven conditional windows contribute 49 instructions. The final source-constant equality contributes four instructions across two signed operand locals and one Boolean result local. The complete callable contains 53 instructions.

Source order distinguishes positive and negated assignment, addition, subtraction, and XOR forms. The compiler preserves each constant identity rather than deriving negation or operation families from numeric ranges.

## Boundaries

The helper classifies conditions that later read signed values. It does not resolve or execute the Boolean condition, signed value, global update, or assignment.

The module has no calls, loops, aggregates, declarations, mutations, ownership effects, inverses, proofs, or result slots. Imported constants remain signed package products.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module between named local assignment and update classifiers. The ordered list remains the sole callable-bearing direct-route authority in Java evidence.

No production source or package lock changes. The route changes only physical product evidence after exact artifact parity passes.

## Evidence

`NativeCompilerNamedLocalConditionalValuesPhysicalProductExampleTest` compiles the module with stage 0 and its native product program. It requires atomic publication and compares all 1,848 bytes.

The focused evidence passes in 4 minutes and 41 seconds. The complete physical closure compares every selected artifact, validates retained functions and relocations, links the exact 96-product subset, repeats the linker, and rejects malformed footer and relocation products. It passes in 15 minutes and 43 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] `NamedLocalConditionalValues.w` uses direct source products.
- [x] Its one function and 53 instructions match the 1,848-byte stage-0 artifact.
- [x] Seven conditional windows retain exact source and constant order.
- [x] The final equality follows the last child without duplication.
- [x] Imported constants resolve without dependency-source reads.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Derive negated forms from positive forms

Rejected. Each statement identity remains an independent stable constant product.

### Group assignment and arithmetic forms by numeric range

Rejected. The registry does not promise a contiguous classifier range.

### Resolve the signed value in this helper

Rejected. This callable classifies unresolved statement forms. Later source and resolved products own operand coordinates.

### Keep a one-function module on parser projection

Rejected. Existing direct products close every statement and return.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0087](WIP-0087-bounded-direct-product-publication.md)
