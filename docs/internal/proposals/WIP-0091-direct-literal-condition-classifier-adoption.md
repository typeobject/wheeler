# WIP-0091: Direct literal-condition classifier adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, migration |
| Depends on | WIP-0049, WIP-0054, WIP-0073, WIP-0087 |
| Supersedes | Parser projection for `NamedLiteralComparisonKinds.w` |
| Superseded by | None |

## Summary

Route `NamedLiteralComparisonKinds.w` through direct source products. Its one function and 53 instructions produce a 1,856-byte artifact that matches stage 0 byte for byte.

The module recognizes eight unresolved signed literal-comparison condition forms. Seven one-arm conditions return `true`. The final equality return classifies the eighth form.

## Problem

The classifier sits between source statement recognition and resolved literal-comparison products. Its implementation is a source-ordered constant guard chain:

```wheeler
if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_ADD_NAMED) {
  return true;
}

return opcode == STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_NAMED;
```

Parser projection reconstructed every imported constant, conditional window, Boolean child return, final equality, local type, and branch coordinate. Existing direct products already close all of those semantics.

## Product path

The callable owns one signed parameter product. Each one-arm conditional consumes the preserved parameter, one imported signed statement constant, one exact root block, and one Boolean-literal child return.

Seven conditional windows contribute 49 instructions. The final signed equality contributes four instructions, for 53 instructions total. The callable uses exact source order and contiguous local windows.

Imported constants preserve package identity, source module identity, dependency rank, symbol identity, signed type, and value. Same-named locals cannot shadow them in return conditions.

## Boundaries

The module has no local or imported calls, loops, aggregates, declarations, mutations, ownership effects, inverses, proofs, or result slots. It does not execute literal comparison operands. It classifies statement opcode constants whose names describe literal forms.

`NamedLiteralComparisonKinds.w` remains distinct from `LiteralComparisonOperations.w`. The former classifies unresolved condition statement kinds. The latter chooses operations during resolved lowering.

## Routing

The ordered `DIRECT_SOURCE_MODULES` list names the module before the other `named_local_*` authorities. The list remains the only callable-bearing migration authority in Java evidence.

No production compiler source or package lock changes. The migration replaces only the physical evidence route after complete artifact comparison.

## Evidence

`NativeCompilerNamedLiteralComparisonKindsPhysicalProductExampleTest` compiles the module through stage 0 and the native product path. It requires atomic publication and compares all 1,856 bytes.

The focused evidence passes in 4 minutes and 43 seconds. The complete physical closure compares every selected artifact, validates retained functions and relocations, links the exact 96-product subset, repeats the linker, and rejects malformed footer and relocation products. It passes in 15 minutes and 19 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] `NamedLiteralComparisonKinds.w` uses direct source products.
- [x] Its one function and 53 instructions match the 1,856-byte stage-0 artifact.
- [x] Seven conditional windows retain source order and exact branch targets.
- [x] The final signed equality follows the last conditional without duplication.
- [x] Imported constants resolve without dependency-source reads.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Treat statement opcode constants as literals

Rejected. Imported constant products carry signed values and package provenance.

### Collapse the guard chain into a range check

Rejected. Statement identities are stable constants, not a promised contiguous range.

### Share parser output with resolved comparison products

Rejected. Parser output would remain a second semantic authority and would couple the artifact to dependency source.

### Route every remaining condition classifier together

Rejected. Each module requires separate complete artifact and closure evidence. Large batches hide unsupported calls or result forms.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0087](WIP-0087-bounded-direct-product-publication.md)
