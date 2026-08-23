# WIP-0283: Bounded native bitwise coverage

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, coverage, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, compiler testing, semantic coverage |
| Depends on | WIP-0282 |
| Supersedes | Sixty-four-transition compiler package coverage |
| Superseded by | WIP-0314 native 255-transition coverage |

## Summary

Extend the compiler package case through bitwise AND, XOR, and ordered local comparison, and raise native coverage reduction to 128 transition rows.

The expanded case crossed the old 64-transition trace ceiling. `BootstrapCoverageFragments.w` and `CoverageReducer.w` now share a 128-row bound. The reducer doubles its private metadata arena from 4,096 to 8,192 bytes so seven 128-word columns fit without relying on allocation failure as policy.

## Compiler case

The case adds:

```text
long masked = width & 3;
assert(masked == 2);
long toggled = width ^ 3;
assert(toggled == 1);
assert(width < doubled);
```

`width` still comes from physical `EncodingWidths.w`. Native coverage now admits exact `LOCAL_AND`, `LOCAL_XOR`, and `LOCAL_LT` keys.

The complete case attempts nine assertions and remains below 128 transitions. It covers constant resolution, local moves, equality, checked arithmetic, bitwise operations, ordering, assertion, call, return, and halt transitions.

## Bound evidence

`wheelerAndStageZeroReduceTransitionsToIdenticalCanonicalBytes` now sends 128 copies of one valid point row to the Wheeler reducer. Native output combines them into one point with count 128 and matches independently assembled canonical bytes.

The regular differential run still compares stage-0 observation reduction byte for byte. Input row 129 remains outside the profile.

`unsupportedNativeTracePublishesNoPartialReport` retains a global write outside the admitted package-test vocabulary and publishes no partial report.

## Evidence

`wheeler test wheeler-compiler --format json` publishes one passing native case with nine assertion attempts.

The report identity is `072b46b21f06a07b3ca33346d30e3dada735aad922378c4107a59fa73e38eb58`. The coverage identity is `9b7f234eb17c82c98bacc76ae4fca4f9532dcf971b8670288ed43fb02f7b6a9e`.

## Acceptance

- [x] The compiler package case executes bitwise AND.
- [x] The case executes bitwise XOR.
- [x] The case executes ordered signed comparison.
- [x] Native coverage names all three opcode families exactly.
- [x] Trace framing admits at most 128 transitions.
- [x] Coverage reduction admits at most 128 rows.
- [x] Private reducer storage fits seven maximum metadata columns.
- [x] A 128-row duplicate fixture reduces to count 128.
- [x] An unadmitted global write still fails atomically.
- [x] Compiler, runtime, conformance archives and consumer locks are rebuilt exactly.
- [x] Focused compiler package, coverage, tools, documentation, workspace, and file-length policy pass.

The compiler archive contains 3,022,938 bytes with SHA-256 `6edbd60d4fa81174b8e2a5521f28fe2efaddaab6da44c85362784d40572ccad0` and root manifest identity `8ca1126edccaa2e857e34d7b186bb7eeb445a2ade52707d093b50799b31ab719`.

The runtime archive contains 380,129 bytes with SHA-256 `cb1e282ba3712070ab197f922447ef97bda7cb7dc51b0ca27565cc6288166f1b` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 132,872 bytes with SHA-256 `1beb2c57f29a587e5d05ed20152204d38769556d3a63550fce3c0d01b21d82be` and root manifest identity `b9beb8697bb55c654a74476b69a5a21fbcded9791e04f771ab4b25186d2d1349`.

## Rejected alternatives

### Keep the 64-row reducer and truncate the trace

Rejected. Truncation would make coverage identity depend on buffer exhaustion.

### Allocate metadata opportunistically

Rejected. The maximum profile has exact private storage.

### Admit global writes without a package fixture

Rejected. Coverage families enter with executable evidence.

## References

- [WIP-0020](WIP-0020-semantic-coverage-and-evidence-accounting.md)
- [WIP-0282](WIP-0282-native-compiler-scalar-arithmetic.md)
- [WIP-0314](WIP-0314-native-255-transition-coverage.md)
