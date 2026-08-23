# WIP-0347: Native compiler terminal return profile

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0328, WIP-0346 |
| Supersedes | Product-only early-source and named return-operand evidence |
| Superseded by | A wider case profile backed by exact exhaustion evidence |

## Summary

Fill the 128-case native compiler profile with three independent return queries from two physical owners:

- both decoders in `EarlyReturnSources.w`, and
- the local-right classifier in `NamedReturnComparisonOperands.w`.

The early-return cases reach source local 255 in the final helper-forwarding and checked-addition columns. The named case reaches the final unresolved signed local-right comparison. Complete physical `ResolvedStatements.w` and `StatementKinds.w` owners remain input.

## Graphs

```text
NativeCompilerEarlyReturnSourceTests
  -> EarlyReturnSources -> ResolvedStatements

NativeCompilerNamedReturnComparisonOperandTests
  -> NamedReturnComparisonOperands -> StatementKinds
```

No test source copies a base, range width, or source count.

## Evidence

`NativeCompilerResolvedReturnEntryExampleTest` compiles one physical entry per graph. Both native artifacts match stage 0 byte for byte and execute successfully.

| Case | Artifact identity | Coverage identity |
| --- | --- | --- |
| `decodesFinalHelperForwardingSource` | `ace78e1a49e086bb1f149e70e8a89c90caad8115526399a8b3629f71f219eae6` | `db1650fc08a261bf3f3b997a52ec669ca108dd4f01148cbd473bfab8188a9936` |
| `decodesFinalComparisonAdditionSource` | `50b56f6f056876a5a94c8b0f16eed55cb24732b0f3e398f1ad3973ef422a5369` | `df13bba48d8b9e132f964673d045e2490fc9a20eb57154698ba36a1bccd29423` |
| `classifiesFinalLocalRightComparison` | `6d94f143f317b2c229b3fdbcf6cfcafa75c30f79663cfc0030e225a4d3357b35` | `7703858e1a4ba105c49f08af6d15f834084cd5db24eb88a95e2a136e58a4e5ad` |

The early-source cases share source identity `d1cb4cd40c97a0ffedd5ec309936d780b3846877768877a8fc797e5d8637a931` and execution identity `edf587ec0f696de6a63eb541c25d4d423682bd94cbc63e7aefbfa386d23cd23e`. The named-operand case has source identity `1fbf7c4d65b159b69cf6fc277fc39a8977378014595fb6be8b10063223b240ed` and execution identity `efb1dccf9a6f0e5edfc652e9db9287d3d97b5439af39d5fe761dc9758def8902`.

`wheeler test wheeler-compiler --format json` publishes 128 selected, 128 passed, and zero failed cases with report identity `b56c392e5d0ef89ce13b2444ce3a8c1fef6a7d6069e82fea5e31dd965188ad97`. The canonical workspace checks 145 targets.

## Acceptance

- [x] Both early-return source decoders have independent native cases.
- [x] The named local-right return classifier has an independent native case.
- [x] Complete resolved and unresolved opcode owners remain input.
- [x] Both physical artifacts match stage 0 byte for byte.
- [x] Every selected case executes exactly once.
- [x] The terminal admitted case count executes and publishes.
- [x] JSON, terminal, and JUnit adapters consume the same 128 rows.
- [x] Compiler, package, workspace, documentation, and file policy gates pass.

The complete package run finished in ten minutes and fifty-four seconds under its twelve-minute host guard.

The compiler manifest contains 21,559 bytes. The compiler archive contains 3,082,462 bytes with SHA-256 `1da81869e917647779e9c1f77c51d57ec0f698bc984263e3e87bbed65c7e65a6`. Its root manifest identity is `d49fae6fb97d8dfbef67bdd72550d4f67905a491c701bcedf579485727f8ca18`.

## Rejected alternatives

### Give each small owner a separate WIP

Rejected. The changes share one exhausted case boundary and one physical return-profile claim.

### Admit the aggregate early-comparison wrapper

Rejected. Its physical nested-helper graph traps ownership preflight. No unproven target remains in the package.

### Add case 129

Rejected. The canonical profile admits exactly 128 cases. A wider profile requires exact boundary evidence and corresponding storage changes.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0328](WIP-0328-native-128-case-test-profile.md)
- [WIP-0346](WIP-0346-native-compiler-resolved-return-call-suite.md)
