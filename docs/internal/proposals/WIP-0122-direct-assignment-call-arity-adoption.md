# WIP-0122: Direct assignment-call arity adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, call assignment |
| Depends on | WIP-0049, WIP-0054, WIP-0056, WIP-0073, WIP-0077, WIP-0079, WIP-0121 |
| Supersedes | Parser projection for `AssignmentCallArities.w` |
| Superseded by | None |

## Summary

Route `AssignmentCallArities.w` through direct source products. Its one function and 121 instructions produce a 3,528-byte artifact that matches stage 0 byte for byte.

The module returns the exact zero- through seven-argument arity for unresolved named assignment calls and resolved target-column identities.

## Product path

`assignmentCallArity` first checks the eight unresolved named identities and returns their exact arities. The seven-argument identity returns the public maximum.

It then rejects values below the resolved zero-argument base and walks the seven internal column boundaries. Each half-open interval returns its arity. A final exclusive assignment-call end admits seven arguments, and the upper tail returns signed minus one.

The complete function contains seventeen one-arm conditional windows and one final literal return. Named identities, target-column bases, the exclusive family end, and the maximum arity remain exact imported products.

## Boundaries

The module classifies identity and arity only. It does not measure source tokens, map arities to columns, decode target indexes, bind arguments, validate signatures, or emit calls.

Gaps below and above the resolved family remain invalid. Every resolved target column remains half open.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module first, before its arity-to-column mapper. The list remains the sole callable-bearing direct-route authority in Java evidence.

No production source or package lock changes belong to this migration. The route consumes existing direct equality, ordering, conditional, constant return, literal return, and final return products only after complete-artifact parity passes.

## Evidence

`NativeCompilerAssignmentCallAritiesPhysicalProductExampleTest` compiles the module with stage 0 and its native product program. It requires atomic publication and compares all 3,528 bytes. Focused physical evidence passes in 4 minutes and 17 seconds.

`NativeCompilerPhysicalClosureExampleTest` compares every selected artifact, validates retained functions and imported relocations, links the exact 96-product subset, repeats publication, and rejects malformed footer and relocation products. It passes in 17 minutes and 51 seconds under the unchanged twenty-minute deadline.

The linked container remains byte-identical with SHA-256 `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] `AssignmentCallArities.w` uses direct source products.
- [x] Its one function and 121 instructions match the 3,528-byte stage-0 artifact.
- [x] All eight unresolved named identities retain exact arities.
- [x] All eight resolved target columns retain exact half-open bounds and arities.
- [x] The public maximum remains the seven-argument authority.
- [x] Values outside both families return exact signed minus one.
- [x] No host range table or column-stride inference becomes semantic authority.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Infer named arity from declaration order

Rejected. Each named statement identity remains an explicit registry product.

### Divide resolved identities by a column width

Rejected. Column bases and the exclusive family end are the semantic boundaries.

### Merge arity classification with column mapping

Rejected. WIP-0121 owns the inverse mapping as a separate product.

### Keep the classifier on parser projection

Rejected. Existing direct equality, ordering, and scalar return products close the artifact.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0077](WIP-0077-exact-constant-return-products.md)
- [WIP-0079](WIP-0079-exact-signed-literal-return-products.md)
- [WIP-0121](WIP-0121-direct-assignment-call-column-adoption.md)
