# WIP-0138: Direct borrowed-intrinsic shape adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-09-04 |
| Area | Self-hosting compiler, physical closure, borrowed intrinsics |
| Depends on | WIP-0049, WIP-0054, WIP-0056, WIP-0073, WIP-0099, WIP-0123, WIP-0136 |
| Supersedes | Parser projection for `BorrowedIntrinsicShapes.w` |
| Superseded by | None |
| Follow-up | WIP-0363 native compiler borrowed-intrinsic shape suite |

## Summary

Route `BorrowedIntrinsicShapes.w` through direct structured source products. Its seven source functions and 409 instructions produce an 11,576-byte artifact that matches stage 0 byte for byte.

The module classifies exact borrowed mutation, indexed read, direct indexed return, register-width, byte-width, and instruction-count shapes. WIP-0136 supplies the missing source-order rule: a helper call may precede later direct conditions without corrupting their absolute branch targets.

## Product path

Three private predicates classify exact statement identities from `BorrowedIntrinsicKinds.w`:

- borrowed word, byte, owned-byte, and map mutation
- map, buffer, UTF-8 scalar, and UTF-8 width reads
- direct UTF-8 scalar, UTF-8 width, map-get, and map-membership returns

The public shape functions call those predicates and return exact local counts. Named unresolved forms return signed minus one from code-length classification. Resolved forms return 64, 72, 96, or 104 encoded bytes.

`borrowedIntrinsicInstructionCount` binds the result of `borrowedIntrinsicCodeLength` to one signed local, then maps the four admitted widths to three or four instructions. Its call assignment, local equality conditions, and final signed result all remain direct products.

No numeric interval replaces the named intrinsic identities. No host table derives one width from another. The source module remains the shape authority.

## Source order

Private helper-call conditions appear before later direct conditions in four public functions. `DirectStatementProducts.w` counts each complete call window before it emits a later direct branch. `SourceCallInstructionProducts.w` independently validates the same source order before call emission. `CallableSourceComposition.w` consumes every direct and call window once.

The final instruction-count function uses a call assignment rather than a call condition. Its complete call extent enters the same running prefix and the later width comparisons retain canonical branch operands.

## Boundaries

This migration does not add an intrinsic, opcode, source form, owner rule, register shape, code width, or instruction count. It does not admit unresolved named forms into code emission.

`BorrowedIntrinsicKinds.w` remains the statement-identity authority. `BorrowedIntrinsicShapes.w` remains the width authority. Backend intrinsic code generation remains separate.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module after `BooleanTokens.w`. The list remains the sole callable-bearing direct-route authority in Java evidence.

The callable-bearing direct-route set now contains 66 modules. Together with seventeen constant-only direct products, every one of the 83 comparable physical modules now avoids parser-projected compilation. The 13 signature-stub products remain a separate imported-call stage.

No Wheeler package source changes in this migration. The compiler archive and exact dependent locks remain unchanged.

## Evidence

`NativeCompilerBorrowedIntrinsicShapesPhysicalProductExampleTest` compiles the complete module through stage 0 and native archive products. It checks all eight artifact functions including the inert library entry, pins the 128-instruction code-length classifier, requires atomic publication, and compares all 11,576 bytes. The focused run passes in 4 minutes and 8 seconds under Java 26.

`NativeCompilerPhysicalClosureExampleTest` compares every selected artifact, validates retained prefixes and relocations, links the exact 96-product subset twice, and rejects malformed footer and relocation products. It passes in 18 minutes and 32 seconds under the unchanged twenty-minute deadline. The linked identity remains `1c0f823871c389bb88ad3df25ae5e4804ecf91ced8ff24e14e71822377047bab`.

## Acceptance

- [x] `BorrowedIntrinsicShapes.w` uses direct structured source products.
- [x] Its seven source functions and 409 instructions match stage 0.
- [x] Mutation, indexed-read, and direct-return predicates retain exact named identities.
- [x] Local, result, byte, and instruction widths retain exact values.
- [x] Unresolved named forms retain signed minus one code lengths.
- [x] Call conditions and call assignments contribute exact later-direct prefixes.
- [x] All 83 comparable physical modules now avoid parser projection.
- [x] Every selected physical artifact and the linked subset match stage 0.
- [x] Repeated linked publication is byte-identical.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Derive widths from one host table

Rejected. The Wheeler source owns the exact named shape mapping.

### Treat named and resolved statements alike

Rejected. Named forms have no final opcode or byte width.

### Inline private predicates into public functions

Rejected. The predicates are shared semantic products and already compile as local calls.

### Keep parser projection

Rejected. Existing call, conditional, literal, assignment, and final-return products close the artifact.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0099](WIP-0099-exact-boolean-literal-return-products.md)
- [WIP-0123](WIP-0123-exact-call-conditioned-literal-return-products.md)
- [WIP-0136](WIP-0136-exact-call-conditioned-signed-literal-products.md)
- [WIP-0363](WIP-0363-native-compiler-borrowed-intrinsic-shape-suite.md)
