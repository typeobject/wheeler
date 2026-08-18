# WIP-0123: Exact call-conditioned literal-return products

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-17 |
| Updated | 2026-08-17 |
| Area | Self-hosting compiler, calls, conditionals, physical closure |
| Depends on | WIP-0049, WIP-0054, WIP-0056, WIP-0057, WIP-0062, WIP-0073, WIP-0099 |
| Supersedes | Parser projection for root helper-call conditions with literal returns |
| Superseded by | WIP-0135 extends the product to signed constant children |

## Summary

Compile exact root `if (helper(args)) { return true; }` and `return false;` products from closed call, block, statement, local, type, target, and source-coordinate products.

The call window now owns the complete conditional. It emits argument preservation, typed transfer, one Boolean call result, the branch, one literal child local, the child return, and the terminal jump. No parser-shaped source or post-emission patch supplies missing control flow.

## Source product

`DirectCallConditionalReturns.w` accepts one root conditional only when all of these facts hold:

- the condition begins with exact `if` and opening punctuation
- one resolved call name starts at the exact call product coordinate
- balanced call punctuation consumes the complete condition expression
- one opening brace owns one exact child block
- the child block owns one statement and no nested child
- that statement is exact `return true;` or `return false;`
- the semicolon closes the child statement extent
- the closing brace closes the parent statement extent
- parent and child physical locals are contiguous
- the parent call width and one-local child width match measured products

The validator does not rediscover a target, arity, argument, type, or call statement. Those facts arrive from existing call products.

## Call kinds

`SourceCallLayoutProducts.w` publishes two named semantic kinds:

- `CALL_CONDITION_FALSE_BOOLEAN`
- `CALL_CONDITION_TRUE_BOOLEAN`

A call-conditioned product with arity `n` owns `2n + 1` call locals and one separately measured child local. Its complete code window contains `2n + 5` instructions and `48n + 120` bytes.

The call result remains Boolean. The child local remains Boolean. The condition kind never aliases signed results, ordinary value calls, forwarded call results, or void calls.

## Coordinates and relocation

`DirectStatementProducts.w` stages condition-kind changes with all other direct publication. Failure leaves the caller's resolved call rows, result types, direct rows, physical widths, types, and code unchanged.

`SourceCallInstructionProducts.w` calculates the complete source-ordered window. `LoopCallProducts.w` emits an absolute branch target at the instruction immediately after the terminal jump. The relocation continues to name the call instruction at `instructionStart + 2n`.

`CallableSourceComposition.w` admits the complete call window for a root statement that owns one child. It consumes that call exactly once and never also consumes the child as a direct product.

## Boundaries

This WIP's implemented child is one Boolean literal return. WIP-0135 adds a uniquely resolved signed constant child. WIP-0136 adds a signed literal child and exact later-direct prefix accounting. Source returns, computed children, nested blocks, negated helper calls, Boolean equality around calls, call results combined with another relation, and reversible call-conditioned returns remain outside the product.

The helper call may carry zero through seven already resolved scalar arguments. Existing target and signature products decide whether the call returns Boolean before this product runs.

## Adoption

`OpcodeKinds.w` now enters through direct products. `isLocalMathOpcode` preserves one signed argument, calls the exact local Boolean classifier, branches on its result, returns `true` in the child, and then performs the final opcode equality. Its four functions and 100 instructions match the 3,336-byte stage-0 artifact.

`ResolvedEarlyResultKinds.w` now enters through direct products. Its local helper-call conditions compose with the existing range products without flattening callable identity. Its eight functions and 249 instructions match the 7,728-byte stage-0 artifact.

The callable-bearing direct-route set now contains 59 modules. Seventeen callable-free physical modules continue to use their dedicated direct emitter.

## Evidence

`NativeCompilerStructuredCallSourceProductExampleTest` compares an exact false-child call condition with stage 0. A second fixture adds another child statement and proves that publication remains empty.

`NativeCompilerOpcodeKindsPhysicalProductExampleTest` and `NativeCompilerResolvedEarlyResultKindsPhysicalProductExampleTest` compare complete artifacts byte for byte. Their focused runs pass in 4 minutes and 24 seconds and 4 minutes and 55 seconds.

`NativeCompilerPhysicalClosureExampleTest` compares every selected physical artifact, validates retained products and relocations, links the exact 96-product subset, repeats publication, and rejects malformed footer and relocation products. It passes in 18 minutes and 33 seconds under the unchanged twenty-minute deadline.

The subset retains 228 functions, 8,286 instructions, 5,729 local types, 193,736 code bytes, and a 246,040-byte container. Adding the new compiler module changes the package archive carried by artifact manifests. The resulting linked identity is `5fc2ddaec2835c516d52d1e8b1254aeaf50789c72d7b42cd0060b026b880ec25`.

The compiler archive contains 2,981,184 bytes with SHA-256 `29c5b6f0a6482f71be6d1603b31fce4638578ebafa3beebd9092e40986559a61`. The package manifest identity remains `e83091ee70e165f76eefcb2135d2b9620af0906f39affb8a0013e9e60bf894c2`.

The bootstrap module manifest contains 174,302 bytes, 374 modules, two externals, and 1,841 imports. Its SHA-256 is `a0f48138321a93a19797bc4c8352d61661a4c1302eba001b14861d6cb9653c66`. Native validation halts after 72,576,797 transitions under the unchanged 73,000,000 ceiling. Wheeler-native SHA-256 uses 33,360,580 transitions.

## Acceptance

- [x] Exact local Boolean call conditions publish without parser projection.
- [x] True and false literal children retain distinct semantic call kinds.
- [x] Call, child, type, instruction, byte, branch, and relocation extents remain exact.
- [x] Balanced call punctuation consumes the complete condition.
- [x] Parent and child source extents retain exact closing punctuation.
- [x] Parent and child physical locals remain contiguous.
- [x] Reversible call-conditioned returns fail closed.
- [x] Multiple children fail before partial publication.
- [x] `OpcodeKinds.w` matches its complete stage-0 artifact.
- [x] `ResolvedEarlyResultKinds.w` matches its complete stage-0 artifact.
- [x] Every selected physical artifact and the linked subset match stage 0.
- [x] Repeated linked publication is byte-identical.
- [x] Existing evidence deadlines remain unchanged.
- [x] Package locks and bootstrap identity fixtures name the current archive.
- [x] Documentation, formatter, readability, Tree-sitter, source length, and layout policy pass.

## Rejected alternatives

### Treat the call as a forwarded return

Rejected. A call condition branches on the result and continues when the result is false.

### Emit the call and patch branch code afterward

Rejected. Branch targets, local types, function descriptors, relocation indexes, and code lengths must close before artifact publication.

### Infer the child from storage adjacency

Rejected. The parent block product and exact child block identity select the child statement.

### Reparse projected dependency source

Rejected. Target, signature, result type, arguments, and relocation identity already exist as closed products.

### Raise the closure deadline

Rejected. The complete evidence transaction remains below its fixed deadline.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0057](WIP-0057-source-call-relocation-and-ownership-coordinate-products.md)
- [WIP-0062](WIP-0062-atomic-source-call-link-publication.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0099](WIP-0099-exact-boolean-literal-return-products.md)
- [WIP-0135](WIP-0135-exact-call-conditioned-constant-return-products.md)
- [WIP-0136](WIP-0136-exact-call-conditioned-signed-literal-products.md)
