# WIP-0395: x86-64 Linux seventh scalar argument

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and native backend maintainers |
| Created | 2026-08-26 |
| Updated | 2026-08-26 |
| Area | Native bootstrap, AOT lowering, x86-64 calls, stack arguments |
| Depends on | WIP-0008, WIP-0026, WIP-0380, WIP-0383, WIP-0386 |
| Supersedes | Six-register scalar AOT call ceiling |
| Superseded by | None |

## Summary

Carry a seventh exact scalar call argument across the private x86-64 Linux AOT boundary. The first six values retain the WIP-0380 register convention. The seventh occupies one aligned caller-owned stack area and enters callee local six before Wheeler execution.

This closes the source compiler's zero- through seven-argument scalar call width in the current AOT leaf. It does not establish a public C ABI, admit parameter eight, add variadic calls, permit recursion, or widen the 32-local and 128-instruction function bounds.

## Call boundary

`ScalarAotProgram.MAX_PARAMETERS` is seven. Validation still requires an exact argument count, one contiguous caller-local span, exact local types, a prior callee, and an in-range destination. Parameter eight rejects before machine bytes exist.

For zero through six arguments, `ScalarAotMachine` retains RDI, RSI, RDX, RCX, R8, and R9 in source order. A seven-argument caller:

1. Loads the six register arguments from its unmodified frame.
2. Loads argument six into RAX.
3. Reserves a 16-byte call area.
4. Stores the seventh value at offset zero in that area.
5. Calls the prior helper.
6. Releases the complete call area before checking trap state or storing a result.

The 16-byte area preserves the existing call-site stack alignment. It contains one eight-byte value and one unused alignment word. No red-zone storage or host stack default enters the contract.

## Callee ownership

A helper reserves its aligned local frame before retaining parameters. Register parameters move to locals zero through five. Parameter six loads from `frameBytes + 8`, past the local frame and return address, then moves to local six. The load occurs after every register parameter has been retained, so RAX is free scratch state.

The helper restores only its own frame. `RETURN_VALUE` leaves the result in RAX and clears RDX. A trap sets RDX and returns through the same frame epilogue. The caller removes its call area on both paths before testing RDX. Nested helpers therefore cannot leak stack depth through success or failure.

Signed, Boolean, immutable byte-view, mutable byte, and UTF-8 handle values use the same exact eight-byte slot. Existing type and escape checks remain authoritative. This WIP changes transport width, not ownership semantics.

## Failure boundary

Reject an eighth parameter, count disagreement, a noncontiguous source span, a type mismatch, an invalid destination, a forward or recursive target, a parameterized entry, or any unsupported opcode. Rejection returns no runtime text, capsule, image plan, or native image.

Machine emission treats a validated count above six as exactly one stack argument. A later increase in `MAX_PARAMETERS` cannot silently allocate further stack slots.

## Evidence

`LinuxX8664ScalarAotCompilerTest.lowersBoundedPriorHelperCalls` retains the six-register fixture and adds seven-parameter value and void helpers. Every argument contributes to status 73. The void helper publishes the sum through one admitted shared scalar global. The runtime identities differ. An eight-parameter artifact rejects.

The seven-argument fixture enters a canonical AOT capsule and ELF. ELF verification retains exact runtime bytes and unsigned PREV. On x86-64 Linux the kernel launches that image, observes status 73, exact `Wheeler\n` output, and no standard error.

| Product | Identity |
| --- | --- |
| WBC | `39fa0ef551020f30afc0a7d2c81b34e65330e3a7ae20d3b6d38db7bfb0e34b11` |
| runtime | `e0b6bf9c822359d43495ac305a3e1c49fb54f283276e0c98ce6a60d778dee97f` |
| capsule | `e17bcfd33634ed7c3e38ec2d075ed3c77a1a59f99766ada479c50bfb85b3d907` |
| native plan | `810b549d557a3ace9a6918d979574157a15f2432821e5209b2da00cf29540bd8` |
| unsigned PREV | `38b9e08e56f24613c57b667e5d368aa7a34617814f82292b4222d3537410484e` |

## Acceptance

- [x] Zero through seven exact scalar parameters validate before lowering.
- [x] The first six arguments retain the established register order.
- [x] Argument seven occupies one aligned caller-owned stack area.
- [x] Callee local six receives the exact seventh value.
- [x] Value-returning and void calls observe all seven arguments.
- [x] Success and trap paths restore caller and callee stack depth.
- [x] Parameter eight rejects before publication.
- [x] Six- and seven-argument runtimes have distinct identities.
- [x] Canonical capsule, plan, ELF, and PREV identities remain exact.
- [x] Native x86-64 Linux launch observes Wheeler-computed status 73.

## Rejected alternatives

### Use an unaligned eight-byte push

Rejected. It changes call-site alignment and makes nested behavior depend on entry stack accidents.

### Borrow a caller local as callee parameter storage

Rejected. Aliasing frames would make helper semantics depend on caller layout.

### Reserve a general variadic stack vector

Rejected. The exhausted profile needs one seventh value. Parameter eight still lacks an admitted source and ownership boundary.

### Leave the seventh value in RAX

Rejected. RAX is result and scratch state. The callee must own the incoming value before executing Wheeler instructions.

## References

- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0380](WIP-0380-x86-64-linux-scalar-call-arguments.md)
- [WIP-0383](WIP-0383-x86-64-linux-void-helper-calls.md)
- [WIP-0386](WIP-0386-x86-64-linux-borrowed-byte-helpers.md)
