# WIP-0074: Direct conditional-classifier adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, migration |
| Depends on | WIP-0049, WIP-0054, WIP-0073 |
| Supersedes | Parser projection for four bounded classifier modules |
| Superseded by | WIP-0075 for classifiers with computed children |

## Summary

Route four physical classifier modules through exact source products:

- `LiteralComparisonOperations.w`
- `ResolvedLocalCopyKinds.w`
- `ResolvedLocalLessThanKinds.w`
- `ResolvedLocalLiteralComparisons.w`

These modules contain 17 functions and 273 instructions in 10,080 artifact bytes. Every artifact matches stage 0 byte for byte. None retains projected dependency source or an imported signature stub.

## Problem

WIP-0073 supplied the missing one-arm conditional return product, but the physical closure used it only for `FourArgumentCalls.w`. Nearby classifier modules still passed closed constant and callable products into the old parser path. That left two implementations for source already covered by direct products.

The Java closure harness also accumulated one `if` and one string replacement for each adopted module. That made migration order a distributed convention. A new direct module needed edits in two distant parts of one generated source transaction.

## Admitted modules

`LiteralComparisonOperations.w` combines signed equality and less-than guards with Boolean-literal returns. Its five functions and 157 instructions produce a 4,880-byte artifact.

`ResolvedLocalCopyKinds.w` contains four bounded range classifiers and no computed early-return child. Its five functions and 45 instructions produce a 1,992-byte artifact.

`ResolvedLocalLessThanKinds.w` contains one bounded range classifier. Its two functions and 12 instructions produce a 792-byte artifact.

`ResolvedLocalLiteralComparisons.w` combines three simple classifiers with one disjoint-range classifier. Its five functions and 59 instructions produce a 2,416-byte artifact.

Each condition consumes signed source values and imported constant products. Each child is exactly `return true;` or `return false;`. Final scalar returns use the existing direct relation product.

## Routing authority

`NativeCompilerPhysicalProductSource` now owns one ordered `DIRECT_SOURCE_MODULES` list. It resolves each module to its physical owner and generates the direct-route checks from that list. Callable-free routing remains data-driven from the exact callable count.

The generated Wheeler transaction no longer carries per-module placeholder names or a replacement chain. Adding a supported module changes one list. Removing parser projection from the production compiler remains a Wheeler-side task under WIP-0054, but closure evidence no longer spreads migration state through generated source text.

## Scope boundary

This migration does not admit computed conditional children. `ResolvedLocalEqualityKinds.w` and `ResolvedLocalInequalityKinds.w` contain signed arithmetic returns inside one-arm conditions. WIP-0075 measures and emits those wider child windows before it moves either module.

This migration also does not admit helper-call conditions or helper-call child returns. WIP-0073 requires a known direct instruction prefix and a four-local parent plus child window.

## Evidence

`NativeCompilerLiteralComparisonOperationsPhysicalProductExampleTest` compares the complete 4,880-byte artifact with stage 0. `NativeCompilerArchiveClosureExampleTest` compares every physical product after all four routes change. It then links the unchanged 96-product subset and retains the same function, instruction, byte, and identity products.

No Wheeler package source changed. The compiler archive identity, module manifest, dependent locks, bootstrap transition budgets, and physical linked-container identity remain unchanged.

## Acceptance

- [x] The four named classifier modules use the direct source-product route.
- [x] All 17 functions and 273 instructions match stage 0 byte for byte.
- [x] A focused literal-comparison artifact test covers equality, less-than, constants, and Boolean-literal children.
- [x] The complete physical product closure matches stage 0 byte for byte.
- [x] One ordered list owns callable-bearing direct-route migration state.
- [x] Generated source carries no per-module route placeholders or replacement chain.
- [x] Computed and call-bearing conditional children remain rejected by this product.
- [x] Source, documentation, line, and directory-width policy pass.

## Rejected alternatives

### Route every classifier with an `if`

Rejected. Several classifiers return arithmetic or helper-call results from the child block. Their source-value widths and instruction windows differ from the WIP-0073 contract.

### Keep one generated `if` replacement per module

Rejected. That repeats migration state and makes stale placeholders a runtime compiler error.

### Infer direct support from module names

Rejected. Names do not prove semantic coverage. The ordered list records only modules with byte-for-byte closure evidence.

### Change the physical subset

Rejected. Migration must change the path, not the selected product bytes. The linked subset identity must remain stable.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
