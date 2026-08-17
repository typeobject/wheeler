# WIP-0096: Direct local-loop classifier adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, migration |
| Depends on | WIP-0049, WIP-0054, WIP-0073, WIP-0087 |
| Supersedes | Parser projection for `ResolvedLocalLoopKinds.w` |
| Superseded by | None |

## Summary

Route `ResolvedLocalLoopKinds.w` through direct source products. Its one function and 11 instructions produce a 776-byte artifact that matches stage 0 byte for byte.

The helper checks whether a resolved opcode belongs to the bounded local `while` column. One lower-bound guard returns `false`. The final less-than return checks the exact computed column end.

## Problem

The source closes one range classifier:

```wheeler
if (opcode < STATEMENT_LOCAL_WHILE_BASE) {
  return false;
}

return opcode < LOCAL_WHILE_END;
```

Parser projection rebuilt the imported lower bound, local computed upper bound, source block, Boolean child, branch coordinates, result types, and final comparison. Existing direct products already own the complete callable.

## Product path

The callable owns one preserved signed `opcode` parameter. Its conditional compares that parameter with the imported signed `STATEMENT_LOCAL_WHILE_BASE` product. The exact child returns Boolean `false` in one seven-instruction window.

The final comparison uses `LOCAL_WHILE_END`, a module-local constant product computed from the imported base, target count, and loop form count. It contributes four instructions across two signed operands and one Boolean result.

Constant evaluation closes before direct relation lookup. The final return consumes the resolved local constant product without rereading source or reconstructing its arithmetic.

## Boundaries

The helper classifies one resolved loop opcode column. It does not parse a loop, decode its target local, measure its body, emit a back edge, or validate bounded progress. WIP-0067 owns exact physical loop coordinates.

The module has no calls, loops in its own body, aggregates, declarations, mutations, ownership effects, inverses, proofs, or result slots.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module before `ResolvedLocalLoopOperands.w`. The ordered list remains the sole callable-bearing direct-route authority in Java evidence.

No production source or package lock changes. The migration changes only physical closure routing after complete-artifact parity passes.

## Evidence

`NativeCompilerResolvedLocalLoopKindsPhysicalProductExampleTest` compiles the module with stage 0 and its native product program. It requires atomic publication and compares all 776 bytes.

The focused evidence passes in 4 minutes and 52 seconds. The complete physical closure compares every selected artifact, validates retained functions and relocations, links the exact 96-product subset, repeats the linker, and rejects malformed footer and relocation products. It passes in 17 minutes and 53 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] `ResolvedLocalLoopKinds.w` uses direct source products.
- [x] Its one function and 11 instructions match the 776-byte stage-0 artifact.
- [x] The lower-bound conditional retains its exact imported constant and false child.
- [x] The final less-than return consumes the exact computed end product.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Decode a target local in this helper

Rejected. This callable only classifies the complete resolved loop column.

### Recompute the upper bound during return lowering

Rejected. `LOCAL_WHILE_END` is a closed module-local constant product.

### Infer loop support from physical body products

Rejected. Syntax classification and physical loop emission have distinct identities and consumers.

### Keep a one-guard helper on parser projection

Rejected. Existing direct condition and scalar products close the complete artifact.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0067](WIP-0067-exact-physical-loop-value-products.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0087](WIP-0087-bounded-direct-product-publication.md)
