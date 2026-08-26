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

No identity aliases another top-level statement family. Loop-body rows remain in their separate nested domain. Registry checks retain both properties.

## Resolution

`StatementOpcodes.w` recognizes a Boolean declaration whose first three arguments are names and delegates exact arity measurement to `WideLocalCalls.w`. The profile admits named arguments only. Literal arguments remain in the one- and two-argument families.

`LocalStatements.w`, `Operands.w`, and `SecondaryOperands.w` route the disjoint wide-call identities through one opcode resolver and two operand resolvers. All three agree on one result family and one source packing. Three and four arguments retain their trailing sources in the opcode. Five through seven retain four sources in the primary operand and the remainder in the secondary operand.

`LocalResolution.w` classifies the resulting declaration as Boolean. `ScalarHelperTables.w` requires the matching Boolean helper kind and compares every selected caller-local type with the callee parameter column. A signed-result call cannot name a Boolean-result helper, and the reverse cannot pass by shape alone.

`HelperCallLocalTypes.w` derives local call results from the call identity rather than the caller's return type. Boolean calls receive Boolean result and destination locals even when they occur in a void or signed caller.

`HelperSourceTypes.w` owns one bounded walk over the caller's resolved statement sequence. Parameters retain their declared types. Named Boolean literal, copy, negation, and call results retain Boolean type after their source declarations have become resolved opcodes. Signed expression temporaries retain the type fixed by their call form. Literal operand values never enter the prior-local lookup, even when a value equals an earlier Boolean slot. Call matching, local rows, and code generation consume the same authority. An unresolved named source still rejects during resolution.

`VoidCallResolution.w` uses the same scalar-name authority for Boolean, signed, and affine sources. `CompilerIr.entryBody` carries entry statements through the helper-body type shape. Entry local rows and code generation select that shape only when every source is a parameter or prior statement result. Literal call forms retain their opcode-defined rows. Four-argument source decoding normalizes the adjacent signed and Boolean packed ranges before division, keeping the body inside the physical compiler profile. The package preflight counts public void dependency functions under the same twenty-three-function bound. Tagged package reduction omits zero-selection target rows unless the whole selection is empty, preventing duplicate empty identities from entering the canonical sorter.

## Evidence

`NativeCompilerMixedCallArgumentsExampleTest` compares complete Wheeler and stage-0 artifacts for an imported mixed three-argument Boolean call and local mixed four-, five-, six-, and seven-argument Boolean calls. A second fixture passes prior Boolean copy and literal results into signed- and Boolean-result calls. Replacing those declarations with signed locals rejects before publication. A dependency with the wrong result type also rejects. The signed-result fixtures remain byte-identical. The physical assignment-call classifier entry passes two Boolean-result calls followed by signed two- and one-argument literal calls without treating either literal as a prior local.

`NativeCompilerFourArgumentCallTests.w` executes the first Boolean identity and both terminal source decoders as three independent native cases. The `call.boolean` report identity is `efec5decdf5f5d58eec5e64773c4ee132593f550ae28a172f01e9cea67bd1874`. The `manifest.primitive` package tag selects the exact three-source manifest target. Sixteen focused cases cover the void assertion dependency, each ASCII digit and letter boundary, each punctuation verdict, and each out-of-range fallback verdict. Every case stays within the 255-transition coverage bound. All sixteen compile, execute, and pass through `NativePackageTestRunner`. The canonical report identity is `49c8f35ceda3ca897810bed62cce4b52699a30aa5a29ec376bc58a0763c01f0e`.

The canonical workspace checks 178 targets. The complete physical closure contains 379 modules, 1,893 imports, and 177,822 canonical manifest bytes. Native validation halts after 74,201,200 committed transitions. Wheeler SHA-256 consumes the same manifest in 34,034,110 transitions.

## Rejection

Reject a literal in the admitted wide named family, a missing or ambiguous source, a source appearing after the call, a parameter-type mismatch, a signed or owned result target, a wrong-result helper, arity eight, malformed delimiters, an unresolved helper, or any identity overlap. Failure publishes no artifact or package report.

## Acceptance

- [x] Three- through seven-argument Boolean-result calls retain disjoint identities.
- [x] Mixed signed and Boolean names resolve to exact parameters and prior locals.
- [x] One bounded type query serves helper matching, local rows, and code generation.
- [x] Primary and secondary operands preserve every selected source.
- [x] Complete helper result and parameter types match before publication.
- [x] Local type rows retain the Boolean call result independently of caller type.
- [x] Boolean locals pass to ordinary void helpers from helper and entry bodies.
- [x] Public void dependencies remain inside the twenty-three-function package profile.
- [x] Tagged package reduction excludes unselected target rows.
- [x] Imported three-argument and local four- through seven-argument artifacts match stage 0 byte for byte.
- [x] Wrong result type and malformed source calls reject without output.
- [x] Three Boolean four-argument range cases execute and pass natively.
- [x] Sixteen manifest-primitive package cases execute and pass natively.
- [x] Signed-result call evidence remains unchanged.
- [x] Closure validation and manifest hashing remain bounded and exact.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0391](WIP-0391-boolean-local-equality-guard-returns.md)
- [WIP-0392](WIP-0392-physical-bootstrap-manifest-primitives.md)
- [WIP-0393](WIP-0393-mixed-scalar-wide-call-sources.md)
- [WIP-0402](WIP-0402-boolean-result-scalar-aot-helpers.md)
- [Bootstrap reference](../../public/reference/bootstrap.md)
