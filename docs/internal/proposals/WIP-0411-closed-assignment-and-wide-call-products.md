# WIP-0411: Closed assignment and wide-call source products

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, source-product, and bootstrap maintainers |
| Created | 2026-08-26 |
| Updated | 2026-08-26 |
| Area | Self-hosting, source products, imported calls, physical closure |
| Depends on | WIP-0049, WIP-0139, WIP-0163, WIP-0172 |
| Supersedes | Projected `AssignmentCallSyntax.w` compilation and the open `WideLocalCalls.w` relocation |
| Superseded by | None |

## Summary

The physical compiler now lowers `AssignmentCallSyntax.w` and `WideLocalCalls.w` directly from their immutable archive ranges. Both products consume imported callable signatures and identities. Neither product reads, copies, or rewrites dependency source.

`AssignmentCallSyntax.w` uses bounded tail recursion for the zero- through seven-argument scan and the exact assignment-width scan. `WideLocalCalls.w` uses the same form for three- through seven-argument syntax, packed-source selection, and source-statement width. Public results and malformed-input behavior remain stage-0 identical.

The addition closes every relocation emitted by `CallForms.w`. The linked physical set no longer names `WideLocalCalls.w` without carrying its artifact.

## Source shape

The direct source-product compiler has a narrower root and nested-body profile than the complete source language. A nested borrowed intrinsic or a compound return expression is valid Wheeler, but it is not a licence to project dependency source or introduce a second lowering rule.

The two owners therefore expose their bounded scans as small private functions:

- each recursive step consumes one argument or one packed source digit.
- every recursive edge advances a signed cursor or decreases a packed value.
- terminal guards return a prior local, not a call hidden in a child block.
- intrinsic indexes and call arguments bind to named locals before lowering.
- an invalid arity returns minus one before recursion.

The public functions retain their names, parameters, result types, and exact verdicts. The refactor changes implementation shape, not syntax authority.

## Imported verifier stubs

A direct source artifact may need temporary functions so the independent Wheeler verifier can type-check unresolved imported calls. Those functions are not closure products and are removed before retained publication.

Each temporary function now receives one unique private string `~00` through `~3f`. The suffix is the bounded stub row in lowercase hexadecimal. These strings sort after canonical source names, fit the 256-string source-artifact limit, and cannot collide with a Wheeler source identifier. Function descriptors use the matching generated string row.

Using `$library` for every temporary descriptor was invalid once a module retained more than one imported target. The Java verifier rejected the duplicate names. The Wheeler verifier could not publish the artifact either. The old unnamed-stub path is deleted.

Generated names remain verification scaffolding. Retained function windows, relocations, final strings, and closure identities do not treat them as source declarations.

## Bounds and failure

No semantic bound changes:

- at most 64 local callables.
- at most 64 temporary imported targets, with local callables and stubs sharing that limit.
- at most seven call arguments.
- at most 256 source-artifact strings.
- at most 256 locals and 4,096 source-local instructions per function.
- at most 32,768 bytes in one source-local artifact.

The complete physical-closure evidence deadline moves from twenty to twenty-four minutes. Ninety-nine artifacts and two fresh linked runs exhausted the old deadline at twenty minutes before the second link. The Gradle task retains a separate twenty-eight-minute process ceiling.

Invalid source, unresolved targets, duplicate generated names, unsorted strings, an overfull function or string table, malformed relocations, or verifier refusal publishes no artifact, relocation, hash, or linked container.

## Evidence

`NativeCompilerAssignmentCallSyntaxPhysicalProductExampleTest` retains twelve local functions, 463 forward-plus-inverse instructions, and five resolved relocations. Its recursive classifier alone contains 75 forward instructions.

`NativeCompilerWideLocalCallsPhysicalProductExampleTest` retains fourteen local functions, 877 forward-plus-inverse instructions, and eight resolved relocations. The complete source decoder contains 120 forward instructions. Its verifier-only artifact contains unique sorted stub strings and passes both independent verifiers before the stubs are removed.

`NativeCompilerPhysicalClosureExampleTest` compares all 99 selected physical artifacts with stage 0. It links 262 functions and 9,998 instructions, retains 7,204 local types, reduces 460 retained source strings to 362 canonical strings, and emits 235,304 code bytes in a 295,568-byte container. Two fresh links reproduce SHA-256 `be94a337291a615a99ca3b072fe382d086d60aeb2d6aad1b338d5afec20afb0b`. Malformed footer and relocation transports still publish nothing.

The compiler package manifest identity remains `939e0e2994c11157b73386901ba3185e5ab5573987686aebb95d0c88410c07c7`. Its 3,164,913-byte source archive has SHA-256 `4a4d2b612afaf874528712b7de080e1e075fcb63a444a5563ab5e6b9dd618582`. The 177,822-byte bootstrap module manifest still contains 379 modules and 1,893 imports. Native validation now halts after 74,201,056 committed transitions.

## Acceptance

- [x] Assignment-call syntax compiles from local source and imported products.
- [x] Wide-local calls compile from local source and imported products.
- [x] The public source behavior remains stage-0 identical.
- [x] Every emitted relocation target exists in the selected physical set.
- [x] Verifier-only stub names are unique, sorted, bounded, and non-source.
- [x] Temporary stubs do not enter retained function windows.
- [x] All 99 physical artifacts compare with stage 0.
- [x] Two fresh linked runs reproduce one complete container identity.
- [x] Malformed physical transports fail before publication.
- [x] Source, documentation, style, and file-length checks pass.

## Rejected alternatives

### Project dependency source

Rejected. An imported call crosses the product boundary as a signature and identity. Copying `WideLocalCalls.w` into `CallForms.w` would hide an open edge instead of closing it.

### Add nested-intrinsic special cases

Rejected. The scans are bounded tail recursion over existing scalar and call products. A second loop-body intrinsic encoder would duplicate canonical lowering.

### Retain generic `$library` stub names

Rejected. Duplicate function names are malformed bytecode. A verifier fixture does not receive an exemption from the verifier.

### Drop `CallForms.w` from closure evidence

Rejected. Removing a caller because its dependency was missing would make the selected set smaller and the claim weaker.

## References

- [WIP-0049: Bounded native source-product compilation](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0139: Structured imported-call product foundations](WIP-0139-structured-imported-call-product-foundations.md)
- [WIP-0163: Sparse reversible-evidence publication](WIP-0163-sparse-reversible-evidence-publication.md)
- [WIP-0172: Direct assignment-call operand physical product](WIP-0172-direct-assignment-call-operand-physical-product.md)
