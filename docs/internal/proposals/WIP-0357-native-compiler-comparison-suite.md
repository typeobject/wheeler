# WIP-0357: Native compiler comparison suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0356 |
| Supersedes | Product-only Boolean and return-comparison evidence |
| Superseded by | Broader physical compiler package suites |

## Summary

Execute four scalar comparison owners through one native package increment:

- `BooleanDeclarationKinds.w`,
- `ResolvedBooleanLiteralComparisons.w`,
- `NamedComparisonKinds.w`, and
- `ReturnOpcodeKinds.w`.

The eleven public queries classify Boolean declarations, decode Boolean-literal comparison columns, classify direct typed comparison returns, and select resolved scalar return opcodes.

## Graphs

```text
NativeCompilerBooleanDeclarationKindTests
  -> BooleanDeclarationKinds -> StatementKinds

NativeCompilerResolvedBooleanLiteralComparisonTests
  -> ResolvedBooleanLiteralComparisons -> ResolvedStatements

NativeCompilerNamedComparisonKindTests
  -> NamedComparisonKinds -> StatementKinds

NativeCompilerReturnOpcodeKindTests
  -> ReturnOpcodeKinds -> StatementKinds
```

Every graph retains its complete physical opcode owner. Tests call production queries and do not copy classifier ranges.

The existing physical product fixtures compile all four complete production modules byte for byte against stage 0. `NativeCompilerLocalSourceExampleTest` independently checks the resolved Boolean-literal owner through the direct source route.

## Boundary cases

The suite executes:

- final Boolean declaration opcode 816,
- Boolean equality opcode 25,343,
- Boolean inequality opcode 25,599 and source local 255,
- final direct signed comparison opcode 877,
- final direct signed inequality opcode 875,
- ambiguous Boolean inequality opcode 865 mapped to 875,
- signed local comparison opcode 877 mapped to literal opcode 876, and
- signed local AND opcode 861 mapped to literal opcode 860.

Every public query receives an independent native case.

The complete compiler package publishes 179 selected, 179 passed, and zero failed cases. The canonical workspace checks 165 targets. JSON, terminal, and JUnit adapters consume the same native rows. The run finishes in twenty-two minutes and twenty-one seconds under a twenty-eight-minute host guard.

The compiler manifest contains 31,924 bytes. The compiler archive contains 3,109,715 bytes with SHA-256 `d0b1996578523d6bc8f3958bf26c45b0092f2d9bdd4eed5e38506234d7e63d46`. Its root manifest identity is `b7a9ffe3a78db249018bdbc9bf4dee2b8223812d0556c1473346df4522831a8e`.

## Acceptance

- [x] All eleven public queries have independent native cases.
- [x] Complete resolved and unresolved opcode owners remain input.
- [x] Boolean literal source local 255 decodes exactly.
- [x] Terminal comparison and arithmetic opcode maps execute.
- [x] All four production artifacts match stage 0 byte for byte.
- [x] Every selected case executes exactly once.
- [x] All report adapters consume the same 179 rows.
- [x] Compiler, package, workspace, documentation, archive, and file policy gates pass.

## Rejected alternatives

### Fold return opcode maps into test code

Rejected. `ReturnOpcodeKinds.w` remains the sole typed selection authority.

### Use one case for all queries

Rejected. Independent cases preserve public-surface identity and diagnostics.

### Split Boolean and return proposals

Rejected. The four small owners share one scalar comparison boundary and the same two opcode authorities.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0356](WIP-0356-native-compiler-local-update-suite.md)
