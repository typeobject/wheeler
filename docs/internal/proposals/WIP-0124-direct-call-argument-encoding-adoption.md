# WIP-0124: Direct call-argument encoding adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-17 |
| Updated | 2026-08-17 |
| Area | Self-hosting compiler, physical closure, call arguments |
| Depends on | WIP-0049, WIP-0054, WIP-0056, WIP-0069, WIP-0073, WIP-0077 |
| Supersedes | Parser projection for `CallArguments.w` |
| Superseded by | None |

## Summary

Route `CallArguments.w` through direct source products. Its two functions and 88 instructions produce a 2,800-byte artifact that matches stage 0 byte for byte.

The module selects one source type from the bounded seven-argument column and selects the exact move or reborrow opcode for that type.

## Product path

`callSourceType` receives one index and seven preserved source-type parameters. Six equality conditional windows return the corresponding first through sixth source. The final return preserves the seventh source. The function uses 44 instructions and 27 physical locals.

`callArgumentOpcode` checks UTF-8, map, region, words, bytes, and byte-view borrow types. Each conditional returns the exact reborrow opcode constant. The final return selects `OPCODE_LOCAL_MOVE`. It also uses 44 instructions.

Every parameter, type identity, opcode identity, condition, child, and final return remains an exact source product. The direct compiler does not build a host switch or infer relationships between nominal borrow types.

## Boundaries

The module selects values and opcodes only. It does not validate callable signatures, bind argument values, allocate transfer locals, emit instructions, resolve targets, or publish relocations.

An index above six selects the seventh source because callers own the zero-through-six bound. Unsupported scalar and owned types select an ordinary local move.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module after `CallArgumentSources.w`. The list remains the sole callable-bearing direct-route authority in Java evidence.

No production source or package lock changes belong to this migration. The route consumes existing direct equality, source-child return, constant-child return, and final return products only after complete-artifact parity passes.

## Evidence

`NativeCompilerCallArgumentsPhysicalProductExampleTest` compiles the module with stage 0 and its native product program. It requires atomic publication and compares all 2,800 bytes. Focused physical evidence passes in 4 minutes and 22 seconds.

`NativeCompilerPhysicalClosureExampleTest` compares every selected artifact, validates retained functions and imported relocations, links the exact 96-product subset, repeats publication, and rejects malformed footer and relocation products. It passes in 18 minutes and 22 seconds under the unchanged twenty-minute deadline.

The linked subset remains byte-identical with SHA-256 `5fc2ddaec2835c516d52d1e8b1254aeaf50789c72d7b42cd0060b026b880ec25`.

## Acceptance

- [x] `CallArguments.w` uses direct source products.
- [x] Its two functions and 88 instructions match the 2,800-byte stage-0 artifact.
- [x] Seven source-type parameters retain exact source order and physical coordinates.
- [x] UTF-8, map, region, words, bytes, and byte-view borrows retain exact identities.
- [x] Reborrow and ordinary move opcodes remain distinct source products.
- [x] No host switch or inferred nominal-type relation becomes semantic authority.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Select arguments through a host array

Rejected. Preserved Wheeler parameters own the source order and physical local identities.

### Merge all borrowed types

Rejected. UTF-8, map, region, and buffer borrows require distinct canonical opcodes.

### Treat byte views as owned bytes

Rejected. A byte view reborrows its backing storage and cannot move ownership.

### Keep the selector on parser projection

Rejected. Existing direct source-child and constant-child products close the artifact.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0069](WIP-0069-exact-scalar-return-expression-products.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0077](WIP-0077-exact-constant-return-products.md)
