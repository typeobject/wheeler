# WIP-0142: Direct void-call form and width products

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, physical closure, void calls |
| Depends on | WIP-0049, WIP-0054, WIP-0057, WIP-0139, WIP-0140 |
| Supersedes | Signature-stub physical routing for void-call forms and widths |
| Superseded by | None |

## Summary

Route three void-call authorities through direct imported structured products:

- `VoidCallSourceForms.w`
- `VoidCallSourceWidths.w`
- `VoidCallWidths.w`

The modules contribute six functions and 343 instructions. Four imported call sites resolve through stable products. Product rank and the 97-product closure membership remain unchanged.

## Source forms

`anyVoidCallSourceStatement` calls the selected zero- through three-argument classifier, then checks the four- through seven-argument named identities directly.

`voidCallSourceArity` maps every named source identity to arity zero through seven. `voidCallSourceKind` maps those arities back to exact identities. Unsupported values return signed minus one.

The first function contributes one imported relocation to `voidCallSourceStatement`. The two mapping functions require only exact constant and literal products.

## Widths

`voidCallLocalCount` maps named source identities to `2n` locals. Resolved identities call `voidCallArity`, reject minus one, and use the same formula. It contributes one imported relocation.

`voidCallCodeLength` maps arities to 16 bytes for zero arguments and `48n + 32` for one through seven arguments.

`voidCallInstructionCount` maps zero arguments to one instruction and otherwise maps to `2n + 1`.

Both resolved width functions call `voidCallArity`, so `VoidCallWidths.w` contributes two imported relocation frames.

## Routing

The three modules remain at their existing imported physical product ranks. `DIRECT_SOURCE_MODULES` selects their manifest owners and the WIP-0139 path publishes their local artifacts without signature stubs.

The direct imported set now contains seven modules. Seven imported modules retain the signature-stub path. Every target of the four new relocations is already present in the comparable physical set.

## Evidence

`NativeCompilerVoidCallFormsAndWidthsPhysicalProductExampleTest` compiles the three modules in one native transaction. It requires six retained functions, 343 retained instructions, three products, four imported relocations, and four resolved targets. The focused run passes in 4 minutes and 10 seconds under Java 26.

`NativeCompilerPhysicalClosureExampleTest` compares every comparable artifact, validates every retained prefix and relocation, links the exact 97-product subset twice, and rejects malformed footer and relocation products. It passes in 19 minutes and 13 seconds under the unchanged twenty-minute deadline. Function, instruction, local-type, and code counts remain 233, 8,556, 5,987, and 200,384. Removing three more stub-only strings reduces source strings to 445, final strings to 349, and the container to 253,792 bytes. The linked SHA-256 identity is `5f4b4797ab4e956b412f3c10b1a4c69d32838ec30aad49022268a114af99b079`.

## Acceptance

- [x] All three modules use direct imported structured products.
- [x] Six retained functions match 343 stage-0 instructions.
- [x] Source identities and arities retain a closed two-way mapping.
- [x] Local, instruction, and code widths retain distinct units.
- [x] Exactly four imported relocations publish and resolve.
- [x] No dependency source or signature stub enters these products.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The 97-product linked subset publishes twice with identical bytes.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Merge source and resolved identities

Rejected. They occupy different registries and different compiler phases.

### Derive code bytes from instruction counts in Java

Rejected. Wheeler source owns both canonical units.

### Keep duplicate signature stubs

Rejected. Direct imported products already preserve target type and identity.

### Raise the physical product count

Rejected. This migration replaces three product routes in place.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0057](WIP-0057-source-call-relocation-and-ownership-coordinate-products.md)
- [WIP-0139](WIP-0139-structured-imported-call-product-foundations.md)
- [WIP-0140](WIP-0140-direct-void-call-syntax-physical-product.md)
