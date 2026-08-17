# WIP-0093: Direct assertion range-decoder adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, migration |
| Depends on | WIP-0049, WIP-0054, WIP-0069, WIP-0073, WIP-0087 |
| Supersedes | Parser projection for three resolved Boolean and assertion range modules |
| Superseded by | None |

## Summary

Route three related resolved range decoders through direct source products.

- `ResolvedBooleanLiteralAssertions.w` produces two functions and 15 instructions in 1,064 bytes.
- `ResolvedBooleanLiteralComparisons.w` produces four functions and 46 instructions in 2,152 bytes.
- `ResolvedLessThanAssertions.w` produces three functions and 26 instructions in 1,456 bytes.

The nine functions and 87 instructions occupy 4,672 artifact bytes. Every byte matches stage 0.

## Problem

These modules classify bounded opcode columns and decode source-local indices. Their helpers use only signed range guards, final signed comparisons, and signed subtraction returns:

```wheeler
if (opcode < STATEMENT_ASSERT_BOOLEAN_LITERAL_BASE) {
  return false;
}

return opcode < ASSERTION_END;
```

```wheeler
return opcode - STATEMENT_ASSERT_BOOLEAN_LITERAL_BASE;
```

Parser projection duplicated imported constant lookup, source block coordinates, Boolean child returns, signed arithmetic, result types, and exact branch targets. Existing direct products close every form.

## Modules

### Boolean literal assertions

One classifier bounds the assertion column. One decoder subtracts the column base and returns the source-local index.

### Boolean literal comparisons

Three classifiers bound equality, inequality, and their combined column range. One decoder selects the equality or inequality base with one exact conditional signed child before its final subtraction.

### Less-than assertions

Two classifiers bound local-right and literal-right assertion columns. One decoder subtracts the literal assertion base.

## Product path

Each function owns one preserved signed `opcode` parameter. Range guards use signed less-than with imported signed constants. Boolean child returns use exact seven-instruction conditional windows.

Signed source-constant subtraction returns use three locals and four instructions. Final less-than returns use the same three-local, four-instruction extent with a Boolean result type.

Constant products preserve package, module, dependency, symbol, type, and value identities. Decoder arithmetic never rereads dependency source or derives a base from storage order.

## Boundaries

These helpers classify and decode resolved statement identities. They do not execute assertions, compare runtime Boolean values, or validate source-local bounds beyond their exact 256-entry opcode columns.

The modules have no calls, loops, aggregates, declarations, mutations, ownership effects, inverses, proofs, or result slots.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names all three modules in lexical order around the earlier resolved comparison routes. The ordered list remains the only callable-bearing direct-route authority in Java evidence.

The three modules form one bounded adoption because they share the resolved assertion and Boolean-literal range layer. No production source or package lock changes.

## Evidence

`NativeCompilerResolvedAssertionRangesPhysicalProductExampleTest` compiles each complete module with stage 0 and its native product program. It requires atomic publication and compares all 4,672 bytes.

Combined focused evidence passes in 14 minutes and 14 seconds. The complete physical closure compares every selected artifact, validates retained functions and relocations, links the exact 96-product subset, repeats the linker, and rejects malformed footer and relocation products. It passes in 16 minutes and 30 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] All three resolved range modules use direct source products.
- [x] Their nine functions and 87 instructions match 4,672 stage-0 bytes.
- [x] Signed less-than guards retain exact source and constant order.
- [x] Boolean and signed child returns retain exact result types.
- [x] Signed subtraction decoders retain exact base constants.
- [x] Imported constants resolve without dependency-source reads.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Decode by masking the opcode

Rejected. Column bases and source-local values are semantic products, not a bit-layout promise.

### Merge Boolean and signed assertion modules

Rejected. Their callable identities, result types, and consumers remain distinct.

### Infer the 256-entry end from the next declaration

Rejected. Each module owns an explicit imported base plus the fixed source-count bound.

### Keep small decoders on parser projection

Rejected. Existing direct condition and scalar products close every function.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0069](WIP-0069-exact-scalar-return-expression-products.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0087](WIP-0087-bounded-direct-product-publication.md)
