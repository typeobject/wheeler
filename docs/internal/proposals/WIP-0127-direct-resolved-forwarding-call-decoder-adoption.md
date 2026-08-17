# WIP-0127: Direct resolved forwarding-call decoder adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-17 |
| Updated | 2026-08-17 |
| Area | Self-hosting compiler, physical closure, forwarded calls |
| Depends on | WIP-0049, WIP-0054, WIP-0056, WIP-0069, WIP-0073, WIP-0075, WIP-0079 |
| Supersedes | Parser projection for `ResolvedReturnCallKinds.w` |
| Superseded by | None |

## Summary

Route `ResolvedReturnCallKinds.w` through direct source products. Its six functions and 277 instructions produce an 8,392-byte artifact that matches stage 0 byte for byte.

The module classifies resolved scalar forwarding-call identities, returns exact arities, and decodes up to four packed prior-local sources.

## Product path

`resolvedReturnHelperCall` admits one- through four-argument packed columns and fixed zero-, five-, six-, and seven-argument identities. It retains every gap and exclusive upper bound in source order.

`returnHelperCallArity` maps the same families to exact arities or signed minus one.

The four source decoders subtract their exact packed-column bases and apply division or modulo by the 256-source dimensions. Three- and four-source products retain the named square and cube dimensions before extracting each source.

Direct declarations preserve intermediate packed and quotient locals. Computed conditional children preserve arithmetic source products and exact physical widths. No host shift, mask, or column table replaces the Wheeler arithmetic.

## Boundaries

The module classifies and decodes resolved identities only. It does not resolve callable targets, validate signatures, bind argument values, allocate transfer locals, emit calls, or publish relocations.

Five- through seven-argument forms use fixed identities and carry their packed sources in separate products. The decoders in this module cover only the one- through four-argument columns represented in the opcode value.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module after `ResolvedLongOperations.w`. The list remains the sole callable-bearing direct-route authority in Java evidence.

No production source or package lock changes belong to this migration. The route consumes existing direct ordering, equality, declaration, arithmetic, computed-child, constant-return, literal-return, and final-return products only after complete-artifact parity passes.

## Evidence

`NativeCompilerResolvedReturnCallKindsPhysicalProductExampleTest` compiles the module with stage 0 and its native product program. It requires atomic publication and compares all 8,392 bytes. Focused physical evidence passes in 4 minutes and 43 seconds.

`NativeCompilerPhysicalClosureExampleTest` compares every selected artifact, validates retained functions and imported relocations, links the exact 96-product subset, repeats publication, and rejects malformed footer and relocation products. It passes in 18 minutes and 43 seconds under the unchanged twenty-minute deadline.

The linked subset remains byte-identical with SHA-256 `5fc2ddaec2835c516d52d1e8b1254aeaf50789c72d7b42cd0060b026b880ec25`.

## Acceptance

- [x] `ResolvedReturnCallKinds.w` uses direct source products.
- [x] Its six functions and 277 instructions match the 8,392-byte stage-0 artifact.
- [x] Zero- through seven-argument forwarding families retain exact identities and arities.
- [x] One- through four-argument packed columns retain exact half-open bounds.
- [x] First through fourth packed sources retain exact arithmetic decoding.
- [x] Intermediate packed and quotient locals retain source order and physical coordinates.
- [x] No host shift, mask, or lookup table becomes semantic authority.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Decode packed sources with host bit operations

Rejected. The Wheeler source defines decimal division and modulo over exact 256-source dimensions.

### Merge fixed wide identities into packed columns

Rejected. Five- through seven-argument forms carry sources through separate products.

### Resolve targets in the identity decoder

Rejected. Target signatures, owner identity, arguments, and relocations close later.

### Keep the decoder on parser projection

Rejected. Existing direct scalar, declaration, and computed-child products close the artifact.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0069](WIP-0069-exact-scalar-return-expression-products.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0075](WIP-0075-exact-computed-conditional-return-products.md)
- [WIP-0079](WIP-0079-exact-signed-literal-return-products.md)
