# WIP-0149: Direct assignment-call kind product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, physical closure, call assignment |
| Depends on | WIP-0049, WIP-0054, WIP-0057, WIP-0139, WIP-0141 |
| Supersedes | Signature-stub physical routing for `AssignmentCallKinds.w` |
| Superseded by | None |

## Summary

Route `AssignmentCallKinds.w` through direct imported structured products. Its four functions and 63 instructions classify source and resolved identity ranges, construct one resolved identity, and recover one signed destination local.

The physical set remains 97 products. One product moves from signature stubs to exact imported target and relocation products.

## Product

`assignmentCallSourceStatement` checks the half-open named source identity range.

`assignmentCallStatement` checks the half-open resolved identity range.

`resolvedAssignmentCall` rejects a negative target, calls `resolvedBase`, and adds a target below the fixed target count.

`assignmentCallTarget` calls `assignmentCallArity`, rejects minus one, calls `resolvedBase`, and subtracts the selected base from the resolved identity.

The first two functions require no imported calls. The latter two functions contribute three relocations in source order: two to `resolvedBase` and one to `assignmentCallArity`.

## Routing

The module retains its imported physical rank. `DIRECT_SOURCE_MODULES` selects its owner and invokes the WIP-0139 direct imported path.

The direct imported set now contains nine modules. Five imported modules retain signature stubs. Every imported target is already a selected comparable function.

## Evidence

`NativeCompilerAssignmentCallKindsPhysicalProductExampleTest` compiles the module through one focused native transaction. It requires four retained functions, 63 retained instructions, one product, three imported relocations, and three resolved targets. The focused run passes in 4 minutes and 5 seconds under Java 26.

`NativeCompilerPhysicalClosureExampleTest` compares every comparable artifact, validates every retained prefix and relocation, links the exact 97-product subset twice, and rejects malformed footer and relocation products. It passes in 19 minutes and 43 seconds under the unchanged twenty-minute deadline. Function, instruction, local-type, and code counts remain 233, 8,556, 5,987, and 200,384. Removing two stub-only strings reduces source strings to 441, final strings to 345, and the container to 253,536 bytes. The linked SHA-256 identity is `9a3fb81e4d75ad52d0ff22deefe636d58d56827ea1de80c1e87a2d96c8c60be9`.

## Acceptance

- [x] `AssignmentCallKinds.w` uses direct imported structured products.
- [x] Four retained functions match 63 stage-0 instructions.
- [x] Named and resolved half-open ranges remain distinct.
- [x] Resolved construction and target recovery retain exact arithmetic.
- [x] Three imported call sites publish and resolve stable identities.
- [x] No dependency source or signature stub enters the product.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The 97-product linked subset publishes twice with identical bytes.
- [x] The complete evidence remains below twenty minutes.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Infer arity from target columns

Rejected. `AssignmentCallArities.w` owns the identity mapping.

### Merge named and resolved ranges

Rejected. They belong to different source and IR phases.

### Keep signature stubs

Rejected. WIP-0139 closes the direct imported boundary.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0057](WIP-0057-source-call-relocation-and-ownership-coordinate-products.md)
- [WIP-0139](WIP-0139-structured-imported-call-product-foundations.md)
- [WIP-0141](WIP-0141-direct-assignment-call-width-products.md)
