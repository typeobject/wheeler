# WIP-0281: Native compiler arithmetic coverage

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, coverage, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, compiler testing, semantic coverage |
| Depends on | WIP-0280 |
| Supersedes | Imported compiler constant equality without arithmetic |
| Superseded by | WIP-0282 native compiler scalar arithmetic |

## Summary

Exercise checked local arithmetic over a physical imported compiler constant and publish its native coverage.

The compiler spine test now adds the imported `ENCODING_WIDTH_U16` value to itself and checks the result 4. The package report records two assertion attempts.

`BootstrapCoverageFragments.w` adds exact `LOCAL_ADD` spelling and framing. The negative coverage fixture moves to `LOCAL_SUB`, which remains outside the admitted bootstrap coverage profile and still proves atomic rejection.

## Test body

The accepted body is:

```text
long width = ENCODING_WIDTH_U16;
assert(width == 2);
long doubled = width + width;
assert(doubled == 4);
```

This path resolves production source, emits local moves and checked addition, compares both results, and executes both assertions under the native package runner. The test does not duplicate the imported width.

## Coverage boundary

The admitted vocabulary now includes `LOCAL_ADD` beside the constant, move, equality, call, return, assertion, and halt forms from WIP-0280.

`LOCAL_SUB` remains executable VM semantics but is not yet an admitted package coverage fragment. Its fixture traps before report length or output publication. Coverage admission stays explicit instead of treating every opcode number as a valid report key.

## Evidence

`wheeler test wheeler-compiler --format json` publishes one passing case with two assertion attempts.

The report identity is `e7b22f150b33246527e9a5f9e36e429a05d5992950fee9bcb4ac19ca9bb01ed5`. The coverage identity is `dbab13697384f550b0289b2b9231428eb2fe1fe8ed2e33f21dd26223627c414e`.

`unsupportedNativeTracePublishesNoPartialReport` now reaches `LOCAL_SUB` and retains its zero-length, zero-output failure contract.

## Acceptance

- [x] The compiler package case performs checked local addition.
- [x] The arithmetic operands derive from a production imported constant.
- [x] Native execution attempts two assertions.
- [x] Coverage reduction admits exact `LOCAL_ADD` events.
- [x] Unadmitted `LOCAL_SUB` coverage fails atomically.
- [x] The package command publishes one passing native report.
- [x] Compiler, runtime, conformance archives and consumer locks are rebuilt exactly.
- [x] Focused compiler package, coverage, tools, documentation, workspace, and file-length policy pass.

The compiler archive contains 3,022,540 bytes with SHA-256 `ea3ce1536133f7f74acda49a5d93fe0dd8e09a18c3cb4d8227fc78c2db5524ef` and root manifest identity `8ca1126edccaa2e857e34d7b186bb7eeb445a2ade52707d093b50799b31ab719`.

The runtime archive contains 378,884 bytes with SHA-256 `93ea30569507b4dea495ebcd64d2313f4e4e621e5dd2167df89e7ff6962a5016` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 132,872 bytes with SHA-256 `1beb2c57f29a587e5d05ed20152204d38769556d3a63550fce3c0d01b21d82be` and root manifest identity `b9beb8697bb55c654a74476b69a5a21fbcded9791e04f771ab4b25186d2d1349`.

## Rejected alternatives

### Use a literal arithmetic operand

Rejected. Both operands should retain the production constant provenance.

### Count assertions without coverage

Rejected. The report must describe the executed transition family.

### Admit every arithmetic opcode at once

Rejected. Each fragment needs executable evidence and an atomic negative boundary.

## References

- [WIP-0020](WIP-0020-semantic-coverage-and-evidence-accounting.md)
- [WIP-0280](WIP-0280-native-compiler-constant-assertion.md)
- [WIP-0282](WIP-0282-native-compiler-scalar-arithmetic.md)
