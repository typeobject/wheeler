# WIP-0333: Native compiler resolved local-inequality suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0332 |
| Supersedes | Product-only resolved local-inequality evidence |
| Superseded by | WIP-0334 native compiler resolved local-assignment suite |

## Summary

Execute every public query in `ResolvedLocalInequalityKinds.w` through an independent native compiler package case.

The suite retains `ResolvedStatements.w` as physical input. Equality and inequality share the then-complete ninety-two-constant opcode authority without projecting either column into test source.

## Graph

```text
NativeCompilerResolvedLocalInequalityTests
  -> ResolvedLocalInequalityKinds
       -> ResolvedStatements
```

The cases check the last admitted inequality opcode, the first signed inequality opcode, and source decoding at the first Boolean inequality opcode.

## Evidence

`NativeCompilerNestedHelperEntryExampleTest` compiles one entry that calls all three physical functions. The native artifact matches stage 0 byte for byte and executes successfully.

`nativecompilerresolvedlocalinequalitytests` publishes three cases with source identity `04c2e90f0ee9bdaf57e5cb7c06e2dd9aafede8b8582d06a6687dba6a6e448527` and execution identity `401670fddd269627f3e2701be6a798a644cff95d331a88e6fffdbd32c0a6f4f7`.

| Query | Artifact identity | Coverage identity |
| --- | --- | --- |
| Inequality membership | `5ead4a013c0f13496e135867d4a4147fb9fb0cf0e68ec95f34337a5aec4e7678` | `6a17ae9872a3b616e6eca1c061a5fe902a97b6a7880fe24e3bfb520e3cec76a7` |
| Signed membership | `ecf9f824f128959a8d0c540053b8159f5ac8360f34d5da4904e6ee0532688504` | `b0fa6246b891fccd82bc8ca44aeab44cd34b4343c771ac8253b1d6c35f75d8b9` |
| Boolean source | `c8fc133b7223ae775efc49e7734895cbc062b1c279df9015ce47477980d3a309` | `56600f2c75246dde9339f1a506567ff68c1a18a55d1b79ffc7a88c892d8ae9a5` |

`wheeler test wheeler-compiler --format json` publishes seventy-three selected, seventy-three passed, and zero failed cases with report identity `79802787e6d16cd807ade6e13d9e61ffb2db301feba846aa2da6cd2615b2bc84`. The canonical workspace checks 128 targets.

## Acceptance

- [x] Every public resolved local-inequality query has an independent native case.
- [x] The complete statement-opcode owner remains physical input.
- [x] Membership reaches the final admitted inequality opcode.
- [x] Signed membership starts at the exact signed column.
- [x] Source decoding starts at the exact Boolean column.
- [x] One combined physical artifact matches stage 0 byte for byte.
- [x] The combined artifact executes exactly once.
- [x] Three selected native cases compile and execute independently.
- [x] JSON, terminal, and JUnit adapters consume the same seventy-three rows.
- [x] Compiler, package, workspace, documentation, and file policy gates pass.

The compiler manifest contains 12,946 bytes. The compiler archive contains 3,058,977 bytes with SHA-256 `2298dc4e7f3c339d5fa63a90dbb938a38f5134116edc140aca6a88cea6727104`. Its root manifest identity is `15ca91660873e7d896d0bfe8c641f3166ed38a37a313275bd3e6247523364831`.

## Rejected alternatives

### Infer inequality from equality coverage

Rejected. The columns have separate bases and physical consumers. Equal control-flow shapes do not establish equal source authority.

### Retain only the two referenced opcode bases

Rejected. Package tests compile complete canonical owners. Declaration projection would lose archive and module provenance.

### Merge all three checks into one package case

Rejected. Independent cases preserve distinct artifact, execution, and coverage evidence for each public query.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0332](WIP-0332-native-compiler-resolved-local-equality-suite.md)
- [WIP-0334](WIP-0334-native-compiler-resolved-local-assignment-suite.md)
