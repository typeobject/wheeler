# WIP-0398: Compiler-width scalar AOT graph

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, and native backend maintainers |
| Created | 2026-08-26 |
| Updated | 2026-08-26 |
| Area | Native bootstrap, AOT lowering, compiler profile, function bounds |
| Depends on | WIP-0007, WIP-0008, WIP-0026, WIP-0397 |
| Supersedes | Sixteen-function scalar AOT graph ceiling |
| Superseded by | None |

## Summary

Raise the closed scalar AOT graph to twenty-four dense functions. This admits the self-hosted compiler profile's twenty-three-helper table plus one final entry without widening any function body, local frame, parameter, call, state, I/O, or execution bound.

The width match is necessary bootstrap plumbing. It does not claim that the compiler's complete WBC is inside the scalar AOT semantic profile. Aggregate values, larger bodies, wider local frames, recursion, and unsupported instructions still reject.

## Bound

`ScalarAotProgram.MAX_FUNCTIONS` is twenty-four. Function IDs remain dense and canonical. The entry remains `functionCount - 1`. Every helper remains subject to:

- at most seven exact parameters
- at most 32 typed locals
- at most 128 instructions
- exact value or void returns
- the WIP-0396 acyclic graph check
- one shared 65,536-instruction budget

The final entry may use the separate bounded dynamic-I/O local profile. Function count does not enlarge its local or byte arenas.

## Terminal graph

The terminal fixture contains twenty-three helpers and one entry. Helper zero returns 73. Each later helper calls its predecessor and returns the same value. The entry calls helper twenty-two, stores status, and halts.

This shape reaches the exact function and acyclic call-depth bounds while keeping each function at its minimum useful body. It proves that descriptor count, offset publication, relative call patching, independent evaluation, aligned frames, and shared fuel all reach the compiler-width edge together.

Function twenty-five rejects before evaluation. A future wider graph needs another explicit boundary rather than inheriting capacity from the core WBC format.

## Failure boundary

Reject function twenty-five, sparse IDs, a nonfinal entry, cycles, malformed calls, oversized functions, exhausted fuel, or any existing scalar-profile failure. Rejection returns no runtime text, capsule, image plan, or image bytes.

Complete-artifact validation remains mandatory. An unused twenty-fifth function cannot hide outside entry reachability.

## Evidence

`ScalarAotArtifacts.helperArtifact(24)` constructs the terminal chain. Independent evaluation returns status 73. `helperArtifact(25)` rejects at the function bound.

`LinuxX8664ScalarAotCompilerTest.lowersBoundedPriorHelperCalls` binds the accepted WBC to a canonical capsule, native image plan, and ELF. On x86-64 Linux the complete image exits with status 73, writes exact `Wheeler\n`, and writes no standard error.

| Product | Identity |
| --- | --- |
| WBC | `582736d63c4d58465e0cd68b633c4d7e315c56817cf2d011db2a3ae6fda05084` |
| runtime | `a8e0dfd175d35bc84e04ef3bea2cb1ca271ccdc006d5e6b25cc39e89363e4b16` |
| capsule | `4896f1b210c3b6ac0f405164467ac2f27f263aed30a6e6150f3679907beb795b` |
| native plan | `1fb2f458bff81b0534ccfcb119fd8dde7fe202bad1e345dc89f02b0ef53ca565` |
| unsigned PREV | `fa543a706e5907aca33fd6c415c0d238cbd95eaa833cec6d6c8e04dc37c610f6` |

## Acceptance

- [x] One through twenty-four dense functions validate before lowering.
- [x] Twenty-three helpers fit beside one final entry.
- [x] A twenty-three-helper chain returns status 73.
- [x] Every call consumes the shared execution budget.
- [x] Every machine frame restores on success and trap paths.
- [x] Function twenty-five rejects before publication.
- [x] WBC, runtime, capsule, plan, and PREV identities remain exact.
- [x] Native x86-64 Linux launch observes exact status and output.

## Rejected alternatives

### Claim compiler AOT parity from matching function count

Rejected. Width is one dimension. The complete compiler still exceeds other scalar profile boundaries.

### Count only called helpers

Rejected. Native-image verification covers the complete WBC function table.

### Share one machine frame across the chain

Rejected. Wheeler calls own independent local frames.

### Remove the next-value rejection

Rejected. A bound without its first rejected value is not a measured profile.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0397](WIP-0397-sixteen-function-scalar-aot-graph.md)
