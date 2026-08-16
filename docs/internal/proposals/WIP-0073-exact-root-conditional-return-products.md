# WIP-0073: Exact root conditional-return products

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, control flow, return products |
| Depends on | WIP-0049, WIP-0054, WIP-0055, WIP-0056, WIP-0069 |
| Supersedes | Parser projection for one-arm root conditional returns |
| Superseded by | None |

## Summary

Emit a root `if` with one Boolean-literal return child from closed source products. The compiler accepts signed `<` and `==` conditions, exact punctuation, one child block, and one `return true;` or `return false;` statement. It maps every operand and temporary through the source-ordered physical coordinate product before it emits code.

`FourArgumentCalls.w` exercises local-to-constant equality and less-than conditions. Its five callables and 39 instructions form a 1,864-byte artifact that matches stage 0 byte for byte.

## Problem

The direct product path treated every root statement with children as a loop. A one-arm early return therefore fell back to parser projection even though scalar relations, return values, source coordinates, and callable composition already had closed products.

The nested child also exposed a measurement error. The old source-value path assigned the parent the aggregate conditional width and then assigned the child again. That shifted every later physical local. Patching the emitted branch operands could not repair callable descriptors or local-type rows after coordinate publication.

## Admitted form

The product accepts only this shape:

```wheeler
if (left < right) {
  return false;
}
```

Equality uses the same shape with adjacent `=` tokens. The left operand must resolve to a signed source value. The right operand may resolve to a signed source value, an exact module constant, or a signed literal. Constant products take precedence over same-named locals.

The parent owns exactly one child block. That block owns exactly one leaf statement. The child begins immediately after the opening brace and ends with a Boolean literal, semicolon, and the parent's closing brace. Extra statements, an `else` arm, a nonliteral return expression, missing punctuation, an unresolved operand, or a noncontiguous physical window invalidates the complete artifact.

Reversible callables reject this product. Ordinary comparison returns have no inverse product.

## Coordinates and code

`SourceValueProducts.w` measures three parent locals and one child result local. `StructuredSourceCoordinates.w` assigns the child immediately after the parent. `DirectConditionalReturnProducts.w` rejects any other arrangement.

The emitted instructions are:

1. retain the signed left operand
2. retain or materialize the signed right operand
3. compare the retained operands
4. branch past the child when the comparison is false
5. materialize the Boolean literal
6. return the literal
7. jump to the instruction after the conditional

The conditional branch and trailing jump use absolute callable instruction coordinates. `DirectStatementProducts.w` therefore admits the product only while the callable instruction prefix remains exact. A prior call, loop, or other separately composed window closes that prefix.

The local-type suffix contains two signed rows followed by the Boolean condition and Boolean child result. Code, types, result kind, child consumption, and failure code stage together.

## Composition

`ResolvedLoopBodyProducts.w` omits only the exact direct conditional child from loop-body lowering. Other nested leaves remain subject to the structured-loop contracts.

`CallableSourceComposition.w` now checks for a direct product before it classifies a root with children as a loop. It consumes the direct window once and never emits the child separately. Leaf calls, leaf direct statements, and structured loops keep their existing source-order rules.

## Failure products

`DirectConditionalReturnProduct` reports a bounded failure code and no extents. `DirectStatementPlan` retains the first failing statement and that code. Neither helper publishes code, type rows, result kinds, or physical widths after a failure.

Focused fixtures cover byte-for-byte valid output, multiple children, and a nonliteral child return. Invalid fixtures leave the artifact length and publication flag at zero.

## Acceptance

- [x] Signed local, constant, and literal condition operands resolve from closed products.
- [x] Less-than and equality conditions emit exact seven-instruction windows.
- [x] The parent and child occupy one contiguous four-local physical window.
- [x] Exact parentheses, braces, comparison tokens, return keyword, Boolean literal, and semicolon validate before emission.
- [x] Multiple children and nonliteral child returns publish no artifact.
- [x] Callable composition consumes the direct parent once and does not emit its child separately.
- [x] `FourArgumentCalls.w` matches its 1,864-byte stage-0 artifact byte for byte.
- [x] The complete physical product closure matches stage 0 byte for byte.
- [ ] Compiler archive identities, dependent locks, and bootstrap budgets are current.
- [ ] A fresh locked workspace build passes.
- [ ] Source, documentation, layout, and directory-width policy pass.

## Rejected alternatives

### Treat every root with children as a loop

Rejected. A conditional return has no back edge, limit local, or loop frame. Inventing those products changes local coordinates and branch targets.

### Flatten the child into the parent measurement

Rejected. The child remains a source statement with its own result local and source coordinate. Flattening it creates a second coordinate authority and breaks failure attribution.

### Recompute branch targets during callable composition

Rejected. Composition must copy closed instruction windows. It cannot reopen source or reinterpret a direct product after type and code publication.

### Admit arbitrary child returns

Rejected. Scalar expressions require wider child windows and different result relations. A later product must specify and test those forms without weakening the literal contract.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0055](WIP-0055-source-ordered-callable-coordinate-products.md)
- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0069](WIP-0069-exact-scalar-return-expression-products.md)
