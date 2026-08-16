# WIP-0076: Direct range-decoder adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, migration |
| Depends on | WIP-0049, WIP-0054, WIP-0075 |
| Supersedes | Parser projection for five bounded range decoders |
| Superseded by | None |

## Summary

Route five more physical compiler modules through direct scalar and conditional products:

- `ResolvedEarlyComparisonKinds.w`
- `ResolvedLiteralComparisonKinds.w`
- `ResolvedLocalLiteralComparisonSources.w`
- `ResolvedLocalPairAssertions.w`
- `ResolvedLongOperations.w`

Their 17 functions and 477 instructions produce 15,760 artifact bytes. The complete physical closure matches every artifact with stage 0 byte for byte.

## Problem

WIP-0075 closed signed computed conditional children and moved two narrow decoders. Five adjacent modules use the same forms over more opcode columns. The old closure still copied their dependency products into projected source and invoked the scalar helper parser.

These modules add no source semantics. They combine ordered imported constants, signed `<` conditions, Boolean-literal children, signed subtraction children, and final scalar returns. Keeping the parser route after direct products covered every statement left duplicate authority in the production closure.

## Adopted products

`ResolvedEarlyComparisonKinds.w` classifies equality and ordering columns for Boolean, signed, local, and computed early returns. Its three-function artifact contains 135 instructions in 4,024 bytes.

`ResolvedLiteralComparisonKinds.w` classifies bounded literal-comparison columns and decodes their packed signed source. Its three-function artifact contains 79 instructions in 2,744 bytes.

`ResolvedLocalLiteralComparisonSources.w` decodes three disjoint literal-comparison ranges. Its two-function artifact contains 23 instructions in 1,128 bytes.

`ResolvedLocalPairAssertions.w` classifies signed and Boolean pair assertions and decodes the packed source. Its four-function artifact contains 45 instructions in 1,928 bytes.

`ResolvedLongOperations.w` classifies and decodes the signed binary and pair-operation columns. Its five-function artifact contains 195 instructions in 5,936 bytes.

## Closed inputs

Each module consumes immutable local source, source-ordered callable coordinates, imported constant values, exact result and parameter types, and the ordered direct-route list. No route reads dependency source.

Conditions resolve their right operands from imported constant products. Computed children resolve subtraction operands and constants through `DirectScalarRelations.w`. Final returns use the same scalar relation authority. Callable composition copies only the closed direct windows.

## Migration rule

A module enters `DIRECT_SOURCE_MODULES` only after the physical closure compares its complete artifact with stage 0. The list remains lexical by semantic module name. Callable-free modules continue to use the callable-count rule and do not appear in the list.

The migration changes the compilation path, not source or output bytes. The compiler package archive, bootstrap module manifest, dependent locks, transition budgets, and physical linked-container identity remain unchanged.

## Scope boundary

Call-conditioned returns remain outside this migration. `ResolvedEarlyResultKinds.w` invokes another classifier inside an `if` condition. The direct condition product requires signed scalar operands and a known source-local instruction prefix. A later call-conditioned product must close call targets, argument windows, result locals, relocations, and branch coordinates together.

A signed constant used as the complete child expression remains outside WIP-0075. WIP-0077 adds that exact relation and routes a constant-return mapping module.

## Evidence

The focused WIP-0075 fixtures cover preserved and binary signed children, literal Boolean children, malformed Boolean comparisons, and multiple-child rejection. `NativeCompilerArchiveClosureExampleTest` then compiles every physical module with the five new route selections. It compares the complete artifacts, retains every local function prefix, links the 96-product subset, verifies the container, and preserves its identity.

## Acceptance

- [x] All five named modules use the direct source-product route.
- [x] Their 17 functions and 477 instructions match 15,760 stage-0 artifact bytes.
- [x] Imported constants resolve without dependency-source projection.
- [x] Signed computed children use exact local widths and branch targets.
- [x] The complete physical product closure matches stage 0 byte for byte.
- [x] Call-conditioned and standalone-constant child forms remain outside this migration.
- [x] Compiler package and physical subset identities remain unchanged.
- [x] Source, documentation, line, and directory-width policy pass.

## Rejected alternatives

### Leave larger decoder tables on the parser route

Rejected. Table size does not change statement semantics. Every admitted statement already has a closed direct product.

### Infer range columns from packed storage order

Rejected. Imported constants and source relations own semantic order. Packed values remain operands, not ordering evidence.

### Move `ResolvedEarlyResultKinds.w` with this set

Rejected. Its call-conditioned branches need products that this migration does not own.

### Add callable-free decoders to the explicit list

Rejected. Exact zero-callable metadata already selects their canonical artifact path without a second list.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0075](WIP-0075-exact-computed-conditional-return-products.md)
