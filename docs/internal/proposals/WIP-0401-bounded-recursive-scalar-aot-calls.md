# WIP-0401: Bounded recursive scalar AOT calls

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, and native backend maintainers |
| Created | 2026-08-26 |
| Updated | 2026-08-26 |
| Area | Native bootstrap, AOT lowering, recursion, call depth |
| Depends on | WIP-0007, WIP-0008, WIP-0026, WIP-0387, WIP-0396, WIP-0400 |
| Supersedes | Acyclic-only scalar AOT call graph |
| Superseded by | None |

## Summary

Lower recursive scalar helper calls under one explicit 64-call depth bound. Recursive and mutually recursive call graphs retain the existing shared fuel bound. An admitted recursive program must satisfy both limits.

Acyclic programs retain their prior runtime bytes. Call-depth state is allocated and emitted only when complete graph analysis finds a cycle. This avoids changing established AOT identities merely to add dormant recursion machinery.

## Graph analysis

After every function and call signature validates, `ScalarAotProgram` walks the complete function table with three states: unseen, active, and closed. An edge to an active function marks the graph recursive. The walk does not discard unreachable functions or rewrite function order.

All targets remain fixed helper IDs below the final entry. Dynamic targets and calls to the entry remain invalid. The graph result selects one of two machine profiles:

- acyclic graphs use only the shared fuel state
- recursive graphs use shared fuel plus one shared call-depth cell

The independent evaluator uses the same graph result and limit.

## Depth authority

`ScalarAotProgram.MAX_CALL_DEPTH` is 64. The entry begins at depth zero. Every helper call increments before control transfer and rejects value 65. Every completed call decrements before trap-state inspection or result publication.

The machine entry stores the depth cell in its aligned frame and keeps its address in R13. R13 is private preserved runtime state. Generated instructions do not expose it as a Wheeler local or host ABI register.

A recursive helper still allocates one independent aligned local frame per call. The depth bound therefore supplies a finite stack-frame count. It does not claim an ambient operating-system stack size.

## Fuel interaction

Call depth and fuel are independent. The call instruction consumes fuel before incrementing depth. Every callee instruction consumes the same shared 65,536-instruction cell. A shallow infinite loop traps on fuel. A deep recursive descent traps on depth. A program must fit both.

Static-I/O lowering evaluates with the same enter and leave operations before machine emission. Dynamic-I/O lowering cannot pre-evaluate input-dependent recursion, so generated machine checks remain authoritative at execution.

## Failure boundary

Reject call depth 65, fuel instruction 65,537, a malformed call edge, a call to the entry, an invalid signature, an unsupported recursive body, or any prior scalar-profile failure. Static failure returns no runtime. Dynamic failure publishes no application output and exits with status 126.

A nonterminating self or mutual cycle fails independent evaluation at the depth boundary. It cannot accompany a claimed static runtime as dormant code.

## Evidence

`ScalarAotArtifacts.recursiveHelperArtifact(63)` builds one signed helper that decrements its parameter, calls itself, and returns 73 at zero. Including the entry call, it reaches depth 64. The depth-64 input attempts call 65 and rejects before emission. Existing nonterminating self and two-function cycles also reject.

`LinuxX8664ScalarAotCompilerTest.lowersBoundedRecursiveHelperCalls` binds the accepted WBC to a canonical capsule, native image plan, and ELF. On x86-64 Linux the complete image executes all 64 calls, exits with status 73, writes exact `Wheeler\n`, and writes no standard error.

| Product | Identity |
| --- | --- |
| WBC | `1b493683700357eb469afcb02a45d06137bbb15d443e287c9677e76beb2c47bc` |
| runtime | `0f8eef2985778f5c9332b5cd3906b2ee98b220a39769ee7fd6c3c4382fabe8e4` |
| capsule | `8397f3b9cd6592a4a955a6c2342bd3e0755d24b01350fbed111ac570999f49e4` |
| native plan | `795acd712b7e9d2370b5372d2ce773381f1793d0c4537d2cc6a85d0bcdb3c245` |
| unsigned PREV | `3974b9d50ed1a6f36ecd8620aea7ac48fd85dea43383217969f2f732cff4eadc` |

## Acceptance

- [x] Recursive graphs select the bounded depth machine profile.
- [x] A terminating self call reaches exact depth 64.
- [x] Call 65 rejects before machine emission for static input.
- [x] Generated recursive calls increment and decrement one shared depth cell.
- [x] Recursive calls consume the existing shared fuel cell.
- [x] Acyclic runtime identities remain unchanged.
- [x] Nonterminating cycles reject during independent evaluation.
- [x] WBC, runtime, capsule, plan, ELF, and PREV identities remain exact.
- [x] Native x86-64 Linux launch observes exact status and output.

## Rejected alternatives

### Use fuel as the only recursion bound

Rejected. Fuel bounds work but does not state a maximum simultaneous frame count.

### Allocate depth state in every runtime

Rejected. Acyclic images need no recursion cell and retain established identities.

### Use the host return address as a depth counter

Rejected. Return-address arithmetic is loader state, not Wheeler semantic state.

### Admit unbounded tail recursion

Rejected. This backend does not rewrite calls into jumps or prove tail position.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0387](WIP-0387-x86-64-linux-scalar-execution-bound.md)
- [WIP-0396](WIP-0396-order-independent-scalar-aot-calls.md)
- [WIP-0400](WIP-0400-compiler-frame-scalar-aot-bounds.md)
- [WIP-0405](WIP-0405-directional-scalar-aot-calls.md)
