# WIP-0171: Direct void-call operand physical product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, physical closure, void-call operands |
| Depends on | WIP-0049, WIP-0139, WIP-0170 |
| Supersedes | Signature-stub routing for `VoidCallOperands.w` |
| Superseded by | None |

## Summary

Route `VoidCallOperands.w` through direct imported structured products. Three source-local functions retain local helper calls, imported shape queries, signed bounds, packed division and modulo, and exact source selection without generated signature-stub source.

The physical set remains 97 products. The signature-stub set falls from two modules to one.

## Operand decoding

`narrowVoidCallSource` selects direct primary and secondary operands, then calls the imported third-source decoder.

`packedVoidCallSource` decodes four base-256 source digits. Its `first` coordinate selects either the leading or trailing packed operand window.

`voidCallSource` calls the imported arity authority, rejects negative and out-of-range source coordinates, computes all narrow, leading, and trailing candidates, then selects by arity and source position.

The positive `VOID_CALL_MINIMUM_SOURCE_GAP` preserves the strict `source < arity` relation without unsigned arithmetic.

## Calls and relocation

Two imported call sites publish relocations:

- `voidCallThirdSource`
- `voidCallArity`

Calls to `narrowVoidCallSource` and `packedVoidCallSource` remain module-local numeric targets. Every imported target already belongs to the physical callable set.

No dependency source or generated recursive stub enters this product.

## Arithmetic and types

Packed source extraction retains signed division and modulo over fixed positive scales. Arity, source, gap, packed digits, and selected operands retain signed locals. Imported call results retain signed return types.

All branches return one signed source or signed minus one.

## Evidence

`NativeCompilerVoidCallOperandsPhysicalProductExampleTest` derives three source-local functions and the exact instruction count from stage 0. It requires one callable product, two imported relocations, two resolved targets, and successful publication.

`NativeCompilerAssignmentCallOperandsSourceExampleTest` and existing generated-source evidence retain differential coverage for packed operand decoding.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. The linked subset retains 233 functions, 8,556 instructions, 5,987 local types, and 200,384 code bytes. Removing two void-call operand stub names reduces source strings to 428, unique strings to 332, and the container to 252,776 bytes. Two runs reproduce SHA-256 `a5b2b34224890471f58823bed11dd760d12adf74a68ad80d237e3c44bb337e94`. Complete evidence passes in 16 minutes and 26 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] `VoidCallOperands.w` uses the direct imported structured route.
- [x] Three source-local functions retain exact stage-0 instruction prefixes.
- [x] Narrow, leading packed, and trailing packed windows retain exact selection.
- [x] Local calls remain owner local.
- [x] Two imported calls publish and resolve stable identities.
- [x] No dependency source or signature stub enters the product.
- [x] Focused physical evidence passes.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The linked physical subset publishes twice with identical bytes.
- [x] Complete evidence remains below twenty minutes.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Decode packed sources in Java

Rejected. Wheeler source owns the canonical operand relation.

### Merge leading and trailing packed operands

Rejected. They occupy distinct call fields and source-coordinate windows.

### Relocate local decoder calls

Rejected. Artifact-local function IDs already own local calls.

### Keep generated recursive stubs

Rejected. Imported target products already own exact signatures and identities.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0139](WIP-0139-structured-imported-call-product-foundations.md)
- [WIP-0170](WIP-0170-direct-helper-value-kind-physical-product.md)
