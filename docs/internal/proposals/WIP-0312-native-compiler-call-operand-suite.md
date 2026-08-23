# WIP-0312: Native compiler call-operand suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, tools, and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0311 |
| Supersedes | Standalone assignment-call operand evidence |
| Superseded by | Broader physical compiler package suites |

## Summary

Compile and execute the physical packed assignment-call source decoder through the checked-in native compiler package suite.

`AssignmentCallOperands.w` owns one public four-argument decoder and one private packed-source helper. The public decoder calls the imported arity helper and then its private helper. The native entry therefore exercises a direct owner with two members, one nested executable dependency, exact four-argument entry-call resolution, and private member retention.

## Graph

The target carries four physical sources:

```text
NativeCompilerCallOperandTests -> AssignmentCallOperands
AssignmentCallOperands -> AssignmentCallArities -> AssignmentCallIdentities
AssignmentCallOperands -> AssignmentCallIdentities
```

The linker retains `packedSource` and `assignmentCallSource` as one owner group. It resolves the public function's arity call to the separate imported owner. The test entry may call only `assignmentCallSource`. Private owner marking keeps `packedSource` out of the root-visible surface.

The case supplies seven-argument assignment opcode 933, leading packed operand 218,893,066, trailing packed operand 2,828,841, and source index zero. The decoder publishes ten, the least-significant leading source. This path calls the private helper once and stays within the canonical 512-step native test execution bound. Deeper trailing traversal remains separate evidence.

## Evidence

`NativeCompilerNestedHelperEntryExampleTest` compiles the physical four-source graph byte for byte against stage 0 and executes the artifact.

`nativecompilercalloperandtests` contributes one native package case. Its source identity is `f5069dd7ed4cfafd8b5fd1a5ccf1e6324b9dd7b1bb1da952aadc9df04330e09a`. Its artifact identity is `0fcc67c3da5183d223cb00a3b88290a6e67c27c593665ecc65328a085bd72d5e`, execution identity is `ad3ce221283a421a4c9c7d4d82bcbbe3190d689251bcdf3ffebe61a02c71be24`, and coverage identity is `e96bb5b4d13945684dd1009ae2c04305667aa425debb02c2c5891980a3f1cf41`.

`wheeler test wheeler-compiler --format json` publishes twenty-three selected, twenty-three passed, and zero failed cases with report identity `bec45b2fe636b7cb6365911fb7e4c9952aac8ce853068321329c5a0255d41c86`.

## Acceptance

- [x] One canonical target carries the complete four-source graph.
- [x] The direct owner retains one private and one public function.
- [x] The public function resolves its imported arity call.
- [x] The entry resolves one exact four-argument call.
- [x] Packed source zero decodes to ten.
- [x] The physical graph compiles byte for byte against stage 0.
- [x] The resulting artifact executes exactly once.
- [x] The native package command publishes twenty-three passing cases.
- [x] JSON, terminal, and JUnit adapters consume the same native rows.
- [x] Compiler, runtime, package, conformance, workspace, documentation, and file policy gates pass.

The compiler archive contains 3,038,866 bytes with SHA-256 `8d6824f820febd5e987c994f6ef40a4d9a333201eadda6a2681b78820b63bf2a`. Its root manifest identity is `0fb8c2668df35bfccccd553de06906c7957038d184587cdb5b36155219f18ce2`.

## Rejected alternatives

### Copy the packed-source arithmetic into the test

Rejected. The package suite must compile and execute the physical public and private owner group.

### Export the private helper

Rejected. Testing does not widen production visibility.

### Raise the runtime step bound for one trailing source

Rejected. The canonical bound is a semantic contract. A broader recursive execution case needs its own bounded runtime work.

### Treat the two functions as separate owners

Rejected. Source ownership and private call identity belong to the physical module.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0293](WIP-0293-native-compiler-call-syntax-suite.md)
- [WIP-0310](WIP-0310-native-multi-helper-entry-programs.md)
- [WIP-0311](WIP-0311-native-compiler-call-width-suite.md)
