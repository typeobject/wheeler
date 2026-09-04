# WIP-0329: Native compiler resolved local-return suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-09-04 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0328 |
| Supersedes | Product-only resolved local-return evidence |
| Superseded by | None |
| Follow-up | WIP-0330 native 256-constant owner profile |

## Summary

Execute every public query in the physical `ResolvedLocalReturns.w` owner through an independent native compiler package case.

The suite checks aggregate local-return membership, the signed subrange, and source decoding at the first Boolean-local opcode. The third case distinguishes the two adjacent 256-opcode columns rather than checking another interior value.

## Graph

All cases retain two physical sources:

```text
NativeCompilerResolvedLocalReturnTests -> ResolvedLocalReturns
```

The dependency owns two public range bases, one private end, and three public functions. Tests pass canonical numeric inputs without copying the range arithmetic.

## Evidence

`NativeCompilerNestedHelperEntryExampleTest` compiles one entry that calls all three physical functions. The artifact matches stage 0 byte for byte and executes successfully.

`nativecompilerresolvedlocalreturntests` publishes three cases with source identity `2aba2c6582f669296e8dae30de916946eea4d11e80713354a486c6a60bcf6dc5` and execution identity `d0a6e9d220193101dd8e9ab0f0e9a18b249f5315f630f8ca91db3e67dbe0f208`.

| Query | Artifact identity | Coverage identity |
| --- | --- | --- |
| Local-return membership | `bd310d7ab58813e73f6c14fc47a5574b18d85d70d2bbfd45c578c65e2e800048` | `6a17ae9872a3b616e6eca1c061a5fe902a97b6a7880fe24e3bfb520e3cec76a7` |
| Signed membership | `3e9bf2ef3408172e986e46ea6ef993fabe58c89113dc016e44c8e4c7a7cc349c` | `b0fa6246b891fccd82bc8ca44aeab44cd34b4343c771ac8253b1d6c35f75d8b9` |
| Boolean source | `229159dd5429ea1636c3348f1803f2fd639e066963362628b898c837cca865a7` | `ec59fd4df6a27955a3aacba3b2080e2dcc07071a04ef1d28afce54c1ad4f126c` |

`wheeler test wheeler-compiler --format json` publishes sixty-seven selected, sixty-seven passed, and zero failed cases with report identity `0015a4663d5add0c961ceaba4c1ef1914ea5e2fd8b08655a6cac8e60c2d9fb57`. The canonical workspace checks 126 targets.

## Acceptance

- [x] Every public resolved local-return query has an independent native case.
- [x] Membership reaches the final Boolean-local opcode.
- [x] Signed membership reaches the final signed-local opcode.
- [x] Source decoding checks the first Boolean-local opcode.
- [x] One combined physical artifact matches stage 0 byte for byte.
- [x] The combined artifact executes exactly once.
- [x] Three selected native cases compile and execute independently.
- [x] JSON, terminal, and JUnit adapters consume the same sixty-seven native rows.
- [x] Compiler, package, workspace, documentation, and file policy gates pass.

The compiler package integration test now has a five-minute ceiling. The prior four-minute ceiling raced the complete sixty-seven-case run rather than bounding a semantic resource.

The compiler archive contains 3,056,298 bytes with SHA-256 `02c31d5ab2fa698dbbded1e732ab78b52886848a9d6b071bcab533443ad10cd8`. Its root manifest identity is `3e8b3aeca47ac789bccd37c455c96a0b5f1fd7ccdea2cfeb5a0577fe4167dab1`.

## Rejected alternatives

### Infer the signed range from aggregate membership

Rejected. The physical signed predicate owns a narrower boundary and has its own callers.

### Check only one decoder column

Rejected. The Boolean-base case proves that decoding changes columns without changing the source ordinal.

### Keep the four-minute host timeout

Rejected. Host scheduling jitter is not a native semantic failure. The test still has a finite five-minute wall-clock guard.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0328](WIP-0328-native-128-case-test-profile.md)
- [WIP-0330](WIP-0330-native-256-constant-owner-profile.md)
