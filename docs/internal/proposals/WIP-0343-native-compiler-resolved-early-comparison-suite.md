# WIP-0343: Native compiler resolved early-comparison suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-09-04 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0342 |
| Supersedes | Product-only resolved early-comparison evidence |
| Superseded by | None |
| Follow-up | WIP-0344 native compiler resolved early-result suite |

## Summary

Execute both public classifiers in `ResolvedEarlyComparisonKinds.w` through independent native compiler package cases.

The equality case reaches the final prior-local return opcode. The less-than case reaches the final checked-addition return opcode. Both traverse the complete physical range owned by `ResolvedStatements.w` without copying its bases or source count.

## Graph

```text
NativeCompilerResolvedEarlyComparisonTests
  -> ResolvedEarlyComparisonKinds
       -> ResolvedStatements
```

## Evidence

`NativeCompilerResolvedReturnEntryExampleTest` compiles one physical entry that invokes both classifiers. The native artifact matches stage 0 byte for byte and executes successfully.

| Case | Artifact identity | Coverage identity |
| --- | --- | --- |
| `classifiesFinalEqualityLocalReturn` | `d3880a01134de0cc09c33251c67096f17eded7af6daf3ebb41b365e455a435bc` | `ae86652c915e0455b6d7883456bd70a169cdba859e05fcd7080d8f303db8f92b` |
| `classifiesFinalLessThanAdditionReturn` | `b1f5bb06754cd0d8eafe0c30072874483236b005dc23119ced49b9db219c1616` | `6d38ca6e9c930893bbc16a84d1bf68522f7641c1f0545ba0f90154a9ff1b7666` |

Both cases share source identity `f3ef626f4b5e81e68521b255c63e22c9d27cc230c53e4f92b56f96ebe60a2d2e` and execution identity `a4a6b6b5159e079b0d697b5409194f303b423dc40b8255c6ffaa7bad8bc22b8d`.

`wheeler test wheeler-compiler --format json` publishes 111 selected, 111 passed, and zero failed cases with report identity `321c2bdcd49a9a6e13c4a9769ab470c140d84f7a39cddc4b08824e20f31b3c66`. The canonical workspace checks 141 targets.

## Acceptance

- [x] Both public classifiers have independent native cases.
- [x] Complete physical opcode ownership remains input.
- [x] The terminal prior-local equality form executes.
- [x] The terminal checked-addition less-than form executes.
- [x] The physical artifact matches stage 0 byte for byte.
- [x] Every selected case executes exactly once.
- [x] JSON, terminal, and JUnit adapters consume the same 111 rows.
- [x] Compiler, package, workspace, documentation, and file policy gates pass.

The complete package run finished in eight minutes and thirty-seven seconds. Its host guard is ten minutes.

The compiler manifest contains 19,612 bytes. The compiler archive contains 3,076,488 bytes with SHA-256 `bb27c3b286cc0e7c6928ce1eb0709ae9074b8237a1e99c6a55a9101bb7143362`. Its root manifest identity is `989b201ce7cb3be4578214edcbc99c8399b7ddbb2cefee30e78aabf8c59d3073`.

## Rejected alternatives

### Check only the first comparison columns

Rejected. The final forms prove the complete discontiguous classifier paths.

### Split the opcode owner by return family

Rejected. The physical compiler consumes one canonical statement-opcode module.

### Keep the nine-minute host guard

Rejected. The complete suite came within twenty-three seconds of it without exhausting a native execution bound.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0342](WIP-0342-native-compiler-resolved-assertion-suite.md)
- [WIP-0344](WIP-0344-native-compiler-resolved-early-result-suite.md)
