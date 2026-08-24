# WIP-0359: Native compiler call classifier suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0358 |
| Supersedes | Product-only one- through four-argument call evidence |
| Superseded by | WIP-0360 native 128-target report profile |

## Summary

Execute five bounded scalar call owners through one native package increment:

- `CallArgumentSources.w`,
- `OneArgumentCalls.w`,
- `TwoArgumentCallKinds.w`,
- `ThreeArgumentCalls.w`, and
- `FourArgumentCalls.w`.

The nineteen public queries classify argument ownership and result types, map source-token columns, and decode packed third and fourth local operands.

## Graphs

Each test root imports one complete production owner. Every owner imports complete `StatementKinds.w`.

```text
NativeCompilerCallArgumentSourceTests -> CallArgumentSources
NativeCompilerOneArgumentCallTests -> OneArgumentCalls
NativeCompilerTwoArgumentCallKindTests -> TwoArgumentCallKinds
NativeCompilerThreeArgumentCallTests -> ThreeArgumentCalls
NativeCompilerFourArgumentCallTests -> FourArgumentCalls
  -> StatementKinds
```

`NativeCompilerSelfSourceExampleTest` independently compiles all five complete modules byte for byte against stage 0.

## Boundary cases

The suite executes:

- final one-argument signed-to-Boolean local call opcode 867,
- final two-argument signed-to-Boolean local call opcode 871,
- final ordinary signed two-local call opcode 844,
- final Boolean two-local call opcode 852,
- final packed three-argument opcode 33,023,
- final packed four-argument opcode 327,679,
- source local 255 in every packed terminal column, and
- token offsets ending at token 255.

Every public query receives an independent native case. Packed decoders consume production constants. Tests do not copy scale arithmetic.

The complete compiler package publishes 198 selected, 198 passed, and zero failed cases. The canonical workspace checks 170 targets. JSON, terminal, and JUnit adapters consume the same native rows. The run finishes in twenty-five minutes and fifty-six seconds under a thirty-one-minute host guard.

The compiler manifest contains 34,215 bytes. The compiler archive contains 3,116,564 bytes with SHA-256 `d94c52dc913afed3e52daa89d865e84864b98bdc7239c618089ff8e6cbb05f94`. Its root manifest identity is `c1ab267f39e25681e484c0c554abab8bace5e66628fdf797142972d65d9799f8`.

## Acceptance

- [x] All nineteen public queries have independent native cases.
- [x] Complete unresolved opcode authority remains input.
- [x] Final packed three- and four-argument identities execute.
- [x] Third and fourth source local 255 decode exactly.
- [x] Terminal token offsets map to 255.
- [x] All five production artifacts match stage 0 byte for byte.
- [x] Every selected case executes exactly once.
- [x] All report adapters consume the same 198 rows.
- [x] Compiler, package, workspace, documentation, archive, and file policy gates pass.

## Rejected alternatives

### Merge the call owners into one production module

Rejected. Classification, argument ownership, token columns, and packed decoding remain separate authorities.

### Use one aggregate test case

Rejected. Independent public-query identities preserve exact failure ownership.

### Copy packed-source arithmetic

Rejected. Tests call production decoders at the final representable source columns.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0358](WIP-0358-native-36k-test-manifest-bound.md)
- [WIP-0360](WIP-0360-native-128-target-report-profile.md)
