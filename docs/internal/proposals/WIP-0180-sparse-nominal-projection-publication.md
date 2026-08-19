# WIP-0180: Sparse nominal-projection publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and linker maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, nominal carriers, aggregate compilation, bounded publication |
| Depends on | WIP-0050, WIP-0051, WIP-0179 |
| Supersedes | Full-capacity imported and local nominal projection copies |
| Superseded by | None |

## Summary

Publish imported nominal references, imported carrier coordinates, and local carrier coordinates through exact projection counts.

`ImportedNominalReferences.w` formerly copied all 49,152 projection words. It now publishes three columns through `projectionCount`.

`LocalNominalCarrierProjections.w` formerly copied all 4,096 projection words. It now publishes eight columns through `referenceCount`.

`AggregateCompiledCallableBodies.w` formerly copied both capacities again and copied all 65,536 imported carrier projection words. The aggregate transaction now transfers each product through its plan count.

## Imported nominal references

Three columns bind:

- module owner
- temporary primitive carrier type code
- counted aggregate target

Record and variant targets emit deterministic temporary declarations. Projection rows retain the exact mapping needed to rewrite final local types.

## Imported carriers

Four columns bind each imported nominal carrier to module owner, local function, local type, and counted aggregate target. Publication uses `carrierProjectionPlan.projectionCount` and the existing 16,384-row column stride.

## Local carriers

Eight columns retain reference identity, role, local function, local slot, original source range, projected source coordinate, and operation owner. Value, constructor, and signature roles remain disjoint.

The aggregate transaction transfers eight columns through `localProjectionPlan.projectionCount` and the 512-row local stride.

## Atomicity

Imported name resolution validates visibility, qualification, ambiguity, aggregate kind, generated declaration bounds, and source rewrites before publication.

Carrier publication validates exact frontend coordinates and target products. Active rows replace caller contents. Untouched rows retain prior contents. Failure publishes no projection row.

## Bounds

No capacity changes:

- 4,096 imported aggregate targets
- three imported reference columns with 16,384-row strides
- four imported carrier columns with 16,384-row strides
- 512 local nominal references
- eight local carrier columns
- 32,768 rewritten source bytes

Worst-case work remains identical.

## Evidence

Imported nominal reference, imported nominal stub, local carrier, aggregate-aware source product, linked local type, and whole-artifact suites cover qualified and unqualified names, ambiguity, record and variant carriers, constructor ranges, signature carriers, malformed source, and atomic failure.

The compiler archive contains 3,015,342 bytes with SHA-256 `5261e87c1fa47f25b53cfcee2d99061df3c35522bc2d17b526b17e6a7cc3a10b`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `08b5978bc9bc6cdc8c314f5a21375d03369e1a5fa1862a36ba5513fcfe837aac`. Complete evidence passes in 16 minutes and 22 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] Imported nominal references publish three columns through `projectionCount`.
- [x] Imported carriers transfer four columns through their projection count.
- [x] Local carrier projections publish and transfer eight columns through their projection count.
- [x] Column strides and target identities remain unchanged.
- [x] Untouched caller rows retain prior contents.
- [x] Focused nominal carrier and aggregate artifact tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] Complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Retain generated nominal declarations in final code

Rejected. They exist only to type-check primitive carriers.

### Match carriers by signed type alone

Rejected. Module, function, local slot, and aggregate identity are required.

### Clear inactive rows

Rejected. Projection counts define complete products.

## References

- [WIP-0050](WIP-0050-native-aggregate-source-lowering.md)
- [WIP-0051](WIP-0051-native-aggregate-frontend-products.md)
- [WIP-0179](WIP-0179-sparse-aggregate-instruction-composition.md)
