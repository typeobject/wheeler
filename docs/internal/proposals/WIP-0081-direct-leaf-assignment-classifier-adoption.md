# WIP-0081: Direct leaf assignment-classifier adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, migration |
| Depends on | WIP-0049, WIP-0054, WIP-0074, WIP-0078 |
| Supersedes | Parser projection for `NamedLocalAssignmentKinds.w` |
| Superseded by | None |

## Summary

Route `NamedLocalAssignmentKinds.w` through direct source products. Its two functions and 12 instructions produce a 792-byte artifact that matches stage 0 byte for byte.

The module is the smallest remaining callable-bearing physical classifier. It proves that the ordered direct-route authority can move a leaf module without changing package source, dependency products, output bytes, or the linked physical subset.

## Problem

The physical closure still selected parser projection for a module whose complete semantics consist of one equality guard, one Boolean-literal child return, and one final equality return:

```wheeler
if (opcode == STATEMENT_ASSIGN) {
  return true;
}

return opcode == STATEMENT_ASSIGN_LOCAL_NAMED;
```

WIP-0073 and WIP-0069 already own these products. Keeping the old route added no coverage and retained duplicate production authority.

## Closed product path

The direct path consumes:

- immutable local source
- one signed parameter product
- imported signed constants
- exact one-arm conditional coordinates
- exact Boolean result products
- canonical callable and string products

The conditional emits its seven-instruction window. The final equality emits two signed operand locals and one Boolean result local. Callable composition publishes the source order once.

The module has no local calls, loops, aggregates, ownership effects, inverses, proofs, or result slots. It needs no projected dependency source or signature stub.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module in lexical semantic order. Callable-free modules remain selected by exact zero-callable metadata.

The route list is evidence, not feature detection. The physical closure must compare the complete artifact before a module enters it.

## Deadline boundary

The full physical product method retains its fixed twenty-minute deadline. The new route passes under that deadline without raising either the JUnit method limit or the Gradle task limit.

This migration consumes the current measured local margin. A later route must first reduce native closure work or split the evidence transaction without weakening complete-product and linked-container checks.

## Evidence

`NativeCompilerNamedLocalAssignmentKindsPhysicalProductExampleTest` compares the complete artifact with stage 0. `NativeCompilerArchiveClosureExampleTest` then compiles every physical product with the new route, compares all artifact bytes, retains exact local function prefixes, and links the unchanged 96-product subset.

No Wheeler package source changed. Compiler and bootstrap archive identities, manifests, locks, transition budgets, and linked subset identity remain unchanged.

## Acceptance

- [x] `NamedLocalAssignmentKinds.w` uses the direct source-product route.
- [x] Its two functions and 12 instructions match the 792-byte stage-0 artifact.
- [x] The route consumes no dependency source or signature stub.
- [x] The complete physical product closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] The existing closure evidence deadline remains unchanged.
- [x] Source, documentation, line, and directory-width policy pass.

## Rejected alternatives

### Leave leaf classifiers on the parser route

Rejected. Closed direct products cover every statement and result.

### Infer support from the absence of loops

Rejected. A loop-free module may still contain calls, unsupported returns, aggregates, or effects. The route list records tested support.

### Raise the closure deadline

Rejected. Migration should remove or bound work before it consumes more test time.

### Add the module to the callable-free path

Rejected. The module owns one source callable. A fabricated empty artifact would discard its semantics.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0074](WIP-0074-direct-conditional-classifier-adoption.md)
- [WIP-0078](WIP-0078-bounded-direct-conditional-lookups.md)
