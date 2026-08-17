# WIP-0095: Direct Boolean declaration-classifier adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, migration |
| Depends on | WIP-0049, WIP-0054, WIP-0073, WIP-0080, WIP-0087 |
| Supersedes | Parser projection for `BooleanDeclarationKinds.w` |
| Superseded by | None |

## Summary

Route `BooleanDeclarationKinds.w` through direct source products. Its one function and 53 instructions produce a 1,840-byte artifact that matches stage 0 byte for byte.

The helper classifies eight parser statement forms that declare nonnegated Boolean locals. Seven one-arm conditional returns precede one final equality return.

## Problem

The classifier names Boolean literal, source, equality, inequality, signed less-than, and signed literal-comparison declaration forms:

```wheeler
if (statementKind == STATEMENT_LOCAL_BOOLEAN) {
  return true;
}

return statementKind == STATEMENT_LOCAL_LONG_LT_LITERAL_NAMED;
```

Parser projection rebuilt every imported statement constant, source block, Boolean child, local coordinate, instruction, type, branch target, and final result. Direct products already close the complete callable.

## Product path

The callable owns one preserved signed `statementKind` parameter. Each condition compares that parameter with one imported signed statement constant. Each exact child returns Boolean `true`.

Seven conditional windows contribute 49 instructions. The final source-constant equality contributes four instructions across two signed operand locals and one Boolean result local. The complete callable contains 53 instructions.

The classifier retains each statement constant independently. It does not infer declaration support from spelling, result type, numeric adjacency, or the direct declaration encoder.

## Boundaries

This helper classifies parser statement products. It does not parse, type-check, allocate, initialize, or encode a Boolean declaration. WIP-0080 owns exact root Boolean declaration bytecode products.

The module has no calls, loops, aggregates, declarations of its own, mutations, ownership effects, inverses, proofs, or result slots.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module first in lexical order. The list remains the sole callable-bearing direct-route authority in Java evidence.

No production source or package lock changes. The migration changes only physical closure routing after complete-artifact parity passes.

## Evidence

`NativeCompilerBooleanDeclarationKindsPhysicalProductExampleTest` compiles the module with stage 0 and its native product program. It requires atomic publication and compares all 1,840 bytes.

The focused evidence passes in 4 minutes and 50 seconds. The complete physical closure compares every selected artifact, validates retained functions and relocations, links the exact 96-product subset, repeats the linker, and rejects malformed footer and relocation products. It passes in 16 minutes and 37 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] `BooleanDeclarationKinds.w` uses direct source products.
- [x] Its one function and 53 instructions match the 1,840-byte stage-0 artifact.
- [x] Seven conditional windows retain exact source and constant order.
- [x] The final equality follows the last child without duplication.
- [x] Imported constants resolve without dependency-source reads.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Infer classifier support from the declaration encoder

Rejected. Parser statement classification and bytecode emission remain distinct source products.

### Group declaration constants by numeric range

Rejected. The registry does not promise one contiguous range for these forms.

### Remove inequality forms because WIP-0080 started with equality

Rejected. The parser classifier records accepted source syntax independently of the current direct emission portfolio.

### Keep a leaf classifier on parser projection

Rejected. Existing direct condition and scalar products close every statement and return.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0080](WIP-0080-exact-root-boolean-declaration-products.md)
- [WIP-0087](WIP-0087-bounded-direct-product-publication.md)
