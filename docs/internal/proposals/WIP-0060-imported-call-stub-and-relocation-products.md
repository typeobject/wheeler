# WIP-0060: Imported call stub and relocation products

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and linker maintainers |
| Created | 2026-08-14 |
| Updated | 2026-08-14 |
| Area | Self-hosting compiler, bytecode, relocation |
| Depends on | WIP-0048, WIP-0057, WIP-0059 |
| Supersedes | Imported artifact-emission work in WIP-0059 |
| Superseded by | WIP-0062 for atomic closure publication |

## Summary

Keep a structured module artifact verifiable while its source calls targets owned by direct dependencies. Emit bounded signature stubs under stable callable identities, then remove their numeric coordinates at the canonical linker boundary.

## Problem

WIP-0059 supplies closed imported names, signatures, effects, and identities to source-call resolution. A canonical `.wbc` function call still carries a numeric function operand. The independent artifact verifier rejects an operand outside the artifact's function table.

Writing a closure index into the source-local artifact would expose product packing and bypass relocation. Reopening dependency source to manufacture a target body would violate the closed-product boundary.

## Products

An imported call artifact retains:

- one deduplicated signature stub per referenced callable identity
- the stub's source-local function row
- the call instruction's exact source-product coordinate
- the stable target callable identity
- an external relocation class
- the owning package and dependency-rank evidence

The stub has no executable semantic authority. The linker resolves the identity, rewrites the call operand, and excludes every stub descriptor and code window from final output.

## Invariants

- Only WIP-0059 target products may request a stub.
- Equal target identities share one stub regardless of call order.
- Numeric closure rows never enter source-call products.
- Stub order follows callable identity, not discovery or dependency storage order.
- The source-local artifact passes the independent bytecode verifier before archive publication.
- The final linker proves that no stub function, type row, string, or code byte survives.
- Missing, private, duplicate, stale-package, and signature-mismatched targets publish nothing.

## Bounds

- 256 imported calls per module
- 256 distinct imported targets per artifact
- seven arguments per source call
- 256 locals per callable
- 32,768 artifact bytes
- 8,192 relocation events per archive

## Implementation

`SourceModuleProductArtifact.w` emits typed verifier-only stubs after local callable code. Void stubs return directly. Signed stubs synthesize a zero result. Boolean stubs synthesize equal signed constants and return the comparison. Stub descriptors preserve parameter and result types, while source calls retain stable target identities in relocation products. The local-only publisher passes an explicit empty stub table.

`compileStructuredSourceModuleWithTargets` now publishes independently verified signed, Boolean, and void imported-call artifacts without dependency source. `ReferencedSourceCallTargets.w` stages a local-plus-referenced table after source-call discovery, remaps imported call rows, and drops every unreferenced target before typed layout. Multiple calls to one imported identity share one stub. Malformed call and target rows leave calls and signature outputs untouched. Structured artifact plans now publish the exact relocation count. Caller-owned rows retain callable owners, instruction offsets, verifier-stub targets, source coordinates, and package-bound callable identities after artifact verification.

The canonical linker decodes the verified artifact, retains only the exact source-local function and instruction prefix, and excludes the suffix stub and library rows before closure append. `CallableFunctionRows.w` accepts the bounded 8,192-byte source relocation identity table and resolves each identity against complete closure functions. `SourceCallRelocationLinkProducts.w` joins the published callable owner and owner-local instruction coordinate to one retained call opcode, rejects duplicate or suffix-owned relocations, and publishes final function targets at closure instruction rows. `emitResolvedLinkedInstructionCodeAt` copies only the retained instruction prefix and rewrites the call operand with that target. Focused native evidence carries a qualified source call through verified stub emission, prefix retention, suffix exclusion, stable-identity resolution, and final code emission. WIP-0062 owns one atomic closure container publication around these products.

## Plan

1. [x] Deduplicate referenced WIP-0059 targets by callable identity.
2. [x] Emit canonical verifier-only stub descriptors and local types.
3. [x] Map imported calls to source-local stub rows during artifact verification.
4. [x] Publish external relocation identities beside exact call instructions.
5. [x] Exclude stub products while appending retained local functions.
6. [x] Resolve every external identity through `CallableFunctionRows.w`.
7. [x] Prove byte-identical products under shuffled call and dependency rows.

## Acceptance

- [x] An imported signed call produces a verified source-local artifact without dependency source.
- [x] Boolean and void imported calls preserve exact result and local windows.
- [x] Two calls to one target share one stub and publish two relocations.
- [x] Local shadowing creates no imported stub.
- [x] A stale package-bound identity publishes no final function target.
- [x] Shuffled dependency and call storage leaves source-local and relocation products unchanged.
- [x] Retained function, type, name, instruction, and code windows contain no verifier stub.

## Rejected alternatives

### Keep stubs in final output

Rejected. A validation scaffold is not program semantics.

### Write closure ordinals directly

Rejected. Closure packing is neither stable identity nor source meaning.

### Copy dependency implementations

Rejected. Dependency source is outside the compilation lifetime.

## References

- [WIP-0048](WIP-0048-canonical-native-product-linker.md)
- [WIP-0057](WIP-0057-source-call-relocation-and-ownership-coordinate-products.md)
- [WIP-0059](WIP-0059-imported-source-call-target-products.md)
- [WIP-0062](WIP-0062-atomic-source-call-link-publication.md)
