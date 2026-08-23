# WIP-0338: Native compiler resolved local-loop kind suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0337 |
| Supersedes | Product-only resolved local-loop classification evidence |
| Superseded by | WIP-0339 native 20 KiB test-manifest bound |

## Summary

Execute `ResolvedLocalLoopKinds.w::resolvedLocalWhile` through an independent native compiler package case.

The case reaches the final opcode in the complete 256-target by twenty-four-form local-loop range. `ResolvedStatements.w` and `LoopKinds.w` remain complete physical inputs.

## Graph

```text
NativeCompilerResolvedLocalLoopKindTests
  -> ResolvedLocalLoopKinds
       -> LoopKinds
       -> ResolvedStatements
```

The target does not copy the base, target count, or form count into test source.

## Evidence

`NativeCompilerNestedHelperEntryExampleTest` compiles a physical entry that calls the classifier. The native artifact matches stage 0 byte for byte and executes successfully.

The native case has source identity `2848d6e42cee8e4302aa67d597534d44cadcc56e30587057c1ae138595d4c802`, execution identity `dc636abced1a933a71f67a99c8a61ff940c95f1374917574d8c588a5048de2bd`, artifact identity `ef7a7888ef773871062d702b4cf2504a533a2e81e90e014bf3c00ff9071008be`, and coverage identity `88996b97c03a03ff773eebbbff0a7d1228b38d9d68a5ffb87b086ce9845d9cbb`.

`wheeler test wheeler-compiler --format json` publishes ninety-two selected, ninety-two passed, and zero failed cases with report identity `a3d9f64878615db3d31cadbb5a729add9e1d87b93068a6e47522b5235135b812`. The canonical workspace checks 134 targets.

## Acceptance

- [x] The public local-loop classifier has an independent native case.
- [x] Complete physical opcode and form owners remain input.
- [x] Classification reaches the final target and form combination.
- [x] The physical artifact matches stage 0 byte for byte.
- [x] The artifact executes exactly once.
- [x] JSON, terminal, and JUnit adapters consume the same ninety-two rows.
- [x] Compiler, package, workspace, documentation, and file policy gates pass.

The complete package run finished in six minutes and twenty-two seconds under its seven-minute host guard.

The compiler manifest contains 15,980 bytes, leaving 404 bytes under the 16,384-byte native bound. The compiler archive contains 3,067,037 bytes with SHA-256 `118c5306574cf1ed05b78f5a835988b87b890de0fdb8f50c200dd84277e5c429`. Its root manifest identity is `9443cecd16c1c516fb2b9f8e835999f0065e513762a8c0aab296087945587e14`.

## Rejected alternatives

### Check the first local-loop opcode

Rejected. The final opcode proves both multiplicative range width and the upper half-open boundary.

### Recompute the end in test source

Rejected. Physical source owns the range formula and imported constants.

### Treat operand decoding as classifier evidence

Rejected. Quotient and remainder decoders do not execute the classifier's lower and upper bound branches.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0337](WIP-0337-native-compiler-resolved-local-loop-operand-suite.md)
- [WIP-0339](WIP-0339-native-20k-test-manifest-bound.md)
