# WIP-0186: Sparse local nominal-carrier rewrite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and linker maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, local nominal carriers, source rewrite, bounded publication |
| Depends on | WIP-0051, WIP-0180 |
| Supersedes | Full-capacity local carrier and projection copies |
| Superseded by | None |

## Summary

Stage and publish local nominal carrier rewrites through exact reference counts. `LocalNominalCarriers.w` formerly copied all 4,096 projection words into staging, then published all 2,048 carrier words and all 4,096 projection words.

The rewriter now stages and publishes eight projection columns through `referenceCount` and publishes four carrier columns through the same count. Rewritten source bytes were already bounded by exact final length.

## Source rewrite

Local record and variant references that primitive compilation cannot retain become the signed carrier spelling `long`. Constructor-name references remain intact so aggregate expression projection can identify them.

References are source ordered, nonoverlapping, and bounded. The rewriter copies bytes before each reference, writes or preserves the replacement, and copies the final tail once.

## Products

Four carrier columns retain:

- reference identity
- original source start
- original source length
- rewritten source start

Eight projection columns retain role, function, local slot, source coordinates, rewritten coordinate, and operation owner from WIP-0180. The rewrite updates only the rewritten-coordinate column.

## Atomicity

The rewriter validates reference order, source ranges, identifier bytes, roles, final length, and source capacity before allocating publication staging.

Source bytes, carrier rows, and projection rows publish only after the final cursor equals measured length. Untouched caller rows retain prior contents. Failure publishes no output.

## Bounds

No capacity changes:

- 512 local nominal references
- four carrier columns
- eight projection columns
- 32,768 source bytes
- 256 bytes per nominal name

Worst-case work remains identical.

## Evidence

Local nominal carrier, carrier projection, aggregate expression projection, aggregate-aware source product, and linked local type suites cover values, constructors, signatures, source offsets, malformed ranges, overlapping references, and atomic failure.

The compiler archive contains 3,019,114 bytes with SHA-256 `bc741722f39feececf38858b469dcea16cfdaa2fed7b8fb76570a2a81722ecb0`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `08b5978bc9bc6cdc8c314f5a21375d03369e1a5fa1862a36ba5513fcfe837aac`. Complete evidence passes in 16 minutes and 28 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] Projection staging and publication use eight columns through `referenceCount`.
- [x] Carrier publication uses four columns through `referenceCount`.
- [x] Rewritten source publication remains bounded by exact final length.
- [x] Constructor names remain intact while value and signature carriers become signed.
- [x] Untouched caller rows retain prior contents.
- [x] Focused carrier rewrite, projection, and artifact tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] Complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Rewrite constructor names

Rejected. Aggregate expression projection still needs their nominal identity.

### Retain nominal names in primitive source

Rejected. Primitive compilation has no final descriptor authority at this stage.

### Clear inactive rows

Rejected. `referenceCount` defines both complete products.

## References

- [WIP-0051](WIP-0051-native-aggregate-frontend-products.md)
- [WIP-0180](WIP-0180-sparse-nominal-projection-publication.md)
