# WIP-0086: Direct named scalar-classifier adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, migration |
| Depends on | WIP-0049, WIP-0054, WIP-0073, WIP-0077, WIP-0085 |
| Supersedes | Parser projection for `NamedLocalUpdateKinds.w` and `NamedLongOperations.w` |
| Superseded by | None |

## Summary

Route the two named signed-scalar classifier modules through direct source products.

- `NamedLocalUpdateKinds.w` produces one function and 39 instructions in 1,488 bytes.
- `NamedLongOperations.w` produces five functions and 240 instructions in 6,960 bytes.

Both complete artifacts match stage 0 byte for byte. The modules consume repeated constant-conditioned Boolean or signed returns and final scalar returns whose products already close under the direct path.

## Problem

The frontend classifies unresolved named scalar forms before resolution. Its helper functions contain long source-ordered guard chains:

```wheeler
if (opcode == STATEMENT_LOCAL_LONG_ADD_NAMED) {
  return STATEMENT_LOCAL_LONG_ADD_BASE;
}

return STATEMENT_LOCAL_LONG_AND_BASE;
```

Parser projection duplicated condition, constant, type, branch, and result semantics after source products had already published them. The duplication covered no call, loop, aggregate, mutation, ownership, inverse, proof, or result-slot behavior.

## Modules

### Named local updates

`localUpdateSourceStatement` recognizes six checked update forms. Five exact one-arm conditionals return `true`. The final signed equality returns the sixth classifier result.

### Named long operations

Five helpers classify literal-column bases, two-local column bases, literal binary declarations, local-pair declarations, and global updates. Their conditional children return either Boolean literals or imported signed constants. Final returns use an imported constant or signed equality relation.

The longest helper owns 12 one-arm conditional windows before its final constant return.

## Product rules

Each guard consumes one preserved signed parameter, one imported signed constant, and one exact root block. The parent conditional owns its child return and absolute branch targets. Child statements do not enter structured body products again.

Boolean-literal children use seven-instruction windows. Signed constant children use the same window width with a `LOCAL_CONST` result. Final constant returns use one local and two instructions. Final signed equality returns use three locals and four instructions.

Constant products preserve package, module, dependency, symbol, and lexical identities. The compiler never substitutes raw Java integers or reopens dependency source.

## Routing

The ordered `DIRECT_SOURCE_MODULES` list names both modules after the earlier `named_local_assignment_kinds` route. It remains the only callable-bearing migration authority in Java evidence.

The two modules form one bounded adoption because they share the same named signed-scalar classifier layer and exact product vocabulary. They change no production source or package identity.

## Evidence

`NativeCompilerNamedScalarClassifiersPhysicalProductExampleTest` compiles each complete module with stage 0 and with its native physical product program. It compares every artifact byte and requires atomic publication.

The combined focused evidence passes in 10 minutes and 29 seconds. The complete physical closure compiles every selected module product, compares the entire artifact prefix, validates retained callable products and relocations, and links the unchanged 96-product subset. It passes in 15 minutes and 49 seconds under the existing twenty-minute method deadline.

## Acceptance

- [x] Both named signed-scalar classifier modules use direct source products.
- [x] `NamedLocalUpdateKinds.w` matches its 1,488-byte stage-0 artifact.
- [x] `NamedLongOperations.w` matches its 6,960-byte stage-0 artifact.
- [x] All six functions and 279 instructions retain exact source order.
- [x] Imported constants resolve without dependency-source reads.
- [x] Conditional children enter their parents exactly once.
- [x] The complete physical product closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Source, documentation, line, and directory-width policy pass.

## Rejected alternatives

### Keep signed constant returns on parser projection

Rejected. WIP-0077 already owns exact root and conditional constant result products.

### Merge the classifier functions

Rejected. Each callable has a distinct source identity, signature, order, and consumer.

### Encode statement constants in Java

Rejected. Imported constant products are the semantic authority and preserve package provenance.

### Add more unrelated classifier modules

Rejected. This adoption remains bounded to the named signed-scalar layer. Later routes require separate complete artifact evidence.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0077](WIP-0077-exact-constant-return-products.md)
- [WIP-0085](WIP-0085-root-task-state-specialization.md)
