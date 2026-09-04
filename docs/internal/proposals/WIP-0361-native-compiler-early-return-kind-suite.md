# WIP-0361: Native compiler early-return kind suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-09-04 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0360 |
| Supersedes | Product-only unresolved early-return kind evidence |
| Superseded by | None |
| Follow-up | WIP-0362 native 40 KiB test-manifest bound |

## Summary

Execute both unresolved scalar early-return classifier owners through native package tests:

- `EarlyReturnKinds.w`, and
- `EarlyReturnResultKinds.w`.

The first classifies complete guarded return statements and maps their physical local width. The second classifies signed and computed result forms.

## Graphs

```text
NativeCompilerEarlyReturnKindTests
  -> EarlyReturnKinds -> StatementKinds

NativeCompilerEarlyReturnResultKindTests
  -> EarlyReturnResultKinds -> StatementKinds
```

Both roots retain complete physical `StatementKinds.w`. `NativeCompilerSelfSourceExampleTest` independently compiles both complete production modules byte for byte against stage 0.

## Boundary cases

`EarlyReturnKinds.w` executes final checked-addition guard opcode 934 and maps it to six physical locals.

`EarlyReturnResultKinds.w` executes all six public queries:

- helper-guard signed result at opcode 885,
- comparison-guard signed and computed results at opcode 934,
- checked addition at opcode 934,
- checked remainder at opcode 891, and
- checked division at opcode 912.

Every public query receives an independent native case.

The complete compiler package publishes 206 selected, 206 passed, and zero failed cases. The canonical workspace checks 172 targets. JSON, terminal, and JUnit adapters consume the same native rows. The run finishes in twenty-seven minutes and twenty-three seconds under a thirty-one-minute host guard.

The compiler manifest contains 35,162 bytes. The compiler archive contains 3,119,471 bytes with SHA-256 `9b6dcecf8c731621df08567340f1a95b6a480560edd6522fe28cb8c8c6831a5a`. Its root manifest identity is `831c328a20f106eaabe6dcb4469d81918a83fe4deec886b43628abde0d44ed66`.

## Acceptance

- [x] All eight public queries have independent native cases.
- [x] Complete unresolved opcode authority remains input.
- [x] The terminal checked early return maps to six locals.
- [x] Signed, computed, addition, remainder, and division result classes execute.
- [x] Both production artifacts match stage 0 byte for byte.
- [x] Every selected case executes exactly once.
- [x] All report adapters consume the same 206 rows.
- [x] Compiler, package, workspace, documentation, archive, and file policy gates pass.

## Rejected alternatives

### Merge kind and result authority

Rejected. Statement membership and result semantics remain separate production owners.

### Reuse resolved early-result tests

Rejected. Resolved opcode columns do not prove unresolved source classification.

### Collapse queries into one case

Rejected. Independent public-query identities preserve exact failure ownership.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0360](WIP-0360-native-128-target-report-profile.md)
- [WIP-0362](WIP-0362-native-40k-test-manifest-bound.md)
