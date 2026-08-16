# WIP-0075: Exact computed conditional-return products

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, control flow, signed returns |
| Depends on | WIP-0054, WIP-0069, WIP-0073, WIP-0074 |
| Supersedes | Boolean-literal-only child restriction in WIP-0073 |
| Superseded by | None |

## Summary

Extend the root conditional product with an exact signed scalar return child. The child may return a preserved signed source or a checked signed binary relation over a source and a source, constant, or literal.

`ResolvedLocalEqualityKinds.w` and `ResolvedLocalInequalityKinds.w` exercise the computed form. Their eight functions and 72 instructions produce 3,360 artifact bytes that match stage 0 byte for byte.

## Problem

WIP-0073 measured every admitted conditional parent as three locals, but it admitted only a one-local Boolean-literal child. Several range classifiers return a decoded signed source from the guarded arm:

```wheeler
if (opcode < STATEMENT_LOCAL_LONG_EQ_BASE) {
  return opcode - STATEMENT_LOCAL_BOOLEAN_EQ_BASE;
}
```

The old route parsed these complete functions again. Treating the child as a Boolean literal rejected valid source. Treating it as an independent nested body shifted branch targets and duplicated its return.

## Child relation

The child starts with `return` and consumes one complete scalar relation through the exact semicolon. The existing `DirectScalarRelations.w` product resolves identifiers, module constants, signed literals, exact transfer types, and physical source locals. The conditional product accepts only a signed result.

A preserved signed source uses one child local and two instructions. A signed binary relation uses three child locals and four instructions. The binary rows retain the left operand, retain or materialize the right operand, compute the result, and return it. Checked signed arithmetic keeps the ordinary scalar relation rules.

Boolean comparison expressions remain outside this product. WIP-0073 continues to own exact `true` and `false` children. A Boolean expression child fails before code, types, or result kinds publish.

## Coordinates and branches

The parent still owns two signed operand locals and one Boolean condition local. The child begins at `parentBase + 3`. Its measured local width must equal the direct return extent.

The complete instruction count is `5 + childInstructionCount`:

- four condition and branch instructions
- two or four child instructions
- one trailing jump

A literal or preserved-source child therefore uses seven instructions. A binary child uses nine. The false branch and trailing jump target the first instruction after that exact window. The product validates the absolute callable prefix before it writes either target.

The local-type rows preserve source order. The parent contributes signed, signed, and Boolean rows. A binary child contributes signed left, signed right, and signed result rows.

## Nested-body classification

`ResolvedLoopBodyProducts.w` recognizes an exact leaf return under a one-child root `if`. It accepts a Boolean literal or one complete identifier-led scalar relation through the child's terminal semicolon. It omits that child from structured-loop lowering.

`DirectConditionalReturnProducts.w` remains the semantic authority. It resolves the relation, rejects unsupported types and operations, verifies the contiguous physical window, and stages the child with its parent. A syntactic candidate that fails those checks invalidates the artifact.

## Physical adoption

`ResolvedLocalEqualityKinds.w` contains two Boolean-literal conditions and one computed signed condition. Its four-function artifact contains 36 instructions in 1,672 bytes.

`ResolvedLocalInequalityKinds.w` has the same shape with disjoint opcode ranges. Its four-function artifact contains 36 instructions in 1,688 bytes.

Both modules now appear once in the ordered direct-route list. The physical closure compares their complete artifacts with stage 0 and retains the unchanged linked subset identity.

## Failure products

The conditional product reports distinct failures for a nonsigned child result, an invalid direct return type relation, an out-of-range child window, and a failed child encoding extent. The outer direct statement plan retains the source statement and failure code. It publishes no partial rows.

Focused evidence compares a computed signed child byte for byte and rejects a Boolean comparison child. Multiple children remain invalid.

## Acceptance

- [x] Preserved signed-source children use one local and two return instructions.
- [x] Signed binary children use three locals and four return instructions.
- [x] Branch targets consume the exact seven- or nine-instruction parent window.
- [x] Child local types and result kinds derive from the closed scalar relation.
- [x] Boolean comparison children and multiple children publish no artifact.
- [x] `ResolvedLocalEqualityKinds.w` and `ResolvedLocalInequalityKinds.w` match stage 0 byte for byte.
- [x] The complete physical product closure matches stage 0 byte for byte.
- [ ] Compiler archive identities, dependent locks, and bootstrap budgets are current.
- [ ] A fresh locked workspace build passes.
- [ ] Source, documentation, line, and directory-width policy pass.

## Rejected alternatives

### Emit the child as a nested loop-body leaf

Rejected. It would compose the return twice and assign a branch target from the wrong instruction window.

### Fix every computed child at three locals

Rejected. A preserved source needs one local. Width follows the exact direct return extent, not the broad source category.

### Admit Boolean comparison children

Rejected. That changes the conditional result contract and needs dedicated evidence for Boolean expression children. Literal Boolean returns remain explicit.

### Reparse constants in the emitter

Rejected. Module constant products already own name, type, value, resolution, and package identity. The child relation consumes those products.

## References

- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0069](WIP-0069-exact-scalar-return-expression-products.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0074](WIP-0074-direct-conditional-classifier-adoption.md)
