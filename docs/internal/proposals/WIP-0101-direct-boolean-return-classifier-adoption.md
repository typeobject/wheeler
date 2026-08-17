# WIP-0101: Direct Boolean return-classifier adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, physical closure, Boolean calls |
| Depends on | WIP-0049, WIP-0054, WIP-0073, WIP-0099 |
| Supersedes | Parser projection for `NamedBooleanReturnKinds.w` |
| Superseded by | None |

## Summary

Route `NamedBooleanReturnKinds.w` through direct source products. Its three functions and 40 instructions produce a 1,800-byte artifact that matches stage 0 byte for byte.

The module classifies named Boolean equality and inequality return forms. Its combined classifier forwards the result of one local Boolean call.

## Product path

`returnBooleanEqualityStatement` and `returnBooleanInequalityStatement` each use one exact equality condition whose child returns `true`, followed by one final equality return.

`returnBooleanComparisonStatement` uses two equality conditions with `true` children. Its final statement calls `returnBooleanInequalityStatement(opcode)` and returns that Boolean result directly.

The local call path retains the source callable identity, one signed argument, Boolean result type, exact call instruction, result local, and terminal `RETURN_VALUE`. It does not reconstruct a comparison at the caller or coerce the Boolean result to signed.

## Local-call boundary

This adoption proves one ordinary local Boolean result call after a direct instruction prefix. It does not add imported calls, reversible calls, result slots, call-conditioned branches, or more than one argument.

Forwarded local calls remain closed call products. Callable order and same-module target identity select the target. Source text does not supply a host function index.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module before the remaining named classifiers. The list remains the sole callable-bearing direct-route authority in Java evidence.

No production source or package lock changes belong to this migration. WIP-0099 separately records the Boolean literal child and root products that close the two leaf classifiers.

## Evidence

`NativeCompilerNamedBooleanReturnKindsPhysicalProductExampleTest` compiles the module with stage 0 and its native product program. It requires atomic publication and compares all 1,800 bytes. Focused physical evidence passes in 4 minutes and 50 seconds.

`NativeCompilerPhysicalClosureExampleTest` compares every selected physical artifact, validates retained functions and imported relocations, links the exact 96-product subset, repeats publication, and rejects malformed footer and relocation products. It passes in 17 minutes and 38 seconds under the unchanged twenty-minute deadline.

The linked container remains byte-identical with SHA-256 `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] `NamedBooleanReturnKinds.w` uses direct source products.
- [x] Its three functions and 40 instructions match the 1,800-byte stage-0 artifact.
- [x] Equality and inequality classifiers retain exact statement constants.
- [x] Boolean literal children retain exact block ownership.
- [x] The combined classifier forwards one exact local Boolean call result.
- [x] Callable order and target identity remain closed products.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] The linked 96-product subset keeps its exact identity.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Inline inequality classification in the caller

Rejected. The source names a local call whose target identity and result local must survive.

### Treat the call result as signed

Rejected. The callee returns Boolean and the forwarded result local retains `TYPE_BOOLEAN`.

### Route only the two leaf classifiers

Rejected. Physical modules publish complete artifacts, not parser and direct mixtures.

### Reparse the callee body at the call site

Rejected. Closed callable and call products already own the target and signature.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0099](WIP-0099-exact-boolean-literal-return-products.md)
