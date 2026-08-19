# WIP-0169: Direct helper-result kind physical product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, physical closure, helper results |
| Depends on | WIP-0049, WIP-0139, WIP-0168 |
| Supersedes | Signature-stub routing for `HelperResultKinds.w` |
| Superseded by | None |

## Summary

Route `HelperResultKinds.w` through direct imported structured products. Three source-local Boolean classifiers retain exact constants, imported call guards, positive and negative branches, and final imported-call results without generated signature-stub source.

The physical set remains 97 products. The signature-stub set falls from four modules to three.

## Classifiers

`signedHelperResult` accepts direct signed returns, resolved signed locals, binary and pair returns, forwarded helper calls, buffer length and element reads, UTF-8 scalar and width reads, and map reads.

`utf8HelperResult` accepts named and moved UTF-8 freeze returns, then forwarded helper calls.

`booleanHelperResult` accepts direct Boolean returns, Boolean negation, comparison returns, forwarded helper calls, and resolved Boolean locals. It rejects resolved signed local returns before the wider local-return classifier.

That signed exclusion is ordered. Reordering the guards would classify a shared numeric range as Boolean.

## Calls and relocation

Nine imported call sites publish relocations across six classifier authorities:

- resolved signed local return
- resolved local return
- binary local return
- pair local return
- comparison return
- forwarded helper return

Repeated targets retain distinct source instruction coordinates and one stable target identity per call site. Every target already belongs to the physical callable set.

No local call or dependency source enters this product.

## Evidence

`NativeCompilerHelperResultKindsPhysicalProductExampleTest` derives three source-local functions and the exact instruction count from stage 0. It requires one callable product, nine imported relocations, nine resolved targets, and successful publication.

Existing framing evidence retains the generated-stub source as a differential fixture only.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. The linked subset retains 233 functions, 8,556 instructions, 5,987 local types, and 200,384 code bytes. Removing helper-result stub names reduces source strings to 431, unique strings to 335, and the container to 252,952 bytes. Two runs reproduce SHA-256 `c973d7cb2490011dd04c17a3ca896447ade7b346936be2c06d95fc2f48b25720`. Complete evidence passes in 15 minutes and 47 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] `HelperResultKinds.w` uses the direct imported structured route.
- [x] Three source-local functions retain exact stage-0 instruction prefixes.
- [x] Signed and Boolean local-return guards remain disjoint and ordered.
- [x] Nine imported calls publish and resolve stable identities.
- [x] No dependency source or signature stub enters the product.
- [x] Focused physical evidence passes.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The linked physical subset publishes twice with identical bytes.
- [x] Complete evidence remains below twenty minutes.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Merge signed and Boolean helper classifiers

Rejected. Ordered negative evidence resolves their overlap.

### Deduplicate repeated relocation targets

Rejected. Relocations identify call sites, not only target identities.

### Keep generated recursive stubs

Rejected. Imported target products already own exact signatures and identities.

### Add another physical product

Rejected. This migration replaces one existing route in place.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0139](WIP-0139-structured-imported-call-product-foundations.md)
- [WIP-0168](WIP-0168-direct-call-form-physical-product.md)
