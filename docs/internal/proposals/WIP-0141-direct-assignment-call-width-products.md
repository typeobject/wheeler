# WIP-0141: Direct assignment-call width products

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, physical closure, call assignment |
| Depends on | WIP-0049, WIP-0054, WIP-0057, WIP-0139, WIP-0140 |
| Supersedes | Signature-stub physical routing for three assignment-call width modules |
| Superseded by | None |

## Summary

Route the three assignment-call width authorities through direct imported structured products:

- `AssignmentCallCodeWidths.w`
- `AssignmentCallInstructionWidths.w`
- `AssignmentCallLocalWidths.w`

Each module owns one 19-instruction function. Each calls `assignmentCallArity`, rejects signed minus one, computes twice the arity, and adds its exact fixed suffix.

The physical set remains 97 products. Three products move from parser projection with signature stubs to direct source, imported target, and stable relocation products.

## Width authorities

`assignmentCallCodeLength` computes `48n + 64` bytes.

`assignmentCallInstructionCount` computes `2n + 2` instructions.

`assignmentCallLocalCount` computes `2n + 1` temporary locals.

All three functions first bind the imported arity call result to one signed source local. A one-arm signed less-than condition returns minus one for an unknown identity. The final multiplication and addition remain exact scalar source products.

The modules do not infer arity from column spacing. `AssignmentCallArities.w` remains the sole source and resolved identity mapping.

## Routing

The modules remain in `PHYSICAL_CALLABLE_MODULES` and retain their existing product ranks. `DIRECT_SOURCE_MODULES` now selects their manifest owners. The archive executor therefore invokes the WIP-0139 direct imported path instead of generating stubs.

Each product publishes one imported relocation identity for `assignmentCallArity`. No local relocation exists. The final physical linker resolves all three identities to the selected `AssignmentCallArities.w` function product.

The direct imported set now contains four modules. Ten selected imported modules retain signature stubs. Comparable product order and the 97-product footer remain unchanged.

## Bounds

No compiler bound changes. Each module has:

- one local function
- one imported target
- one imported call site
- one relocation frame
- 19 retained instructions
- 16 local registers

`NativeCompilerPhysicalPrograms` accepts a bounded list in its focused callable-product entry point. One native closure setup can therefore test all three products instead of rebuilding identical metadata three times. The extraction also leaves the generated archive program at 968 lines.

## Evidence

`NativeCompilerAssignmentCallWidthsPhysicalProductExampleTest` compiles all three modules in one native transaction. It pins 19 instructions per stage-0 function and requires three retained functions, 57 retained instructions, three direct products, three imported relocations, and three resolved targets. The focused run passes in 4 minutes and 4 seconds under Java 26.

`NativeCompilerPhysicalClosureExampleTest` compares every comparable artifact, validates every retained prefix and relocation, links the exact 97-product subset twice, and rejects malformed footer and relocation products. It passes in 19 minutes and 18 seconds under the unchanged twenty-minute deadline. Function, instruction, local-type, and code counts remain 233, 8,556, 5,987, and 200,384. Removing three stub-only strings reduces source strings to 448, final strings to 352, and the container to 253,984 bytes. The linked SHA-256 identity is `f2f690ab82f9df325112a3af7b9fc4919ae9819365770aeff0d9dc29a41db61e`.

## Acceptance

- [x] All three assignment-call width modules use direct imported products.
- [x] Each retained function matches its 19-instruction stage-0 shape.
- [x] Byte, instruction, and local formulas remain distinct authorities.
- [x] Unknown identities retain signed minus one.
- [x] Exactly three imported relocation identities publish and resolve.
- [x] No dependency source or signature stub enters these products.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The 97-product linked subset publishes twice with identical bytes.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Merge the three formulas

Rejected. Their units and fixed suffixes differ.

### Infer widths in Java evidence

Rejected. The Wheeler modules are compiler authority.

### Keep signature stubs

Rejected. WIP-0139 already closes the direct imported target and relocation path.

### Run three independent native setup transactions

Rejected. One bounded product list supplies stronger shared-closure evidence at lower cost.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0057](WIP-0057-source-call-relocation-and-ownership-coordinate-products.md)
- [WIP-0139](WIP-0139-structured-imported-call-product-foundations.md)
- [WIP-0140](WIP-0140-direct-void-call-syntax-physical-product.md)
