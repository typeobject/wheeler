# WIP-0406: Forward control marker AOT

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and native backend maintainers |
| Created | 2026-08-26 |
| Updated | 2026-08-26 |
| Area | Native bootstrap, AOT lowering, checkpoint, commit, forward execution |
| Depends on | WIP-0001, WIP-0008, WIP-0026, WIP-0404, WIP-0405 |
| Supersedes | Rejection of forward-only checkpoint and commit markers |
| Superseded by | WIP-0409 for capsule binding |

## Summary

Admit canonical `CHECKPOINT` and `COMMIT` instructions in the one-way scalar AOT process profile. Both markers consume execution fuel and preserve forward machine state. Neither emits machine code beyond the shared fuel check.

This result is deliberately narrower than native history parity. The scalar executable exposes no rewind operation, retained history, commit-horizon query, or history-exhaustion observation.

## Semantics

The stage-0 VM advances past `CHECKPOINT` without changing classical values. `COMMIT` advances and clears retained rewind history. In an execution interface that cannot retain or inspect history, both instructions have the same forward value transition: advance once and leave globals, locals, output, and call state unchanged.

The AOT evaluator and machine backend preserve that transition. They do not erase instruction cost. Each marker consumes one unit from the common 65,536-instruction budget before continuing.

A later native runtime with rewind authority must implement distinct history behavior. This WIP cannot serve as evidence for commit horizons or history exhaustion.

## Validation

Both instructions require zero operands and may appear in any admitted forward or inverse scalar body before its canonical terminal. Existing bytecode verification rejects malformed forms before scalar admission.

Markers grant no status publication. An entry containing only markers and `HALT` still rejects because final process status was not stored. Markers do not change call depth, output commitment, I/O capability, or global ownership.

## Evaluation

Independent static evaluation increments the program counter after either marker. The enclosing evaluation loop consumes shared fuel. Every value and ownership bit remains unchanged.

`COMMIT` does not clear an invented evaluator log. No such log exists in this one-way profile. `CHECKPOINT` does not allocate a hidden snapshot.

## Machine lowering

The x86 body emitter places each marker at its own instruction offset, emits the ordinary R15 fuel decrement and exhaustion branch, then emits no marker-specific bytes. Branches may target either marker exactly. Calls and returns cannot fuse across it because each source instruction retains a distinct fuel boundary.

Generated code contains no history buffer, host callback, dynamic allocation, or ambient state.

## Failure boundary

Reject malformed operands, missing status publication, unsupported rewind-bearing interfaces, fuel exhaustion, or any prior scalar-profile failure. Static rejection publishes no runtime text. Native fuel failure exits with status 126 and publishes no application output.

## Evidence

`ScalarAotArtifacts.controlMarkerArtifact` replaces a shared global with 40, crosses a checkpoint, adds two, checks 42, crosses a commit, subtracts one, and publishes 41 as process status.

`LinuxX8664ScalarAotCompilerTest.lowersForwardControlMarkers` independently evaluates the WBC, binds it to a canonical capsule, native image plan, and ELF, and checks every identity. On x86-64 Linux the image executes both markers, exits with status 41, writes exact `Wheeler\n`, and writes no standard error.

| Product | Identity |
| --- | --- |
| WBC | `7b7f7222338a4b77b1604305eb98c20cde67693f37c99d6e6ecefece70e1f288` |
| runtime | `3edc4e58f037392d63fd5e823c1ab395b4e75ac086f1a5859404f242a17cf741` |
| capsule | `2c6ce55839b61b9c1378de4c5e0d1f0d47c533de3ed6dbdbd64ea0bd7029e01d` |
| native plan | `f52e0e561e04374b5e626b51691fe74c8b689b80a8aa29e1f69a4c1948649c12` |
| unsigned PREV | `dec745548190f7f59a27cd33ac9b86df8788918b2ae1b57ebcef13cdfb7e83f8` |

## Acceptance

- [x] Canonical checkpoint and commit forms enter the scalar profile.
- [x] Both retain exact forward globals, locals, output, and call state.
- [x] Both consume common execution fuel.
- [x] Neither marker satisfies process-status publication.
- [x] Branch offsets retain each marker as an instruction boundary.
- [x] No synthetic history or hidden host authority is introduced.
- [x] WBC, runtime, capsule, plan, ELF, and PREV identities remain exact.
- [x] Native x86-64 Linux launch observes exact status and output.

## Rejected alternatives

### Drop markers before instruction accounting

Rejected. Source instructions remain observable through the execution bound.

### Allocate a partial history stack

Rejected. Incomplete rewind state would overclaim WIP-0001 parity.

### Treat commit as process termination

Rejected. Commit changes history, not forward control flow.

### Mark native rewind complete

Rejected. No rewind interface or history observation exists in this profile.

## References

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0404](WIP-0404-scalar-global-replacement-aot.md)
- [WIP-0405](WIP-0405-directional-scalar-aot-calls.md)
- [WIP-0407](WIP-0407-helper-owned-process-status-aot.md)
- [WIP-0408](WIP-0408-reversible-scalar-result-slot-aot.md)
- [WIP-0409](WIP-0409-exact-native-capsule-binding.md)
