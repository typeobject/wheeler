# WIP-0100: Direct local-loop form adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, loop semantics |
| Depends on | WIP-0049, WIP-0054, WIP-0067, WIP-0096, WIP-0099 |
| Supersedes | Parser projection for `ResolvedLocalLoopForms.w` |
| Superseded by | None |

## Summary

Route `ResolvedLocalLoopForms.w` through direct source products. Its four functions and 21 instructions produce a 1,392-byte artifact that matches stage 0 byte for byte.

The module decodes the condition-source bit, limit-source pair, reversed comparison flag, and direction/update bits from a bounded local-loop form.

## Product path

`localWhileConditionBit` returns `form % CONDITION_FORM_COUNT`. `localWhileLimitPair` returns `form / LIMIT_FORM_DIVISOR`. `localWhileUpdateBits` returns `form % STATEMENT_LOCAL_WHILE_REVERSED_FORM`.

Each arithmetic return preserves its signed `form` parameter, resolves the exact module-local or imported constant product, emits `LOCAL_MOD` or `LOCAL_DIV`, and returns the signed result. No decoder assumes a mask or a host integer layout.

`localWhileReversed` has one lower-bound conditional whose child returns `false`, followed by root `return true;`. WIP-0099 closes the final Boolean literal without parser projection.

## Boundaries

The module decodes an already selected loop form. It does not classify resolved loop opcodes, decode local operands, measure a body, emit instructions, or prove bounded progress.

WIP-0096 owns the resolved loop-column classifier. WIP-0067 owns exact physical loop values, local widths, body windows, and back edges.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module immediately before `ResolvedLocalLoopKinds.w`. The ordered list remains the sole callable-bearing direct-route authority in Java evidence.

No production source or package lock changes belong to this migration. WIP-0099 separately records the Boolean literal return product and resulting compiler identities.

## Evidence

`NativeCompilerResolvedLocalLoopFormsPhysicalProductExampleTest` compiles the module with stage 0 and its native product program. It requires atomic publication and compares all 1,392 bytes. Focused physical evidence passes in 4 minutes and 50 seconds.

`NativeCompilerPhysicalClosureExampleTest` compares every selected physical artifact, validates retained functions and imported relocations, links the exact 96-product subset, repeats publication, and rejects malformed footer and relocation products. It passes in 16 minutes and 30 seconds under the unchanged twenty-minute deadline.

The linked container remains byte-identical with SHA-256 `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] `ResolvedLocalLoopForms.w` uses direct source products.
- [x] Its four functions and 21 instructions match the 1,392-byte stage-0 artifact.
- [x] Modulo and division returns retain exact constant identities.
- [x] The reversed-form predicate retains its false child and final true return.
- [x] No decoder infers bit positions outside source products.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Replace modulo and division with host masks and shifts

Rejected. Source constants and bytecode arithmetic define the loop form.

### Merge form decoding with opcode classification

Rejected. Resolved opcode columns and decoded form values have separate consumers and coordinates.

### Keep the final Boolean literal on parser projection

Rejected. WIP-0099 provides an exact ordinary root return product.

### Route only the arithmetic helpers

Rejected. A physical module enters direct publication only when its complete artifact closes.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0067](WIP-0067-exact-physical-loop-value-products.md)
- [WIP-0096](WIP-0096-direct-local-loop-classifier-adoption.md)
- [WIP-0099](WIP-0099-exact-boolean-literal-return-products.md)
