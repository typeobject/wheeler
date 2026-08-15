# WIP-0063: Generated inverse coordinate products

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, bytecode, and proof maintainers |
| Created | 2026-08-15 |
| Updated | 2026-08-15 |
| Area | Self-hosting compiler, generated inverses, callable coordinates |
| Depends on | WIP-0038, WIP-0041, WIP-0055, WIP-0057 |
| Supersedes | Generated-inverse integration split from WIP-0055 |
| Superseded by | WIP-0064 owns ownership, proof, and physical source integration |

## Summary

Generate reversible callable inverse code from the source-ordered callable coordinate plan. Inverse code, call relocations, function descriptors, ownership facts, and proof rows must use the same forward callable windows. No inverse pass may reparse source or reconstruct local coordinates.

## Problem

WIP-0055 closes forward local, type, instruction, call, ownership, and return coordinates. The current structured source-product profile emits forward classical functions only. Stage 0 still owns reversible source lowering and generated inverse publication.

Adding inverse flags to the existing emitter without an explicit product would create another coordinate authority. An inverse reverses instruction order, maps reversible opcodes, retains exact payloads, carries call identities to new instruction rows, and shares the forward local-type window. Those facts require a bounded product before artifact emission.

## Invariants

- Every inverse callable consumes the exact code start, code length, and instruction count published by `CallableCoordinateProducts.w`.
- The terminal return stays terminal. Earlier instructions appear in reverse order with the registry-approved inverse opcode.
- Instruction payload bytes remain exact. Call and uncall targets retain their stable callable identity.
- Inverse generation allocates no local or local type.
- Unsupported, irreversible, branching, malformed, overlapping, or excessive input publishes no inverse row or code byte.
- Generated inverse verification consumes the same opcode-pair authority as generation.
- A caller observes inverse code, relocation rows, descriptor windows, proof products, and the artifact together or observes none of them.

## Bounds

- 64 callables
- 32,768 forward instructions
- 262,144 forward bytes
- 256 source calls per callable
- 65,536 closure relocation events
- 256 locals and 4,096 local types per source-local artifact

## Implementation

`GeneratedInverseProducts.w` consumes the WIP-0055 callable code starts, lengths, and instruction counts. It validates complete contiguous windows, records every exact instruction start, keeps the terminal return in place, and emits each earlier instruction in reverse order through one shared opcode-pair function. It stages all 262,144 code bytes and every callable row before publication. An unsupported opcode leaves caller sentinels untouched. Checked updates, assertions, calls, and result-slot returns match stage 0 byte for byte.

`GeneratedInverseRelocations.w` maps each forward owner-local call coordinate to its exact reversed instruction. It sorts output by callable and inverse instruction, retains the target row and all 32 identity bytes, and rejects duplicate forward coordinates before copying one caller row. Two shuffled calls to one target publish inverse coordinates zero and three with separate stable identity rows.

`ReversibleSourceProductArtifact.w` consumes one verified forward artifact, the same callable rows, and completed inverse code. It preserves manifest, string, type, variant, local-type, synthetic-library, and optional proof bytes, then interleaves each local forward and inverse window while publishing reversible descriptor flags and exact offsets. The complete void fixture matches stage 0 byte for byte. Its generated function runs forward, crosses an explicit effect boundary that clears history, runs inverse, and restores its global exactly.

`ProofVerifier.w` now calls the generated-inverse opcode-pair function. The verifier no longer carries a private inverse table.

## Plan

1. [x] Publish callable inverse instruction and code windows from the WIP-0055 callable rows.
2. [x] Move reversible opcode pairing out of the proof verifier into the shared product authority.
3. [x] Differentially generate a straight-line checked-update inverse byte for byte.
4. [x] Extend differential generation to assertions, calls, and result-slot operations.
5. [x] Rebase local and imported call relocations into inverse instruction order without changing identities.
6. [x] Split inverse ownership, proof rows, and direct physical source adoption into WIP-0064.
7. [x] Emit reversible function flags, inverse offsets, inverse lengths, and code from completed products.
8. [x] Match a complete artifact byte for byte and execute forward then inverse after a history commit.
9. [x] Reject structured reversible control until WIP-0035 publishes branch and loop inverse products.

## Acceptance

- Shuffled forward product storage does not change inverse bytes or rows.
- Signed, Boolean, void, local-call, imported-call, and result-slot fixtures retain exact windows.
- Two calls to one target retain two inverse relocations with one target identity.
- Forward execution followed by generated inverse execution restores exact state without VM rewind.
- The proof verifier accepts generated output and rejects one changed pair or payload byte.
- Failed generation leaves caller buffers untouched.
- Complete reversible artifact publication uses only a forward artifact and closed inverse products. WIP-0064 removes the remaining stage-0 forward-artifact producer.

## Rejected alternatives

### Generate inverses while writing function descriptors

Rejected. Descriptor emission cannot become an instruction, relocation, ownership, and proof planner.

### Reparse reversible source in reverse order

Rejected. Source order is already a closed product, and reparsing would restore a second frontend authority.

### Treat VM rewind as an inverse

Rejected. Rewind consumes retained transition history. An inverse is new execution over current typed state.

## References

- [WIP-0035](WIP-0035-reversible-and-coherent-control-flow.md)
- [WIP-0041](WIP-0041-reversible-result-slots-and-explicit-presence-values.md)
- [WIP-0055](WIP-0055-source-ordered-callable-coordinate-products.md)
- [WIP-0057](WIP-0057-source-call-relocation-and-ownership-coordinate-products.md)
- [WIP-0064](WIP-0064-reversible-source-product-evidence.md)
