# WIP-0187: Sparse nominal-reference publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and linker maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, nominal references, generated stubs, bounded publication |
| Depends on | WIP-0050, WIP-0051, WIP-0186 |
| Supersedes | Full-capacity local reference and imported stub projection copies |
| Superseded by | None |

## Summary

Publish local nominal references and generated imported nominal stub projections through exact counts.

`LocalNominalReferences.w` formerly copied all 1,536 reference words. It now publishes three columns through `referenceCount`.

`ImportedNominalStubs.w` formerly copied all 49,152 projection words. It now publishes three columns through `projectionCount` while retaining its exact generated source length.

## Local references

Three columns retain:

- local aggregate target
- source start
- source length

The scanner identifies record and variant names in callable signatures, parameters, locals, and aggregate expressions while excluding declaration bodies. Each source range resolves to at most one local nominal target.

## Imported stub projections

Generated record and variant stubs let the primitive compiler type-check imported nominal references without retaining dependency source.

Three columns bind:

- module owner
- temporary primitive carrier type code
- counted aggregate target

Stub declarations remain sorted by target row and use deterministic local record and variant IDs. Projection publication uses the 16,384-row column stride and exact `projectionCount`.

## Atomicity

Local scanning validates tokens, declaration exclusion, source ranges, name matching, ambiguity, and reference capacity in private staging.

Imported stub generation validates target order, uniqueness, aggregate kind, generated names, source capacity, and exact target count before publication. Untouched rows retain prior contents. Failure publishes no reference or projection row.

## Bounds

No capacity changes:

- 512 local nominal references
- three local reference columns
- 4,096 imported aggregate targets
- three imported projection columns with 16,384-row strides
- 32,768 generated source bytes

Worst-case work remains identical.

## Evidence

Local nominal reference, imported nominal stub, aggregate source operation, carrier rewrite, aggregate-aware artifact, and linked local type suites cover local and imported records and variants, declaration exclusion, ambiguity, malformed ranges, generated names, and atomic failure.

The compiler archive contains 3,019,612 bytes with SHA-256 `aa374794a2374cb067035ca25ae427e9423ff8add06ec0adcaaa488655f0d582`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `08b5978bc9bc6cdc8c314f5a21375d03369e1a5fa1862a36ba5513fcfe837aac`. Complete evidence passes in 16 minutes and 37 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] Local reference publication uses three columns through `referenceCount`.
- [x] Imported stub projection publication uses three columns through `projectionCount`.
- [x] Generated source publication remains bounded by exact cursor length.
- [x] Local and imported nominal target identities remain distinct.
- [x] Untouched caller rows retain prior contents.
- [x] Focused nominal reference, stub, carrier, and artifact tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] Complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Reparse generated stub source for projection rows

Rejected. The generator already owns exact target identity and type code.

### Include nominal declarations as references

Rejected. Declarations create identities and do not consume them.

### Clear inactive rows

Rejected. Reference and projection counts define complete products.

## References

- [WIP-0050](WIP-0050-native-aggregate-source-lowering.md)
- [WIP-0051](WIP-0051-native-aggregate-frontend-products.md)
- [WIP-0186](WIP-0186-sparse-local-nominal-carrier-rewrite.md)
