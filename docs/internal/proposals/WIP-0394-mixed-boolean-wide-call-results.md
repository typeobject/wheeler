# WIP-0394: Mixed Boolean wide-call results

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Compiler frontend, resolver, backend, bootstrap, and test maintainers |
| Created | 2026-08-25 |
| Updated | 2026-08-25 |
| Area | Self-hosting compiler, Boolean results, wide calls, physical package evidence |
| Depends on | WIP-0391, WIP-0392, WIP-0393 |
| Supersedes | None |
| Superseded by | None |

## Summary

The recovery compiler lowers Boolean-result helper calls with three through seven named scalar arguments. Each argument may name a signed or Boolean parameter or prior local. Resolution preserves the declaration result type, packs exact source locals, matches the callee's complete parameter column, and emits the same artifact as stage 0.

This closes the source path used by `ManifestProfile.w`. The physical manifest-primitive target now executes through the native package runner instead of relying only on isolated owner compilation.

## Problem

WIP-0393 admitted mixed signed and Boolean arguments for signed-result calls. A Boolean declaration with the same call shape still entered the two-argument classifier or lost its result type after resolution. Three-argument calls had no Boolean source column. Four-argument calls had no Boolean packed range. Five- through seven-argument calls shared identities with unrelated void-call rows when a Boolean result was attempted.

The helper table already retained exact result and parameter types. The call statement discarded that authority before helper matching.

## Identity allocation

Boolean-result calls own unresolved identities 940 through 944 for arities three through seven. They follow the conditional-assignment identities at 935 through 937 and leave the global-update family at 1,040 untouched.

Resolved three-argument calls pack their third source in the half-open range 33,024 through 33,280. Resolved four-argument calls pack their final two sources in the half-open range 327,680 through 393,216. The existing owned UTF-8 copy-loop column occupies 393,216 through 393,472. Fixed five-, six-, and seven-argument Boolean calls use 393,472, 393,473, and 393,474.

No identity aliases a signed call, void call, assignment call, loop-body row, or owner-copy column. Registry checks retain that property.

## Resolution

`StatementOpcodes.w` recognizes a Boolean declaration whose first three arguments are names and delegates exact arity measurement to `WideLocalCalls.w`. The profile admits named arguments only. Literal arguments remain in the one- and two-argument families.

`LocalStatements.w`, `Operands.w`, and `SecondaryOperands.w` route the disjoint wide-call identities through one opcode resolver and two operand resolvers. All three agree on one result family and one source packing. Three and four arguments retain their trailing sources in the opcode. Five through seven retain four sources in the primary operand and the remainder in the secondary operand.

`LocalResolution.w` classifies the resulting declaration as Boolean. `ScalarHelperTables.w` requires the matching Boolean helper kind and compares every selected caller-local type with the callee parameter column. A signed-result call cannot name a Boolean-result helper, and the reverse cannot pass by shape alone.

`HelperCallLocalTypes.w` derives local call results from the call identity rather than the caller's return type. Boolean calls receive Boolean result and destination locals even when they occur in a void or signed caller.

## Evidence

`NativeCompilerMixedCallArgumentsExampleTest` compares complete Wheeler and stage-0 artifacts for an imported mixed three-argument Boolean call and local mixed four-, five-, six-, and seven-argument Boolean calls. A dependency with the wrong result type rejects before publication. The signed-result fixtures remain byte-identical.

The `manifest.primitive` package tag selects the exact three-source manifest target. All four cases pass. They cover the void assertion dependency, ASCII digit and letter boundaries, punctuation policy, and out-of-range fallback. The canonical report identity is `42dc6cea338d7621b503263c310b92b4fab4b7c26846d0715b70d0ad66223e85`.

The canonical workspace checks 178 targets. The complete physical closure contains 379 modules, 1,885 imports, and 177,466 canonical manifest bytes. Native validation halts after 74,021,533 committed transitions. Wheeler SHA-256 consumes the same manifest in 33,974,230 transitions.

## Rejection

Reject a literal in the admitted wide named family, a missing or ambiguous source, a source appearing after the call, a parameter-type mismatch, a signed or owned result target, a wrong-result helper, arity eight, malformed delimiters, an unresolved helper, or any identity overlap. Failure publishes no artifact or package report.

## Acceptance

- [x] Three- through seven-argument Boolean-result calls retain disjoint identities.
- [x] Mixed signed and Boolean names resolve to exact prior locals.
- [x] Primary and secondary operands preserve every selected source.
- [x] Complete helper result and parameter types match before publication.
- [x] Local type rows retain the Boolean call result independently of caller type.
- [x] Imported three-argument and local four- through seven-argument artifacts match stage 0 byte for byte.
- [x] Wrong result type and malformed source calls reject without output.
- [x] Four manifest-primitive package cases execute and pass natively.
- [x] Signed-result call evidence remains unchanged.
- [x] Closure validation and manifest hashing remain bounded and exact.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0391](WIP-0391-boolean-local-equality-guard-returns.md)
- [WIP-0392](WIP-0392-physical-bootstrap-manifest-primitives.md)
- [WIP-0393](WIP-0393-mixed-scalar-wide-call-sources.md)
- [Bootstrap reference](../../public/reference/bootstrap.md)
