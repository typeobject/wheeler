# WIP-0402: Boolean-result scalar AOT helpers

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, and native backend maintainers |
| Created | 2026-08-26 |
| Updated | 2026-08-26 |
| Area | Native bootstrap, AOT lowering, Boolean calls, typed results |
| Depends on | WIP-0007, WIP-0008, WIP-0026, WIP-0394, WIP-0399, WIP-0401 |
| Supersedes | Signed-result-only scalar AOT helpers |
| Superseded by | None |

## Summary

Lower scalar helpers returning Boolean as exact typed `CALL_VALUE` targets. The caller destination must be Boolean. Signed-result helpers still require a signed destination. RAX transports either scalar representation without conversion.

This aligns the native call leaf with the self-hosted compiler's disjoint signed and Boolean helper results. It does not admit aggregate, owned, borrowed, UTF-8, or result-slot return values.

## Validation

A nonentry helper result may be signed, Boolean, or absent for void. `ScalarAotProgram` compares the caller destination type directly with the callee result type. The former blanket signed-result check is gone.

All prior call checks remain:

- exact helper target
- exact argument count and contiguous source span
- exact argument types
- in-range fresh destination
- bounded function, local, instruction, graph, depth, and fuel profiles

The canonical WBC verifier checks that `RETURN_VALUE` reads a local matching the function result type. A Boolean helper cannot return a signed local or arbitrary integer under a Boolean descriptor.

## Machine result

A helper loads its terminal result into RAX, clears RDX, restores its frame, and returns. This instruction sequence is type-neutral because canonical WBC already established the scalar type. The caller checks RDX and stores RAX into the exact validated destination.

No tag, boxing, coercion, condition-code dependency, or host ABI type enters the image. Later Boolean instructions read the destination through their ordinary typed local coordinates.

Static evaluation retains the same long storage but consumes the verified local types. Boolean equality in the evidence fixture produces one. `EXPECT_TRUE` observes that result before process status publication.

## Failure boundary

Reject a Boolean result into a signed destination, a signed result into a Boolean destination, a wrong return-local type, an absent value, an aggregate result, malformed call operands, or any prior scalar-profile failure. Rejection returns no runtime text, capsule, image plan, or image bytes.

The entry still returns no value. Final process status remains the signed `status` global in the range zero through 124.

## Evidence

`ScalarAotCallArtifacts.booleanResultHelperArtifact` declares one signed-parameter Boolean helper. It compares its argument with 73 and returns the Boolean local. The entry stores that result in a Boolean destination, asserts it, and publishes signed status 73.

`LinuxX8664ScalarAotCompilerTest.lowersBooleanResultHelpers` independently evaluates the WBC, binds its runtime to a canonical capsule and native image plan, and verifies the complete ELF. On x86-64 Linux the image exits with status 73, writes exact `Wheeler\n`, and writes no standard error.

| Product | Identity |
| --- | --- |
| WBC | `6dc5168e89f91976d6e30e199c786fbb11b88351a2b0dfeb01b3e4c762731e90` |
| runtime | `10cb2cfc9d342eb5f4931c004bf6e29c5b981a27aae2ff3ec245e6cbbdcbcd10` |
| capsule | `89bfcb13e03cd645bed30bc43a7987ae854ce6591e726539910a968f8fdd07f9` |
| native plan | `e42257216000efe849c5980eef426780d2365e659587fae905de44deae88661f` |
| unsigned PREV | `35c1afdb6504e16a75bf7bb5a629567e7f46f9b83c41a1ee9869537faf31c39c` |

## Acceptance

- [x] Signed and Boolean helper result types validate independently.
- [x] `CALL_VALUE` destination type equals the exact callee result type.
- [x] Boolean RAX transport adds no conversion or tag.
- [x] A returned Boolean feeds `EXPECT_TRUE` before status publication.
- [x] Entry process status remains signed and bounded.
- [x] WBC, runtime, capsule, plan, ELF, and PREV identities remain exact.
- [x] Native x86-64 Linux launch observes exact status and output.

## Rejected alternatives

### Convert Boolean results to signed

Rejected. WBC local types are semantic input, not optimization hints.

### Add a runtime type tag to RAX

Rejected. Static verification already owns scalar result type.

### Infer result type from the destination

Rejected. The callee descriptor and caller destination must agree independently.

### Let Boolean helpers publish process status directly

Rejected. Only the signed status global owns process exit.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0394](WIP-0394-mixed-boolean-wide-call-results.md)
- [WIP-0399](WIP-0399-compiler-width-scalar-aot-arguments.md)
- [WIP-0401](WIP-0401-bounded-recursive-scalar-aot-calls.md)
