# WIP-0326: Native compiler opcode-kind suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0325 |
| Supersedes | Constant-only opcode package coverage |
| Superseded by | WIP-0327 native single imported helper ownership |

## Summary

Execute every public opcode-family classifier in the physical `OpcodeKinds.w` owner through an independent native compiler package case.

The suite checks global constant mutation, result-slot fill, signed result binary, and local math families. Each input selects the last admitted member of its family. `isLocalMathOpcode` therefore executes its nested call to `isResultBinaryOperation` before accepting `OPCODE_LOCAL_ROTR32`.

## Graph

All four cases retain the same three physical sources:

```text
NativeCompilerOpcodeKindTests -> OpcodeKinds -> Opcodes
```

The test root passes canonical numeric opcode values. It does not import `Opcodes.w`, because the classifier owns that dependency and package roots do not inherit or repeat transitive visibility.

## Evidence

`NativeCompilerNestedHelperEntryExampleTest` compiles one entry that calls all four physical members. The artifact matches stage 0 byte for byte and executes successfully.

`nativecompileropcodekindtests` publishes four cases with source identity `1a1187b71042790d232c4e0791ba1d282e904a1c9ecf84be474479c69a3d7997` and execution identity `c038169d934891a7c3535dfdad76fac7c5128da39e8ca80c087718490c110bc4`.

| Query | Artifact identity | Coverage identity |
| --- | --- | --- |
| Global constant | `2ea15fdc9f457595754ce868d8feef6781ca6ad615e0492314e7cc1e02c30268` | `83a9fcc7c5ee94259b81bc71596ed85312cd485dded2d2f5bfe3f151410031e5` |
| Result fill | `a456c0ab23886678e84e04b2403094a25fa888b12eb8185df1d67a5241f8d68d` | `9cd36bc6f5b14899a392876dc5a367052bfe30664acad11ae9e6d016dc95fcaf` |
| Result binary | `a8e213ae95719240fe7e42cf008b41cce7efc6d6719d0ab3c336283da32bdf65` | `f6fdc9ff012ec742c09b8cdca4995d09a143065a2fa883b3157b513747505540` |
| Local math | `e6021f397cd79b0bb7cb4c3c689923f3e86849258c74f3da579256416f8bbe31` | `d9941b04ebf84514e716f882b868e9889ac2081e8d9b8a8c07218d69b46e7dbe` |

`wheeler test wheeler-compiler --format json` publishes sixty-three selected, sixty-three passed, and zero failed cases with report identity `cb3b40eeb381a44fe0431f6bd586837cf92e1c1937adf41f77feb5e202a7f208`. The canonical workspace checks 124 targets.

## Acceptance

- [x] Every public opcode-family classifier has an independent native case.
- [x] Each case reaches the final admitted member of its family.
- [x] The local-math case executes the nested binary classifier.
- [x] One combined physical artifact matches stage 0 byte for byte.
- [x] The combined artifact executes exactly once.
- [x] Four selected native cases compile and execute independently.
- [x] JSON, terminal, and JUnit adapters consume the same sixty-three native rows.
- [x] Compiler, package, workspace, documentation, and file policy gates pass.

The compiler archive contains 3,054,042 bytes with SHA-256 `abc4a2349f10c6cb7ec5f1463e8059f1aecae8978bb03c4cd68ea001c6f469e3`. Its root manifest identity is `e72b3007f180998b358b2228794a298bc52f444c2e5229203139f5322da99c21`.

## Rejected alternatives

### Import the opcode table from the test root

Rejected. The production classifier already has that direct dependency. A test should not alter graph authority merely to avoid writing the canonical input value.

### Combine the package checks

Rejected. Independent cases retain exact coverage identities and isolate the nested local-math path.

### Reimplement the families in tests

Rejected. Constants and arithmetic ranges do not replace the physical predicates that the compiler calls.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0325](WIP-0325-native-compiler-instruction-form-suite.md)
- [WIP-0327](WIP-0327-native-single-imported-helper-ownership.md)
