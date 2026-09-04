# WIP-0356: Native compiler local update suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-09-04 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0355 |
| Supersedes | Product-only local assignment, update, and operation evidence |
| Superseded by | None |
| Follow-up | WIP-0357 native compiler comparison suite |

## Summary

Execute four related local-operation owners through one native package increment:

- `NamedLocalAssignmentKinds.w`,
- `NamedLocalUpdateKinds.w`,
- `ResolvedLocalUpdates.w`, and
- `NamedLongOperations.w`.

The ten public queries classify unresolved assignments and updates, classify and decode resolved updates, and map unresolved signed arithmetic forms to resolved opcode columns.

## Linked source table

`NamedLongOperations.w` imports both complete opcode owners. Linking those declarations into the owner exceeds the former 32,768-byte intermediate source-table slot before the test root is linked.

`SourceTable.w` now separates physical source admission from linked slot capacity:

- physical source bytes remain bounded to 32,768,
- linked slots admit 36,864 bytes,
- seven linked slots occupy 258,048 bytes, and
- the table arena occupies 258,104 bytes including seven length words.

`GraphOwnerMetadata.w` uses the 36,864-byte slot stride while retaining a 32,768-iteration bound for physical module-name copies. A larger linked stride cannot weaken physical source admission.

`NativeCompilerGraphSourcesExampleTest` replaces a slot with exactly 36,864 ASCII bytes, copies the complete value back, and executes successfully without retaining rewind history. Replacement byte 36,865 rejects without changing the former one-byte slot. Count eight still rejects before table mutation.

## Graphs

```text
NativeCompilerNamedLocalAssignmentKindTests
  -> NamedLocalAssignmentKinds -> StatementKinds

NativeCompilerNamedLocalUpdateKindTests
  -> NamedLocalUpdateKinds -> StatementKinds

NativeCompilerResolvedLocalUpdateTests
  -> ResolvedLocalUpdates -> ResolvedStatements

NativeCompilerNamedLongOperationTests
  -> NamedLongOperations
       -> ResolvedStatements
       -> StatementKinds
```

`NativeCompilerLocalSourceExampleTest` independently compiles all four complete production modules byte for byte against stage 0.

## Boundary cases

The suite executes:

- unresolved assignment opcode 805,
- unresolved update opcode 808,
- resolved update opcode 17,663 and target local 255,
- unresolved signed AND opcodes 858 and 859, and
- resolved signed AND bases 14,848 and 15,104.

Every public query receives an independent native case.

The complete compiler package publishes 168 selected, 168 passed, and zero failed cases. The canonical workspace checks 161 targets. JSON, terminal, and JUnit adapters consume the same native rows. The run finishes in twenty minutes and thirty seconds under a twenty-five-minute host guard.

The complete 376-module archive join retains 2,041 scalar symbols and 1,529 callable products. The source-table split accounts for three constants and one callable beyond the preceding closure.

The compiler manifest contains 29,929 bytes. The compiler archive contains 3,104,396 bytes with SHA-256 `cda4957bc6acabf4bff450743f5b4d2f1f7c0a87b6d69b729d18fd8894371b38`. Its root manifest identity is `a2c57f1a74ce639302380f13b00152070e7ae9b7a63536359b6dc3299fd8d3b3`.

## Acceptance

- [x] All ten public queries have independent native cases.
- [x] Complete resolved and unresolved opcode owners remain input.
- [x] Resolved update target local 255 decodes exactly.
- [x] Linked slot byte 36,864 round-trips without repair.
- [x] Linked slot byte 36,865 rejects without mutation.
- [x] Physical source admission remains capped at 32,768 bytes.
- [x] All four production artifacts match stage 0 byte for byte.
- [x] Every selected case executes exactly once.
- [x] All report adapters consume the same 168 rows.
- [x] Compiler, package, workspace, documentation, archive, and file policy gates pass.

## Rejected alternatives

### Project one opcode owner

Rejected. `NamedLongOperations.w` consumes both complete physical authorities. A projected source would avoid the graph under test.

### Raise physical source size

Rejected. No physical file exhausts that boundary. Intermediate linked storage is a separate concern.

### Retain rewind history for the slot boundary

Rejected. Copying 36,864 bytes with persistent snapshots adds no semantic evidence and exhausts host heap.

### Split assignment and update proposals

Rejected. The small owners share one local-operation authority and package evidence boundary.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0355](WIP-0355-native-32k-test-manifest-bound.md)
- [WIP-0357](WIP-0357-native-compiler-comparison-suite.md)
