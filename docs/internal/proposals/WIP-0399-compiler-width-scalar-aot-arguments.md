# WIP-0399: Compiler-width scalar AOT arguments

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, and native backend maintainers |
| Created | 2026-08-26 |
| Updated | 2026-08-26 |
| Area | Native bootstrap, AOT lowering, compiler profile, stack arguments |
| Depends on | WIP-0007, WIP-0008, WIP-0026, WIP-0395, WIP-0398 |
| Supersedes | Seven-argument scalar AOT call ceiling |
| Superseded by | WIP-0401 for recursion |

## Summary

Carry up to sixteen exact scalar arguments across the private x86-64 Linux AOT call boundary. The first six retain the register order fixed by WIP-0380. Arguments six through fifteen occupy one aligned caller-owned stack area in source order.

Sixteen matches the self-hosted compiler helper-signature bound. This removes one width mismatch. It does not admit wider local frames, larger function bodies, aggregate parameters, variadic calls, recursion, or the complete compiler WBC.

## Caller layout

For a call with `n` arguments, the caller computes:

```text
stack_count = max(0, n - 6)
call_area = align(stack_count * 8, 16)
```

The caller reserves that complete area before loading arguments. Register loads account for the shifted caller frame. Each stack argument then loads from its original caller local and stores at `(argument - 6) * 8` in the call area. Padding, when needed, follows the final argument and carries no value.

The relative call occurs only after all values are retained. Success and trap paths release the complete call area before inspecting RDX or writing a result local.

## Callee layout

The callee reserves its aligned local frame first. Register arguments move to locals zero through five. A stack argument `i` loads from:

```text
frame_bytes + 8 + (i - 6) * 8
```

The first term skips the callee frame. The eight-byte term skips the return address. The final term selects the caller's source-ordered stack slot. RAX carries each loaded stack value into its exact callee local after register retention.

Signed, Boolean, immutable byte-view, mutable byte, and UTF-8 handles use the same eight-byte transport. Existing type checks and handle-escape checks remain unchanged. This is transport width, not a conversion or ownership rule.

## Bounds

`ScalarAotProgram.MAX_PARAMETERS` is sixteen. Validation still requires exact count agreement, one contiguous in-range caller-local span, exact type equality, one helper target, and a signed destination for value calls.

The ordinary 32-local helper bound admits the terminal sixteen-parameter sum with fifteen result temporaries. Parameter seventeen would also exhaust that local shape. It rejects before evaluation and machine emission.

The stack area is at most 80 bytes. It is independent of the callee frame and the shared 65,536-instruction budget. No host stack-size claim enters the profile.

## Failure boundary

Reject parameter seventeen, malformed source spans, type disagreement, result mismatch, a nonhelper target, a cycle, unsupported handle use, or any prior scalar-profile failure. Rejection returns no runtime text, capsule, image plan, or native image.

The machine encoder checks the validated argument count again. A later validator increase cannot silently emit more stack slots.

## Evidence

`ScalarAotArtifacts.parameterHelperArtifact(16)` makes every parameter contribute to status 73. `parameterVoidHelperArtifact(16)` computes the same sum through an admitted shared scalar global. Parameter seventeen rejects.

`LinuxX8664ScalarAotCompilerTest.lowersBoundedPriorHelperCalls` retains the six-register fixture beside the sixteen-argument fixture and requires distinct runtime identities. The accepted WBC enters a canonical capsule, native image plan, and ELF. On x86-64 Linux the complete image exits with status 73, writes exact `Wheeler\n`, and writes no standard error.

| Product | Identity |
| --- | --- |
| WBC | `6940835cec9eecb155ac4de2efb9a6514b0b316dadf0f546057d1f064dff0cf1` |
| runtime | `65cffb9320ded62993da55b2945d9309f675c8f89883d1f06076125be79d6d7e` |
| capsule | `36c72ed8eb1a550bd5c25834005bdd00f50f9b7b5c1635a935b36bd4e2a42438` |
| native plan | `6c5e5073b7520a3f95baa665dd3204fb373f326418974da62a199d87f5c1f1e0` |
| unsigned PREV | `243ca19309b6037d9df1a46d66dc5342b3db9dca1417679dff2e867ee2f11ed7` |

## Acceptance

- [x] Zero through sixteen exact scalar parameters validate before lowering.
- [x] Six register arguments retain their established order.
- [x] Ten stack arguments retain source order in one aligned call area.
- [x] Value and void helpers observe all sixteen values.
- [x] Caller and callee restore exact stack depth on success and trap paths.
- [x] Parameter seventeen rejects before publication.
- [x] Runtime, capsule, plan, ELF, and PREV identities remain exact.
- [x] Native x86-64 Linux launch observes exact status and output.

## Rejected alternatives

### Push arguments without one call area

Rejected. Incremental pushes complicate source-local offsets and make alignment depend on argument parity.

### Pass all arguments on the stack

Rejected. It would replace the proven six-register boundary without need.

### Allocate stack arguments in the callee

Rejected. The callee cannot recover values that the caller never retained.

### Claim an external System V ABI

Rejected. The register names and stack geometry are image-private Wheeler lowering details.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0395](WIP-0395-x86-64-linux-seventh-scalar-argument.md)
- [WIP-0398](WIP-0398-compiler-width-scalar-aot-graph.md)
- [WIP-0401](WIP-0401-bounded-recursive-scalar-aot-calls.md)
