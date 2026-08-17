# WIP-0108: Direct Boolean token-classifier adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, lexical products |
| Depends on | WIP-0049, WIP-0054, WIP-0073, WIP-0099 |
| Supersedes | Parser projection for `BooleanTokens.w` |
| Superseded by | None |

## Summary

Route `BooleanTokens.w` through direct source products. Its one function and 11 instructions produce a 752-byte artifact that matches stage 0 byte for byte.

The classifier accepts only the stable token hashes for `true` and `false`.

## Product path

`booleanLiteralToken` owns one preserved signed `hash` parameter. One equality condition compares it with `TOKEN_TRUE`. The exact child returns Boolean `true`. The final return compares the same source with `TOKEN_FALSE`.

The conditional window contributes seven instructions. The final signed equality contributes four instructions across two signed operands and one Boolean result local.

Both token identities remain module-local constant products. The classifier does not compare source spelling, infer hash adjacency, or coerce token hashes to Boolean values.

## Boundaries

The module classifies a hash that an earlier lexer product computed. It does not scan UTF-8, calculate a token hash, parse a literal, emit a Boolean constant, or select a result local.

WIP-0099 owns exact ordinary root Boolean literal returns. This module only decides whether a token hash names one of those literals.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module after `BooleanDeclarationKinds.w`. The list remains the sole callable-bearing direct-route authority in Java evidence.

No production source or package lock changes belong to this migration. The route consumes existing direct equality, conditional child, Boolean literal, and final return products only after complete-artifact parity passes.

## Evidence

`NativeCompilerBooleanTokensPhysicalProductExampleTest` compiles the module with stage 0 and its native product program. It requires atomic publication and compares all 752 bytes. Focused physical evidence passes in 4 minutes and 38 seconds.

`NativeCompilerPhysicalClosureExampleTest` compares every selected artifact, validates retained functions and imported relocations, links the exact 96-product subset, repeats publication, and rejects malformed footer and relocation products. It passes in 16 minutes and 28 seconds under the unchanged twenty-minute deadline.

The linked container remains byte-identical with SHA-256 `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] `BooleanTokens.w` uses direct source products.
- [x] Its one function and 11 instructions match the 752-byte stage-0 artifact.
- [x] The `true` condition retains the exact token-hash constant.
- [x] The child retains exact Boolean literal type and block ownership.
- [x] The final equality retains the exact `false` token-hash constant.
- [x] No source spelling or hash adjacency is inferred.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Compare token source text

Rejected. The caller supplies one closed token-hash product.

### Treat every nonzero hash as true

Rejected. Only two stable lexical identities are Boolean literals.

### Compute `TOKEN_FALSE` from `TOKEN_TRUE`

Rejected. Hash identities have no arithmetic relationship contract.

### Keep a one-condition classifier on parser projection

Rejected. Existing direct equality, condition, and Boolean return products close the artifact.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0099](WIP-0099-exact-boolean-literal-return-products.md)
