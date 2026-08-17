# WIP-0114: Direct resolved local-conditional classifier adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, conditionals |
| Depends on | WIP-0049, WIP-0054, WIP-0056, WIP-0073, WIP-0075, WIP-0077 |
| Supersedes | Parser projection for `ResolvedLocalConditionalKinds.w` |
| Superseded by | None |

## Summary

Route `ResolvedLocalConditionalKinds.w` through direct source products. Its four functions and 100 instructions produce a 3,472-byte artifact that matches stage 0 byte for byte.

The module classifies resolved Boolean-local conditional regions, negation, assignments, and assignment-from-local forms.

## Product path

`resolvedLocalConditional` admits the nonnegated add-through-XOR region and the complete negated add-through-XOR-value region. Its three one-arm conditions and final upper-bound return use 25 instructions.

`resolvedLocalConditionalNegated` admits four disjoint negated regions and rejects the gaps between them. Its seven one-arm conditions and final upper-bound return use 53 instructions.

`resolvedLocalConditionalAssignment` and `resolvedLocalConditionalAssignmentValue` each retain one exact lower bound and one exclusive upper bound in 11 instructions.

Private exclusive-end constants remain source products derived from imported statement bases and the 256-source bound. Direct compilation consumes their resolved values without copying the arithmetic into Java.

## Boundaries

The module classifies resolved identity ranges only. It does not decode the conditional source local, decode an assigned value, select an update opcode, validate types, or emit branches.

Every accepted interval remains half open. Gaps between conditional families remain invalid even when adjacent families share an eventual machine opcode.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module before its operand decoder. The list remains the sole callable-bearing direct-route authority in Java evidence.

No production source or package lock changes belong to this migration. The route consumes existing direct ordering, conditional, Boolean literal, constant, and final return products only after complete-artifact parity passes.

## Evidence

`NativeCompilerResolvedLocalConditionalKindsPhysicalProductExampleTest` compiles the module with stage 0 and its native product program. It requires atomic publication and compares all 3,472 bytes. Focused physical evidence passes in 4 minutes and 47 seconds.

`NativeCompilerPhysicalClosureExampleTest` compares every selected artifact, validates retained functions and imported relocations, links the exact 96-product subset, repeats publication, and rejects malformed footer and relocation products. It passes in 17 minutes and 56 seconds under the unchanged twenty-minute deadline.

The linked container remains byte-identical with SHA-256 `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] `ResolvedLocalConditionalKinds.w` uses direct source products.
- [x] Its four functions and 100 instructions match the 3,472-byte stage-0 artifact.
- [x] Nonnegated and negated conditional regions retain exact half-open bounds.
- [x] Gaps between negated regions retain exact false returns.
- [x] Assignment and assignment-value regions remain distinct.
- [x] Private exclusive ends remain resolved source constant products.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Collapse all resolved conditionals into one interval

Rejected. The registry leaves deliberate gaps between several families.

### Derive exclusive ends in Java

Rejected. Source constants are the semantic authority for range boundaries.

### Decode sources in this classifier

Rejected. `ResolvedLocalConditionalSources.w` and operand products own source decoding.

### Keep the classifier on parser projection

Rejected. Existing direct ordering and Boolean return products close the artifact.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0075](WIP-0075-exact-computed-conditional-return-products.md)
- [WIP-0077](WIP-0077-exact-constant-return-products.md)
