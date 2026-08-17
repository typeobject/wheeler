# WIP-0103: Direct conditional-operand decoder adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, conditional operands |
| Depends on | WIP-0049, WIP-0054, WIP-0075, WIP-0078, WIP-0087 |
| Supersedes | Parser projection for `ResolvedLocalConditionalOperands.w` |
| Superseded by | None |

## Summary

Route `ResolvedLocalConditionalOperands.w` through direct source products. Its one function and 40 instructions produce a 1,592-byte artifact that matches stage 0 byte for byte.

The decoder returns the signed local encoded in five resolved conditional opcode regions. It preserves exact subtraction and modulo semantics at each region boundary.

## Product path

The callable owns one preserved signed `opcode` parameter. Four source-ordered less-than conditions divide the resolved conditional space.

- The first child subtracts `STATEMENT_IF_LOCAL_ADD_BASE`.
- The second child reduces the opcode modulo `RESOLVED_SOURCE_COUNT`.
- The third child subtracts `STATEMENT_IF_LOCAL_XOR_BASE`.
- The fourth child again reduces modulo `RESOLVED_SOURCE_COUNT`.
- The final return subtracts `STATEMENT_IF_NOT_LOCAL_XOR_VALUE_BASE`.

Each conditional child retains one exact nine-instruction window: two signed operands, one signed arithmetic result, `RETURN_VALUE`, and the enclosing branch. The final subtraction contributes four instructions. Total width is 40 instructions.

Module-local range ends and source counts resolve through closed constant products. Imported statement bases retain owner, name, type, value, visibility, and dependency identities.

## Boundaries

The module decodes one signed condition local. It does not classify a conditional opcode, decode its Boolean operation, bind a child block, or emit branch bytecode.

The decoder does not mask opcode bits or infer numeric adjacency beyond its named source formulas. WIP-0078 owns bounded source-local and constant lookup for the child arithmetic relations.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module after `ResolvedLocalAssignments.w`. The list remains the sole callable-bearing direct-route authority in Java evidence.

No production source or package lock changes belong to this migration. The route consumes existing direct conditional and scalar products only after complete-artifact parity passes.

## Evidence

`NativeCompilerResolvedLocalConditionalOperandsPhysicalProductExampleTest` compiles the module with stage 0 and its native product program. It requires atomic publication and compares all 1,592 bytes. Focused physical evidence passes in 4 minutes and 46 seconds.

`NativeCompilerPhysicalClosureExampleTest` compares every selected artifact, validates retained functions and imported relocations, links the exact 96-product subset, repeats publication, and rejects malformed footer and relocation products. It passes in 16 minutes and 45 seconds under the unchanged twenty-minute deadline.

The linked container remains byte-identical with SHA-256 `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] `ResolvedLocalConditionalOperands.w` uses direct source products.
- [x] Its one function and 40 instructions match the 1,592-byte stage-0 artifact.
- [x] Four conditional windows retain exact source order and block ownership.
- [x] Subtraction children retain exact statement-base identities.
- [x] Modulo children retain the exact resolved source-count product.
- [x] The final subtraction retains its exact value-form base.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Decode the source local with a bit mask

Rejected. The statement registry defines named arithmetic regions, not a host bitfield contract.

### Flatten all regions into one modulo

Rejected. Literal, source, negated, operation, and value forms use distinct bases.

### Publish one child at a time

Rejected. The complete callable artifact enters publication only after all five regions validate.

### Keep the decoder on parser projection

Rejected. Existing direct conditional, constant, modulo, subtraction, and return products close the artifact.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0075](WIP-0075-exact-computed-conditional-return-products.md)
- [WIP-0078](WIP-0078-bounded-direct-conditional-lookups.md)
- [WIP-0087](WIP-0087-bounded-direct-product-publication.md)
