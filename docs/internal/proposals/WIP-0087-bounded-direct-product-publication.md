# WIP-0087: Bounded direct-product publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, direct products, evidence deadlines |
| Depends on | WIP-0049, WIP-0054, WIP-0056, WIP-0078, WIP-0085 |
| Supersedes | Capacity-wide direct row, type, and statement-width publication |
| Superseded by | None |

## Summary

Publish only measured direct statement products, local types, and statement widths from private staging. Stop copying unused zero-filled capacity into fresh product buffers.

The direct transaction still validates against full bounded capacities. Successful publication copies seven rows for each admitted product, three rows for each admitted local type, one width for each measured statement, all 64 callable result slots, and the exact emitted code prefix. Failure copies nothing.

## Problem

`materializeDirectStatementProducts` stages bounded products atomically. Its previous success path copied:

- all 28,672 direct row cells
- all 12,288 local type cells
- all 4,096 statement width cells
- all 64 callable result cells
- the emitted code bytes

Most physical classifier modules own fewer than 100 statements and local types. The capacity-wide loops copied tens of thousands of unreachable zeros after every successful module. Direct adoption therefore spent native transitions publishing no semantic product and consumed the physical closure deadline.

The input statement-width staging loop had the same problem. It copied all 4,096 widths even though `statementCount` closes the only readable range.

## Count authorities

The transaction already publishes exact counts:

- `productCount` owns valid entries in each direct row.
- `typeCount` owns valid entries in each local type row.
- `statementCount` owns valid statement widths.
- `cursor` owns valid code bytes.
- the fixed callable limit owns the 64 result slots.

No downstream product may read a direct row at or above `productCount`, a type row at or above `typeCount`, a statement width at or above `statementCount`, or code at or above `cursor`. Those bounds remain asserted by coordinate, composition, and artifact products.

## Publication

On success, one loop over `productCount` copies corresponding cells from all seven direct rows. One loop over `typeCount` copies owner, physical local, and type cells from the three type rows. One loop over `statementCount` copies exact physical widths.

The output buffers originate as fresh region allocations in `StructuredSourceModuleCompiler.w`. Unpublished tails remain zero and outside every admitted count. Their storage capacity does not become a semantic row.

Callable result slots retain the fixed 64-cell copy because later composition addresses them by callable ordinal. Code publication retains its exact `cursor` bound.

## Atomicity

Scanning, statement selection, relation resolution, instruction encoding, type assignment, width replacement, and result-type updates remain private. The compiler starts all output loops only when `valid` remains true.

A malformed statement, unresolved constant, stale physical coordinate, type mismatch, code overflow, or incomplete callable prefix leaves direct rows, type rows, statement widths, result types, and output bytes unchanged. This WIP narrows only the successful publication extent.

## Evidence

Focused direct comparison-classifier evidence matches every stage-0 artifact byte after the publication change. Formatter, source documentation, readability, Tree-sitter, line, and layout policy continue to pass.

The complete physical closure compares every selected module artifact, validates retained function and relocation products, links the exact 96-product subset, repeats the linker, and rejects malformed footer and relocation products. It passed in 14 minutes and 27 seconds. The preceding capacity-wide run with the same direct routes took 15 minutes and 49 seconds.

The method keeps its twenty-minute JUnit deadline and the task keeps its twenty-five-minute deadline.

## Bootstrap closure

The compiler archive contains 2,968,740 bytes and has identity `c5027e65f8b17265db41a31b3da6e379d8cb004a26f6fbeab65733dae6fac7f8`. All four dependent locks name that identity. The package manifest identity remains `e83091ee70e165f76eefcb2135d2b9620af0906f39affb8a0013e9e60bf894c2`.

The bootstrap module manifest remains 173,585 bytes with 373 modules, two externals, and 1,832 imports. Native validation halts after 72,194,836 transitions under the 73,000,000-transition ceiling.

A fresh locked workspace build at `/tmp/wheeler-bounded-publication-build` reproduces the accepted artifacts.

## Acceptance

- [x] The compiler bounds all seven direct rows by `productCount`.
- [x] The compiler bounds all three local type rows by `typeCount`.
- [x] The compiler bounds statement-width staging and publication by `statementCount`.
- [x] Callable result and code publication retain their exact existing bounds.
- [x] Failure publishes no direct product state.
- [x] Focused complete artifacts match stage 0 byte for byte.
- [x] The complete physical closure and linked subset identities remain exact.
- [x] Existing evidence deadlines remain unchanged.
- [x] Compiler archive identities, dependent locks, and bootstrap budgets are current.
- [x] A fresh locked workspace build passes.
- [x] Documentation and source policy pass.

## Rejected alternatives

### Raise evidence deadlines

Rejected. Capacity tails carried no product and justified no transition budget.

### Shrink public buffers to current counts

Rejected. Product carriers retain fixed capacities so later bounded stages can share one verified layout.

### Publish one flattened prefix

Rejected. Row offsets are physical product coordinates. Flattening would copy holes and erase row ownership.

### Skip private staging

Rejected. Direct products must fail before any externally readable row, type, width, result, or code byte changes.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0078](WIP-0078-bounded-direct-conditional-lookups.md)
- [WIP-0085](WIP-0085-root-task-state-specialization.md)
