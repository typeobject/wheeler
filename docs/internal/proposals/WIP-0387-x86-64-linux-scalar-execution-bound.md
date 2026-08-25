# WIP-0387: x86-64 Linux scalar execution bound

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and native runtime maintainers |
| Created | 2026-08-25 |
| Updated | 2026-08-25 |
| Area | Native bootstrap, AOT lowering, execution bounds, trap parity |
| Depends on | WIP-0007, WIP-0008, WIP-0026, WIP-0381, WIP-0386 |
| Supersedes | Per-evaluation call budgets and structurally bounded native execution |
| Superseded by | WIP-0388 for 4,096-iteration local loop bounds |

## Summary

Every scalar AOT execution owns one 65,536-instruction budget. Entry instructions, helper instructions, call sites, returns, loop checks, and repeated loop bodies consume the same budget. Instruction 65,536 may complete. Attempting instruction 65,537 traps before that instruction has an effect.

This closes the exponential prior-call graph left by per-function instruction and loop bounds. Eight acyclic functions with 128 instructions each can still call earlier helpers many times. Structural bounds alone do not bound one execution.

## Counting rule

The budget counts canonical WBC instructions on the selected execution path. A call instruction consumes one unit in its caller. Every selected instruction in the callee consumes another unit, including its terminal return. Untaken branch bodies consume nothing. Host framing, input admission, output zeroing, final status validation, and the one host output write are outside the Wheeler instruction count.

The bound applies across the complete root call tree. A helper does not receive a fresh budget. A second process launch receives fresh storage and a fresh budget. WIP-0388 widens the independent local loop limit to 4,096.

## Compile-time evaluation

Constant-input AOT uses one `EvaluationBudget` object for the entry and every recursive Java evaluator invocation. The evaluator rejects an artifact as soon as the selected path asks for instruction 65,537. It does not publish runtime text, status, output, or an image plan for that artifact.

The retained terminal fixture executes exactly 65,536 instructions:

- A four-instruction leaf.
- An inner helper that calls the leaf 61 times, for 306 instructions.
- An outer helper that calls the inner helper three times, for 922 instructions.
- An entry that calls the outer helper 71 times and executes three terminal instructions.

The count is `71 * (1 + 922) + 3 = 65,536`. A 72nd outer call rejects compile-time evaluation.

## Native execution

The entry reserves one 64-bit fuel cell in its aligned stack frame and initializes it to 65,536. Register `r15` retains the cell address across the bounded internal call graph. Each emitted instruction begins with a checked decrement. The decrement from zero to negative branches to the owning function's trap path before the instruction body.

Helpers retain the entry fuel pointer. They neither allocate nor reset fuel. Dynamic-I/O programs cannot be evaluated before input exists, so the same machine check is their semantic authority. Fuel exhaustion follows helper trap propagation to process status 126.

Final status validation and standard-output publication occur after the instruction budget. Fuel exhaustion therefore publishes no application output, even if earlier Wheeler instructions wrote the private output arena and committed a length.

The fuel cell is not a Wheeler local. Source code, call arguments, byte handles, status state, and WBC cannot inspect or modify it.

## Failure boundary

Reject a constant-input selected path above 65,536 during lowering. Trap an input-dependent selected path above 65,536 at native execution. Preserve status 125 for mapped-image framing failures and status 126 for fuel, assertion, arithmetic, range, helper, and dynamic I/O traps.

Do not use elapsed time, host timers, signals, scheduler state, or machine-instruction counts. The budget is deterministic canonical-WBC evidence.

## Evidence

`LinuxX8664ScalarAotCompilerTest.enforcesOneSharedExecutionBound` constructs the counted four-function graph. It requires exact terminal success, next-call evaluator rejection, complete ELF reconstruction for both terminal and dynamic excess artifacts, native-host status 73 at the terminal count, native-host status 126 after excess fuel, and empty output on the excess path.

An independent Alpine 3.22 x86-64 guest launched both retained images. The 9,688-byte terminal image printed the fixed eight-byte loader output and returned status 73. The 13,960-byte excess image returned status 126 with zero output bytes.

Terminal identities:

| Product | Identity |
| --- | --- |
| WBC | `b557a62b59a3980edf9948d18efaeba5777b09ffab33bb51fc592bb608003769` |
| runtime | `75fc122b0eaed6c556af39d2f5396d10fe79319b09e6a6e50cd6acaff6112786` |
| capsule | `d6ffe076b917823bfc1a9bbfc40dcf7167d5583003a45f0eb313245b84c24955` |
| native plan | `1da7e4ac0add79fa17e1dff658860f40d009792ddafa240397ee94647af9ef3a` |
| unsigned PREV | `592e8e15b94f4d6ac428b8ff55fe2706373f23d8931d0469f6283eb7df86209f` |

Excess identities:

| Product | Identity |
| --- | --- |
| WBC | `eb40430d8f233fe24fbf807a8e15867155a485ff942ef66338e887944979d6e2` |
| runtime | `95a368590a3645b4c4492208a2366b0989fd45a7724bb6d284066120bf71aa91` |
| capsule | `faed9ee5f7708601bbc5556d4f769b0d02e13b5942c50f3ef4f4c70c82ad7c4d` |
| native plan | `8aa3a5481303604829ca0268487e2a56a52d1a477e87ed341e1493e06a7379e8` |
| unsigned PREV | `7f17dab8ad707117fcc854ce1998f9d5bcba95191a6e44196ee26a3a397ab388` |

## Acceptance

- [x] One budget covers the entry and complete helper call tree.
- [x] Loops consume fuel on every selected iteration.
- [x] Exactly 65,536 instructions succeed.
- [x] Instruction 65,537 rejects constant evaluation.
- [x] Instruction 65,537 traps dynamic native execution with status 126.
- [x] Fuel traps publish no application output.
- [x] Independent Linux evidence agrees with evaluator counting.

## Rejected alternatives

### Reset fuel on helper entry

Rejected. Repeated or nested calls would multiply the published bound.

### Count native instructions

Rejected. Encoding changes would alter semantics, and one WBC instruction has no stable machine-instruction width.

### Rely on the acyclic call graph

Rejected. Acyclicity bounds depth, not repeated call count.

### Kill long processes with a host timer

Rejected. Scheduler and host load would become semantic inputs and would not identify the failing Wheeler instruction.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0381](WIP-0381-x86-64-linux-bounded-scalar-loops.md)
- [WIP-0386](WIP-0386-x86-64-linux-borrowed-byte-helpers.md)
- [WIP-0388](WIP-0388-x86-64-linux-4096-iteration-byte-loops.md)
