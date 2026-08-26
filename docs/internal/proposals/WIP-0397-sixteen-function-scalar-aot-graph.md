# WIP-0397: Sixteen-function scalar AOT graph

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and native backend maintainers |
| Created | 2026-08-26 |
| Updated | 2026-08-26 |
| Area | Native bootstrap, AOT lowering, function bounds, call depth |
| Depends on | WIP-0008, WIP-0026, WIP-0387, WIP-0396 |
| Supersedes | Eight-function scalar AOT graph ceiling |
| Superseded by | None |

## Summary

Raise the closed scalar AOT graph from eight to sixteen dense functions. The final function remains the entry. The preceding fifteen helpers may form any WIP-0396 acyclic graph admitted by the existing call, local, type, instruction, and fuel checks.

This is a measured bound increase after the eight-function terminal fixture passed and function nine rejected. It is not the complete compiler graph. Function seventeen now rejects before evaluation or machine emission.

## Bound

`ScalarAotProgram.MAX_FUNCTIONS` is sixteen. Canonical WBC still requires:

- dense function IDs beginning at zero
- the entry at ID `functionCount - 1`
- no coherent body, inverse body, result slot, or unsupported signature
- at most 128 instructions and 32 locals in each ordinary function
- at most seven exact parameters
- one complete acyclic call graph
- one shared 65,536-instruction budget

The function bound and instruction budget remain independent. Sixteen dormant two-instruction helpers cannot buy more fuel for the entry. A cycle cannot trade call depth for function count.

## Call depth

The terminal fixture is a fifteen-helper chain followed by the entry call. Each helper owns one aligned local frame, calls the preceding helper, returns the exact signed result, and restores its frame. The leaf returns 73.

The graph check closes before independent evaluation. Evaluation consumes the shared fuel cell through every call. Machine emission records sixteen function offsets and patches every relative edge only after complete emission. No host linker, symbol table, trampoline, or dynamic target enters the image.

Recursion remains rejected. The maximum admitted native call depth is therefore bounded by the fifteen helper functions plus the entry. This WIP does not infer ambient process stack size as Wheeler authority.

## Failure boundary

Reject function seventeen, a sparse or reordered function table, a nonfinal entry, a cyclic graph, a malformed call edge, an exhausted instruction budget, or any existing scalar-profile failure. Rejection returns no runtime text, capsule, image plan, or native image.

A future increase must provide new terminal admission, next-value rejection, physical launch, and stack-depth evidence. It cannot follow from a larger Java array alone.

## Evidence

`ScalarAotArtifacts.helperArtifact(16)` constructs the terminal chain. Independent evaluation observes status 73. `helperArtifact(17)` rejects at the function boundary.

`LinuxX8664ScalarAotCompilerTest.lowersBoundedPriorHelperCalls` binds the sixteen-function artifact to a canonical capsule, native image plan, and ELF. On x86-64 Linux the kernel launches the complete image, observes process status 73, exact `Wheeler\n` output, and no standard error.

| Product | Identity |
| --- | --- |
| WBC | `ef233c168ccd94d2037740d7c1d007b5fb137214a8f45c4bf839cc78a12d0da5` |
| runtime | `5c8cebfe0dfa7ae8a7a51b670979883d541ecca04929c8c074041ff27255ff5c` |
| capsule | `5b513275e8a6e4205a819b32765f7bd834de1e2647d8e18cc4f973614f2382b9` |
| native plan | `88a05d2d4e917ee9280984f1f34b15030a223e9c2a5992f7755a58616b5fcc4d` |
| unsigned PREV | `0dfe8ffa291e9e52f9badb02a5f4dd4ed2aa9d9e5ff699b3b2a5bacf1e2f972d` |

## Acceptance

- [x] One through sixteen dense functions validate before lowering.
- [x] The final function remains the sole entry.
- [x] A fifteen-helper chain returns status 73.
- [x] Every helper frame restores through success and trap epilogues.
- [x] All calls consume one shared execution budget.
- [x] Function seventeen rejects before publication.
- [x] Runtime, capsule, plan, ELF, and PREV identities remain exact.
- [x] Native x86-64 Linux launch observes exact status and output.

## Rejected alternatives

### Remove the function bound

Rejected. Dense IDs do not bound code, validation work, call depth, or machine offset storage.

### Jump directly to the compiler's full helper profile

Rejected. The terminal sixteen-function chain is one reviewable bound. A wider compiler profile needs its own exhaustion evidence.

### Count only reachable functions

Rejected. Complete-artifact validation does not hide dormant code.

### Treat fuel as the only stack bound

Rejected. Fuel bounds executed instructions. Acyclic function count supplies the independent call-depth bound.

## References

- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0387](WIP-0387-x86-64-linux-scalar-execution-bound.md)
- [WIP-0396](WIP-0396-order-independent-scalar-aot-calls.md)
