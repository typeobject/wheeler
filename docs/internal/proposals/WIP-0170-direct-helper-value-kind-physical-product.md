# WIP-0170: Direct helper-value kind physical product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, physical closure, helper values |
| Depends on | WIP-0049, WIP-0139, WIP-0169 |
| Supersedes | Signature-stub routing for `HelperValueKinds.w` |
| Superseded by | WIP-0364 native compiler helper-value suite |

## Summary

Route `HelperValueKinds.w` through direct imported structured products. Its single source-local classifier retains the complete unresolved helper-value statement vocabulary, ordered range guards, direct identities, and one imported void-call classifier without generated signature-stub source.

The physical set remains 97 products. The signature-stub set falls from three modules to two.

## Closed classification

`helperValueStatement` accepts direct named forms for:

- byte allocation, owned drop, and UTF-8 freeze
- zero- through seven-argument void calls
- word, byte, and map writes
- three- through seven-local result calls
- helper-call and borrowed-intrinsic returns
- local buffer length, UTF-8 scalar and width, map reads and membership, and buffer reads

It also classifies the closed call, arithmetic, comparison, conditional, loop, and return ranges through ordered half-open boundaries.

The false gaps are part of the authority. They prevent adjacent signed and Boolean ranges from collapsing into one broad numeric interval.

## Call and relocation

One imported call to `voidCallSourceStatement` classifies unresolved zero- through three-argument void calls. The remaining four- through seven-argument identities stay direct constants.

The call publishes one source instruction coordinate and one stable target identity. The target already belongs to the physical callable set.

No local call or dependency source enters this product.

## Evidence

`NativeCompilerHelperValueKindsPhysicalProductExampleTest` derives the source-local function and exact instruction count from stage 0. It requires one callable product, one imported relocation, one resolved target, and successful publication.

`NativeCompilerFramingExampleTest` retains the generated-stub source as differential evidence only.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. The linked subset retains 233 functions, 8,556 instructions, 5,987 local types, and 200,384 code bytes. Removing the helper-value stub name reduces source strings to 430, unique strings to 334, and the container to 252,896 bytes. Two runs reproduce SHA-256 `d01d59db9aed8a807f1d4f02cf1c0913b7faf7c930624b33dfedd9f02e1c3d67`. Complete evidence passes in 16 minutes and 14 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] `HelperValueKinds.w` uses the direct imported structured route.
- [x] Its source-local function retains the exact stage-0 instruction prefix.
- [x] Ordered true ranges and false gaps remain unchanged.
- [x] One imported void-call classifier publishes and resolves its identity.
- [x] No dependency source or signature stub enters the product.
- [x] Focused physical evidence passes.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The linked physical subset publishes twice with identical bytes.
- [x] Complete evidence remains below twenty minutes.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Replace range guards with one minimum and maximum

Rejected. Deliberate false gaps separate unrelated statement families.

### Copy the void-call classifier

Rejected. `VoidCallSourceKinds.w` owns the zero- through three-argument range.

### Keep a generated recursive stub

Rejected. The imported target product already owns the exact signature and identity.

### Add another physical product

Rejected. This migration replaces one existing route in place.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0139](WIP-0139-structured-imported-call-product-foundations.md)
- [WIP-0169](WIP-0169-direct-helper-result-kind-physical-product.md)
- [WIP-0364](WIP-0364-native-compiler-helper-value-suite.md)
