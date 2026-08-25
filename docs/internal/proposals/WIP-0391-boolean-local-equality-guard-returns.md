# WIP-0391: Boolean-local equality guard returns

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-25 |
| Updated | 2026-08-25 |
| Area | Self-hosting, source lowering, typed control flow |
| Depends on | WIP-0007, WIP-0343, WIP-0344 |
| Supersedes | None |
| Superseded by | None |

## Summary

The recovery compiler admits an equality guard over a signed local or parameter whose taken arm returns a prior Boolean local or parameter. Resolution assigns a distinct opcode column, retains the signed guard source and Boolean result source separately, emits a Boolean result slot, and rejects type drift before publication.

This closes the source shape used by the canonical bootstrap-profile byte classifier. Punctuation guards can return the caller's `allowPunctuation` policy without flattening policy into literals or retaining a one-iteration loop as parser bait.

## Source form

The admitted form is:

```wheeler
if (scalar == 45) {
  return allowPunctuation;
}
```

`scalar` resolves through prior signed declarations. `allowPunctuation` resolves independently through prior Boolean declarations. Parameters and ordinary prior locals use the same typed declaration history.

The comparison right operand remains the existing signed literal or signed class-constant profile. This WIP does not admit Boolean-local results behind less-than guards, helper-call guards, nested blocks, or arbitrary expressions.

## Resolved form

`STATEMENT_IF_SIGNED_EQ_RETURN_BOOLEAN_LOCAL_BASE` starts a 256-entry source-local column at 32,512. The opcode delta identifies the signed comparison source. The secondary operand identifies the Boolean result source.

The column ends immediately before the existing three-argument local-call column at 32,768. It does not overlap any statement identity, resolved column, call family, or loop-body identity.

`ResolvedEarlyComparisonKinds` classifies the column as equality control flow. `ResolvedEarlyResultKinds` classifies it as a local return but not a signed return. This distinction drives three independent decisions:

- Scalar-helper validation admits the form only in Boolean-result helpers.
- Secondary-operand resolution requires a Boolean source.
- Local-type emission assigns Boolean to the returned temporary.

The machine-code shape remains the canonical four-local, seven-instruction equality guard. The result arm uses `LOCAL_MOVE` from the resolved Boolean source followed by `RETURN_VALUE`. There is no Boolean-to-signed conversion and no literal reconstruction.

## Manifest profile

`BootstrapManifestProfile.profileByte` uses ordered early returns. ASCII letters and digits return literal verdicts. Hyphen, dot, and underscore return `allowPunctuation`. Bytes outside the profile return the caller's `valid` fallback.

The rewrite is equivalent to the former chain of assignments inside a one-iteration loop. It removes dead loop state and gives every policy exit an explicit source form. Existing bootstrap-manifest and compiler-options identity tests retain the complete accepted and rejected transport behavior.

## Failure boundary

Reject:

- A Boolean comparison source.
- A signed value returned from a Boolean helper.
- An unknown result name.
- A result declaration after the guard.
- A 256-or-greater source-local index.
- Any malformed equality framing.
- Any prior recovery-compiler limit breach.

A failed resolution emits no artifact. The compiler does not reinterpret a signed source as Boolean merely because both occupy one scalar machine slot.

## Evidence

`NativeCompilerConditionalSourceExampleTest.compilesBooleanLocalEqualityReturnsByteForByte` compiles the complete profile-byte decision chain through the Wheeler recovery compiler and compares the artifact byte for byte with stage 0. WIP-0392 moves those exact production bytes into a focused physical owner. Replacing the Boolean result with the signed guard source rejects before publication.

`NativeBootstrapManifestIdentityExampleTest` and `NativeCompilerOptionsIdentityExampleTest` execute the rewritten canonical classifier through valid and invalid metadata transports. The focused early-return source, result-kind, comparison-kind, operand, type, and code-generation suites remain byte-identical.

## Acceptance

- [x] Equality guards return prior Boolean parameters and locals.
- [x] Signed guard and Boolean result sources resolve independently.
- [x] The result temporary has Boolean type.
- [x] Signed-result helpers reject the Boolean column.
- [x] Invalid result types publish no artifact.
- [x] The complete profile classifier matches stage 0 byte for byte.
- [x] Bootstrap metadata behavior remains unchanged.

## Rejected alternatives

### Keep the one-iteration loop

Rejected. The loop hid a scalar decision chain behind mutable state and still did not compile through the recovery parser.

### Reuse the signed-local return column

Rejected. Opcode identity must preserve result type. Treating Boolean as signed here would leak machine representation into source semantics and corrupt local-type evidence.

### Add every missing guard/result pairing at once

Rejected. Less-than Boolean-local returns and helper-call variants need their own exhausted source cases and opcode identities. This WIP publishes only the equality form required by a physical bootstrap owner.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0343](WIP-0343-native-compiler-resolved-early-comparison-suite.md)
- [WIP-0344](WIP-0344-native-compiler-resolved-early-result-suite.md)
- [WIP-0392](WIP-0392-physical-bootstrap-profile-classifier.md)
