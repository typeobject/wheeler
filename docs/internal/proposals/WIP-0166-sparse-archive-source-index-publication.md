# WIP-0166: Sparse archive-source index publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, package, and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, package archives, source index, bounded publication |
| Depends on | WIP-0043, WIP-0044, WIP-0165 |
| Supersedes | Full-capacity archive-source index copies |
| Superseded by | None |

## Summary

Publish package-archive source rows only through the validated entry count. `ArchiveSources.w` formerly visited all 512 row positions after parsing an exact archive index, guarding every write with the final validity bit.

The indexer now enters publication only after complete validation and writes four columns through `entryCount`.

## Index products

Each canonical archive entry contributes:

- path start
- path length
- source-data start
- source-data length

Paths remain strict ASCII, normalized, sorted, unique, and bounded. Every source payload retains its preceding SHA-256 identity and exact data range.

The returned plan also retains manifest start, manifest length, entry count, and payload length.

## Atomicity

Archive framing, version, manifest extent, entry count, path bytes, path order, data ranges, payload end, and every source digest validate in private staging.

Publication begins only when the final cursor equals payload length. Active rows replace caller contents. Untouched rows retain prior contents. Failure returns one source offset and publishes no row.

## Bounds

No capacity changes:

- 512 archive entries
- four index columns
- 16 MiB archive payload
- 32-byte entry identities
- 32,768-byte source files

Worst-case work remains identical.

## Evidence

`NativeCompilerArchiveSourcesExampleTest` checks canonical three-entry indexing, 512-entry capacity, the rejected 513th entry, digest failure, malformed framing, and unchanged caller rows.

Archive closure and physical compiler evidence consume the same index before any module source is selected.

The compiler archive contains 3,008,782 bytes with SHA-256 `d4c4784d2cdb0abb81ce97252146a3fed8f20cff84b3adb8370545d8cf10a243`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `9a3fb81e4d75ad52d0ff22deefe636d58d56827ea1de80c1e87a2d96c8c60be9`. WIP-0165 and WIP-0166 complete in 14 minutes and 56 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] Four index columns publish exactly `entryCount` rows.
- [x] Publication begins only after complete archive validation.
- [x] Every entry digest binds its exact source range.
- [x] Untouched rows retain caller contents.
- [x] Focused archive-source tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The linked physical subset publishes twice with identical bytes.
- [x] Complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Publish each row while parsing

Rejected. A later path, range, digest, or payload failure would expose a partial index.

### Keep a validity branch inside 512 iterations

Rejected. Complete validation already owns the publication gate.

### Raise archive capacity

Rejected. This change removes inactive work without changing package limits.

## References

- [WIP-0043](WIP-0043-bounded-generic-compiler-module-graph-execution.md)
- [WIP-0044](WIP-0044-counted-native-compiler-closure-execution.md)
- [WIP-0165](WIP-0165-bounded-source-artifact-publication.md)
