# WIP-0139: Structured imported-call product foundations

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, imported calls, source products, relocation |
| Depends on | WIP-0049, WIP-0054, WIP-0057, WIP-0059, WIP-0062, WIP-0136 |
| Supersedes | Primitive-only imported target rows and unfiltered structured relocations |
| Superseded by | None |

## Summary

Close the product boundaries required to compile a structured archive module with imported callable targets. The structured compiler now preserves parameter loans, measures declaration and condition call windows before layout, separates imported relocations from local calls, admits Boolean literal equality in nested and root conditions, and emits root word-buffer projections.

This WIP does not add a physical module. WIP-0140 uses the completed path for `VoidCallSyntax.w`.

## Imported target types

`ImportedSourceCallTargets.w` formerly copied a callable's owned source type into the local call target table and stored its loan mode in a second row that `SourceCallTargetTable.w` did not consume. A `borrow utf8` parameter therefore arrived as owned UTF-8. Mutable and shared words, bytes, map, and region parameters had the same defect.

The target product now maps each nonowned source parameter to its canonical local borrow type:

- region to region borrow
- words to words borrow
- bytes to bytes borrow
- map to map borrow
- UTF-8 to UTF-8 borrow
- byte view to byte view

The mode row remains available as source signature evidence. Unsupported type and mode pairs invalidate the complete target view.

## Source value calls

`SourceValueProducts.w` now joins every statement to at most one call before local measurement. A signed or Boolean declaration initialized by a call owns `2n + 2` physical locals for arity `n`. A call condition owns `2n + 1`.

The ordinary call layout remains authoritative for final kind and width. The value product supplies the defining named local and the provisional physical coordinate required by argument resolution. Duplicate calls on one statement fail before publication.

## Imported relocation filter

A structured artifact publishes relocation identities for local and imported calls. Local call targets are already numeric source-local function rows. Sending them through closure identity lookup rejected valid recursion because local structured target identity is not an imported callable-product identity.

`ImportedStructuredArchiveModuleCompiler.w` now compares each relocation identity against the closed imported target view. Exactly one imported match enters relocation linking and publication. Zero imported matches denote a local call and remain in the artifact. Duplicate imported identities trap before any artifact, relocation, or instruction-target publication.

The wrapper returns the imported relocation count. It stages artifact bytes, identity, filtered relocation rows, owners, identities, and resolved instruction targets before copying any caller output.

## Boolean conditions

`LoopNestedConditions.w` accepts exact `booleanLocal == true` and `booleanLocal == false` forms. Kind four denotes Boolean equality with a literal. `LoopNestedBlockProducts.w` emits the existing equality window. `LoopLocalTypeProducts.w` types the preserved source, literal, and result locals as Boolean.

`DirectConditionalReturnProducts.w` applies the same rule at a callable root. Boolean equality permits only `LOCAL_EQ` and exact Boolean literals. Its three parent locals are Boolean. Signed equality and ordering retain their prior rules.

## Buffer projection

`DirectByteProjectionProducts.w` is removed. `DirectBufferProjectionProducts.w` owns the complete indexed buffer relation.

Byte views, owned bytes, and borrowed bytes select `BYTES_GET`. Owned and borrowed words select `WORDS_GET`. The source owner and index move into private locals, the projection produces one signed local, and the final move binds the named destination. Every other owner type fails before code or type publication.

## Bounds

All existing bounds remain:

- seven arguments per source call
- 256 calls and relocations per module
- 1,792 call arguments
- 4,096 source statements and local types
- 256 locals per callable
- 32,768 source and artifact bytes

The imported structured wrapper adds 16,384 bytes of staged relocation storage. No limit or public artifact format changes.

## Evidence

`NativeCompilerStructuredCallSourceProductExampleTest` compares a root borrowed-word projection with stage 0. It also compares a nested Boolean-literal equality and the existing declaration call after a completed root loop.

`NativeCompilerPhysicalClosureExampleTest` compares every selected artifact, validates retained prefixes and relocations, links the exact 96-product subset twice, and rejects malformed footer and relocation products. It passes in 18 minutes and 38 seconds under the unchanged twenty-minute deadline. Counts remain 228 functions, 8,286 instructions, 5,729 local types, 193,736 code bytes, and a 246,040-byte container. The linked identity is `c525f89dc0e96226241d473c7e9e1693d084b08abf66a88a8257bd7e803a50a2`.

The compiler archive contains 2,992,039 bytes with SHA-256 `0273e4c1e316a55e298a96d2717ed34d5d71ba44ba2ff31e6df9c2f7807e02ba`. Exact dependent locks name that archive.

## Acceptance

- [x] Imported target rows convert source loans to canonical local borrow types.
- [x] Unsupported imported type and mode pairs fail atomically.
- [x] Signed and Boolean declaration calls publish exact provisional local widths.
- [x] Call conditions publish exact arity-dependent provisional widths.
- [x] Structured imported publication excludes local calls from closure relocations.
- [x] Duplicate imported relocation identities fail before publication.
- [x] Nested and root Boolean literal equality retain Boolean local types.
- [x] Root word projections emit `WORDS_GET` through the sole buffer projection owner.
- [x] The byte-only projection owner is removed.
- [x] Every selected physical artifact and the linked subset match stage 0.
- [x] Repeated linked publication is byte-identical.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, formatter, Tree-sitter, source length, and layout policy pass.

## Rejected alternatives

### Ignore parameter modes in target layout

Rejected. Owned and borrowed values require different local types and transfer opcodes.

### Relocate local calls through closure identities

Rejected. Local numeric targets are already source-local artifact authority.

### Patch target types during call emission

Rejected. Argument type checking closes before code emission.

### Keep separate byte and word projection owners

Rejected. The relation differs only by admitted owner type and canonical get opcode.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0057](WIP-0057-source-call-relocation-and-ownership-coordinate-products.md)
- [WIP-0059](WIP-0059-imported-source-call-target-products.md)
- [WIP-0062](WIP-0062-atomic-source-call-link-publication.md)
- [WIP-0136](WIP-0136-exact-call-conditioned-signed-literal-products.md)
