# WIP-0313: Native compiler void-call operand suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, tools, and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-09-04 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0312, WIP-0314 |
| Supersedes | Standalone void-call operand evidence |
| Superseded by | None |
| Follow-up | WIP-0315 native compiler void-call width suite |

## Summary

Compile and execute the physical packed void-call source decoder through the checked-in native compiler package suite.

`VoidCallOperands.w` owns two private decoders and one public four-argument decoder. `VoidCallKinds.w` owns three public shape queries. The native entry reaches all six functions: it asks for arity, takes the narrow third-source path, decodes both packed operand columns, and returns one trailing source. This is the first package case with two complete three-member production owners between an entry and its result.

## Graph

The target carries three physical sources:

```text
NativeCompilerVoidCallOperandTests -> VoidCallOperands -> VoidCallKinds
```

The linker retains each production source as one owner group. The test entry may call only `voidCallSource`. The two private operand decoders remain unavailable to the root while calls from their physical owner resolve normally.

The case supplies seven-argument void opcode 31,744, leading packed operand 218,893,066, trailing packed operand 387,323,156, and source index six. It publishes 22 after 221 artifact transitions, below the canonical 512-step execution bound and the WIP-0314 255-transition coverage bound.

## Evidence

`NativeCompilerNestedHelperEntryExampleTest` compiles the physical three-source graph byte for byte against stage 0 and executes the artifact.

`nativecompilervoidcalloperandtests` contributes one native package case. Its source identity is `ec9518eee88f6c8fc9cc333c08e781a9e2abb8e0fb716c5e494961d0ec99cc96`. Its artifact identity is `80703df0e7366b6e3a410750e42962655f0b534e462ecedba9eea62d302f8818`, execution identity is `2e3a0c1ec0db15b5e1d3bb0e6f58e8caec78913749af7b0169d74096ac707f29`, and coverage identity is `a66842c3dc2f5180e549790f0e5a87be08702da4c1efc04614054b68c4e23ffe`.

`wheeler test wheeler-compiler --format json` publishes twenty-four selected, twenty-four passed, and zero failed cases with report identity `18838be87fe4c2489437a51be49c07d08b4393a3ce1b25d0be34f14301678ef2`.

## Acceptance

- [x] One canonical target carries the complete three-source graph.
- [x] Both production sources retain their complete three-member owner groups.
- [x] Private operand helpers remain private.
- [x] Cross-owner arity and third-source calls resolve exactly.
- [x] Both packed columns execute before trailing source six publishes 22.
- [x] The physical graph compiles byte for byte against stage 0.
- [x] The resulting artifact executes exactly once.
- [x] The native package command publishes twenty-four passing cases.
- [x] JSON, terminal, and JUnit adapters consume the same native rows.
- [x] Compiler, runtime, package, conformance, workspace, documentation, and file policy gates pass.

The compiler archive contains 3,039,977 bytes with SHA-256 `976d60788b7ca8613ece94e18ed9e4dbfcd01cd3126aab58fe747413dd1829cc`. Its root manifest identity is `8ea4bd0279c654b1773bd9a338e3e2d35d68c4aa85ed011b2271ce14c2f7d2da`.

## Rejected alternatives

### Copy the packed arithmetic into the test

Rejected. The package suite must execute the physical private helpers and both physical owner groups.

### Export the private decoders

Rejected. Testing does not widen production visibility.

### Test only a leading source

Rejected. A trailing source forces both packed columns and the complete shape-query path through execution.

### Split one physical owner per function

Rejected. The linker already admits bounded member groups. Source ownership should not be rewritten to flatter a test profile.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0293](WIP-0293-native-compiler-call-syntax-suite.md)
- [WIP-0310](WIP-0310-native-multi-helper-entry-programs.md)
- [WIP-0312](WIP-0312-native-compiler-call-operand-suite.md)
- [WIP-0314](WIP-0314-native-255-transition-coverage.md)
- [WIP-0315](WIP-0315-native-compiler-void-call-width-suite.md)
