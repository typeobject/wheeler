# WIP-0478: Expanded native archive-source index

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-02 |
| Updated | 2026-09-02 |
| Area | Self-hosting, package archives, source provenance |
| Depends on | WIP-0044, WIP-0166, WIP-0477 |
| Supersedes | The 512-entry native package-archive ceiling |
| Superseded by | None |

## Summary

Raise the native package-archive source index from 512 to 1,024 entries. The compiler package had filled the old boundary; one additional self-hosting source would otherwise fail before target selection.

## Bounds

`ArchiveSources.w` admits entry counts from one through 1,024 and rejects 1,025 before hashing or caller mutation. Four 1,024-word scratch columns consume 32,768 bytes. The private index arena retains 72 bytes of allocation framing, for an exact 32,840-byte bound.

Archive entries and compiler modules remain separate populations. Counted closure programs allocate four archive columns at the new bound while module, source, schedule, and graph columns remain at 512. The production archive format keeps its independent 10,000-entry schema ceiling and 16 MiB byte ceiling.

## Evidence

`NativeCompilerArchiveSourcesExampleTest` indexes a canonical three-entry archive, rejects damaged outer and entry digests, accepts exactly 1,024 sorted entries, and rejects entry 1,025 with caller rows unchanged. `NativeCompilerCountedClosureExecutionExampleTest` carries the widened columns through a seven-import closure. A focused retained capability product compiles from the current 512-entry compiler archive through the widened production index.

The selected physical set remains 112 comparable products and 46 callable products. Its last complete closure run retained 138 non-empty module products, 477 functions, and 16,524 forward-plus-inverse instructions. The linked closure contains 393,864 code bytes, 13,226 local-type rows, 793 source strings, and 636 unique strings. Its 503,896-byte executable has SHA-256 `d3f642dffffe10df2ca614339619361f1f451bf85596cdbd9ebd868d31bdf175`.

## Bootstrap identities

The compiler graph remains 435 modules, two externals, and 2,023 imports. Its 198,824-byte canonical manifest has SHA-256 `d426ddae85da0a638fcca62d1396ade249e121a02be30c03e49acc03cccc2b7f`. Native validation halts after 84,469,541 transitions under the 85,000,000-transition evidence ceiling. Wheeler SHA-256 consumes the same bytes in 38,050,718 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,280,353-byte compiler archive has SHA-256 `b11831bf0ffdc8bb9f3a7d70dd993f992e356e3563ed9e79d02e7ce19f0b322b`. Every dependent lock names that archive.

## Failure boundary

Reject entry 1,025 before digest work, scratch publication, target selection, or graph planning. Reject undersized caller columns, malformed paths, framing gaps, unsorted entries, digest mismatches, stale graph identities, archive mismatches, or lock mismatches before publication.

## Acceptance

- [x] Native archive indexing admits exactly 1,024 entries.
- [x] Entry 1,025 fails before publication.
- [x] Scratch and caller arenas account for the widened columns exactly.
- [x] Module graph columns remain independently bounded at 512.
- [x] Small and boundary archives execute through the production indexer.
- [x] Counted closure execution consumes the widened columns.
- [x] A retained physical product compiles from the current compiler archive.
- [x] Manifest, archive, SHA-256, and locks reflect the new bound.

## Rejected alternatives

### Raise every module table

Archive entries include test sources and other target files; the selected compiler graph does not. Coupling both ceilings would spend memory without admitting a larger graph.

### Add one slot

A 513-entry ceiling would immediately recreate the same boundary. The power-of-two index leaves room for reviewable self-hosting growth while staying well below the archive schema ceiling.

### Omit the terminal rejection fixture

A source guard cannot prove that digest and publication remain untouched. The 1,025-entry archive is small enough to execute directly.

## References

- [WIP-0044](WIP-0044-counted-native-compiler-closure-execution.md)
- [WIP-0166](WIP-0166-sparse-archive-source-index-publication.md)
- [WIP-0477](WIP-0477-retained-package-manifest-capability-rows.md)
