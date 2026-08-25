# WIP-0393: Mixed scalar wide-call sources

| Field | Value |
|---|---|
| Status | Implemented |
| Depends on | WIP-0007, WIP-0310, WIP-0366 |
| Supersedes | Signed-only source lookup for three- through seven-argument value calls |

## Problem

The recovery compiler admitted signed-result helpers with up to seven parameters and retained each parameter's exact type. Call-source resolution nevertheless treated every source in a three- through seven-argument assignment call as signed.

A helper such as:

```wheeler
public long select(long value, boolean selected, boolean fallback) {
  return value;
}
```

compiled in isolation. `long result = select(value, selected, fallback);` did not. Both Boolean names disappeared during source lookup before the helper table could compare the call against the declared parameter column.

The later signature check already owned type agreement. An earlier signed-only lookup duplicated a weaker policy and rejected valid typed calls.

## Resolution

`LocalResolution.resolvePriorScalarDeclaration` resolves one source name against the signed and Boolean declaration histories. Exactly one match is required. Missing or ambiguous names return minus one.

Three- and four-argument resolution uses that query for every source. Five- through seven-argument packing uses the same query before writing either packed operand. Primary and secondary operand resolution no longer impose a separate signed-only rule.

The helper table remains authoritative for parameter order and exact type equality. General source lookup does not coerce Boolean values to signed values, infer types from machine representation, or repair a mismatched signature.

One- and two-argument calls retain their existing literal and local identity families. This change concerns named prior locals in the wide-call family only.

## Encoding

No opcode, operand, local, instruction, or artifact bound changes.

Three-argument calls retain the third source in the resolved statement identity. Four-argument calls retain the third and fourth sources there. Five- through seven-argument calls retain four source digits in the primary operand and the remainder in the secondary operand. Signed and Boolean locals share the same bounded source index domain. Local types still select `LOCAL_MOVE` and prove the callee signature.

The source modules now describe these as scalar call arguments rather than signed call arguments. Result type remains signed. Boolean-result wide calls are outside this WIP.

## Evidence

`NativeCompilerMixedCallArgumentsExampleTest` compiles complete source modules through Wheeler and stage 0 and compares every artifact byte.

The imported three-argument fixture passes `long, boolean, boolean` to a public signed-result helper. A dependency that changes the second parameter to signed rejects before publication. An unresolved third source also rejects without output.

The local four-argument fixture passes `long, boolean, boolean, long`. The wide fixture independently compiles five, six, and seven arguments with alternating signed and Boolean types. Every helper and caller retains the exact parameter column.

The complete physical closure remains 379 modules, 1,883 imports, and 177,378 canonical manifest bytes. Native validation halts after 73,964,449 committed transitions. Wheeler SHA-256 consumes the same manifest in 33,948,356 transitions.

## Acceptance

- [x] Three-argument signed-result calls resolve mixed signed and Boolean locals.
- [x] Four-argument signed-result calls resolve mixed signed and Boolean locals.
- [x] Five-, six-, and seven-argument source packing resolves mixed scalar locals.
- [x] Exact helper parameter types still gate call resolution.
- [x] Missing and mismatched sources publish no artifact.
- [x] Wheeler and stage 0 emit byte-identical complete artifacts.
- [x] Existing source and machine bounds remain unchanged.

## Rejected alternatives

### Treat Boolean locals as signed

Rejected. Shared source indexes do not imply shared source types. The helper signature must still distinguish the two.

### Encode argument types in new opcodes

Rejected. Canonical local-type rows already carry that evidence. A second type channel could disagree with the callable descriptor.

### Select the helper before resolving names

Rejected. Name lookup and callable selection have separate failure boundaries. Reordering them would make unresolved source names depend on candidate arrival order.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0310](WIP-0310-native-multi-helper-entry-programs.md)
- [WIP-0366](WIP-0366-native-compiler-call-argument-opcodes.md)
