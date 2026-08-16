# WIP-0088: Direct comparison-operand classifier adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, migration |
| Depends on | WIP-0049, WIP-0054, WIP-0073, WIP-0087 |
| Supersedes | Parser projection for `NamedReturnComparisonOperands.w` |
| Superseded by | None |

## Summary

Route `NamedReturnComparisonOperands.w` through direct source products. Its one function and 32 instructions produce a 1,328-byte artifact that matches stage 0 byte for byte.

The classifier recognizes five unresolved comparison returns whose right operand names a prior local. Four exact one-arm conditionals return `true`. The final signed equality returns the fifth result.

## Problem

The parser projection path rebuilt a complete artifact for this source-closed helper:

```wheeler
if (opcode == STATEMENT_RETURN_BOOLEAN_EQ_LOCAL_NAMED) {
  return true;
}

return opcode == STATEMENT_RETURN_SIGNED_LT_LOCAL_NAMED;
```

Direct products already owned every parameter, imported constant, block, statement, local, instruction, type, result, and branch coordinate. Retaining parser projection preserved a duplicate production authority for no unsupported language form.

## Product path

The callable owns one preserved signed parameter. Each conditional consumes one imported signed statement constant and one Boolean-literal child return. The four seven-instruction windows contribute 28 instructions.

The final source-constant equality contributes two retained signed locals, one Boolean result local, `LOCAL_EQ`, and `RETURN_VALUE`. It contributes four instructions and closes the 32-instruction callable.

Imported constants preserve package identity, module identity, dependency rank, symbol identity, signed type, and exact value. The compiler does not infer a contiguous range from statement opcode numbers.

## Boundaries

The source names comparison forms whose right operand is local, but this helper does not execute those comparisons. It compares its signed `opcode` parameter with imported statement constants.

The module has no local calls, imported calls, loops, aggregates, declarations, mutations, ownership effects, inverses, proofs, or result slots.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module after the other `named_*` scalar classifiers. The ordered list remains the only callable-bearing direct-route authority in Java evidence.

No production package source changes. The route affects only physical closure evidence after complete-artifact parity passes.

## Evidence

`NativeCompilerNamedReturnComparisonOperandsPhysicalProductExampleTest` compiles the complete module with stage 0 and its native physical product program. It requires atomic publication and compares all 1,328 bytes.

The focused run passes in 4 minutes and 47 seconds. The complete physical closure compares every selected artifact, validates retained functions and relocations, links the exact 96-product subset, repeats the link, and rejects malformed footer and relocation products. It passes in 15 minutes and 16 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] `NamedReturnComparisonOperands.w` uses direct source products.
- [x] Its one function and 32 instructions match the 1,328-byte stage-0 artifact.
- [x] Four conditional windows retain source order and exact branch targets.
- [x] The final signed equality follows the last child without duplication.
- [x] Imported constants resolve without dependency-source reads.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Infer one numeric range

Rejected. Stable statement identities do not promise contiguous values across these five forms.

### Treat the named right operand as a source local here

Rejected. This helper classifies statement opcodes. The resolved comparison product owns operand locals.

### Keep one leaf helper on parser projection

Rejected. Every statement and return closes under existing direct products.

### Merge this route with larger return classifiers

Rejected. Classifiers with calls or additional arithmetic forms require separate complete-artifact evidence.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0087](WIP-0087-bounded-direct-product-publication.md)
