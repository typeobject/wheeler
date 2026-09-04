# WIP-0342: Native compiler resolved assertion suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-09-04 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0341 |
| Supersedes | Product-only resolved assertion evidence |
| Superseded by | None |
| Follow-up | WIP-0343 native compiler resolved early-comparison suite |

## Summary

Execute every public query in the three physical resolved assertion owners through native compiler package cases:

- `ResolvedBooleanLiteralAssertions.w`,
- `ResolvedLessThanAssertions.w`, and
- `ResolvedLocalPairAssertions.w`.

The nine cases reach source local 255 in every represented assertion column. Pair-source cases execute both signed and Boolean decoder branches. `ResolvedStatements.w` remains complete physical input.

## Graphs

```text
NativeCompilerResolvedBooleanLiteralAssertionTests
  -> ResolvedBooleanLiteralAssertions -> ResolvedStatements

NativeCompilerResolvedLessThanAssertionTests
  -> ResolvedLessThanAssertions -> ResolvedStatements

NativeCompilerResolvedLocalPairAssertionTests
  -> ResolvedLocalPairAssertions -> ResolvedStatements
```

No test owner copies a base, end, or source count.

## Evidence

`NativeCompilerResolvedAssertionEntryExampleTest` compiles one physical entry per graph. Each native artifact matches stage 0 byte for byte and executes successfully.

| Case | Artifact identity | Coverage identity |
| --- | --- | --- |
| `classifiesFinalBooleanLiteralAssertion` | `9dbe2cd9dc8c10267938cc1ed21c0b221ae314a3b239280f2a14601050473fc5` | `784bffc5e433997ec525fb927a811d5b31f5b8bb860ab9b08ffec1c9208f5fc3` |
| `decodesFinalBooleanLiteralAssertionSource` | `5e7572b7f9f478b11f0bfd57ca746a7c96ee9077294e8bb955aaefe61322fb2f` | `7ab7a28242aed5702f7c1b874078cda64060230baec4fd3befc31ec4fdc8a2c7` |
| `classifiesFinalLocalLessThanAssertion` | `9738dd3c72d82c7aaa127b3410649b28ba703e06cc2080758fa6e57bcfff0f03` | `6a17ae9872a3b616e6eca1c061a5fe902a97b6a7880fe24e3bfb520e3cec76a7` |
| `classifiesFinalLiteralLessThanAssertion` | `81539eddcd7ea6015c08b80e6bafe7d11863f4ba8cfa5a7dad01c1b173e2c05b` | `b0fa6246b891fccd82bc8ca44aeab44cd34b4343c771ac8253b1d6c35f75d8b9` |
| `decodesFinalLiteralLessThanAssertionSource` | `a39a01d1e69dd035a689213e023a048b15c3b780c6bea70a731497c24c21c976` | `fde4f9536bc62e8282377c97d6bf4b4bd9346c29507c05861654feb550bdeed4` |
| `classifiesFinalBooleanPairAssertion` | `b8ff7f3732e03dd10ac038e03f63c7e6e3f13250fcaf3e2a6b7d76d96e0907f9` | `6a17ae9872a3b616e6eca1c061a5fe902a97b6a7880fe24e3bfb520e3cec76a7` |
| `classifiesFinalSignedPairAssertion` | `10a57c51e046d785fb3b8b3f1dfb0c5e04705a6438abafbc9b8dc53c3dff1e86` | `b0fa6246b891fccd82bc8ca44aeab44cd34b4343c771ac8253b1d6c35f75d8b9` |
| `decodesFinalSignedPairAssertionSource` | `b9e92d4245dd2d30ee048d8917d3c4a38f275fd366d5b17dce3617ba0a14660d` | `82aa5ac6a4ed07935155668c8ba7d1477f86febda9a9ae32896b78fe9e6a355d` |
| `decodesFinalBooleanPairAssertionSource` | `4ef99002d508f9e9a1176962805cbac3679263697f0e039193c084f120844290` | `ec59fd4df6a27955a3aacba3b2080e2dcc07071a04ef1d28afce54c1ad4f126c` |

The Boolean-literal cases share source identity `895a250a76821693d128d75584c5aa3fe699ee35fbccfa11624868f04f3e756a` and execution identity `2f7dff6c0e31f6679d8e9413537712155e1dbdade180bce428ca9e52c2692fa2`. Less-than cases share source identity `c9c33558f14de8ce552e806f397c263c7ebf41074a48e29a7a686f1e79702a40` and execution identity `61214b97e53726a034c0e06f2f1681d7f1f6a6f4f2040c809821ca442de05c08`. Pair cases share source identity `2984c73531e110e73fa07ec3237c040ba082c4984e1110cb797d974ed1951931` and execution identity `0f3e03787a87e2ae8668740b75e4446d87b6198a548842204ae05145197bc0ec`.

`wheeler test wheeler-compiler --format json` publishes 109 selected, 109 passed, and zero failed cases with report identity `a56bd7cc2e52ad4300c6be054a5bca3af3014f03d0e34ae51c778d48a863d2f9`. The canonical workspace checks 140 targets.

## Acceptance

- [x] All nine public assertion queries have independent native cases.
- [x] Complete physical opcode ownership remains input to all graphs.
- [x] Every represented terminal assertion source executes.
- [x] Signed and Boolean pair-source branches execute independently.
- [x] All three physical artifacts match stage 0 byte for byte.
- [x] Every selected case executes exactly once.
- [x] JSON, terminal, and JUnit adapters consume the same 109 rows.
- [x] Compiler, package, workspace, documentation, and file policy gates pass.

The complete package run finished in eight minutes and four seconds. Its host guard is nine minutes.

The compiler manifest contains 19,110 bytes. The compiler archive contains 3,075,270 bytes with SHA-256 `374959af84693f5d50eaaa88b8aca7bfa75b153a9d651aded82afbbc20e9d4ad`. Its root manifest identity is `aed24b346bd3de9316b51bb0e3060fd5a01e5b056ef770423bb251093bbf1575`.

## Rejected alternatives

### Infer assertion columns from expression columns

Rejected. Assertion bases, consumers, and source decoders are independent physical authority.

### Test one pair source form

Rejected. Signed and Boolean pair opcodes use separate decoder branches.

### Keep the eight-minute host guard

Rejected. The complete suite consumed it without exhausting a native execution bound.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0341](WIP-0341-native-compiler-local-literal-comparison-suite.md)
- [WIP-0343](WIP-0343-native-compiler-resolved-early-comparison-suite.md)
