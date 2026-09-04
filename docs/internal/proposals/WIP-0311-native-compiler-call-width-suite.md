# WIP-0311: Native compiler call-width suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, tools, and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-09-04 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0310 |
| Supersedes | Standalone assignment-call width evidence |
| Superseded by | None |
| Follow-up | WIP-0312 native compiler call-operand suite |

## Summary

Compile and execute the three physical assignment-call width decoders through the checked-in native compiler package suite.

`AssignmentCallCodeWidths.w`, `AssignmentCallInstructionWidths.w`, and `AssignmentCallLocalWidths.w` each call `AssignmentCallArities.w`. The test root imports all three width modules. The native graph therefore contains one shared executable dependency beneath three direct executable owners. Each selected case calls one exact direct owner.

This graph was the smallest checked-in compiler partition blocked by the old one-helper entry profile. WIP-0310 removed that restriction. The package suite now proves the production graph rather than a synthetic substitute.

## Source graph

The target carries six physical sources:

```text
NativeCompilerCallWidthTests
  -> AssignmentCallCodeWidths       -> AssignmentCallArities -> AssignmentCallIdentities
  -> AssignmentCallInstructionWidths -> AssignmentCallArities -> AssignmentCallIdentities
  -> AssignmentCallLocalWidths      -> AssignmentCallArities -> AssignmentCallIdentities
```

The shared arity helper appears once in the linked function table. Each width owner retains its own module-qualified function identity. The entry call row selects code, instruction, or local width without relying on helper order.

The code-width case expects 400 encoded bytes for a seven-argument assignment call. The instruction-width case expects sixteen instructions. The local-width case expects fifteen temporary locals. All three use production identity 933 and execute exactly once.

## Evidence

`nativecompilercallwidthtests` contributes three independent native cases. The target source identity is `8f80ccd15eb99e058d381f819f357b5641470ffca45d9c7327a449524b2dc5e7`, and its execution identity is `7a1e1c408eff3477e0e7e178fe3591c1bf85bcdca6bf467b945d3b49be62401e`.

The code, instruction, and local artifacts have identities `688536a99c4f7c6059cd01169684223ac8b640c3ab7f12485a26fba691c988aa`, `9a49b8242c1d5ca801468549585de9c2e6db20402dbe1ca3bea272fd3cecb4b7`, and `55a8c0a0e25df7c519f41112bb5a037676b1944909117c3d559ac9fc8b2a5662`.

`wheeler test wheeler-compiler --format json` publishes twenty-two selected, twenty-two passed, and zero failed cases with report identity `d13d143930342b38a0661b35f9fa687cd5abeae7ae8e469894d3bd88a14fb3e2`.

## Acceptance

- [x] One canonical test target carries the complete six-source graph.
- [x] Three direct width owners share one nested arity owner.
- [x] Entry call rows select three distinct helper functions.
- [x] The code-width case publishes 400.
- [x] The instruction-width case publishes sixteen.
- [x] The local-width case publishes fifteen.
- [x] Three cases compile and execute exactly once.
- [x] The native package command publishes twenty-two passing cases.
- [x] JSON, terminal, and JUnit adapters consume the same native rows.
- [x] Compiler, runtime, package, conformance, workspace, documentation, and file policy gates pass.

The compiler archive contains 3,037,654 bytes with SHA-256 `f94dfc131a9d33c95fe7010e1221556ea871987c19ded3acd6ac4217518cfb7b`. Its root manifest identity is `88fe9825f5f91d85c393cddeacd75b0a1038634a59c91c3cb5091c412aa24408`.

## Rejected alternatives

### Copy the arithmetic into the tests

Rejected. The package suite must execute the physical compiler functions and their nested import.

### Merge the width decoders

Rejected. Encoded bytes, instructions, and locals remain separate units with separate owners.

### Add one case with three calls

Rejected. Independent cases retain separate artifacts, coverage, diagnostics, and identities.

### Duplicate the arity helper per width owner

Rejected. The graph linker already owns shared dependency deduplication. Copying the helper would hide a graph failure.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0305](WIP-0305-native-compiler-call-arity-suite.md)
- [WIP-0310](WIP-0310-native-multi-helper-entry-programs.md)
- [WIP-0312](WIP-0312-native-compiler-call-operand-suite.md)
