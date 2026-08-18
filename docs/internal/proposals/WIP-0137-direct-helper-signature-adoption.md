# WIP-0137: Direct helper-signature adoption

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, physical closure, helper signatures |
| Depends on | WIP-0049, WIP-0054, WIP-0056, WIP-0073, WIP-0077, WIP-0079 |
| Supersedes | Parser projection for `HelperSignatures.w` |
| Superseded by | None |

## Summary

Route `HelperSignatures.w` through direct structured source products. Its nine source functions and 726 instructions produce a 19,592-byte artifact that matches stage 0 byte for byte.

The module maps exact helper-kind constants to parameter counts, result classes, generated-inverse state, result-slot state, and owned UTF-8 state. It also maps signed parameter counts back to exact signed, Boolean, and UTF-8 helper kinds.

## Product path

`parameterCountForHelper` checks every admitted one- through sixteen-parameter family. Signed and Boolean signed families remain separate products. The dedicated Boolean one- and two-parameter forms and the reversible and UTF-8 forms retain their exact constants.

`signedScalarHelperKind` and `booleanScalarHelperKind` map counts zero through sixteen through ordered conditional returns. Out-of-range counts return signed minus one.

The remaining predicates classify:

- UTF-8 helper arities two and ten
- reversible helper kinds
- reversible result-slot kinds
- owned UTF-8 result kinds
- Boolean result kinds
- Boolean parameter kinds

Every condition uses one source-anchored constant product from `HelperAbi.w`. Every child is an exact signed or Boolean literal return. Final returns remain source ordered. No host range, bit field, generated switch, or copied dependency source replaces the named helper families.

## Boundaries

This migration does not change helper identities, accepted arities, callable signatures, result-slot widths, loan modes, effects, or generated inverse rules. It does not merge the dedicated Boolean parameter families with the signed-parameter families.

`HelperAbi.w` remains the sole identity and width authority. `HelperSignatures.w` owns only mappings and predicates over those products.

## Routing

`NativeCompilerPhysicalProductSource.DIRECT_SOURCE_MODULES` names the module between `FourArgumentCalls.w` and `IdentifierStarts.w`. The list remains the sole callable-bearing direct-route authority in Java evidence.

The callable-bearing direct-route set now contains 65 modules. The physical closure still contains 83 comparable products and 13 signature-stub products.

No Wheeler package source changes in this migration. The compiler archive and exact dependent locks therefore remain unchanged.

## Evidence

`NativeCompilerHelperSignaturesPhysicalProductExampleTest` compiles the complete module through stage 0 and native archive products. It checks all ten artifact functions including the inert library entry, pins the 268-instruction parameter classifier, requires atomic publication, and compares all 19,592 bytes. The focused run passes in 4 minutes and 21 seconds under Java 26.

`NativeCompilerPhysicalClosureExampleTest` compares every selected artifact, validates retained prefixes and relocations, links the exact 96-product subset twice, and rejects malformed footer and relocation products. It passes in 18 minutes and 42 seconds under the unchanged twenty-minute deadline. The linked identity remains `1c0f823871c389bb88ad3df25ae5e4804ecf91ced8ff24e14e71822377047bab`.

## Acceptance

- [x] `HelperSignatures.w` uses direct structured source products.
- [x] Its nine source functions and 726 instructions match stage 0.
- [x] Zero through sixteen signed and Boolean signed parameter counts retain exact mappings.
- [x] Reversible, result-slot, UTF-8, and Boolean predicates retain exact named families.
- [x] Unsupported scalar counts return signed minus one.
- [x] No host range or generated switch becomes semantic authority.
- [x] Every selected physical artifact and the linked subset match stage 0.
- [x] Repeated linked publication is byte-identical.
- [x] Existing evidence deadlines remain unchanged.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Replace named families with arithmetic ranges

Rejected. Helper identities are explicit registry products. Contiguity is not part of their contract.

### Generate a host lookup table

Rejected. The Wheeler module is the mapping authority and must compile itself.

### Merge Boolean and signed parameter forms

Rejected. Their source signatures and result classes differ.

### Keep parser projection

Rejected. Existing constant-condition, literal-child, and final-return products close the complete artifact.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0073](WIP-0073-exact-root-conditional-return-products.md)
- [WIP-0077](WIP-0077-exact-constant-return-products.md)
- [WIP-0079](WIP-0079-exact-signed-literal-return-products.md)
