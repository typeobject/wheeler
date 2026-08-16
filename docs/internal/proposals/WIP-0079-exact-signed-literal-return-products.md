# WIP-0079: Exact signed-literal return products

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, scalar literals, return products |
| Depends on | WIP-0054, WIP-0069, WIP-0077, WIP-0078 |
| Supersedes | Identifier-only left source in ordinary direct returns |
| Superseded by | None |

## Summary

Emit an ordinary signed return from one exact source literal. The product accepts positive and negative signed literals through the terminal semicolon. It emits `LOCAL_CONST` and `RETURN_VALUE` in one signed local.

Root returns and one-arm conditional children consume the same relation kind. The product prepares direct adoption of bounded arity and opcode-column mapping modules whose fallback is commonly `return -1;`.

## Problem

WIP-0077 distinguished exact constant products from physical source locals. Numeric source literals still failed because `sourceScalarRelation` deliberately parses identifier-led relations. A root `return -1;` had no closed direct relation even though declarations and binary right operands already used the canonical signed-number parser.

Mapping modules expose the gap at their final fallback:

```wheeler
if (arity == MAX_ASSIGNMENT_CALL_ARGUMENTS) {
  return STATEMENT_ASSIGN_CALL_SEVEN_NAMED;
}

return -1;
```

Treating minus as a binary operator requires a nonexistent left source. Treating the literal value as a local coordinate repeats the constant-return category error.

## Relation kind

`RESULT_RELATION_LITERAL` names one exact signed source literal. `resolveDirectReturnRelation` checks the signed token width, exact terminal semicolon, canonical number syntax, and checked signed parse before it publishes the value.

The relation carries the signed value in its left field. It carries `TOKEN_LONG` as its left type and no operation or right operand. Consumers test the kind before they interpret the left field as a physical local.

`resolveDirectScalarRelation` remains identifier-led. Declaration initializers retain their own literal path and widths.

## Encoding

`DirectScalarEncoding.w` classifies constant and literal returns as materialized relations. Both forms emit:

1. `LOCAL_CONST destination, signedValue`
2. `RETURN_VALUE destination`

The extent is 40 code bytes, two instructions, and one local. The writer uses signed little-endian encoding for the value and unsigned encoding for the destination.

The ordinary type validator admits the relation as signed. Reversible callables reject it until a result-slot product stages the literal with matching inverse evidence.

## Conditional children

A signed literal child uses one local and two child instructions. Its parent therefore keeps the seven-instruction conditional window and exact false-branch target.

`ResolvedLoopBodyProducts.w` recognizes the same canonical signed width and semicolon while it classifies the child as a direct candidate. `DirectConditionalReturnProducts.w` performs final relation, type, coordinate, extent, and result-kind validation before publication.

The bounded suffix lookup from WIP-0078 covers a negative literal without widening its seven-token search after `return`.

## Failure products

The product rejects overflow, malformed signs, a missing semicolon, trailing expression tokens, a nonsigned result context, and reversible use. A failed root or child relation leaves code, local types, result kind, and artifact publication unchanged.

Focused fixtures compare `return -1;` at a root and under a signed less-than condition with stage 0 byte for byte. Existing malformed relation fixtures retain atomic failure.

## Closure evidence

The complete physical product closure compiles and compares every selected artifact after the new relation kind enters the compiler package. The selected physical modules keep their existing output bytes. The linked 96-product subset retains its identity.

The closure method remains under its existing twenty-minute deadline. This WIP adds no physical direct-route selection. Mapping-module migration must follow only after closure execution has enough measured deadline headroom.

## Acceptance

- [x] Positive and negative signed literals parse through one exact terminal semicolon.
- [x] Literal returns emit `LOCAL_CONST` and `RETURN_VALUE` in one signed local.
- [x] Root and conditional literal returns match stage 0 byte for byte.
- [x] Conditional literal children retain the exact seven-instruction window.
- [x] Declaration literal handling remains separate and unchanged.
- [x] Reversible literal returns fail before publication.
- [x] The complete physical product closure matches stage 0 byte for byte under its existing deadline.
- [ ] Compiler archive identities, dependent locks, and bootstrap budgets are current.
- [ ] A fresh locked workspace build passes.
- [ ] Source, documentation, line, and directory-width policy pass.

## Rejected alternatives

### Parse minus as a binary return

Rejected. Unary sign belongs to the literal. A binary relation requires a preserved left source.

### Reuse the constant relation kind

Rejected. A source literal and a module constant have different provenance and failure products even though their final instruction forms match.

### Route arity mapping modules immediately

Rejected. The full closure evidence method has a fixed deadline. Direct adoption must not consume the remaining margin without first reducing closure work or splitting its evidence transaction.

### Admit reversible literals through ordinary code

Rejected. Reversible results require explicit presence and payload slots plus inverse evidence.

## References

- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0069](WIP-0069-exact-scalar-return-expression-products.md)
- [WIP-0077](WIP-0077-exact-constant-return-products.md)
- [WIP-0078](WIP-0078-bounded-direct-conditional-lookups.md)
