# WIP-0144: Private structured instruction-target staging

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, relocation, bounded storage, evidence runtime |
| Depends on | WIP-0057, WIP-0062, WIP-0139 |
| Supersedes | Caller-visible 131,072-row direct instruction-target scratch table |
| Superseded by | None |

## Summary

Keep structured imported instruction-target staging inside `ImportedStructuredArchiveModuleCompiler.w`. The wrapper needs the table to validate relocation identity and retained instruction coordinates. Its sole caller consumes only artifact bytes, artifact identity, imported relocation rows, relocation owners, and relocation identities.

Removing the unused caller output saves one 1,048,576-byte allocation and 131,072 native word writes from every direct imported physical product.

## Ownership

`materializeSourceCallRelocationLinkProducts` stages a complete 131,072-row instruction-target table. It uses that table to prove:

- every imported identity resolves once
- every relocation names one retained call instruction
- local calls stay outside imported publication
- inverse call rows, when present, name the same target

No later physical phase reads the table. Final closure linking consumes the compact relocation frames and resolves identities again against the final function set.

The wrapper now drops the staged table immediately after relocation validation. Its API no longer accepts a caller-owned target table and no longer copies the complete capacity after success.

## Physical evidence storage

`NativeCompilerArchiveClosureProgram` removes the matching direct instruction-target allocation. The columns arena falls from 7,692,328 bytes and 99 allocations to 6,643,752 bytes and 98 allocations.

The compact direct relocation columns remain:

- 768 words of relocation coordinates
- 256 words of local owners
- 8,192 bytes of target identities

No source, artifact, relocation, function, or instruction bound changes.

## Evidence

`NativeCompilerEarlyComparisonFormsPhysicalProductExampleTest` traverses the direct imported wrapper after the API cut. Its focused run falls from 4 minutes and 2 seconds to 3 minutes and 59 seconds under Java 26 while preserving one local function and two imported relocations.

`NativeCompilerPhysicalClosureExampleTest` compares every comparable artifact, validates every retained prefix and relocation, links the exact 97-product subset twice, and rejects malformed footer and relocation products. It passes in 19 minutes and 43 seconds under the unchanged twenty-minute deadline. All container counts and the linked identity `2d078ef722d6cc916a7a8649492f9f0871efeb507d96abd32e1bf971497268ca` remain unchanged.

The compiler archive contains 3,000,855 bytes with SHA-256 `f0bce3a4c3475060265bce1c858c661e77562029242e967e5908af6241f3d7c5`. Exact dependent locks name that archive.

## Acceptance

- [x] The imported structured wrapper owns instruction-target staging privately.
- [x] Caller APIs expose only artifact and compact imported relocation products.
- [x] Every relocation and inverse-target validation remains in place.
- [x] The physical columns arena drops one MiB and one allocation.
- [x] Focused direct imported output and relocation counts remain exact.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The 97-product linked subset publishes twice with identical bytes.
- [x] The complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Copy only the active target prefix

Rejected. No caller consumes even the active prefix.

### Let the physical harness skip relocation validation

Rejected. The wrapper still validates complete target coordinates before compact publication.

### Raise the closure deadline

Rejected. Dead staging is not semantic work.

## References

- [WIP-0057](WIP-0057-source-call-relocation-and-ownership-coordinate-products.md)
- [WIP-0062](WIP-0062-atomic-source-call-link-publication.md)
- [WIP-0139](WIP-0139-structured-imported-call-product-foundations.md)
