# WIP-0280: Native compiler constant assertion

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, coverage, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, compiler testing, semantic coverage |
| Depends on | WIP-0020, WIP-0279 |
| Supersedes | Structural-only native compiler spine test |
| Superseded by | WIP-0281 native compiler arithmetic coverage |

## Summary

Make the native compiler package suite assert a value imported from physical compiler source.

`NativeCompilerSpineTests.w` now initializes a signed local from `ENCODING_WIDTH_U16` in `compiler/backend/EncodingWidths.w` and checks that it equals 2. The test no longer passes merely because seven compiler modules parse and link.

The resulting native artifact adds `LOCAL_EQ` to the package runner's transition stream. `BootstrapCoverageFragments.w` now names and reduces that opcode instead of trapping during coverage publication.

## Lowering boundary

A direct assertion over an imported constant is not yet admitted by the minimal test-expression compiler. The accepted source uses the existing proven shape:

```text
long width = ENCODING_WIDTH_U16;
assert(width == 2);
```

Native compilation resolves the imported constant, emits `LOCAL_CONST`, moves it into the declared local, compares it through `LOCAL_EQ`, and attempts one assertion. Stage 0 is not asked to rewrite the expression.

This is an executable value check, not a copied fixture. Removing or changing the production constant changes compilation or the outcome.

## Coverage

The accepted transition vocabulary already included `LOCAL_CONST`, `LOCAL_MOVE`, `EXPECT_TRUE`, `RETURN`, `CALL_VOID`, and `HALT`. The new case reaches `LOCAL_EQ`.

Coverage JSON uses the exact stable opcode spelling `LOCAL_EQ`. Artifact, execution, coverage, case, and report identities all change together. Opcodes outside the admitted coverage profile still fail closed.

## Evidence

`wheeler test wheeler-compiler --format json` publishes one selected and one passed native case. The report identity is `b0181587bb729c6be07938fd8ca7e3b43102416067976e7e8159b6a0b16e1cf0`. The coverage identity is `b390a844375bed5f4fda6ccc29c6aa547f3ac59ca693e6ed5f24a8d8f1067d2c`.

The case is still discovered, compiled, executed, reduced, ordered, and rendered through native package rows. No Java execution checks the constant.

## Acceptance

- [x] The compiler suite reads a production imported constant.
- [x] Native lowering emits a signed local from that constant.
- [x] Native execution checks exact equality with 2.
- [x] Coverage reduction admits and names `LOCAL_EQ`.
- [x] Opcodes outside the coverage profile remain rejected.
- [x] The package command publishes one passing native case.
- [x] Compiler, runtime, conformance archives and consumer locks are rebuilt exactly.
- [x] Focused compiler package, coverage, tools, documentation, workspace, and file-length policy pass.

The compiler archive contains 3,022,480 bytes with SHA-256 `1a9b97f212b78a8385da85524f93b86e0d151d657e1c610fb51d313858636cc6` and root manifest identity `8ca1126edccaa2e857e34d7b186bb7eeb445a2ade52707d093b50799b31ab719`.

The runtime archive contains 378,706 bytes with SHA-256 `720e97a6e82010352910cad957d7b5e9ec865106f330f57259cbc42bbe8966b8` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 132,872 bytes with SHA-256 `1beb2c57f29a587e5d05ed20152204d38769556d3a63550fce3c0d01b21d82be` and root manifest identity `b9beb8697bb55c654a74476b69a5a21fbcded9791e04f771ab4b25186d2d1349`.

## Rejected alternatives

### Keep `assert(true)`

Rejected. Parsing evidence is useful, but the suite can now check a physical compiler value.

### Copy the width into test source

Rejected. The production module must own the value.

### Ignore `LOCAL_EQ` in coverage

Rejected. Executed transitions either receive exact semantic coverage or fail publication.

### Claim direct imported-constant assertions

Rejected. The accepted local-binding shape is the proven boundary.

## References

- [WIP-0020](WIP-0020-semantic-coverage-and-evidence-accounting.md)
- [WIP-0279](WIP-0279-native-compiler-package-suite.md)
- [WIP-0281](WIP-0281-native-compiler-arithmetic-coverage.md)
