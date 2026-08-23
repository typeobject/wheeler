# WIP-0332: Native compiler resolved local-equality suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0330, WIP-0331 |
| Supersedes | Product-only resolved local-equality evidence |
| Superseded by | WIP-0333 native compiler resolved local-inequality suite |

## Summary

Execute every public query in the physical `ResolvedLocalEqualityKinds.w` owner through an independent native compiler package case.

This is the first checked-in compiler target to import `ResolvedStatements.w`. Its ninety-two public constants crossed the former package-adapter ceiling. The target therefore proves that the 256-constant profile reaches physical compiler source rather than only a generated boundary fixture.

## Graph

All cases retain three physical sources:

```text
NativeCompilerResolvedLocalEqualityTests
  -> ResolvedLocalEqualityKinds
       -> ResolvedStatements
```

The tests check the last admitted equality opcode, the first signed equality opcode, and source decoding at the first Boolean equality opcode. Numeric inputs identify stable opcode boundaries without duplicating the production range formulas.

## Evidence

`NativeCompilerNestedHelperEntryExampleTest` compiles one entry that calls all three physical functions. The native artifact matches stage 0 byte for byte and executes successfully.

`nativecompilerresolvedlocalequalitytests` publishes three cases with source identity `e061c72580b2fb3bdb4332b75bdc6372cb114d3395d1eaf2be76d536564ebf1b` and execution identity `518476097b85887ad9826a6a31d5203a10d3a0a9372509f40227d8f6ea7c7e4c`.

| Query | Artifact identity | Coverage identity |
| --- | --- | --- |
| Equality membership | `23a0dfd6042a00ea6cb05b7f26eceaada86086cbddd09572caba779525a73836` | `6a17ae9872a3b616e6eca1c061a5fe902a97b6a7880fe24e3bfb520e3cec76a7` |
| Signed membership | `8503853a9531bb3f45aaa0e65dadc437ed5739b2e1e1be79d331ef2d764aca23` | `b0fa6246b891fccd82bc8ca44aeab44cd34b4343c771ac8253b1d6c35f75d8b9` |
| Boolean source | `42ae13381849168546fd8ddf474f42d96ed6c62d1ddc5c63e56831819cc9b75c` | `56600f2c75246dde9339f1a506567ff68c1a18a55d1b79ffc7a88c892d8ae9a5` |

`wheeler test wheeler-compiler --format json` publishes seventy selected, seventy passed, and zero failed cases with report identity `fb83fdbb1bb763287b04884c95138e78714a5b4eb859b00d447c9f861adf77cb`. The canonical workspace checks 127 targets.

## Acceptance

- [x] Every public resolved local-equality query has an independent native case.
- [x] The complete ninety-two-constant opcode owner remains physical input.
- [x] Membership reaches the final admitted equality opcode.
- [x] Signed membership starts at the exact signed column.
- [x] Source decoding starts at the exact Boolean column.
- [x] One combined physical artifact matches stage 0 byte for byte.
- [x] The combined artifact executes exactly once.
- [x] Three selected native cases compile and execute independently.
- [x] JSON, terminal, and JUnit adapters consume the same seventy native rows.
- [x] Compiler, package, workspace, documentation, and file policy gates pass.

The canonical compiler manifest contains 12,448 bytes and remains below the 16,384-byte native bound.

The compiler archive contains 3,057,620 bytes with SHA-256 `1583d5f191c9b3aaf623c3004b172aab8aaa6ef51676ba43062a3e9bfbc11415`. Its root manifest identity is `4bb94d7015999ae6c853a640dc196aea79536049b10a2013c5a720fc909c0779`.

## Rejected alternatives

### Copy the two opcode bases into the test owner

Rejected. That would test duplicated constants rather than imported physical authority.

### Project only the referenced constants

Rejected. Native package tests transport complete selected sources. Partial declaration projection cannot prove owner identity or archive provenance.

### Treat one combined entry as package coverage

Rejected. Differential parity proves graph compilation. Independent native cases retain distinct execution and coverage identities for each public query.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0330](WIP-0330-native-256-constant-owner-profile.md)
- [WIP-0331](WIP-0331-native-16k-test-manifest-bound.md)
- [WIP-0333](WIP-0333-native-compiler-resolved-local-inequality-suite.md)
