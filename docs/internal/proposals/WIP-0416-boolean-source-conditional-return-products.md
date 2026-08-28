# WIP-0416: Boolean-source conditional return products

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-28 |
| Updated | 2026-08-28 |
| Area | Self-hosting, structured source products, Boolean returns, physical closure |
| Depends on | WIP-0049, WIP-0392, WIP-0415 |
| Supersedes | Literal-only Boolean child support in direct conditional returns |
| Superseded by | None |

## Summary

Allow one-arm direct conditional products to return a preserved Boolean source. Use that path to compile and retain `ManifestProfile.w` without parser projection or an imported helper.

## Problem

`DirectConditionalReturnProducts.w` accepted Boolean literals and signed source or computed children. It rejected a Boolean source child with failure code 35 even though scalar relation resolution, direct return emission, and local-type encoding already support Boolean source relations.

`ManifestProfile.w` exposes the gap three times:

```wheeler
if (scalar == 45) {
  return allowPunctuation;
}
```

Its final `return valid` already follows the ordinary direct source-return path. Only the conditional child was missing. The focused recovery compiler could compile the module, but the structured archive compiler trapped before artifact publication.

## Design

`writeDirectConditionalReturn` now admits `TYPE_BOOLEAN` when the child relation kind is exactly `RESULT_RELATION_SOURCE`. The existing source relation supplies one local, one canonical `LOCAL_MOVE`, one `RETURN_VALUE`, and a Boolean local-type row.

The change does not admit Boolean arithmetic or a computed Boolean child. A non-source Boolean relation keeps failure code 35. `rejectsComparisonConditionalReturns` continues to pin that boundary.

No new opcode, relation kind, table, bound, or fallback path enters the compiler. The existing direct return writer and type mapper remain authoritative.

## Physical product

`wheeler.compiler.closure.manifest_profile` joins the comparable physical list and direct-source routing table. `NativeCompilerManifestProductExampleTest` compiles both manifest metadata classifiers from exact archive ranges and compares each complete artifact with stage 0.

The retained set grows from 107 to 108 artifacts. It contains 91 comparable products and 17 imported-call products. `profileByte` adds one function, 65 instructions, 41 local types, and 1,480 code bytes.

The linked closure contains 280 functions, 10,819 instructions, 7,894 local types, and 255,088 code bytes. It carries 496 source-local strings into 389 canonical rows. The 320,272-byte container has SHA-256 `bf676a00a974f2faa3e304170be4cf084a17c0390eb8e78fcf7b84a830bda8b3` and prefix `bf676a00`.

## Bootstrap identities

The compiler graph remains at 385 modules and 1,919 imports. Its 180,786-byte canonical manifest now has SHA-256 `55c4cf6674e1d321c4bc0280e06e6eedd40c4a2327ee231a89912fbbdfe35d38`. Native graph validation halts after 75,382,983 transitions. Wheeler SHA-256 consumes the same bytes in 34,597,266 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,180,141-byte compiler archive has SHA-256 `7917acfe76bbabdbcbee19b3c51eced6ecb58eb76d784f43cdfac58b883b9c8c`. Every dependent lock names the new archive.

## Failure boundary

Reject a malformed child coordinate, non-Boolean source, computed Boolean relation, mixed function result type, stale source identity, or malformed product transport before artifact or linked identity publication. Existing signed and literal children keep their byte layout.

## Acceptance

- [x] Boolean source children use the existing direct relation and return encoders.
- [x] Computed Boolean conditional children remain rejected.
- [x] Focused `ManifestProfile.w` output matches stage 0 byte for byte.
- [x] The profile classifier enters the comparable physical set without relocation.
- [x] A complete physical link reproduces the 108-product container identity in 19 minutes 13 seconds under the fixed method limit.
- [x] Manifest, archive, dependent-lock, and all sixteen package-shard evidence passes.
- [x] Current documentation names the 108-product closure.

## Rejected alternatives

### Rewrite `ManifestProfile.w`

The source expresses an ordinary preserved Boolean return. Rewriting it as duplicated literal branches would hide a compiler defect.

### Treat every Boolean relation as a child

The source-product path does not yet lower computed Boolean children here. Admitting them without exact local and instruction evidence would move the failure downstream.

### Add a profile-specific emitter

Manifest syntax needs no private backend. The general direct conditional boundary already owns the required shape.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0392](WIP-0392-physical-bootstrap-manifest-primitives.md)
- [WIP-0415](WIP-0415-retained-manifest-assertion-product.md)
