# WIP-0168: Direct call-form physical product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, physical closure, call forms |
| Depends on | WIP-0049, WIP-0139, WIP-0167 |
| Supersedes | Signature-stub routing for `CallForms.w` |
| Superseded by | None |

## Summary

Route `CallForms.w` through direct imported structured products. The module retains four source-local functions, one local call, four imported call targets, UTF-8 scalar projection, signed arithmetic, and Boolean call guards without generated signature-stub source.

The physical set remains 97 products. The signature-stub set falls from five modules to four.

## Functions

`twoArgumentFirstToken` adds the fixed first-argument offset.

`twoArgumentSecondToken` calls that local helper, projects the first UTF-8 scalar, and selects the narrow or signed-literal token width.

`wideLocalCallStatement` joins imported three- and four-argument classifiers with exact named and packed five- through seven-local identities.

`scalarResultCallStatement` joins direct named result-call identities, imported one- and two-argument classifiers, and the local wide-call classifier.

## Calls and relocation

The local calls to `twoArgumentFirstToken` and `wideLocalCallStatement` remain module-local numeric targets. They do not publish cross-owner relocations.

Four imported Boolean classifiers publish stable target identities:

- one-argument call statement
- two-argument call statement
- three-argument call statement
- four-argument call statement

Every identity resolves through the existing physical callable products. No dependency source or generated recursive stub enters the direct artifact.

## Types and code

Borrowed UTF-8 and mutable words parameters retain canonical loan types. `utf8Scalar` consumes the source loan and the copied token start. Signed token offsets and scalar values retain signed locals. Imported and local classifier results retain Boolean locals.

Source order, call argument types, return types, instruction widths, code bytes, local types, and relocation sites close through the ordinary structured product pipeline.

## Evidence

`NativeCompilerCallFormsPhysicalProductExampleTest` derives the four source-local functions and exact instruction count from stage 0. It requires one callable product, four imported relocations, four resolved targets, and successful publication.

`NativeCompilerCallFormsSourceExampleTest` retains differential evidence for the old generated-stub shape. It remains a fixture for canonical source generation, not the physical production route.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. The linked subset retains 233 functions, 8,556 instructions, 5,987 local types, and 200,384 code bytes. Removing generated call-form stub names reduces source strings to 437, unique strings to 341, and the container to 253,328 bytes. Two runs reproduce SHA-256 `24c2ab4827516761246beeb86004de08cc4d0318e6aaf76a744805b2edf7358f`. Complete evidence passes in 15 minutes and 37 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] `CallForms.w` uses the direct imported structured route.
- [x] Four source-local functions retain their exact stage-0 instruction prefixes.
- [x] Two local calls remain owner local.
- [x] Four imported classifier calls publish and resolve stable identities.
- [x] UTF-8 scalar projection and signed token offsets retain exact types.
- [x] No dependency source or signature stub enters the product.
- [x] Focused physical evidence passes.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The linked physical subset publishes twice with identical bytes.
- [x] Complete evidence remains below twenty minutes.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Keep generated recursive stubs

Rejected. Imported target products already own exact signatures and identities.

### Relocate local calls

Rejected. Source-local targets already have stable artifact-local function IDs.

### Inline classifier dependencies

Rejected. Imported modules retain their own callable authority.

### Add another physical product

Rejected. This migration replaces one existing product route in place.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0139](WIP-0139-structured-imported-call-product-foundations.md)
- [WIP-0167](WIP-0167-bounded-structured-artifact-publication.md)
