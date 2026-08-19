# WIP-0165: Bounded source-artifact publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, source artifacts, bounded publication |
| Depends on | WIP-0054, WIP-0164 |
| Supersedes | Fixed-capacity source-artifact copies |
| Superseded by | None |

## Summary

Publish only canonical source-artifact bytes. `SourceProductArtifact.w` formerly copied all 32,768 bytes of private staging after assembling and verifying an exact `artifactLength`.

The publisher now copies `artifactLength` bytes. Identity, function count, maximum local count, code start, verification, and section bounds remain unchanged.

## Artifact boundary

The source-product assembler receives canonical manifest, string, function, and code sections. It validates six section extents, writes the sorted directory, computes exact alignment and padding, and verifies the resulting artifact before publication.

`artifactLength` is the end of the code section after canonical alignment. Bytes beyond that coordinate are staging capacity and carry no artifact meaning.

The caller receives:

- exact artifact length
- code-section start
- function count
- maximum local count
- zero relocations for this artifact form
- 32-byte SHA-256 identity over the exact artifact

## Atomicity

Every section, directory row, function descriptor, local count, code extent, bytecode verification result, and identity completes in private regions.

The output prefix changes only after verification and hashing. Untouched output bytes retain caller contents. Any malformed product traps before the first output write.

## Bounds

No capacity changes:

- 32,768 artifact bytes
- 64 functions
- six canonical sections
- 32 identity bytes

Worst-case work remains identical. Small artifacts no longer publish unused capacity.

## Evidence

`NativeCompilerSourceProductArtifactExampleTest` checks exact stage-0 bytes, identity, function metadata, malformed products, and publication failure.

Structured source-product suites compare published prefixes against independent stage-0 artifacts. Physical closure evidence retains and links only reported artifact lengths.

The compiler archive contains 3,008,782 bytes with SHA-256 `d4c4784d2cdb0abb81ce97252146a3fed8f20cff84b3adb8370545d8cf10a243`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `9a3fb81e4d75ad52d0ff22deefe636d58d56827ea1de80c1e87a2d96c8c60be9`. WIP-0165 and WIP-0166 complete in 14 minutes and 56 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] Output publication writes exactly `artifactLength` bytes.
- [x] SHA-256 covers exactly the published prefix.
- [x] Canonical verification precedes publication.
- [x] Untouched output bytes retain caller contents.
- [x] Focused source-artifact and structured-product tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The linked physical subset publishes twice with identical bytes.
- [x] Complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Include zero staging tail in artifact identity

Rejected. Canonical `.wbc` length ends with its final section.

### Publish before verification

Rejected. Caller-owned output is an irreversible boundary for this transaction.

### Shrink artifact capacity

Rejected. This change removes inactive work without changing accepted module size.

## References

- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0164](WIP-0164-sparse-compiled-function-publication.md)
