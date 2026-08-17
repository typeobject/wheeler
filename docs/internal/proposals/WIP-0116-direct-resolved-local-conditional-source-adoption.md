# WIP-0116: Direct resolved local-conditional source adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, conditionals |
| Depends on | WIP-0049, WIP-0054, WIP-0056, WIP-0073, WIP-0075, WIP-0077, WIP-0114 |
| Supersedes | Parser projection for `ResolvedLocalConditionalSources.w` |
| Superseded by | None |

## Summary

Route `ResolvedLocalConditionalSources.w` through direct source products. Its three functions and 117 instructions produce a 3,752-byte artifact that matches stage 0 byte for byte.

The module classifies resolved conditionals that read a prior signed value and selects subtraction or XOR update families.

## Product path

`resolvedLocalConditionalValue` retains the assignment-value lower bound and the final negated XOR-value exclusive end. Its one conditional and final upper-bound return use 11 instructions.

`resolvedLocalConditionalSubtract` checks four disjoint subtraction intervals. Seven one-arm conditions admit each interval and reject its following gap before the final exclusive upper bound. The function uses 53 instructions.

`resolvedLocalConditionalXor` mirrors that product for four XOR intervals and also uses 53 instructions.

Private exclusive-end constants remain source products derived from imported statement bases and the 256-source bound. Direct compilation consumes the resolved values and does not duplicate interval arithmetic in Java.

## Boundaries

The module classifies identity ranges only. It does not decode packed source-local indexes, decide condition negation, bind an assigned value, validate types, or emit update instructions.

Each accepted range remains half open. Nonnegated, negated, immediate-value, and prior-local-value forms remain separate products with exact gaps.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module after the conditional operand decoder. The list remains the sole callable-bearing direct-route authority in Java evidence.

No production source or package lock changes belong to this migration. The route consumes existing direct ordering, conditional, Boolean literal, constant, and final return products only after complete-artifact parity passes.

## Evidence

`NativeCompilerResolvedLocalConditionalSourcesPhysicalProductExampleTest` compiles the module with stage 0 and its native product program. It requires atomic publication and compares all 3,752 bytes. Focused physical evidence passes in 4 minutes and 35 seconds.

`NativeCompilerPhysicalClosureExampleTest` compares every selected artifact, validates retained functions and imported relocations, links the exact 96-product subset, repeats publication, and rejects malformed footer and relocation products. It passes in 16 minutes and 26 seconds under the unchanged twenty-minute deadline.

The linked container remains byte-identical with SHA-256 `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] `ResolvedLocalConditionalSources.w` uses direct source products.
- [x] Its three functions and 117 instructions match the 3,752-byte stage-0 artifact.
- [x] The prior-value region retains exact half-open bounds.
- [x] All four subtraction intervals remain disjoint.
- [x] All four XOR intervals remain disjoint.
- [x] Every gap retains an exact false-child product.
- [x] Private exclusive ends remain resolved source constant products.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Collapse update families into broad ranges

Rejected. Deliberate gaps separate add, subtract, XOR, assignment, and source forms.

### Decode packed locals in this classifier

Rejected. Operand decoders own source-local extraction.

### Derive exclusive ends in Java

Rejected. Source constants remain the interval authority.

### Keep the classifier on parser projection

Rejected. Existing direct ordering and Boolean return products close the artifact.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0075](WIP-0075-exact-computed-conditional-return-products.md)
- [WIP-0077](WIP-0077-exact-constant-return-products.md)
- [WIP-0114](WIP-0114-direct-resolved-local-conditional-classifier-adoption.md)
