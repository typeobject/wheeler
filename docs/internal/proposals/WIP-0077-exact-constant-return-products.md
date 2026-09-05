# WIP-0077: Exact constant-return products

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-09-05 |
| Area | Self-hosting compiler, constants, return products |
| Depends on | WIP-0054, WIP-0069, WIP-0075 |
| Supersedes | Local-only source relation for ordinary signed returns |
| Superseded by | None |
| Follow-up | WIP-0079 for signed source literals |

## Summary

Emit an ordinary signed return from one exact module constant product. The relation uses one signed local, `LOCAL_CONST`, and `RETURN_VALUE`. Root returns and one-arm conditional children share the same relation kind and encoder.

`NamedConditionalBases.w` exercises constant children and final constant returns. Its three functions and 159 instructions produce a 4,592-byte artifact that matches stage 0 byte for byte.

## Problem

The scalar relation parser accepts an identifier followed by a semicolon. The direct resolver previously required that identifier to name a source value. A module constant worked only as the right operand of a binary relation or as a declaration initializer.

Opcode mapping modules often return imported constants directly:

```wheeler
if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_ADD_NAMED) {
  return STATEMENT_IF_LOCAL_EQ_LITERAL_ADD_BASE;
}
```

The parser route could lower this source, but the closed product route could not. Treating the constant value as a local index would emit `LOCAL_MOVE` with an arbitrary operand and corrupt the physical coordinate contract.

## Relation kind

`RESULT_RELATION_CONSTANT` names one signed value from an exact constant product.
`DirectScalarRelations.w` resolves the lexical identifier through packed name
bytes and owner, length, type, value, and resolution rows. WIP-0049 removed the
local source-use mapping. Resolution requires one signed match and rejects
ambiguous, unresolved, nonsigned, or non-source relation forms.

Constant lookup precedes local lookup. A module constant therefore keeps the existing precedence over a same-named source value.

`resolveDirectReturnRelation` owns that lookup. Declaration initializers continue to call `resolveDirectScalarRelation` and then use their existing constant initializer path. This boundary prevents a one-local return relation from entering the four-local declaration encoder. It also avoids a constant-symbol scan for every local declaration.

The relation carries the signed value in its left field. It carries no physical source local, operation, or right operand. Consumers must test the relation kind before they interpret that field as a coordinate.

## Encoding

`writeDirectReturn` validates one destination local and emits:

1. `LOCAL_CONST destination, value`
2. `RETURN_VALUE destination`

The extent is 40 code bytes, two instructions, and one signed local. Negative values use signed little-endian encoding.

`directReturnTypesValid` admits the relation only for ordinary callables. Reversible constant returns need explicit result-slot staging and inverse evidence, so this product rejects them.

## Declarations and conditionals

`DirectLongDeclarationProducts.w` retains its existing constant initializer path. It distinguishes binary scalar initializers from the new source constant relation before it delegates to the four-local declaration encoder. Constant declarations still emit their canonical source and named-destination moves.

`DirectConditionalReturnProducts.w` treats a constant child like a preserved source child for width and instruction count. The child uses one local and two instructions, so the complete conditional remains a seven-instruction window. Child type and callable result products remain signed.

## Physical adoption

`NamedConditionalBases.w` maps named comparison and local-condition forms to imported resolved opcode columns. Every guarded arm and final fallback returns one imported signed constant. The direct route consumes only local source and copied constant products.

The full physical product closure compares the 4,592-byte artifact with stage 0. The selected linked subset keeps the same bytes and identity.

## Failure products

A constant candidate fails before publication when no symbol matches, more than one symbol matches, the owner differs, the type is not signed, or the resolution bit is not set. A binary relation with a constant on the left remains outside this product.

Focused fixtures compare root and conditional constant returns byte for byte. Existing declaration fixtures prove that the new relation kind does not steal or widen constant initializers.

## Bootstrap closure

The compiler archive contains 2,955,226 bytes and has identity `1c1fc199fc87071d5341ad5b17a81b3dc0f524b8efe41f2dd01e5d0fcc8cf34e`. The package manifest identity remains `e83091ee70e165f76eefcb2135d2b9620af0906f39affb8a0013e9e60bf894c2`. All four dependent locks name both identities.

The bootstrap module manifest remains 172,543 bytes with 372 modules, two externals, and 1,816 imports. Native validation halts after 71,675,885 transitions under the 73,000,000-transition ceiling.

The 96-product physical subset remains unchanged. It contains 228 functions and 8,286 instructions in 246,040 bytes. Its identity is `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] One exact signed constant relation kind has a documented closed representation.
- [x] Root constant returns emit `LOCAL_CONST` and `RETURN_VALUE` in one local.
- [x] Conditional constant children keep the exact seven-instruction window.
- [x] Constant lookup retains precedence over same-named locals.
- [x] Constant declarations retain their existing canonical code and local widths.
- [x] Return-only constant lookup cannot enter scalar declaration encoding.
- [x] Reversible and nonsigned constant returns fail before publication.
- [x] `NamedConditionalBases.w` matches its 4,592-byte stage-0 artifact byte for byte.
- [x] The complete physical product closure matches stage 0 byte for byte.
- [x] Compiler archive identities, dependent locks, and bootstrap budgets are current.
- [x] A fresh locked workspace build passes.
- [x] Source, documentation, line, and directory-width policy pass.

## Rejected alternatives

### Encode a constant as a source local

Rejected. Constant values and physical local coordinates share an integer carrier but not an identity domain.

### Rewrite the return as a synthetic declaration

Rejected. That adds a destination move and changes code, local, and branch extents.

### Admit constants in every scalar position

Rejected. This product owns a complete source return only. Left-constant binary relations need their own precedence, typing, and encoding contract.

### Stage reversible constants through the ordinary encoder

Rejected. Reversible publication requires presence and payload result slots plus inverse evidence.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0069](WIP-0069-exact-scalar-return-expression-products.md)
- [WIP-0075](WIP-0075-exact-computed-conditional-return-products.md)
