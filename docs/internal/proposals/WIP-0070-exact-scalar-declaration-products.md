# WIP-0070: Exact scalar declaration products

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, scalar lowering, declaration products |
| Depends on | WIP-0049, WIP-0054, WIP-0069 |
| Supersedes | First-token projection of scalar declaration initializers |
| Superseded by | None |

## Summary

Lower complete signed scalar declaration initializers from source products. The compiler now measures and emits both operands, the exact binary operation, the expression result, and the named destination before it publishes callable coordinates.

`WideReturnSources.w` enters the physical archive through this route. Its nine callables use local signed values and module-local constants across multiply, divide, remainder, and add relations. The resulting 3,704-byte artifact matches stage 0 byte for byte.

## Problem

The first direct declaration product admitted a literal, a copied local, or `bufferLength`. It also accepted the first token of `long product = value * RADIX;` and emitted a local copy. The remaining operation and operand disappeared while the resulting artifact still passed structural verification.

Module-local constants created another gap. The archive compiler passed direct dependency constants into structured compilation but omitted the selected module's own constant products. Reopening the source declaration as a semantic authority would retain the parser path that WIP-0054 removes.

## Scalar relation product

`SourceReversibleResultRelations.w` now exposes one identifier-led scalar relation parser. Returns and declarations consume that one parser. It admits:

```wheeler
value;
value + other;
value * 256;
value & SOURCE_MASK;
```

The parser binds the exact semicolon. It publishes the left token, right token or signed immediate, operation, and relation kind atomically.

`DirectScalarRelations.w` then binds identifier tokens to the latest visible source value. It maps each value through `StructuredSourceCoordinates.w`. It resolves a closed compile-time constant before a same-named local on the right. That precedence matches stage 0. Without a constant product, it binds the latest visible source value.

## Declaration coordinates

`SourceValueProducts.w` measures four physical locals for a binary signed declaration:

1. copied left operand
2. copied or materialized right operand
3. binary result
4. named destination

`DirectScalarEncoding.w` emits four instructions over that window. The final move preserves the source declaration's named-value identity instead of treating an expression temporary as the declaration result.

Literal and copied-local declarations retain their two-local, two-instruction form. `bufferLength` retains its three-local, three-instruction form. Each form requires its exact terminal semicolon.

## Constant products

`ImportedConstantValues.w` appends the selected module's own scalar products after its direct dependency products. It retains declaration order, type, value, resolution, module identity, and an archive-owned name coordinate.

The archive compiler copies every selected name before it freezes local source. Structured compilation compares the initializer token with that local source-anchored name. It never reads dependency source. Multiple local uses of one constant resolve through the same product.

The packed table remains bounded at 16,384 rows and 1 MiB of copied names. Local products enter only direct source-product compilation. Legacy projected modules retain their prior dependency view.

## Fail-closed behavior

The compiler publishes no statement product when:

- the initializer has missing or trailing tokens
- the operation falls outside the admitted signed scalar set
- either source value has a nonsigned type
- a constant is unresolved, nonsigned, absent, or ambiguous
- a local or destination exceeds bytecode local 255
- the four-local window would exceed local 252
- the encoded statement would exceed 262,144 code bytes
- measured and emitted local widths disagree

Code, local types, statement widths, result values, and artifact bytes remain private on failure.

## Refactoring

`DirectStatementProducts.w` no longer owns duplicate value-coordinate, buffer-type, or packed-assertion mapping code.

- `StructuredSourceCoordinates.w` owns logical-to-physical value mapping.
- `DirectStatementCoordinates.w` owns direct buffer types and assertion opcode rebasing.
- `DirectScalarRelations.w` owns scalar name and product resolution.
- `DirectScalarEncoding.w` owns scalar declaration and return bytes.

No authored source exceeds 1,000 lines or 32,768 bytes.

## Acceptance

- [x] Identifier-immediate and identifier-identifier declarations emit exact four-local windows.
- [x] Module-local and imported signed constants resolve from closed products.
- [x] Compile-time constant products retain precedence over same-named locals.
- [x] Negative signed immediates use canonical signed little-endian encoding.
- [x] Malformed declaration suffixes publish no artifact.
- [x] Return and declaration products share one scalar relation parser.
- [x] `WideReturnSources.w` matches its 3,704-byte stage-0 artifact byte for byte.
- [x] The complete 96-product physical closure matches stage 0 byte for byte.
- [x] The linked 228-function container retains its canonical identity.

## Rejected alternatives

### Parse only the initializer's first token

Rejected. Structural verification cannot detect omitted source semantics.

### Reopen module or dependency source for constants

Rejected. Counted scalar products already carry the required type, value, resolution, and name evidence.

### Publish the expression temporary as the named local

Rejected. Stage 0 emits a final move, and subsequent source values bind the named destination coordinate.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0069](WIP-0069-exact-scalar-return-expression-products.md)
