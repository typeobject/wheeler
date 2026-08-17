# WIP-0099: Exact Boolean literal return products

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, scalar products, Boolean semantics |
| Depends on | WIP-0054, WIP-0069, WIP-0073, WIP-0079, WIP-0082 |
| Supersedes | Parser projection for root Boolean literal returns |
| Superseded by | None |

## Summary

Emit exact direct products for `return true;` and `return false;` in ordinary Boolean callables. Boolean literals now share the closed materialized-return encoding with signed literals while retaining Boolean source and local types.

The feature closes leaf predicates whose final answer is a Boolean literal. It does not admit reversible literal returns or treat Boolean values as signed zero and one.

## Source product

`resolveDirectReturnRelation` checks a bounded identifier token against the stable `TOKEN_TRUE` and `TOKEN_FALSE` hashes. A match requires the next token to be the exact terminal semicolon.

The relation product records:

- `RESULT_RELATION_LITERAL` provenance,
- literal value one for `true` or zero for `false`,
- `TOKEN_BOOLEAN` as the left source type,
- no right source, operation, or immediate, and
- a valid product only after exact punctuation passes.

The materialized return encoder emits `LOCAL_CONST` followed by `RETURN_VALUE`. `directReturnType(TOKEN_BOOLEAN)` assigns `TYPE_BOOLEAN` to the sole local. Stage-0 bytecode therefore remains the comparison authority for neither spelling nor type.

## Type boundary

Boolean literal returns remain ordinary-only because materialized returns reject a nonzero reversible callable count. Boolean equality remains a separate two-source relation under WIP-0082.

The resolver does not accept a Boolean literal as a signed operand, an immediate comparison operand, a declaration initializer through this path, or a prefix of a longer return expression.

## Failure and publication

Unknown identifiers continue through constant and local lookup. A recognized Boolean literal without an immediate semicolon yields an invalid relation and prevents the complete direct statement plan from publishing.

The callable artifact remains quarantined until every statement, type row, code byte, function row, section, and final artifact verification succeeds. A malformed Boolean literal return publishes no prefix.

## Bootstrap identities

The compiler archive contains 2,969,980 bytes and has SHA-256 `950531b99dc1808eae8a7d9407a186a792350afcde3dede0b9902ae240ca7482`. All four dependent package locks name that archive. The package manifest identity remains `e83091ee70e165f76eefcb2135d2b9620af0906f39affb8a0013e9e60bf894c2`.

The new `boolean_tokens` dependency raises the bootstrap module manifest to 173,627 bytes, 373 modules, two externals, and 1,833 imports. Its SHA-256 is `c350e80c5c2f4a5e5d83daab56edeaf2037da34965ca955fefbcfde6e309cef2`. Native validation halts after 72,223,344 transitions under the unchanged 73,000,000-transition ceiling. Wheeler-native SHA-256 hashes the manifest in 33,239,462 transitions.

## Evidence

`NativeCompilerStructuredComparisonSourceProductExampleTest` compares complete stage-0 and direct artifacts for both Boolean literals. A malformed `return true false;` fixture traps before publication and leaves artifact length zero.

`NativeCompilerResolvedLocalLoopFormsPhysicalProductExampleTest` exercises `return true;` as the final statement of a physical compiler callable. WIP-0100 records its complete physical adoption evidence.

## Acceptance

- [x] Ordinary `return true;` emits exact direct products.
- [x] Ordinary `return false;` emits exact direct products.
- [x] The result local has `TYPE_BOOLEAN`.
- [x] The product retains literal provenance and Boolean source type.
- [x] A missing terminal semicolon invalidates the complete statement plan.
- [x] Trailing expression tokens cannot enter a Boolean literal return.
- [x] Reversible Boolean literal returns remain invalid.
- [x] Existing Boolean equality and conditional-child rules remain unchanged.
- [x] Failed compilation publishes no artifact prefix.
- [x] Dependent locks and bootstrap graph fixtures name current products.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Resolve Boolean literals as imported constants

Rejected. `true` and `false` are lexical literals with stable token identities, not package symbols.

### Lower literals through signed returns

Rejected. Equal bit patterns do not erase Boolean local type or source provenance.

### Reuse conditional-child parsing

Rejected. A root return owns different statement, local, code, and publication coordinates.

### Admit reversible literal returns

Rejected. Materialization has no preserved source relation for inverse execution.

## References

- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0069](WIP-0069-exact-scalar-return-expression-products.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0079](WIP-0079-exact-signed-literal-return-products.md)
- [WIP-0082](WIP-0082-exact-boolean-equality-products.md)
