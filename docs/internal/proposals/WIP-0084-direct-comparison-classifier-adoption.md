# WIP-0084: Direct comparison-classifier adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, migration |
| Depends on | WIP-0049, WIP-0054, WIP-0073, WIP-0077, WIP-0083 |
| Supersedes | Parser projection for `NamedComparisonKinds.w` |
| Superseded by | None |

## Summary

Route `NamedComparisonKinds.w` through direct source products. Its three functions and 131 instructions produce a 4,040-byte artifact that matches stage 0 byte for byte.

The module exercises repeated root one-arm conditionals rather than one isolated branch. Direct callable composition preserves each conditional window and final scalar return in source order.

## Problem

`NamedComparisonKinds.w` classifies Boolean and signed named comparison statements. Each function consists of zero or more exact guards followed by one final return:

```wheeler
if (opcode == STATEMENT_RETURN_BOOLEAN_EQ_LITERAL_NAMED) {
  return true;
}

return opcode == STATEMENT_RETURN_SIGNED_LT_LOCAL_NAMED;
```

The old physical route parsed the same source again after source products had already established every block, condition, constant, local, type, instruction, and result coordinate.

## Closed product path

Each guard consumes:

- the preserved signed `opcode` parameter
- one imported signed constant product
- one exact root conditional block
- one Boolean-literal child return
- absolute branch targets derived from the measured child extent

The final equality return consumes the preserved parameter and imported constant product. It emits a Boolean result and `RETURN_VALUE` without reopening dependency source.

The module has no calls, loops, aggregates, mutations, ownership effects, inverses, proofs, or result slots. Its imported constants keep package identity, dependency rank, and lexical identity throughout resolution.

## Repeated conditionals

The longest function contains nine one-arm conditionals before its final return. Each conditional owns one contiguous seven-instruction window. Callable instruction planning sums the windows in source order and resolves every branch target against the final callable prefix.

A child block enters only its parent conditional. Structured loop-body products omit the exact direct child by block identity, so no child return appears twice.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module before the other `named_*` authorities. That list remains the only Java evidence authority for migrated callable-bearing physical modules.

The route neither changes compiler package source nor infers support from statement shape. Focused complete-artifact evidence precedes the list entry.

## Evidence

`NativeCompilerNamedComparisonKindsPhysicalProductExampleTest` compiles the complete module with stage 0 and the native physical product program, then compares every artifact byte.

The focused run passes under its evidence deadline. The complete physical closure compiles all selected products, preserves the exact artifact concatenation, retains callable prefixes, resolves relocations, and links the unchanged 96-product subset. It passed in 18 minutes and 47 seconds after WIP-0083 removed no-op observation allocation.

## Acceptance

- [x] `NamedComparisonKinds.w` uses the direct source-product route.
- [x] Its three functions and 131 instructions match the 4,040-byte stage-0 artifact.
- [x] Repeated one-arm conditional windows retain source order and exact branch targets.
- [x] Child returns enter each callable exactly once.
- [x] Imported constants resolve without dependency-source reads.
- [x] The complete physical product closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing closure evidence deadlines remain unchanged.
- [x] Source, documentation, line, and directory-width policy pass.

## Rejected alternatives

### Keep repeated conditionals on the parser route

Rejected. Direct products close every statement and final return in all three functions.

### Merge adjacent guards

Rejected. Each source block has a distinct condition, child identity, source range, and branch target.

### Replace imported constants with integer literals

Rejected. Constant products preserve imported symbol provenance and same-name precedence.

### Raise the closure deadline

Rejected. WIP-0083 removed avoidable VM allocation and restored margin before this route entered the evidence set.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0077](WIP-0077-exact-constant-return-products.md)
- [WIP-0083](WIP-0083-zero-allocation-unobserved-transitions.md)
