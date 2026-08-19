# WIP-0167: Bounded structured-artifact publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, structured artifacts, direction selection, bounded publication |
| Depends on | WIP-0064, WIP-0163, WIP-0165 |
| Supersedes | Fixed-capacity ordinary structured-artifact copies |
| Superseded by | None |

## Summary

Publish an ordinary structured artifact through its canonical length. `StructuredArtifactDirections.w` formerly copied all 32,768 bytes from its verified forward staging buffer when no reversible direction was required.

The ordinary branch now copies `forwardResult.length` bytes. The reversible branch remains owned by `ReversibleSourceProductArtifact.w`, which already publishes measured canonical sections.

## Direction boundary

Structured source composition first closes callable code, local types, result products, strings, and optional inverse proof evidence.

The forward artifact publisher returns exact length, code start, function count, maximum local count, and relocation count. For an ordinary module, those bytes and its 32-byte identity publish directly.

For a reversible module, generated inverse rows and code join the verified forward artifact, result-slot local types, and exact proof products. The reversible artifact publisher computes its own final length and identity.

Direction selection does not change source effects, callable counts, or artifact format.

## Atomicity

Forward assembly and identity complete in private staging before direction selection. Reversible inverse and proof products also close before their final publication.

An ordinary output receives only the verified canonical prefix. Untouched bytes retain caller contents. Any failure traps before publication.

## Bounds

No capacity changes:

- 32,768 ordinary artifact bytes
- 262,144 composed or inverse code bytes
- 64 callables
- 32 identity bytes

Worst-case work remains identical.

## Evidence

Structured comparison, call, reversible, and CoreParsing source-product suites compare exact stage-0 artifact prefixes and identities. They cover ordinary, imported-call, local-call, nested-loop, result-slot, and reversible directions.

Physical closure evidence exercises direction publication for every selected structured module before immutable retention.

The compiler archive contains 3,008,797 bytes with SHA-256 `ed5fce63dd84f573a57135dbb82069383984eb9fa950fbaa73236553ffc0bae8`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `9a3fb81e4d75ad52d0ff22deefe636d58d56827ea1de80c1e87a2d96c8c60be9`. Complete evidence passes in 15 minutes and 7 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] Ordinary publication writes exactly `forwardResult.length` bytes.
- [x] Ordinary identity remains the forward artifact identity.
- [x] Reversible publication retains its independent measured boundary.
- [x] Untouched ordinary output bytes retain caller contents.
- [x] Focused ordinary and reversible structured-product tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The linked physical subset publishes twice with identical bytes.
- [x] Complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Copy the forward capacity before reversible assembly

Rejected. Reversible publication consumes only the reported forward prefix.

### Infer length from zero padding

Rejected. Canonical sections own exact artifact length and may contain zero bytes.

### Merge ordinary and reversible publishers

Rejected. Reversible artifacts add inverse, ownership, and proof sections under a separate verified plan.

## References

- [WIP-0064](WIP-0064-reversible-source-product-evidence.md)
- [WIP-0163](WIP-0163-sparse-reversible-evidence-publication.md)
- [WIP-0165](WIP-0165-bounded-source-artifact-publication.md)
