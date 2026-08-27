# WIP-0413: Closed guarded UTF-8 call product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, source-product, and bootstrap maintainers |
| Created | 2026-08-26 |
| Updated | 2026-08-26 |
| Area | Self-hosting, source products, token syntax, physical closure |
| Depends on | WIP-0049, WIP-0163, WIP-0411 |
| Supersedes | The unlinked `EarlyUtf8CallForms.w` probe |
| Superseded by | None |

## Summary

The physical compiler now lowers `EarlyUtf8CallForms.w` directly from its immutable archive range. All sixteen source functions and 613 forward-plus-inverse instructions match stage 0 byte for byte. The resulting artifact carries no projected dependency source, verifier stub, or unresolved relocation.

The old source shape coupled one fixed seventeen-token form to the general token-hash module. It also hid arithmetic and call arguments inside compound expressions that the closed source-product profile could not represent. The owner now checks its fixed punctuation and `return` keyword locally. General token hashing remains in `Tokens.w`. A fixed grammar word no longer drags that module's number parser into this product.

## Source shape

`earlyUtf8Call` uses one pinned half-open upper bound. The value, 460800, is the first opcode after eight rows of 256 selectors starting at 458752. The lower bound remains the public base identity.

Condition-local and selector decoding bind the base-relative opcode before division or remainder. The seventeen-token width check is split into two private predicates:

- `validEarlyUtf8Condition` checks the condition and opening body tokens.
- `validEarlyUtf8CallBody` checks `return`, the helper call, both sources, and the closing tokens.

Each predicate binds token coordinates, token kinds, punctuation values, and call results to named locals. The public width function combines their verdicts and returns either seventeen or minus one.

`punctuationAt` is private to this fixed syntax owner. It checks token kind before reading one scalar. `returnTokenAt` first requires six bytes and then checks the ASCII scalars in order. Neither helper scans beyond the supplied token range. Comments and whitespace remain the scanner's concern.

This is not a second token lexer. The functions recognize one fixed source form already owned by this module. Generic token equality, hashing, number parsing, and scanner policy remain elsewhere.

## Failure boundary

The product rejects an opcode below 458752 or at or above 460800. A wrong token kind, punctuation scalar, keyword byte, source position, call target, argument token, semicolon, or brace returns minus one. Invalid source-product coordinates, local types, function tables, or artifact framing publish no bytes.

No bound changes. The module remains below 256 locals and 4,096 instructions per function. The physical artifact remains below 32,768 bytes. The complete selected set remains below 128 products and the linked container remains below four MiB.

## Evidence

`NativeCompilerEarlyUtf8CallFormsPhysicalProductExampleTest` compiles the complete physical module through Wheeler source products and compares every artifact byte with stage 0. The expected artifact contains sixteen source functions plus the canonical inert library entry. The focused run publishes no imported relocation.

`NativeCompilerPhysicalClosureExampleTest` now compares 100 selected physical artifacts with stage 0. Two fresh links retain 278 functions, 10,611 instructions, 7,771 local types, and 250,392 code bytes. They reduce 478 source strings to 379 canonical strings and reproduce a 314,624-byte container with SHA-256 `152204b3a8b93ec880959353fb0abab702191fcafe1e30545d3b454ed7466f09`. The independent reader verifies the container, its inert entry executes, and malformed footer and relocation transports still publish nothing.

The compiler package manifest identity remains `939e0e2994c11157b73386901ba3185e5ab5573987686aebb95d0c88410c07c7`. Its 3,169,026-byte source archive has SHA-256 `1b212dff6eea82adb63b3b0fe9608f69366915458da80d2839cd732898b649c5`.

Removing the two broad token-module imports leaves the bootstrap graph at 379 modules and 1,891 imports. The canonical module manifest is 177,746 bytes with SHA-256 `99bf546e1868a8fe3b688101cd348c8762a2680f49982e5dc0bbff56cc25b90c`. Native validation halts after 74,162,601 committed transitions. Wheeler-native SHA-256 consumes the same bytes in 34,021,960 transitions and matches the independent host digest.

## Acceptance

- [x] The guarded UTF-8 call owner compiles from its physical source range.
- [x] All sixteen source functions match stage 0 byte for byte.
- [x] Fixed punctuation and keyword checks remain bounded and local.
- [x] The artifact carries no dependency-source projection or imported relocation.
- [x] All 100 selected physical artifacts compare with stage 0.
- [x] Two fresh links reproduce one complete container identity.
- [x] Malformed physical transports fail before publication.
- [x] Compiler archive, module manifest, transition, and lock identities are current.
- [x] Source, documentation, style, and file-length checks pass.

## Rejected alternatives

### Pull in the complete token module

Rejected. `EarlyUtf8CallForms.w` needs one punctuation predicate and one fixed keyword. Pulling in number parsing, rotate-name hashing, token equality, and signed literal decoding would widen the selected closure without serving this syntax owner.

### Keep compound source expressions

Rejected. Hiding source coordinates and imported call arguments inside arithmetic expressions makes physical products depend on a second expression lowering path. Named intermediates use the canonical direct products.

### Retain the old failing probe

Rejected. A probe that returns no artifact is not closure evidence. The permanent test compares the complete artifact and participates in the linked physical set.

## References

- [WIP-0049: Bounded native source-product compilation](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0163: Sparse reversible-evidence publication](WIP-0163-sparse-reversible-evidence-publication.md)
- [WIP-0411: Closed assignment and wide-call source products](WIP-0411-closed-assignment-and-wide-call-products.md)
