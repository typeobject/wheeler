# WIP-0157: Sparse call-emission publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, call emission, relocation, bounded publication |
| Depends on | WIP-0057, WIP-0145, WIP-0156 |
| Supersedes | Full-capacity call relocation, identity, type, and width copies |
| Superseded by | None |

## Summary

Publish only active call-emission products. `LoopCallProducts.w` formerly copied all relocation rows, all relocation identity bytes, all local type rows, all call widths, and all statement widths after emitting a bounded call set.

Call emission does not change statement widths. The product now leaves that table untouched and publishes exact active call rows.

## Active products

For `c` calls, three 256-row relocation columns publish:

- callable-local call instruction row
- compact target row
- source call coordinate

Exactly `32c` target identity bytes publish. Exactly `c` call-local widths publish.

For `t` local type products, three 4,096-row columns publish owner, local row, and canonical type for exactly `t` rows.

Code bytes already publish through the exact emitted cursor and remain unchanged.

## Statement widths

`SourceCallLayoutProducts.w` validates and owns each call statement width under WIP-0156. `LoopCallProducts.w` verifies that width against the final call kind and arity but never changes it.

The redundant 4,096-row staging and copy are removed. The emission arena falls from 409,600 bytes and six allocations to 376,832 bytes and five allocations.

## Atomicity

Call kind, conditional value, statement, instruction start, target, argument, parameter, owner, local, type, relocation, code, and capacity checks finish before the emission arena is allocated.

The complete call set then stages code and every active output. Active rows replace prior contents through fixed-capacity coordinates. Any malformed call returns an invalid plan without caller mutation.

## Bounds

No capacity changes:

- 256 calls and relocations
- 32 identity bytes per call
- 4,096 call-local type rows
- seven arguments per call
- 262,144 code bytes

Worst-case work remains identical. Small modules no longer publish unused call capacity.

## Evidence

`NativeCompilerStructuredCallSourceProductExampleTest` covers value, forwarded, void, conditional, local, imported, qualified, nested, reversible, and malformed calls.

`NativeCompilerPhysicalClosureExampleTest` remains the complete relocation and final code-emission gate.

`NativeCompilerPhysicalClosureExampleTest` compares every comparable artifact, validates every retained prefix and relocation, links the exact 97-product subset twice, and rejects malformed footer and relocation products. It passes in 19 minutes and 38 seconds under the unchanged twenty-minute deadline. All container counts and the linked identity `9a3fb81e4d75ad52d0ff22deefe636d58d56827ea1de80c1e87a2d96c8c60be9` remain unchanged.

The compiler archive contains 3,006,256 bytes with SHA-256 `63f4c3e547e9e9a64441d66fbb397892e3b7ff6f5bcc1084dc9e74e95b38a7af`. Exact dependent locks name that archive.

## Acceptance

- [x] Three relocation columns publish exactly `callCount` rows.
- [x] Identity publication writes exactly `32 * callCount` bytes.
- [x] Three type columns publish exactly `localTypeCount` rows.
- [x] Call widths publish exactly `callCount` rows.
- [x] Statement-width staging and publication are removed.
- [x] The emission arena drops 32,768 bytes and one allocation.
- [x] Focused structured call tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The 97-product linked subset publishes twice with identical bytes.
- [x] The complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Recompute statement widths during emission

Rejected. WIP-0156 already owns and validates those products.

### Publish calls one at a time

Rejected. A later malformed call would expose partial relocation and code state.

### Shrink relocation tables

Rejected. Downstream code retains fixed-column direct indexing.

### Raise the evidence deadline

Rejected. Inactive call capacity carries no emission fact.

## References

- [WIP-0057](WIP-0057-source-call-relocation-and-ownership-coordinate-products.md)
- [WIP-0145](WIP-0145-sparse-structured-instruction-target-publication.md)
- [WIP-0156](WIP-0156-sparse-source-call-layout-publication.md)
