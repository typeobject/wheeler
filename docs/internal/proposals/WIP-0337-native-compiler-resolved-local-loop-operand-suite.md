# WIP-0337: Native compiler resolved local-loop operand suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0336 |
| Supersedes | Product-only resolved local-loop operand evidence |
| Superseded by | WIP-0338 native compiler resolved local-loop kind suite |

## Summary

Execute both public operand decoders in `ResolvedLocalLoopOperands.w` through independent native compiler package cases.

The target retains `ResolvedStatements.w` and `LoopKinds.w` as physical inputs. One opcode encodes target local three and form nineteen, exercising quotient and remainder decoding against the canonical twenty-four-form column.

## Graph

```text
NativeCompilerResolvedLocalLoopOperandTests
  -> ResolvedLocalLoopOperands
       -> LoopKinds
       -> ResolvedStatements
```

Neither imported owner is projected or reduced to the referenced constants.

## Evidence

`NativeCompilerNestedHelperEntryExampleTest` compiles one entry that calls both physical functions. The native artifact matches stage 0 byte for byte and executes successfully.

`nativecompilerresolvedlocalloopoperandtests` has source identity `d3f6b91387b0375ed62fb059ce3158392f58fa960f6bfa68ddd63ae69f94c4cd` and execution identity `77283d2be5b0d54fb5a03e92412a77594ddf8f846692f56340a2d2885f68a6bb`.

| Query | Artifact identity | Coverage identity |
| --- | --- | --- |
| Target local | `78ae7ac9104fa3b5549ff1d95ea8a2fbaf33a673d21f3ebdaf73894b25cc0bfb` | `39a253cdf0b3e4d0866a9fa1b41794409332c21411aa1a2e879fcc25a3487281` |
| Form bits | `89e733f358e5405dffc997c79522f00fa1719f6fc0d905918f96e02f10a5dde1` | `b9ccdce16f9a056619039a10f2ce0047aa85d07190bc5d8b04d45baa9aa49bc6` |

`wheeler test wheeler-compiler --format json` publishes ninety-one selected, ninety-one passed, and zero failed cases with report identity `51e27633c0eb4f6c39b06784d267a4076244562146b2a43b01304f40d3b1d05d`. The canonical workspace checks 133 targets.

## Acceptance

- [x] Both public local-loop operand decoders have independent native cases.
- [x] The complete physical opcode and form owners remain input.
- [x] Target decoding uses a nonzero target.
- [x] Form decoding retains reversal, limit, and condition bits.
- [x] One combined artifact matches stage 0 byte for byte.
- [x] The combined artifact executes exactly once.
- [x] Both selected cases compile and execute independently.
- [x] JSON, terminal, and JUnit adapters consume the same ninety-one rows.
- [x] Compiler, package, workspace, documentation, and file policy gates pass.

The complete package run finished in six minutes and twelve seconds under its seven-minute host guard.

The compiler manifest contains 15,442 bytes. The compiler archive contains 3,065,944 bytes with SHA-256 `98fe8f76782ad4debba538cca942c621c14f4210a2ad195e0d674d0dd98d564f`. Its root manifest identity is `0a58939b2e85842585bb6c52c3b586936832b785cb827c39d8d2d11223a59d48`.

## Rejected alternatives

### Use target zero and form zero

Rejected. A zero result can hide a missing subtraction, division, or modulo operation.

### Copy the base and form count into test source

Rejected. The physical imports own those values and their archive identity.

### Merge the two checks into one package case

Rejected. Each public decoder retains its own artifact and coverage evidence.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0336](WIP-0336-native-compiler-resolved-local-loop-form-suite.md)
- [WIP-0338](WIP-0338-native-compiler-resolved-local-loop-kind-suite.md)
