# WIP-0090: Direct arithmetic return-classifier adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, migration |
| Depends on | WIP-0049, WIP-0054, WIP-0073, WIP-0087 |
| Supersedes | Parser projection for `NamedReturnArithmeticKinds.w` |
| Superseded by | None |

## Summary

Route `NamedReturnArithmeticKinds.w` through direct source products. Its two functions and 64 instructions produce a 2,256-byte artifact that matches stage 0 byte for byte.

The helpers classify unresolved signed arithmetic returns with literal or local right operands. Each callable uses four exact one-arm conditional returns and one final equality return.

## Problem

The two classifiers share a bounded source shape:

```wheeler
if (opcode < STATEMENT_RETURN_LOCAL_ADD_NAMED) {
  return false;
}

if (opcode < STATEMENT_RETURN_LOCAL_MOD_NAMED) {
  return true;
}
```

They then check the modulus and XOR statement identities before returning equality with the AND identity. Parser projection rebuilt these condition, constant, branch, local, type, and result semantics after direct source products had already closed them.

## Product path

Each callable owns one preserved signed `opcode` parameter. Its first two conditions use signed less-than with imported constants. Its next two conditions use signed equality with imported constants. Boolean-literal children return `false` or `true` in exact source order.

Four seven-instruction conditional windows contribute 28 instructions per callable. The final source-constant equality contributes four instructions. Each callable therefore owns 32 instructions, for 64 instructions across the module.

The literal-right and local-right classifiers retain separate callable identities and constant products. The compiler does not infer one from the other or flatten the two source ranges.

## Boundaries

This module classifies statement identities. It does not execute addition, subtraction, multiplication, division, remainder, XOR, or AND operations.

The module has no calls, loops, aggregates, declarations, mutations, ownership effects, inverses, proofs, or result slots. Imported statement constants remain signed products with exact package provenance.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module between the named long-operation and comparison-operand classifiers. The ordered list remains the sole callable-bearing direct-route authority in Java evidence.

No production source or package lock changes. The route changes only the physical product evidence path.

## Evidence

`NativeCompilerNamedReturnArithmeticKindsPhysicalProductExampleTest` compiles the complete module with stage 0 and its native product program. It requires atomic publication and compares all 2,256 bytes.

The focused evidence passes in 4 minutes and 48 seconds. The complete physical closure compares every selected artifact, validates retained functions and relocations, links the exact 96-product subset, repeats the link, and rejects malformed footer and relocation products. It passes in 15 minutes and 21 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] `NamedReturnArithmeticKinds.w` uses direct source products.
- [x] Its two functions and 64 instructions match the 2,256-byte stage-0 artifact.
- [x] Less-than and equality conditions retain exact operation identities.
- [x] Boolean child returns retain source order and exact branch targets.
- [x] Final equality returns follow their children without duplication.
- [x] Imported constants resolve without dependency-source reads.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Convert the classifier to one broad numeric range

Rejected. The modulus, XOR, and AND identities do not promise one contiguous range.

### Merge literal-right and local-right helpers

Rejected. They have distinct source identities and consumers.

### Execute arithmetic during classification

Rejected. This layer classifies statement products. Resolved lowering owns operand and operation semantics.

### Keep mixed less-than and equality helpers on parser projection

Rejected. Existing direct conditional products close both operations exactly.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0087](WIP-0087-bounded-direct-product-publication.md)
