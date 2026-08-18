# WIP-0136: Exact call-conditioned signed-literal products

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, calls, conditionals, source ordering |
| Depends on | WIP-0049, WIP-0054, WIP-0056, WIP-0057, WIP-0062, WIP-0079, WIP-0123, WIP-0135 |
| Supersedes | Signed-literal child gap and call-prefix restriction in WIP-0123 |
| Superseded by | None |

## Summary

Compile exact positive and negative signed literal children behind Boolean helper calls:

```wheeler
if (helper(opcode)) {
  return 3;
}
```

The parser consumes one magnitude token or one minus token followed by a magnitude. The complete signed value then crosses the same closed value column introduced by WIP-0135. A new semantic kind keeps literal evidence distinct from symbol evidence.

This product also permits direct root statements after a call. Direct branch targets now count every earlier call window in source order instead of requiring calls to end the direct prefix. That change routes `InstructionForms.w` directly without moving its storage-opcode helper call or flattening either imported constant module.

## Literal product

`DirectCallConditionalReturns.w` first recognizes Boolean `true` and `false`. It then asks the canonical token helper for a signed-number width. A positive literal consumes one token. A negative literal consumes two.

The validator requires:

- canonical bounded number syntax
- a value representable by the accepted signed-number parser
- the semicolon immediately after the complete literal
- the child extent to end at that semicolon
- the parent extent to end at the following closing brace

An identifier still goes through WIP-0135 symbol resolution. Other punctuation, an incomplete minus, overflow, an extra token, or a displaced semicolon invalidates the direct-statement transaction.

`CALL_CONDITION_SIGNED_LITERAL` names the new relation. `sourceCallReturnsSignedChild` closes the shared signed-child set over literal and constant kinds. Layout, direct-result typing, local typing, validation, and emission consume that predicate rather than duplicating two kind checks.

## Source-ordered prefixes

A later direct conditional writes absolute branch targets. Its instruction base must include all earlier root products, including calls.

`DirectStatementProducts.w` now receives exact call argument counts. When it visits a selected root call, it adds `sourceCallInstructionCount(kind, arity)` to the owning callable's running instruction count. A later direct product therefore receives the complete source prefix.

Structured loops still close that direct-prefix path. Their nested code windows require separate composition products, so a later direct conditional after a loop remains rejected until a loop-aware prefix product owns that case. Calls no longer set the same restriction because their complete bounded instruction extent is already closed.

`SourceCallInstructionProducts.w` and `CallableSourceComposition.w` independently recompute source order from direct, call, and loop products. They validate the final call starts and consume each window once. The direct prefix count does not become another final layout authority.

## Emission

A signed literal uses the existing call-conditioned extent for arity `n`:

- `2n + 1` call locals
- one signed child local
- `2n + 5` instructions
- `48n + 120` code bytes

`LOCAL_CONST` receives the parsed signed value. The Boolean call result still controls `JUMP_IF_ZERO`. Relocation still names the call instruction at `instructionStart + 2n`.

The signed-literal value is valid across the complete accepted range, including zero and negative values. Boolean kinds still require exact values zero and one. Nonconditional call kinds still require zero in the conditional-value column.

## Adoption

`InstructionForms.w` now enters through direct structured source products. `expectedOperandCount` contains 373 instructions and 214 locals. Its private `threeOperandStorageOpcode` helper contains 116 instructions and 68 locals. The canonical artifact contains 12,904 bytes plus the inert library entry.

The decisive source window calls the private Boolean helper in the middle of `expectedOperandCount`, branches on its result, and returns signed literal three. Later opcode conditions continue through direct products with branch targets that include the seven-instruction call window.

The callable-bearing direct-route set now contains 64 modules. The physical closure still contains 83 comparable products and 13 signature-stub products.

## Evidence

`NativeCompilerStructuredCallSourceProductExampleTest` emits positive three and negative three through the native imported-call path and reads the emitted instruction-four operand from the verified artifact. An overflowing magnitude traps before artifact publication.

`NativeCompilerInstructionFormsPhysicalProductExampleTest` checks the stage-0 call and literal instructions, compiles the complete module through native archive products, requires atomic publication, and compares all 12,904 bytes. The focused run passes in 4 minutes and 8 seconds under Java 26.

`NativeCompilerPhysicalClosureExampleTest` compares every selected artifact, validates retained prefixes and relocations, links the exact 96-product subset twice, and rejects malformed footer and relocation products. It passes in 18 minutes and 24 seconds under the unchanged twenty-minute deadline. Counts remain 228 functions, 8,286 instructions, 5,729 local types, 193,736 code bytes, and a 246,040-byte container. The canonical linked identity is `1c0f823871c389bb88ad3df25ae5e4804ecf91ced8ff24e14e71822377047bab`.

The compiler archive contains 2,985,679 bytes with SHA-256 `ae4ef106c2cb823dc7625a45d0f132fd84a6a612aa9c42a85b7e312a0120545a`. Exact dependent locks name that archive. The compiler manifest identity remains `e83091ee70e165f76eefcb2135d2b9620af0906f39affb8a0013e9e60bf894c2`.

## Acceptance

- [x] Positive and negative signed literal children compile through one canonical parser.
- [x] Literal, constant, true, and false children retain distinct semantic kinds.
- [x] Literal width selects the exact semicolon and closing-brace coordinates.
- [x] Overflow and malformed signed syntax fail before publication.
- [x] Signed child values cross both call-emission passes unchanged.
- [x] A direct product after a call receives the complete source instruction prefix.
- [x] Structured loops still close the unsupported later-direct path.
- [x] `InstructionForms.w` matches its complete 12,904-byte stage-0 artifact.
- [x] Every selected physical artifact and the linked subset match stage 0.
- [x] Repeated linked publication is byte-identical.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, formatter, readability, Tree-sitter, source length, and layout policy pass.

## Rejected alternatives

### Treat a literal as a synthetic symbol

Rejected. A literal has source syntax and value but no owner, name, visibility, or resolution product.

### Reuse the signed constant kind

Rejected. Literal parsing and symbol resolution have different failure rules and evidence.

### Move the helper call to the end of `InstructionForms.w`

Rejected. Source order is semantic input. Rearranging the module would hide the compiler limitation.

### Ignore earlier calls in branch targets

Rejected. Branch operands are absolute callable instruction coordinates.

### Reopen emitted code to patch later branches

Rejected. Direct products close branch targets before composition and artifact publication.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0057](WIP-0057-source-call-relocation-and-ownership-coordinate-products.md)
- [WIP-0062](WIP-0062-atomic-source-call-link-publication.md)
- [WIP-0079](WIP-0079-exact-signed-literal-return-products.md)
- [WIP-0123](WIP-0123-exact-call-conditioned-literal-return-products.md)
- [WIP-0135](WIP-0135-exact-call-conditioned-constant-return-products.md)
