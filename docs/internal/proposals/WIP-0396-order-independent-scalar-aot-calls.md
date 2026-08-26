# WIP-0396: Order-independent scalar AOT calls

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and native backend maintainers |
| Created | 2026-08-26 |
| Updated | 2026-08-26 |
| Area | Native bootstrap, AOT lowering, call graphs, function layout |
| Depends on | WIP-0008, WIP-0026, WIP-0379, WIP-0395 |
| Supersedes | Prior-function-only scalar AOT calls |
| Superseded by | WIP-0397 for graph width, WIP-0401 for recursion |

## Summary

Lower exact acyclic helper calls independently of canonical function-table order. A helper may call an earlier or later helper. The entry remains the final function and cannot become a call target.

The machine emitter already patches calls after every function offset is known. This WIP removes the semantic ordering restriction and adds one closed call-graph check before evaluation or emission. Recursion, entry calls, dynamic targets, missing functions, and cycles remain rejected.

## Validation

Every call still binds:

- one dense in-range helper ID below the final entry ID
- an exact value or void result shape
- the callee's exact parameter count
- one contiguous caller-local argument span
- exact signed, Boolean, or admitted handle types
- one signed destination for `CALL_VALUE`

Function IDs remain canonical artifact identities. Source order and helper order remain observable in WBC identity, but neither may change whether an otherwise identical acyclic call edge lowers.

After all function and instruction checks pass, `ScalarAotProgram` walks the complete eight-function table with a three-state depth-first check. State zero is unseen, state one is active, and state two is closed. Reaching an active function rejects the complete program as cyclic. The fixed function bound makes this check bounded without host recursion policy becoming artifact semantics.

The independent evaluator uses the same validated graph and the existing shared 65,536-instruction budget. Forward calls cannot reset fuel. Evaluation therefore remains a complete pre-emission check for static-I/O programs.

## Emission

`ScalarAotMachine` emits functions in canonical ID order and records every relative call displacement. It patches those displacements only after all function offsets exist. A forward edge and a backward edge therefore use the same checked patch authority.

No trampoline, symbol table, dynamic relocation, linker, or execution-time lookup enters the image. The emitted call still names one fixed relative target. WIP-0395 register and stack argument transport remains unchanged.

## Failure boundary

Reject a self edge, a multi-function cycle, a call to the entry, an out-of-range target, a malformed signature, an unsupported callee, or any prior scalar-profile failure before runtime text is returned. The canonical bytecode verifier rejects entry and out-of-range targets before AOT validation. The AOT boundary retains its independent helper-only target check. Dormant invalid functions remain invalid. An unreachable cycle cannot hide behind the entry.

## Evidence

`ScalarAotArtifacts.forwardHelperArtifact` places a forwarding helper before its literal-producing callee. The entry calls the forwarder, the callee returns 73, and both independent evaluation and machine emission accept the graph. `cyclicHelperArtifact` replaces the terminal leaf with a two-function cycle and rejects before publication.

`LinuxX8664ScalarAotCompilerTest.lowersAcyclicForwardHelperCalls` binds the accepted artifact to a canonical capsule, native image plan, and ELF. On x86-64 Linux the kernel launches the complete image, observes process status 73, exact `Wheeler\n` output, and no standard error.

| Product | Identity |
| --- | --- |
| WBC | `9920c68d45d4a1ec1870cf62950cb8c08ba25549c9c28dffe3ae9c14367e21e4` |
| runtime | `d731526c670d251e0b2d65e22a33615c5b43743b2bea968ad0fd4634a3ffdd00` |
| capsule | `7a348327fb9386bb1899edefd0d6da3c8095dc4a238a1d1bf547143645008d8f` |
| native plan | `c76d9538d1ea8bf1e584cab8276fb2ac6cef23440a59ff432d555f8b60305589` |
| unsigned PREV | `d6365e30ee0494041b65304508d6b49eee45591b66774e8a3caffaa47aaa0271` |

## Acceptance

- [x] A helper may call one later helper.
- [x] Earlier-helper calls remain unchanged.
- [x] Entry and helper calls share one closed acyclic graph check.
- [x] Calls still bind exact argument and result types.
- [x] Forward relative displacements patch after complete function emission.
- [x] Self edges and longer cycles reject in AOT validation.
- [x] Canonical verification and AOT validation both retain helper-only target checks.
- [x] Static evaluation and native execution observe status 73.
- [x] Capsule, plan, ELF, and PREV identities remain exact.

## Rejected alternatives

### Sort functions into call order

Rejected. Function IDs are artifact semantics. A backend cannot rewrite them to simplify layout.

### Emit one trampoline table

Rejected. Complete relative patching already owns fixed targets without runtime lookup.

### Permit recursion under fuel alone

Rejected. Fuel bounds instructions but does not by itself establish a stack-depth contract.

### Ignore unreachable cycles

Rejected. Dormant malformed functions cannot enter a verified native image.

## References

- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0379](WIP-0379-x86-64-linux-scalar-helper-calls.md)
- [WIP-0395](WIP-0395-x86-64-linux-seventh-scalar-argument.md)
- [WIP-0397](WIP-0397-sixteen-function-scalar-aot-graph.md)
- [WIP-0401](WIP-0401-bounded-recursive-scalar-aot-calls.md)
