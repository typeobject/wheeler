# WIP-0390: x86-64 Linux shared scalar globals

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and native runtime maintainers |
| Created | 2026-08-25 |
| Updated | 2026-08-25 |
| Area | Native bootstrap, AOT lowering, scalar state, helper calls |
| Depends on | WIP-0007, WIP-0008, WIP-0026, WIP-0382, WIP-0387, WIP-0389 |
| Supersedes | The one-global scalar AOT process-status profile |
| Superseded by | None |

## Summary

Scalar AOT admits one through 32 signed global state slots. Global zero remains the process `status` authority. Helpers may load any global and may store non-status globals. Entry code alone commits process status.

Compile-time evaluation and generated x86-64 share one mutable global array across the complete prior-helper call tree. Calls do not copy, reset, or reconstruct state.

## Global profile

A valid program has:

- One through 32 canonical globals.
- Global zero named `status` with initial value zero.
- Signed 64-bit initial values retained exactly for every additional global.
- Dense WBC global indices.
- Signed destinations for `LOCAL_LOAD_GLOBAL`.
- Signed sources for `LOCAL_STORE_GLOBAL`.
- At least one entry-owned store to global zero on the selected static path.

Helpers may read status but cannot store it. Helpers may read and store globals one through 31. Entry code may read and store every admitted global. Final process status still validates the value in global zero from 0 through 124 before application output.

WBC globals are scalar state, not owned buffers, pointers, capabilities, host handles, or thread-local storage.

## Evaluation

`EvaluationState` owns one array initialized from the canonical WBC global table. The entry and every nested evaluator call receive the same object. A helper store is immediately visible to its caller and to later calls.

The status-written flag also belongs to shared evaluation state. Helper stores cannot satisfy it because helpers cannot target global zero. The independent 65,536-instruction budget remains shared beside global state.

## Machine layout

The entry frame lays out locals, all global slots, fuel, dynamic-I/O metadata when present, and bounded byte arenas. Register `r14` retains the address of global zero across the internal call graph. Global loads and stores use checked constant displacements from that base. Register `r15` independently retains execution fuel.

Every global is initialized before entry WBC execution. Helpers allocate only local frames and address the retained entry state through `r14`. UTF-8 decoding, Linux system calls, and helper argument transfer do not alter `r14`.

The runtime contains no absolute global address, relocation, heap allocation, thread-local lookup, or dynamic symbol. A fresh process launch creates fresh global state.

## Source boundary

Physical source may use helper-owned state transitions:

```wheeler
state long status = 0;
state long counter = 40;
state long mask = 3;

long update() {
  counter += 1;
  return counter ^ mask;
}

entry void main() {
  long result = update();
  result = update();
  status = result;
}
```

The first call observes counter 40, stores 41, and returns 42. The second observes 41, stores 42, and returns 41. The entry publishes status 41.

## Failure boundary

Reject zero globals, global 33, a nonzero or renamed status global, an out-of-range global index, a nonsigned local operand, helper writes to status, an entry path without a status store, and every prior scalar-profile failure.

Do not infer process status from the last written non-status global. Only canonical global zero supplies the final native exit value.

## Evidence

`LinuxX8664ScalarAotCompilerTest.lowersBoundedSharedScalarGlobals` executes the two-call state transition with three globals, repeats it at the exact 32-global terminal profile, rejects global 33, reconstructs the complete ELF, and on x86-64 Linux observes status 41 and exact fixed loader output.

`ImageCommandTest.lowersSharedScalarStateThroughHelpers` compiles the physical source form and requires the command to report evaluated status 41 before atomic runtime publication.

An independent Alpine 3.22 x86-64 guest launched the 5,584-byte physical source image. It returned status 41 and wrote the exact eight-byte fixed output.

| Product | Identity |
| --- | --- |
| WBC | `5f7a4b24b6ef25fa3b9e28dfd8755bd6193d2d2f0a6720d8088d122d78c85b96` |
| runtime | `658bf151801055f7c1705f64a3bcadf1cd697ca04b37c07f21187d9a98aded1f` |
| capsule | `d953056babfd618af0a9b633f07e50b96d622293d6b9ff145581812381af90d2` |
| native plan | `2cc9493fe13c9525ee4bf65fdb6ac5897df7ede962a678554e4928ec5f33a550` |
| unsigned PREV | `791484102d272b88f219090a911bd6f52fe87d3670a7d734c932425233517268` |

## Acceptance

- [x] One through 32 globals retain exact initial values.
- [x] Entry and helpers observe one shared state array.
- [x] Helpers mutate non-status globals without copying state.
- [x] Entry alone commits status global zero.
- [x] Global 32 succeeds and global 33 rejects.
- [x] Evaluator and native process agree on status 41.
- [x] Independent Linux evidence uses physical source.

## Rejected alternatives

### Copy globals into each helper frame

Rejected. Caller and callee would disagree after a state transition, and nested call order would become a lowering artifact.

### Let any global become process status

Rejected. Native exit authority must remain one canonical named slot.

### Store globals in writable image data

Rejected. The current canonical ELF profile has executable runtime text and read-only capsule data. Per-process state belongs in the entry stack.

### Permit helper writes to status

Rejected for this profile. Entry ownership keeps final process policy visible at the root boundary.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0382](WIP-0382-x86-64-linux-scalar-state-checks.md)
- [WIP-0387](WIP-0387-x86-64-linux-scalar-execution-bound.md)
- [WIP-0389](WIP-0389-x86-64-linux-strict-utf8-input.md)
