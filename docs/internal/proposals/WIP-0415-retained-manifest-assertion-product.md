# WIP-0415: Retained manifest assertion product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-28 |
| Updated | 2026-08-28 |
| Area | Self-hosting, source products, manifest validation, physical closure |
| Depends on | WIP-0048, WIP-0049, WIP-0392, WIP-0414 |
| Supersedes | Product-only `ManifestAssertions.w` evidence |
| Superseded by | None |

## Summary

Retain `ManifestAssertions.w` in the immutable physical body archive. Compile its dependency-free source range through the direct structured product path, compare the complete artifact with stage 0, and carry its function into the executable closure.

## Problem

WIP-0392 proved native byte parity and package execution for `requireMetadata`. The full physical closure still omitted that artifact. A focused harness result does not establish archive ownership, retained function framing, string closure, local-type linking, or final container emission.

`ManifestAssertions.w` has one function and no imports. Routing it through imported-call products would invent a dependency boundary. Leaving it outside the closure would keep package evidence ahead of bootstrap product coverage.

## Design

Add `wheeler.compiler.closure.manifest_assertions` to the comparable physical module list and direct-source routing table. The archive compiler reads the exact manifest-selected source range, resolves no dependency products, emits one source-local artifact, and appends it under the canonical module owner.

`NativeCompilerManifestProductExampleTest` now exercises both native boundaries:

- `NativeModuleCompilerHarness` retains the original dependency-free recovery path.
- `NativeCompilerPhysicalPrograms.comparable` proves archive indexing, owner selection, direct structured compilation, and immutable product publication.

The two complete artifacts match stage 0 byte for byte. No projected source, signature stub, or callable relocation enters either path.

## Physical closure

The retained set grows from 106 to 107 artifacts. It contains 90 comparable products and 17 imported-call products. `requireMetadata` adds one function, three instructions, two local types, and 48 code bytes.

The linked closure contains 279 functions, 10,754 instructions, 7,853 local types, and 253,608 code bytes. It carries 493 source-local strings into 387 canonical rows. The resulting 318,496-byte classical container has SHA-256 `19f287f7e6c55e42a252d1d58f2e6a6749c38d2c59da64b52ee94602bf3a0cbd` and prefix `19f287f7`.

The complete link passes in 19 minutes 7 seconds under the fixed 24-minute method limit. The package, compiler module manifest, and native package suite do not change. This WIP changes the selected physical product set and its linked identity only.

## Failure boundary

Reject a missing owner, stale source identity, nonempty import set, malformed Boolean parameter, artifact mismatch, invalid retained prefix, or malformed transport before linked code or identity publication. A false runtime condition still traps through `EXPECT_TRUE`. Product construction does not weaken that effect.

## Acceptance

- [x] `ManifestAssertions.w` enters the comparable physical module set.
- [x] Direct source-product routing uses the exact immutable archive range.
- [x] Focused archive output matches stage 0 byte for byte.
- [x] The retained artifact carries no relocation or synthetic dependency.
- [x] A complete physical link reproduces the new container identity under the fixed method limit.
- [x] Documentation and closure identities name the retained 107-product set.

## Rejected alternatives

### Keep focused parity only

That leaves the artifact outside immutable closure ownership and final linking.

### Treat the function as an imported-call product

The source has no imports. A synthetic edge would misstate the module graph.

### Add `ManifestProfile.w` in the same change

Its structured source-product gap has a separate failure mode. Folding that work into this WIP would turn one retained leaf into a compiler-profile expansion.

## References

- [WIP-0048](WIP-0048-canonical-native-product-linker.md)
- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0392](WIP-0392-physical-bootstrap-manifest-primitives.md)
- [WIP-0414](WIP-0414-bounded-signed-helper-result-owner.md)
