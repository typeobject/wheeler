# WIP-0135: Exact call-conditioned constant-return products

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-09-04 |
| Area | Self-hosting compiler, calls, conditionals, scalar products |
| Depends on | WIP-0049, WIP-0054, WIP-0056, WIP-0057, WIP-0062, WIP-0077, WIP-0123 |
| Supersedes | Signed-constant child gap in WIP-0123 |
| Superseded by | None |
| Follow-up | WIP-0136 extends the product to signed literal children |

## Summary

Extend exact helper-call conditions from Boolean literal children to signed constant children. A closed product now compiles:

```wheeler
if (helper(value)) {
  return LIMIT;
}
```

The helper result remains Boolean. `LIMIT` is one uniquely resolved signed symbol owned by the selected module. Its value, type, owner, source spelling, and resolution bit arrive through counted symbol products. No dependency source or parser projection enters the call window.

This closes the remaining product needed to route `EarlyReturnKinds.w` directly. The module's `sourceEarlyReturnLocalCount` helper calls `earlyReturnStatement` and returns the imported constants `EARLY_RETURN_LOCAL_COUNT` and `EARLY_COMPUTED_RETURN_LOCAL_COUNT` on distinct paths.

## Product boundary

`DirectCallConditionalReturns.w` already owns the exact parent condition, call punctuation, child block, child statement, source extent, and physical adjacency checks from WIP-0123. The extension adds the selected module owner and counted symbol columns to that validator.

A nonliteral child is accepted only when `resolveDirectReturnConstant` finds exactly one product with:

- the selected module owner
- the exact source-anchored name
- signed type
- resolved value state
- a bounded name range

A missing, duplicate, unresolved, Boolean, foreign-owner, or out-of-range product invalidates the complete direct-statement transaction. The validator does not publish a call kind, child value, result type, local type, instruction, or relocation on failure.

Boolean `true` and `false` remain their own call kinds. Signed constants use `CALL_CONDITION_SIGNED_CONSTANT`. The kind states the layout relation. A separate 256-entry value column carries the exact signed result. WIP-0136 adds a distinct signed literal kind to the same column.

## Emission

A call-conditioned child keeps the WIP-0123 shape for arity `n`:

- `2n + 1` call locals
- one separately measured child local
- `2n + 5` instructions
- `48n + 120` code bytes

Argument preservation and transfer produce the Boolean call result. `JUMP_IF_ZERO` skips the child. The child local receives the signed product value through `LOCAL_CONST`, returns it, and reaches the existing terminal jump.

`LoopCallProducts.w` validates the value column before emission. False and true kinds require zero and one respectively. Kinds without a conditional child require zero. The signed kind permits the complete signed value domain. Its child local type is signed while its call-result local remains Boolean.

`DirectStatementProducts.w` stages call kinds, values, function result types, local types, physical widths, and code together. `StructuredSourceModuleCompiler.w` owns the value column for both preliminary and final call emission and drops it with the rest of the product arena.

## Scanner bound

The structured orchestrator remains below the fixed 4,096-token source limit. Redundant `length` labels were removed from a contiguous allocation ledger. Variable names and exact capacities remain adjacent. The limit was not raised to hide orchestration growth.

## Adoption

`EarlyReturnKinds.w` now enters through direct structured source products. Its two source functions contain 139 instructions and compile to a 4,104-byte artifact with the canonical inert library entry.

The second function contains the decisive window: instruction 37 calls `earlyReturnStatement`, instruction 38 branches on the Boolean result, and instruction 39 loads signed constant value four. The complete artifact still matches stage 0 byte for byte.

The callable-bearing direct-route set now contains 63 modules. The selected physical set remains 83 comparable products plus 13 signature-stub products. This WIP changes a compilation route, not the 96-product closure membership.

## Evidence

`NativeCompilerStructuredCallSourceProductExampleTest` emits a signed constant child behind an imported Boolean call. A Boolean symbol product for the same child fails before artifact publication.

`NativeCompilerEarlyReturnKindsPhysicalProductExampleTest` compiles `EarlyReturnKinds.w` through stage 0 and the native archive-product program. It checks the call and signed child in the stage-0 body, requires atomic native publication, and compares all 4,104 bytes. The focused native run passes in 4 minutes and 17 seconds under Java 26.

`NativeCompilerPhysicalClosureExampleTest` compares every selected artifact, validates retained prefixes and relocations, links the exact 96-product subset twice, and rejects malformed footer and relocation products. It passes in 17 minutes and 57 seconds under the unchanged twenty-minute deadline. The linked identity remains `5fc2ddaec2835c516d52d1e8b1254aeaf50789c72d7b42cd0060b026b880ec25`.

The compiler archive contains 2,984,068 bytes with SHA-256 `5806fba1a4a9c0adca4f67d5796e13a1c005d79bcf43adfd380c1c5d6bc23449`. Exact dependent locks name that archive. The compiler manifest identity remains `e83091ee70e165f76eefcb2135d2b9620af0906f39affb8a0013e9e60bf894c2`.

## Acceptance

- [x] Exact helper-call conditions admit uniquely resolved signed constant children.
- [x] Boolean literal and signed constant children retain distinct semantic kinds.
- [x] The call result remains Boolean and the constant child local is signed.
- [x] Exact signed values cross planning and both emission passes without source reopening.
- [x] Missing, duplicate, unresolved, Boolean, and foreign-owner symbols fail before publication.
- [x] Nonconditional call kinds reject a nonzero child value.
- [x] Call, child, local, instruction, byte, branch, and relocation extents remain unchanged.
- [x] `EarlyReturnKinds.w` matches its complete 4,104-byte stage-0 artifact.
- [x] Every selected physical artifact and the linked subset match stage 0.
- [x] Repeated linked publication is byte-identical.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, formatter, readability, Tree-sitter, source length, and layout policy pass.

## Rejected alternatives

### Reclassify signed constants as Boolean literals

Rejected. The call result controls the branch. The child result sets the callable result. They have different types and different source authority.

### Store the value in the call kind

Rejected. Kinds describe a closed layout family. Signed values are data and span the complete signed domain.

### Resolve the child during byte emission

Rejected. Type, width, function result, and atomic publication decisions close before emission.

### Reopen dependency source

Rejected. Counted symbol products already carry owner, spelling, type, value, and resolution evidence.

### Raise the scanner token limit

Rejected. Removing redundant allocation labels keeps the orchestrator inside the existing recovery bound.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0057](WIP-0057-source-call-relocation-and-ownership-coordinate-products.md)
- [WIP-0062](WIP-0062-atomic-source-call-link-publication.md)
- [WIP-0077](WIP-0077-exact-constant-return-products.md)
- [WIP-0123](WIP-0123-exact-call-conditioned-literal-return-products.md)
- [WIP-0136](WIP-0136-exact-call-conditioned-signed-literal-products.md)
