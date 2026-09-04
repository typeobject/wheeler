# WIP-0143: Direct early-comparison form product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-09-04 |
| Area | Self-hosting compiler, physical closure, early comparisons |
| Depends on | WIP-0049, WIP-0054, WIP-0057, WIP-0139, WIP-0140 |
| Supersedes | Signature-stub physical routing for `EarlyComparisonForms.w` |
| Superseded by | None |
| Follow-up | WIP-0365 nested helper-owner graph execution |

## Summary

Route `EarlyComparisonForms.w` through direct imported structured products. Its sole 11-instruction function calls the selected equality classifier, returns true on a match, then forwards the selected less-than classifier result.

The physical set remains 97 products. One product moves from parser projection with signature stubs to direct source, imported target, and stable relocation products.

## Product

`resolvedEarlyComparisonReturn` receives one signed opcode.

The first call targets `resolvedEarlyEqualityReturn`. A call-conditioned Boolean literal child returns true. The later forwarding call targets `resolvedEarlyLessReturn` and supplies the callable result directly.

WIP-0136 supplies exact instruction-prefix accounting for the direct statement after the first call. WIP-0139 supplies imported target types, identity filtering, and relocation publication.

Both targets are selected comparable physical functions. The linker therefore resolves two stable identities without adding a dependency product.

## Routing

The module retains its imported physical product rank. `DIRECT_SOURCE_MODULES` selects its owner and invokes the direct imported archive path.

The direct imported set now contains eight modules. Six imported modules retain signature stubs. Product membership, retained function count, instruction count, local types, and code bytes remain unchanged.

## Evidence

`NativeCompilerEarlyComparisonFormsPhysicalProductExampleTest` compiles the module through one focused native transaction. It requires one retained function, 11 retained instructions, one product, two imported relocations, and two resolved targets. The focused run passes in 4 minutes and 2 seconds under Java 26.

`NativeCompilerPhysicalClosureExampleTest` compares every comparable artifact, validates every retained prefix and relocation, links the exact 97-product subset twice, and rejects malformed footer and relocation products. It passes in 19 minutes and 45 seconds under the unchanged twenty-minute deadline. Function, instruction, local-type, and code counts remain 233, 8,556, 5,987, and 200,384. Removing two stub-only strings reduces source strings to 443, final strings to 347, and the container to 253,664 bytes. The linked SHA-256 identity is `2d078ef722d6cc916a7a8649492f9f0871efeb507d96abd32e1bf971497268ca`.

## Acceptance

- [x] `EarlyComparisonForms.w` uses direct imported structured products.
- [x] Its retained function matches the 11-instruction stage-0 shape.
- [x] Equality and less-than targets retain separate stable identities.
- [x] The local true child and forwarded final result retain source order.
- [x] Exactly two imported relocations publish and resolve.
- [x] No dependency source or signature stub enters the product.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The 97-product linked subset publishes twice with identical bytes.
- [x] The complete evidence remains below twenty minutes.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Merge equality and less-than classifiers

Rejected. They own distinct resolved opcode families.

### Evaluate both calls eagerly

Rejected. The equality result returns before the less-than call.

### Keep signature stubs

Rejected. WIP-0139 closes the direct imported product path.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0057](WIP-0057-source-call-relocation-and-ownership-coordinate-products.md)
- [WIP-0136](WIP-0136-exact-call-conditioned-signed-literal-products.md)
- [WIP-0139](WIP-0139-structured-imported-call-product-foundations.md)
- [WIP-0140](WIP-0140-direct-void-call-syntax-physical-product.md)
- [WIP-0365](WIP-0365-nested-helper-owner-graph-execution.md)
