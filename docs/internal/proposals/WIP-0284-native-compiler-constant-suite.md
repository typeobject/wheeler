# WIP-0284: Native compiler constant suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, package, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Self-hosting, compiler testing, package reports |
| Depends on | WIP-0283 |
| Supersedes | One-declaration native compiler spine target |
| Superseded by | None |
| Follow-up | WIP-0285 native compiler callable suite |

## Summary

Give every production module in the native compiler spine an executable imported-constant assertion.

The compiler package target still carries one root and seven physical imports. It now discovers, compiles, executes, and reduces seven independent test declarations. Six focused cases check one constant owner each. The encoding case retains the nine-assertion scalar operation chain from WIP-0283.

## Cases

The suite checks:

- `MAX_MINIMAL_STATEMENTS == 64` from `CompilerProgramLimits.w`.
- `MAX_COMPILER_TOKENS == 4096` from `CompilerTokenLimits.w`.
- `ENCODING_WIDTH_U16 == 2` plus the arithmetic and bitwise chain from `EncodingWidths.w`.
- `STATEMENT_LOCAL_WHILE_CONDITION_NAMED == 1` from `LoopKinds.w`.
- `OPCODE_HALT == 1` from `Opcodes.w`.
- `PROOF_GENERATED_INVERSE == 1` from `ProofRules.w`.
- `TYPE_SIGNED == 1` from `TypeCodes.w`.

Each case lowers independently from the same exact source plan. Peer tests and the production entry are blanked before compilation. Each selected artifact receives fresh storage, one verifier attempt, one execution, one coverage reduction, and one profile-2 row.

## Report

The package command publishes rows in native case-identity order rather than source declaration order. All seven rows share one source identity and carry independent case, artifact, execution, and coverage identities.

Several one-assertion cases compile to identical artifacts because their resolved values and lowered instruction shapes are equal. Case identity remains distinct because the declaration name enters its transcript. Artifact identity is not a case identifier.

## Evidence

`wheeler test wheeler-compiler --format json` publishes seven selected and seven passed native cases. The combined report identity is `8ee1d9ea8bfec0217c87d7cff4d168c0444e9564f7a6c3bc35666ba3afcdcda6`.

`testsThePhysicalCompilerSpineNatively` requires all seven rows through the direct adapter and package command and checks the native report identity is stable across both invocations.

## Acceptance

- [x] Every selected production module owns one checked constant.
- [x] Seven declarations are discovered without Java reflection.
- [x] Seven artifacts compile independently from one source plan.
- [x] Every case receives fresh execution storage.
- [x] Seven complete native rows reduce in case-identity order.
- [x] Shared artifact identities do not collapse case identities.
- [x] The package report records seven selected and seven passed cases.
- [x] Compiler archive and every consumer lock are rebuilt exactly.
- [x] Focused compiler package, tools, documentation, workspace, and file-length policy pass.

The compiler archive contains 3,023,614 bytes with SHA-256 `1b9d60c8257ba2227d5d187d9ee1da534f51c1950e1e5f033c0f27e7ed7c90f7` and root manifest identity `8ca1126edccaa2e857e34d7b186bb7eeb445a2ade52707d093b50799b31ab719`.

The runtime archive remains 380,129 bytes with SHA-256 `cb1e282ba3712070ab197f922447ef97bda7cb7dc51b0ca27565cc6288166f1b` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 132,872 bytes with SHA-256 `1beb2c57f29a587e5d05ed20152204d38769556d3a63550fce3c0d01b21d82be` and root manifest identity `b9beb8697bb55c654a74476b69a5a21fbcded9791e04f771ab4b25186d2d1349`.

## Rejected alternatives

### Keep one structural case

Rejected. Every selected production module can now prove one owned value.

### Combine all constants into one test

Rejected. Independent declarations retain owner-local failures and case identities.

### Treat duplicate artifacts as duplicate tests

Rejected. Cases and artifacts have separate identity domains.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0279](WIP-0279-native-compiler-package-suite.md)
- [WIP-0283](WIP-0283-bounded-native-bitwise-coverage.md)
- [WIP-0285](WIP-0285-native-compiler-callable-suite.md)
