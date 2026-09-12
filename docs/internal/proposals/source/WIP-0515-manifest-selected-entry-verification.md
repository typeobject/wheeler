# WIP-0515: Manifest-selected entry verification

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-12 |
| Updated | 2026-09-12 |
| Area | Self-hosting, bytecode verification, entry signatures |
| Depends on | WIP-0001, WIP-0011 |
| Supersedes | None |
| Superseded by | None |

## Failure

The first WIP-0514 entry artifact passes when its entry follows every helper.
Putting the entry first exposes a verifier restriction, not a different source
contract. `publishSourceProductArtifact` rejects the private artifact at instruction
111, local 98. The independent stage-0 compiler accepts the unchanged source.

`FunctionVerifier.w` and `Verifier.w` require the final function as entry.
`InstructionVerifier.w` excludes that ordinal from five call forms.
`ProofVerifier.w` requires every proof subject to precede the entry. Those fences
cannot verify a declared entry followed by a callable or proof subject.

## Contract

1. Select the entry from the manifest. Check its complete function-index range.
   Do not infer an entry from its position or reserve the final descriptor.
2. Preserve entry flag, result, local-type, and termination checks. Require the
   canonical host ABI: no parameters, one input loan, one output loan, or input
   followed by output. Reject owned, scalar, reversed, or excess parameters.
3. Put canonical entry parameter shapes in one IR owner. Source binding converts
   its validated source type and loan products, then uses that same owner. Do not
   keep separate source and bytecode signature-shape decisions.
4. Validate call targets against the complete function table. Retain each opcode's
   argument, result, reversibility, slot, and ownership checks. A final-position
   helper must not lose those checks or require a synthetic trailing function.
5. Validate proof subjects against the complete function table and the actual rule.
   Entry position does not prove an inverse or a step bound. Remove the unused
   entry-index parameter from proof verification rather than retain an adapter.
6. Keep unknown opcodes and malformed products closed. These changes do not widen
   source, function, frame, scanner, history, or step limits.

This proposal covers verification. It does not establish native runtime support
for every host operation or calls that halt inside a nested entry invocation.
Those remain runtime integration obligations. WIP-0514 still requires complete
source-artifact publication evidence.

## Bounds and publication

The shared signature check reads at most two active type codes. Its inactive
positions must be zero. It allocates no owned storage. Function and proof scans
retain their existing counted bounds.

The canonical source publisher and callable composer construct result records
before changing caller output. Code verification and hashing still precede
artifact publication. Private staging may change when a later check rejects.

## Evidence so far

The source entry regression now passes with the entry before its helper and with
proof subjects after the entry. The same selection also checks all six host-loan
shapes, late claim rejection with complete prepared-buffer preservation, and an
unchanged library control. Four methods pass in a 34-second command with no
failures, errors, or skips. Direct fixtures now compare Java bytecode-reader decisions with native verification
for first, middle, and last entries. They cover all six call opcodes, entry and
later helper proofs, all host-loan shapes, invalid entry and target indices,
false bounds, and malformed entry descriptors. Complete input state and real
verification rewind/replay agree. These three methods pass in the 182-example
WIP-0514 selection. A fourth method and expanded operand mutations also pass.
They reject final-target signature and inverse mismatches, wrong loan types,
invalid argument bases and counts, and invalid value or result-slot destinations.
All four methods retain complete input, region, and verification rewind/replay
checks. The same short selection passes source-budget and documentation gates.

The WIP-0514 physical, package, locked-consumer, and workspace evidence also
exercises these verifier changes. Exact-tree hosted acceptance remains open.

## Acceptance

- [x] Independent bytecode fixtures exercise first, middle, and last entry positions.
- [x] All call families retain complete target, argument, result, and inverse checks.
- [x] Entry and later helper claims verify or reject from actual code and rule facts.
- [x] All entry ABI shapes and malformed descriptor boundaries have direct evidence.
- [x] Complete input state, cleanup, and verification rewind/replay agree.
- [x] The original WIP-0514 source regression passes unchanged.
- [x] Physical budgets, affected artifacts, packages, and documentation agree.
- [ ] The exact verified feature tree is committed, pushed, and checked remotely.
