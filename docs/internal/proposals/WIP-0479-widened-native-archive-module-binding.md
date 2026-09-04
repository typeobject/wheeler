# WIP-0479: Widened native archive-module binding

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-02 |
| Updated | 2026-09-02 |
| Area | Self-hosting, closure planning, source provenance |
| Depends on | WIP-0044, WIP-0166, WIP-0478 |
| Supersedes | The 512-entry archive join and closure-plan bounds |
| Superseded by | None |

## Summary

Carry WIP-0478's 1,024-entry archive bound through module-source binding and closure planning. Archive ingestion alone is insufficient: a module whose source lands after entry 511 must remain addressable through publication.

## Contract

`joinArchiveModuleSources` scans at most 1,024 canonical archive entries for each of at most 512 manifest modules. It publishes only the matching entry coordinate for each module. No per-entry table is added to the module arena. `planClosureStructure` accepts every published entry coordinate from zero through 1,023 while retaining the independent 512-module graph bound.

The join still requires one and only one path match, an exact source digest, a source no larger than 32 KiB, and complete caller-owned columns. Closure planning still copies only selected module ranges into its 512-row scratch tables.

## Evidence

`NativeCompilerArchiveClosureExampleTest` places a one-module compiler source after 1,023 unrelated archive entries. The native pipeline validates all entry digests, joins the last entry to the manifest identity, plans the one-module closure, publishes one product, and reports the complete 1,024-entry archive count. A full metadata pass also joins all 435 current compiler modules and publishes 2,091 symbols and 1,741 callables. WIP-0478 separately proves admission at 1,024 and rejection at 1,025.

The selected physical set remains 112 comparable products and 46 callable products. Its last complete closure run retained 138 non-empty module products, 477 functions, and 16,524 forward-plus-inverse instructions. The 503,896-byte executable retains SHA-256 `d3f642dffffe10df2ca614339619361f1f451bf85596cdbd9ebd868d31bdf175`.

## Bootstrap identities

The compiler graph remains 435 modules, two externals, and 2,023 imports. Its 198,824-byte canonical manifest has SHA-256 `448c6dc03d9df710be48c9beecb30464e318df9a38714fb6c7ad0de7a83d5ea1`. Native validation halts after 84,469,541 transitions. Wheeler SHA-256 halts after 38,050,718 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,280,355-byte compiler archive has SHA-256 `f4f8fa2cf28dcfbac49dd78f918b0a7702b7aec242ffe953463c6f9c7b271b1c`. Every dependent lock names that archive.

## Failure boundary

Reject an archive above 1,024 entries during indexing. Reject an out-of-range published coordinate, a missing or duplicate path, a stale source identity, an oversized module source, a malformed closure graph, or an undersized caller column before publication.

## Acceptance

- [x] Module-source binding scans all 1,024 admitted archive entries.
- [x] Entry coordinate 1,023 survives into closure planning.
- [x] Module tables remain independently bounded at 512 rows.
- [x] A terminal archive entry binds by path and digest.
- [x] The resulting closure publishes without copying source bytes.
- [x] Manifest, archive, SHA-256, and dependent locks reflect the wider join.

## Rejected alternatives

### Reorder compiler sources

Moving one source below entry 512 hides the stale bound and makes unrelated path names part of correctness. The archive order must remain canonical and semantically irrelevant.

### Allocate 1,024 module rows

Archive entries are not modules. A sparse package may carry test fixtures or unselected Wheeler files. Only manifest modules consume graph rows.

### Drop the plan guard

The join result crosses a trust boundary. Closure planning must check its archive coordinate against the same admitted bound before reading source ranges.

## References

- [WIP-0044](WIP-0044-counted-native-compiler-closure-execution.md)
- [WIP-0166](WIP-0166-sparse-archive-source-index-publication.md)
- [WIP-0478](WIP-0478-expanded-native-archive-source-index.md)
