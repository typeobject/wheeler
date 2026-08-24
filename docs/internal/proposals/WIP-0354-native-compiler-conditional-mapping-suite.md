# WIP-0354: Native compiler conditional mapping suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0353 |
| Supersedes | Product-only conditional operation and base-map evidence |
| Superseded by | Broader physical compiler package suites |

## Summary

Execute the two remaining scalar conditional mapping owners that fit the compiler's fixed imported-constant profile:

- `LiteralComparisonOperations.w`, and
- `NamedConditionalBases.w`.

The first classifies resolved equality and less-than updates. The second maps unresolved statement identities to resolved opcode columns. Their six public queries share `StatementKinds.w` and `ResolvedStatements.w`, so one proposal owns the graph and evidence.

## Linked root capacity

Each native target retains both complete opcode owners. Its framed source plan contains 33,607 or 33,426 bytes. Linking the imported declarations into the selected test root crosses the former 32,768-byte linked-root ceiling.

`Linker.w` and the graph root path now admit 36,864 linked bytes. Original source-table slots remain 32,768 bytes. `GraphOwnerMetadata.w` keeps those two strides separate. Table addressing cannot borrow the larger root stride. Intermediate dependency slots, individual physical sources, source count, and compiler artifact storage do not change.

The old profile fails while writing the linked root. Both complete physical graphs execute after the isolated root capacity change. No declaration is projected or omitted.

## Graphs

```text
NativeCompilerLiteralComparisonOperationTests
  -> LiteralComparisonOperations
       -> ResolvedStatements
       -> StatementKinds

NativeCompilerNamedConditionalBaseTests
  -> NamedConditionalBases
       -> ResolvedStatements
       -> StatementKinds
```

`NativeCompilerConditionalSourceExampleTest` independently compiles both complete production modules byte for byte against stage 0.

## Boundary cases

The operation suite checks the last admitted resolved range for less-than, subtraction, XOR, and assignment. The base suite maps unresolved opcodes 825 and 814 to resolved bases 14,080 and 11,520.

A focused native package run publishes four passing operation cases with report identity `6ef58106916a7ccbc99a46a4ddde4d9cf7ce86f8dad77ec4e36eb9ba1a964811`. The base-map run publishes two passing cases with report identity `15c3ce8e4e948d43d63afc0524e4a6e1a838ec4ecbea530344d4c15c344bf982`.

The complete compiler package publishes 158 selected, 158 passed, and zero failed cases. The canonical workspace checks 157 targets. JSON, terminal, and JUnit adapters consume the same native rows. The run finishes in seventeen minutes and one second under a twenty-two-minute host guard.

The compiler manifest contains 27,933 bytes. The compiler archive contains 3,098,657 bytes with SHA-256 `71b73a37c3c79a0c6e51a37a8a757f88080e33f7cbb5dad81917dbe7785eed38`. Its root manifest identity is `27d219b432c11919d11215b8904ee2fae228bc0a42a264fb883657f54e6bad51`.

## Acceptance

- [x] All six public queries have independent native cases.
- [x] Both complete physical opcode owners remain input.
- [x] Linked test roots cross the former 32,768-byte ceiling without projection.
- [x] Original source slots retain their 32,768-byte stride.
- [x] Both production artifacts match stage 0 byte for byte.
- [x] Every selected case executes exactly once.
- [x] All report adapters consume the same 158 rows.
- [x] Compiler, package, workspace, documentation, archive, and file policy gates pass.

## Rejected alternatives

### Project imported constants

Rejected. That would restore the old capacity by compiling a smaller graph than the checked-in compiler uses.

### Widen source-table slots

Rejected. Both imported physical sources already fit. Only the final linked root exhausts its storage.

### Keep the unused graph-helper limit

Rejected. `GraphHelperMembers.w` carried an unused linked-source constant. The dead declaration was removed while separating source-table and root capacities.

### Split mapping and operation proposals

Rejected. Both small owners share the same imports, linked-root limit, and package evidence boundary.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0353](WIP-0353-native-40k-source-plan-bound.md)
