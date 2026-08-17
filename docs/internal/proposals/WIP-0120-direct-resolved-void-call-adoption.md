# WIP-0120: Direct resolved void-call adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, call syntax |
| Depends on | WIP-0049, WIP-0054, WIP-0056, WIP-0069, WIP-0073, WIP-0075, WIP-0118 |
| Supersedes | Parser projection for `VoidCallKinds.w` |
| Superseded by | None |

## Summary

Route `VoidCallKinds.w` through direct source products. Its three functions and 143 instructions produce a 4,280-byte artifact that matches stage 0 byte for byte.

The module owns resolved ordinary void-call identities, classifies their bounded family, decodes the packed third source, and returns exact arities.

## Product path

`voidCallStatement` checks seven fixed statement identities before selecting the half-open three-argument packed column. Its eight conditional windows and final upper-bound return use 60 instructions.

`voidCallThirdSource` rejects values below the packed base, subtracts that base inside the accepted 256-row interval, and rejects values at or above the exclusive limit. It uses 18 instructions.

`voidCallArity` maps seven fixed identities to arities zero, one, two, four, five, six, and seven. It then rejects values below the three-argument base, returns three inside the packed interval, and rejects the upper tail. The function uses 65 instructions.

The packed limit remains a source constant derived from the public base and the public 256-source bound. The maximum arity remains the public source authority for the seven-argument result.

## Boundaries

The module owns resolved identity and arity products only. It does not decode the first two sources, bind targets, validate signatures, emit calls, or publish relocations.

The three-argument interval remains half open. Fixed four- through seven-argument identities remain separate from that column.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module before its unresolved source classifier. The list remains the sole callable-bearing direct-route authority in Java evidence.

No production source or package lock changes belong to this migration. The route consumes existing direct equality, ordering, computed conditional child, arithmetic return, constant return, literal return, and final return products only after complete-artifact parity passes.

## Evidence

`NativeCompilerVoidCallKindsPhysicalProductExampleTest` compiles the module with stage 0 and its native product program. It requires atomic publication and compares all 4,280 bytes. Focused physical evidence passes in 4 minutes and 21 seconds.

`NativeCompilerPhysicalClosureExampleTest` compares every selected artifact, validates retained functions and imported relocations, links the exact 96-product subset, repeats publication, and rejects malformed footer and relocation products. It passes in 17 minutes and 22 seconds under the unchanged twenty-minute deadline.

The linked container remains byte-identical with SHA-256 `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] `VoidCallKinds.w` uses direct source products.
- [x] Its three functions and 143 instructions match the 4,280-byte stage-0 artifact.
- [x] Seven fixed resolved identities remain exact products.
- [x] The packed three-argument interval retains exact half-open bounds.
- [x] Third-source decoding retains exact base subtraction and rejection tails.
- [x] Arity mapping retains exact zero- through seven-argument results.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Treat the packed column as fixed identity

Rejected. Its 256 rows encode the third prior-local source.

### Infer all arities from numeric order

Rejected. Fixed and packed identities occupy different registry regions.

### Merge source and resolved void-call authorities

Rejected. WIP-0118 owns unresolved syntax identities without target resolution.

### Keep the module on parser projection

Rejected. Existing direct scalar and conditional products close the artifact.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0069](WIP-0069-exact-scalar-return-expression-products.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0075](WIP-0075-exact-computed-conditional-return-products.md)
- [WIP-0118](WIP-0118-direct-void-call-source-classifier-adoption.md)
