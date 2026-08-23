# WIP-0352: Native compiler conditional classifier suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0351 |
| Supersedes | Product-only conditional range evidence |
| Superseded by | Broader physical compiler package suites |

## Summary

Execute the remaining standalone Boolean-local and literal-comparison conditional classifiers through one native package increment:

- `NamedLocalConditionalKinds.w`,
- `ResolvedLiteralComparisonKinds.w`,
- `ResolvedLocalConditionalKinds.w`, and
- `ResolvedLocalConditionalSources.w`.

These four owners expose thirteen small queries. Splitting them would add proposal machinery without separating authority or evidence.

## Graphs

```text
NativeCompilerNamedLocalConditionalKindTests
  -> NamedLocalConditionalKinds -> StatementKinds

NativeCompilerResolvedLiteralComparisonKindTests
  -> ResolvedLiteralComparisonKinds -> ResolvedStatements

NativeCompilerResolvedLocalConditionalKindTests
  -> ResolvedLocalConditionalKinds -> ResolvedStatements

NativeCompilerResolvedLocalConditionalSourceTests
  -> ResolvedLocalConditionalSources -> ResolvedStatements
```

Each graph retains the complete physical opcode owner. Test sources call production queries and do not copy range arithmetic.

## Boundary cases

The unresolved graph executes the final local-conditional opcode, the final negated form, and both terminal assignment forms. The resolved graphs execute:

- literal-comparison opcode 14,335 and source local 255,
- local-conditional opcode 11,775,
- assignment-value opcode 10,239,
- final subtraction-value opcode 11,519, and
- final XOR-value opcode 11,775.

These values cover each public query at its last admitted class or source column.

## Evidence

`NativeCompilerConditionalEntryExampleTest` compiles one physical entry per graph. Each entry calls every public query owned by that graph, matches stage 0 byte for byte, and executes successfully.

The canonical native package run publishes 152 selected, 152 passed, and zero failed cases. JSON, terminal, and JUnit rendering consume those same rows. The canonical workspace checks 155 targets. The complete run finished in fourteen minutes and fifty-three seconds under its seventeen-minute host guard.

The compiler manifest contains 26,795 bytes. The compiler archive contains 3,095,771 bytes with SHA-256 `ddc9836911e8c367b2ea6267963f3057e84ced320c6e9b723f4cfa678873cee4`. Its root manifest identity is `983a30789ad560b14950a686b2bb0bc82a9d0cb492cb9beffb8da123cbedb144`.

## Acceptance

- [x] All thirteen public queries have independent native cases.
- [x] Complete resolved and unresolved opcode owners remain input.
- [x] Every terminal classifier class executes.
- [x] Both terminal source-local decoders return 255.
- [x] All four physical artifacts match stage 0 byte for byte.
- [x] Every selected case executes exactly once.
- [x] All report adapters consume the same 152 rows.
- [x] Compiler, package, workspace, documentation, archive, and file policy gates pass.

## Rejected alternatives

### Split one proposal per owner

Rejected. All four modules classify one conditional encoding family and share the same two physical opcode authorities.

### Assert copied range endpoints

Rejected. That proves the fixture. Native cases call public production classifiers against physical constants.

### Extend the manifest profile again

Rejected. The complete manifest remains below the 28,672-byte bound established by WIP-0350.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0351](WIP-0351-native-compiler-conditional-value-suite.md)
