# WIP-0400: Compiler-frame scalar AOT bounds

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, and native backend maintainers |
| Created | 2026-08-26 |
| Updated | 2026-08-26 |
| Area | Native bootstrap, AOT lowering, compiler profile, frame bounds |
| Depends on | WIP-0007, WIP-0008, WIP-0026, WIP-0387, WIP-0398, WIP-0399 |
| Supersedes | 32-local and 128-instruction scalar AOT bounds |
| Superseded by | None |

## Summary

Raise ordinary scalar AOT functions to 256 typed locals and 512 instructions. These are the established Wheeler-native interpreter frame and code-window bounds. The static AOT shim now admits up to 16 KiB of validated machine code so the terminal instruction fixture reaches image construction.

The dynamic-I/O entry keeps its independent 64-local bound and fixed byte arenas. Function count, parameters, globals, loops, fuel, input, and output do not widen.

## Function profile

`ScalarAotProgram.MAX_LOCALS` is 256 and `MAX_INSTRUCTIONS` is 512. Every local still has one canonical signed, Boolean, or admitted handle type. Every instruction still passes complete operand, initialization, branch, call, storage, ownership, and terminal checks before evaluation.

The terminal fixture combines both bounds. It declares 256 signed locals, executes 509 canonical `NOP` instructions, writes status 73 through local 255, and halts at instruction 511. This keeps the control-flow shape simple while proving the highest local and final instruction coordinates together.

Local 256 and instruction 512 are the final admitted zero-based coordinates. A 257th local or 513th instruction rejects before evaluation.

## Machine frame

The entry reserves its complete aligned local, global, and fuel frame before execution. Local offsets remain checked 32-bit displacements and the terminal local occupies byte offset 2,040. The frame requires no heap allocation, red zone, dynamic alloca, or host metadata.

Each Wheeler instruction consumes the shared fuel cell before its machine effect. The 512-instruction body therefore cannot bypass WIP-0387 by widening code. Calls still share that one cell.

The position-independent static application-code input to `LinuxX8664EntryShim` is bounded at 16 KiB, matching the existing dynamic-I/O machine-code input. Runtime text remains far below the independent 16 MiB runtime-text limit. The shim does not accept an unverified code stream from a physical path.

## Separate output entry

A one- or two-parameter output entry remains limited to 64 locals. Its 4,096-byte input and output arenas, length slots, handles, globals, and fuel occupy a separately computed aligned frame. This WIP does not let scalar frame capacity consume byte-arena authority.

Ordinary helpers called by that entry may use the 256-local bound if their admitted handle types and instructions remain valid.

## Failure boundary

Reject local 257, instruction 513, static application code byte 16,385, an invalid local type, an uninitialized read, a malformed terminal, fuel exhaustion, or any prior scalar-profile failure. Rejection returns no runtime text, capsule, image plan, or image bytes.

A larger core WBC limit cannot silently widen this AOT profile. Each boundary remains named and tested independently.

## Evidence

`ScalarAotArtifacts.localBoundArtifact(256)` reaches the local edge. `instructionBoundArtifact(512)` reaches both edges in one artifact. Variants with 257 locals and 513 instructions reject. Independent evaluation observes status 73.

`LinuxX8664ScalarAotCompilerTest.lowersCompilerWidthFramesAndBodies` binds the terminal WBC to a canonical capsule, native image plan, and ELF. On x86-64 Linux the kernel launches the complete image, reads local 255, executes all 512 Wheeler instructions under shared fuel, exits with status 73, writes exact `Wheeler\n`, and writes no standard error.

| Product | Identity |
| --- | --- |
| WBC | `b2804f1ac4c7adca624b28dd201748c3e5c54868f9db68665a07010d2234fe61` |
| runtime | `61054c91676da459114a52ca9ecdaa1c7ab240644a8735fc6571c4d7f90adfec` |
| capsule | `0150846094f14c76a4609bccb0a37c702979363bdca841e7ee1f1be25a94485e` |
| native plan | `923d2a75e8d39c8fbd1bb7483b96dffaf7ed475169a74caad3854f2e923d8730` |
| unsigned PREV | `313bc2cd71e0047069f815a45efba04a5ce232e3d9f3ee33d5b2524e708d0fed` |

## Acceptance

- [x] Ordinary functions admit one through 256 typed locals.
- [x] Ordinary functions admit two through 512 instructions.
- [x] Local 255 and instruction 511 execute in one retained artifact.
- [x] Local 257 and instruction 513 reject before publication.
- [x] Every instruction consumes the shared execution budget.
- [x] Dynamic-I/O entry local and byte bounds remain unchanged.
- [x] Static machine code remains bounded to 16 KiB.
- [x] WBC, runtime, capsule, plan, ELF, and PREV identities remain exact.
- [x] Native x86-64 Linux launch observes exact status and output.

## Rejected alternatives

### Share the output-entry local bound

Rejected. Byte arenas and host handles give that entry a different frame contract.

### Allocate large local frames on a heap

Rejected. The bounded stack frame is simpler and carries no allocator authority.

### Stop charging NOP instructions

Rejected. Canonical NOP still consumes one Wheeler instruction and must consume fuel.

### Infer machine-code capacity from runtime-text capacity

Rejected. The application-code input has its own smaller preflight bound.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0387](WIP-0387-x86-64-linux-scalar-execution-bound.md)
- [WIP-0398](WIP-0398-compiler-width-scalar-aot-graph.md)
- [WIP-0399](WIP-0399-compiler-width-scalar-aot-arguments.md)
