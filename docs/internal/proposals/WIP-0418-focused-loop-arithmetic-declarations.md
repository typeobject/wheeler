# WIP-0418: Focused loop arithmetic declarations

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-28 |
| Updated | 2026-08-29 |
| Area | Self-hosting, structured loops, signed arithmetic, instruction encoding |
| Depends on | WIP-0049, WIP-0052, WIP-0417 |
| Supersedes | Accidental copy lowering for arithmetic declarations in loop bodies |
| Superseded by | None |

## Summary

Lower checked literal multiplication and two-local addition declarations inside direct structured loop bodies. Reject other operand shapes before the generic copy path can misclassify them.

## Problem

`DirectLoopBodyProducts.w` recognized a `long` declaration by its first source token. An unhandled arithmetic initializer such as:

```wheeler
long product = hash * 31;
```

fell through to local-copy handling. The compiler could therefore publish code that copied `hash` and ignored the multiplication. A following two-local addition had the same ambiguity.

The structured source path needs a closed arithmetic owner before it can compile bounded token hashing. Silent fallback is worse than rejection.

## Design

`LoopBodyOpcodes.w` assigns two disjoint 256-local columns:

- `BODY_LONG_MUL_LITERAL_BASE = 35328`.
- `BODY_LONG_ADD_LOCAL_BASE = 35584`.

`ArithmeticLoopDeclarations.w` owns source recognition and logical operands. It accepts only `RESULT_RELATION_BINARY` with `LOCAL_MUL`, or `RESULT_RELATION_BINARY_SOURCES` with `LOCAL_ADD`. A multiplication with a local right operand and an addition with a literal right operand are recognized as unsupported forms and fail closed. They cannot fall through to copy lowering.

`DirectLoopBodyProducts.w` delegates arithmetic recognition to that focused owner. WIP-0427 also requires the token after a scalar local or literal fallback to be the statement semicolon. Operators outside the focused owner therefore fail instead of entering copy or constant lowering.

`LoopArithmeticInstructionEncoding.w` owns measurement and bytes. Each declaration emits:

1. a move for the left source.
2. a constant or local move for the right source.
3. checked `LOCAL_MUL` or `LOCAL_ADD`.
4. a move into the declared result local.

The exact extent is four signed locals, four instructions, and 104 bytes. `LoopBodyInstructionEncoding.w` delegates to the focused encoder and remains at 865 lines.

Physical projection maps the left coordinate encoded in the opcode and a local right operand independently. Loop insertion rebases both coordinates. Literal operands remain signed values and do not enter local rebasing.

## Evidence

`NativeCompilerStructuredComparisonSourceProductExampleTest` compiles one loop containing an indexed read, literal multiplication, two-local addition, assertions over the result, buffer output, and the loop update. The complete source-local artifact matches stage 0 byte for byte.

Four negative fixtures change multiplication to a local right operand, addition to a literal right operand, and both expressions to subtraction. Every form traps before artifact length, code, identity, or publication changes.

Existing copy, update, assertion, buffer, UTF-8, call, and nested-control loop products retain their opcode ranges.

## Bootstrap identities

The two focused owners raise the compiler graph to 387 modules and 1,931 imports. Its 181,926-byte canonical manifest has SHA-256 `3ab946c43908973379f95b4cff32d03873779d489305212f4906e68103870297`. Native validation halts after 75,749,156 transitions. Wheeler SHA-256 consumes the same bytes in 34,817,790 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,198,504-byte compiler archive has SHA-256 `3b599b5f62d829ad5e84e3fc67538bf00fd59d6c757789ea48821cec2c29b7cb`. Every dependent lock names the new archive.

The selected physical product set remains at the WIP-0416 boundary. This WIP closes a source-product ambiguity and does not add a retained module.

## Failure boundary

Reject an unsupported relation kind, wrong operation, non-signed source, unknown prior local, logical coordinate above 255, malformed arithmetic syntax, failed physical mapping, over-bound local window, or exhausted code buffer before publication. Checked overflow remains a runtime `LOCAL_MUL` or `LOCAL_ADD` trap.

## Acceptance

- [x] Literal multiplication and two-local addition have distinct closed opcode columns.
- [x] Unsupported operand shapes fail instead of lowering as copies.
- [x] Logical left and right coordinates map and rebase independently.
- [x] Measurement, local width, and code emission have one focused owner.
- [x] The positive artifact matches stage 0 byte for byte.
- [x] Unsupported operand and operator fixtures publish no artifact.
- [x] General resolver and encoder files remain below 1,000 lines.
- [x] Manifest, archive, SHA-256, and dependent locks name the focused owners.

## Rejected alternatives

### Reuse the local-copy opcode

A copy has no right operand and cannot preserve overflow semantics.

### Pack a literal and both locals into one operand

A signed 64-bit literal leaves no lossless coordinate field. The opcode column already owns the left local.

### Admit every arithmetic operation at once

Each operation and operand family needs exact negative evidence. This WIP closes the two forms required by bounded token hashing. WIP-0427 closes the scalar fallback, so the remaining matrix is rejected rather than guessed.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0417](WIP-0417-utf8-loop-projection-products.md)
- [WIP-0427](WIP-0427-retained-semver-identifier-comparison-product.md)
