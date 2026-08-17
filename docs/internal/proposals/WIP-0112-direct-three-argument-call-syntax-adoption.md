# WIP-0112: Direct three-argument call-syntax adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, call syntax |
| Depends on | WIP-0049, WIP-0054, WIP-0056, WIP-0069, WIP-0073, WIP-0079 |
| Supersedes | Parser projection for `ThreeArgumentCalls.w` |
| Superseded by | None |

## Summary

Route `ThreeArgumentCalls.w` through direct source products. Its five functions and 48 instructions produce a 2,192-byte artifact that matches stage 0 byte for byte.

The module classifies the bounded three-prior-local signed call form, owns its token coordinates, and decodes the packed third source.

## Product path

`threeArgumentCallStatement` accepts the named source identity or a resolved identity in the exact 256-row packed interval. Its equality child, lower-bound child, and final exclusive upper-bound return use 18 instructions.

The three token-coordinate functions each return `statementStart` plus the exact offsets five, seven, or nine in four instructions.

`threeArgumentThirdSource` rejects values below the packed base, subtracts that base inside the accepted interval, and rejects values at or above the exclusive limit. Its two conditional windows and final literal return use 18 instructions.

The private interval limit remains a source constant derived from the public base and the 256-source bound. Direct compilation consumes the resolved value product and does not repeat that calculation in Java.

## Boundaries

The module owns one three-argument syntax family. It does not resolve target callables, bind the first two sources, validate parameter types, emit call instructions, or publish relocations.

The packed source interval remains half open. Values below the base and at or above the limit return minus one.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module after `ReturnOpcodeKinds.w`. The list remains the sole callable-bearing direct-route authority in Java evidence.

No production source or package lock changes belong to this migration. The route consumes existing direct equality, ordering, arithmetic return, literal return, conditional, and final return products only after complete-artifact parity passes.

## Evidence

`NativeCompilerThreeArgumentCallsPhysicalProductExampleTest` compiles the module with stage 0 and its native product program. It requires atomic publication and compares all 2,192 bytes. Focused physical evidence passes in 4 minutes and 52 seconds.

`NativeCompilerPhysicalClosureExampleTest` compares every selected artifact, validates retained functions and imported relocations, links the exact 96-product subset, repeats publication, and rejects malformed footer and relocation products. It passes in 17 minutes and 16 seconds under the unchanged twenty-minute deadline.

The linked container remains byte-identical with SHA-256 `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] `ThreeArgumentCalls.w` uses direct source products.
- [x] Its five functions and 48 instructions match the 2,192-byte stage-0 artifact.
- [x] Named and packed resolved statement identities remain distinct.
- [x] The packed interval retains its exact lower and exclusive upper bounds.
- [x] Token offsets five, seven, and nine remain exact arithmetic products.
- [x] Invalid packed sources return exact signed minus one.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Infer token columns from argument count in Java

Rejected. Source token coordinates belong to the compiled module.

### Widen the packed interval

Rejected. The local-source field has an exact 256-row bound.

### Decode the third source during target resolution

Rejected. Syntax decoding and callable target resolution own separate products.

### Keep the module on parser projection

Rejected. Existing direct scalar and conditional products close the artifact.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0069](WIP-0069-exact-scalar-return-expression-products.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0079](WIP-0079-exact-signed-literal-return-products.md)
