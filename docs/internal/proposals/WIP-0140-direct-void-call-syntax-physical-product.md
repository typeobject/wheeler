# WIP-0140: Direct void-call syntax physical product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, physical closure, imported structured calls |
| Depends on | WIP-0049, WIP-0054, WIP-0057, WIP-0062, WIP-0139 |
| Supersedes | Parser-only physical boundary for imported callable modules |
| Superseded by | None |

## Summary

Compile `VoidCallSyntax.w` from its immutable archive source, counted imported values, direct dependency callable products, parameter loan products, and stable callable identities. Publish its local function prefix and one imported relocation without signature stubs or dependency source.

This adds the ninety-seventh physical compiler product. The first 83 products remain byte-comparable complete local artifacts. Thirteen later products retain the signature-stub path. `VoidCallSyntax.w` is the first later product built through the direct imported structured path completed by WIP-0139.

## Archive path

`NativeCompilerArchiveClosureProgram` now includes `ImportedStructuredArchiveModuleCompiler.w` in the native evidence machine. Four bounded columns carry direct relocation rows, owners, identities, and resolved instruction targets.

`NativeCompilerPhysicalProductSource` selects one of three paths:

1. comparable direct modules use the existing compact structured archive compiler
2. imported direct modules use `compileStructuredArchiveModuleWithImportedTargets`
3. remaining imported modules use projected source and signature stubs

The comparable path does not pay for the imported target arena. The imported direct path materializes callable products in dependency rank, compiles the structured source, excludes local calls from closure relocation, and appends only imported relocation frames.

Each imported frame binds:

- physical product rank
- retained source-local instruction row
- final target callable-product row

The physical linker continues to assign final numeric function IDs. The source artifact never treats a closure row as stable identity.

## Source shape

`VoidCallSyntax.w` keeps exact public behavior but removes forms that obscured product boundaries.

`wordAt` owns one words projection. The local `punctuationAt` owns token-kind lookup and UTF-8 scalar projection. `separatorEnd` validates one comma or reports signed minus one. `argumentEnd` traverses the bounded zero- through seven-argument list by tail recursion. `voidCallStatementWidth` freezes four punctuation constants into named locals, validates the first token, calls the recursive cursor product, validates close and semicolon punctuation, and returns the exact measured width.

The rewrite removes early returns from a loop, nested multi-statement control, computed call arguments, constant call arguments, and a chained return expression. Each intermediate value now has one source name and one product coordinate. `DirectUtf8ScalarProducts.w` emits the local punctuation helper's exact four-instruction UTF-8 projection. The seven-argument language bound remains owned by `voidCallSourceArity`.

## Retained product

The module contributes five local functions:

- `wordAt`
- `punctuationAt`
- `separatorEnd`
- `argumentEnd`
- `voidCallStatementWidth`

They contain 270 forward instructions. The public function contains 134 instructions and 120 locals. One imported call site resolves to `voidCallSourceArity`. Calls to the four private helpers remain numeric inside the source artifact and produce no closure relocation frame.

## Bounds

The evidence machine adds 1,064,960 bytes and four allocations for direct imported relocation staging. `NativeCompilerPhysicalSelection` owns module selection and manifest-owner rows, keeping the generated archive program below the 1,000-line source limit. Existing source, artifact, callable, call, argument, relocation, function, instruction, and output bounds remain unchanged.

The physical product count rises from 96 to 97. No package or bytecode format changes.

## Evidence

`NativeCompilerVoidCallSyntaxPhysicalProductExampleTest` compiles the module through the direct imported path. It checks the 134-instruction public function, all five retained functions, all retained instructions, one product publication, one imported relocation, and one resolved target. The focused run passes in 4 minutes and 9 seconds under Java 26.

`NativeCompilerPhysicalClosureExampleTest` compares every comparable artifact, validates every retained prefix and relocation, links the exact 97-product subset twice, and rejects malformed footer and relocation products. It passes in 19 minutes and 7 seconds under the unchanged twenty-minute deadline. The subset contains 233 functions, 8,556 instructions, 5,987 local types, 200,384 code bytes, and a 254,192-byte container. Its SHA-256 identity is `c66dfbc87b666ab587d36102c32e21798c210eba84a6b6176813346bfcf12e00`.

The compiler archive contains 3,001,226 bytes with SHA-256 `9b2a80e3812814047204ac71c02d01c6c7ebc7697fe7ac89117f0c7f4de28f8c`. Exact dependent locks name that archive.

## Acceptance

- [x] `VoidCallSyntax.w` uses direct imported structured products.
- [x] Dependency source and signature stubs are absent from this path.
- [x] Imported parameter loans retain canonical local types.
- [x] Local calls remain local numeric targets.
- [x] Exactly one imported call site publishes a stable relocation identity.
- [x] The five local functions retain 270 stage-0 instructions.
- [x] Malformed argument punctuation still returns signed minus one.
- [x] Zero through seven arguments retain exact measured widths.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The 97-product linked subset publishes twice with identical bytes.
- [x] Malformed footer and relocation products fail before publication.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, formatter, Tree-sitter, source length, and layout policy pass.

## Rejected alternatives

### Add another signature stub product

Rejected. WIP-0139 closes the direct imported target and relocation path.

### Copy `Tokens.w` or `VoidCallSourceForms.w`

Rejected. Counted callable products carry every required signature and identity.

### Keep loop early returns

Rejected. Tail recursion gives each cursor transition one closed call and result product.

### Relocate private helper calls

Rejected. Their numeric targets are valid inside the source-local artifact.

### Run the large imported target arena for every direct module

Rejected. Comparable modules keep the compact no-target path and its evidence deadline.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0057](WIP-0057-source-call-relocation-and-ownership-coordinate-products.md)
- [WIP-0062](WIP-0062-atomic-source-call-link-publication.md)
- [WIP-0139](WIP-0139-structured-imported-call-product-foundations.md)
