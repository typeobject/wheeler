# WIP-0282: Native compiler scalar arithmetic

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, coverage, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, compiler testing, semantic coverage |
| Depends on | WIP-0281 |
| Supersedes | Addition-only native compiler arithmetic coverage |
| Superseded by | WIP-0283 bounded native bitwise coverage |

## Summary

Extend the native compiler package case through checked subtraction, multiplication, division, and remainder.

All operands descend from the physical imported `ENCODING_WIDTH_U16` constant. The case now attempts six assertions and covers the complete signed arithmetic opcode family used by the bounded compiler spine.

`BootstrapCoverageFragments.w` admits exact `LOCAL_SUB`, `LOCAL_MUL`, `LOCAL_DIV`, and `LOCAL_MOD` keys. The negative coverage fixture now executes a global assignment, which remains outside this package coverage profile and proves atomic rejection without borrowing an admitted local opcode.

## Test body

After checking width 2 and doubled width 4, the case computes:

```text
long difference = doubled - width;
assert(difference == 2);
long product = difference * width;
assert(product == 4);
long quotient = product / width;
assert(quotient == 2);
long remainder = product % 3;
assert(remainder == 1);
```

The runtime uses checked Wheeler arithmetic. Divide-by-zero, overflow, and malformed operand behavior remain interpreter traps rather than coverage events.

The complete selected trace remains within the 64-transition bootstrap coverage bound. A wider case must raise trace storage, reduction limits, and evidence together.

## Evidence

`wheeler test wheeler-compiler --format json` publishes one passing native case with six assertion attempts.

The report identity is `68bd362aaa066e075d782051c448c968d2caa3a13dc4e7c908d0723f7f23312d`. The coverage identity is `3f329863163e3310cf220c2219563d0f72bdd9aeca1ecab48d64b214360a8df7`.

`unsupportedNativeTracePublishesNoPartialReport` executes a global write and still publishes neither report length nor bytes.

## Acceptance

- [x] The compiler package case executes checked subtraction.
- [x] The case executes checked multiplication.
- [x] The case executes checked division.
- [x] The case executes checked remainder.
- [x] Every arithmetic operand derives from the imported compiler width.
- [x] Native coverage names all four added opcode families exactly.
- [x] The report records six assertion attempts.
- [x] An unadmitted global write still fails coverage atomically.
- [x] Compiler, runtime, conformance archives and consumer locks are rebuilt exactly.
- [x] Focused compiler package, coverage, tools, documentation, workspace, and file-length policy pass.

The compiler archive contains 3,022,799 bytes with SHA-256 `a1f0affc0a8efe12bc2e37a5c029b6e69cb9ef851e68b90deae4259fa0e12f25` and root manifest identity `8ca1126edccaa2e857e34d7b186bb7eeb445a2ade52707d093b50799b31ab719`.

The runtime archive contains 379,596 bytes with SHA-256 `f8a67aa6be30986d4481792d6372e9f41fecd82dac663955cf0f9de33396baef` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 132,872 bytes with SHA-256 `1beb2c57f29a587e5d05ed20152204d38769556d3a63550fce3c0d01b21d82be` and root manifest identity `b9beb8697bb55c654a74476b69a5a21fbcded9791e04f771ab4b25186d2d1349`.

## Rejected alternatives

### Use unrelated literals for each operation

Rejected. The test follows one imported compiler value through the arithmetic chain.

### Raise the transition bound for convenience

Rejected. The current case fits. A bound change needs its own capacity evidence.

### Reuse an admitted local opcode as the negative fixture

Rejected. Negative coverage must remain outside the admitted vocabulary.

## References

- [WIP-0020](WIP-0020-semantic-coverage-and-evidence-accounting.md)
- [WIP-0281](WIP-0281-native-compiler-arithmetic-coverage.md)
- [WIP-0283](WIP-0283-bounded-native-bitwise-coverage.md)
