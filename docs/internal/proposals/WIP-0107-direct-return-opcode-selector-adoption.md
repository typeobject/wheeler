# WIP-0107: Direct return-opcode selector adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, return selection |
| Depends on | WIP-0049, WIP-0054, WIP-0077, WIP-0078, WIP-0099 |
| Supersedes | Parser projection for `ReturnOpcodeKinds.w` |
| Superseded by | None |

## Summary

Route `ReturnOpcodeKinds.w` through direct source products. Its three functions and 83 instructions produce a 2,776-byte artifact that matches stage 0 byte for byte.

The module maps ambiguous scalar comparisons and local-right arithmetic returns to exact signed or literal-right statement opcodes.

## Product path

`signedAmbiguousOpcode` uses one equality condition. Its child returns the signed equality opcode, while the final return selects signed inequality.

`literalComparisonOpcode` uses four equality conditions for Boolean equality, Boolean inequality, signed equality, and signed inequality. Each child returns the corresponding literal-right opcode. The final return selects signed less-than with a literal right operand.

`literalReturnOpcode` uses six equality conditions for add, subtract, multiply, divide, modulo, and XOR local-right forms. Each child returns the corresponding literal-right form. The final return selects bitwise AND.

Each conditional child retains one exact imported statement constant as both source identity and materialized signed return value. No selector infers arithmetic ordering or computes an opcode offset.

## Boundaries

The module maps resolved statement identities. It does not parse an expression, resolve an operand, emit arithmetic bytecode, execute checked arithmetic, or coerce a Boolean result.

Literal-right selection remains explicit for every accepted source form. The default return is source-defined, not a catch-all for unknown opcodes supplied by a caller.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module after `ResultSlotVerifier.w`. The list remains the sole callable-bearing direct-route authority in Java evidence.

No production source or package lock changes belong to this migration. The route consumes existing exact conditions, imported constants, materialized signed returns, and terminal punctuation products only after complete-artifact parity passes.

## Evidence

`NativeCompilerReturnOpcodeKindsPhysicalProductExampleTest` compiles the module with stage 0 and its native product program. It requires atomic publication and compares all 2,776 bytes. Focused physical evidence passes in 4 minutes and 50 seconds.

`NativeCompilerPhysicalClosureExampleTest` compares every selected artifact, validates retained functions and imported relocations, links the exact 96-product subset, repeats publication, and rejects malformed footer and relocation products. It passes in 16 minutes and 45 seconds under the unchanged twenty-minute deadline.

The linked container remains byte-identical with SHA-256 `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] `ReturnOpcodeKinds.w` uses direct source products.
- [x] Its three functions and 83 instructions match the 2,776-byte stage-0 artifact.
- [x] Ambiguous comparison selection retains exact signed opcode identities.
- [x] Literal comparison selection retains all five destination opcode identities.
- [x] Arithmetic selection retains all seven destination opcode identities.
- [x] No selector computes opcode identities from numeric adjacency.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Add a numeric offset to local-right opcodes

Rejected. Statement identities are registry products, not an arithmetic layout contract.

### Merge Boolean and signed comparison selectors

Rejected. Their source and destination statement identities remain distinct.

### Emit arithmetic bytecode in the selector

Rejected. This module selects statement opcodes. Lowering owns instruction emission.

### Keep the selector on parser projection

Rejected. Existing direct conditions, constants, and materialized returns close the artifact.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0077](WIP-0077-exact-constant-return-products.md)
- [WIP-0078](WIP-0078-bounded-direct-conditional-lookups.md)
- [WIP-0099](WIP-0099-exact-boolean-literal-return-products.md)
