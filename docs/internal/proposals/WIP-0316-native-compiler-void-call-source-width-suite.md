# WIP-0316: Native compiler void-call source-width suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-09-04 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0315 |
| Supersedes | Standalone void-call source-width evidence |
| Superseded by | None |
| Follow-up | WIP-0317 native compiler void-call source-form suite |

## Summary

Compile and execute the physical source-or-resolved void-call local-width decoder through the native compiler package suite.

`VoidCallSourceWidths.w` owns one public decoder. Named source forms return their widths directly. Resolved forms fall through to `voidCallArity` in the three-member `VoidCallKinds.w` owner. Two independent cases exercise both paths at seven arguments and require fourteen locals.

## Graph

The target carries four physical sources:

```text
NativeCompilerVoidCallSourceWidthTests -> VoidCallSourceWidths -> VoidCallKinds
                                                            -> VoidCallSourceKinds
```

The test root sees only `voidCallLocalCount`. Constant publication from `VoidCallSourceKinds.w`, helper ownership from `VoidCallKinds.w`, and the nested arity relocation remain separate authorities.

## Evidence

`NativeCompilerNestedHelperEntryExampleTest` compiles one entry that executes both physical paths. Its four-source artifact matches stage 0 byte for byte and executes successfully.

`nativecompilervoidcallsourcewidthtests` publishes two native cases with source identity `de91eaed164ef26257412e1d4de75b3c32c90adc6110395e7ff74c2bdbfec2da`.

The source-form case has artifact identity `7dd2f2fa67303a8eb283d409f0c3e4195022cfc767a961ba804e967111b774be`, execution identity `cba024d156c1dafa734b2232b2a2e26675f8669b67e0397ed9e3d53150cf4da1`, and coverage identity `4a8d7b11f642cca7a8ff1f401e8137c72cf01b4335ac005397546e13fedbcae5`.

The resolved-form case has artifact identity `e881a08c3850ab8350b9365b7cf8ed52595d3292b39fa5627b84346301137221`, the same execution identity, and coverage identity `0fd442c3ec27c3c651fd97f1015651fc98e5853fb48f3796286dada9a19ccf66`.

`wheeler test wheeler-compiler --format json` publishes twenty-eight selected, twenty-eight passed, and zero failed cases with report identity `f9f563b8e8d7236bff43985d0df8da1c8bd61c5d61e8857569c0c9ebd9c26f3c`.

## Acceptance

- [x] One canonical target carries the complete four-source graph.
- [x] Named source form 925 publishes fourteen locals directly.
- [x] Resolved form 31,744 publishes fourteen locals through imported arity.
- [x] The physical graph compiles byte for byte against stage 0.
- [x] The resulting combined artifact executes exactly once.
- [x] Both selected native cases compile and execute independently.
- [x] JSON, terminal, and JUnit adapters consume the same twenty-eight native rows.
- [x] Compiler, package, workspace, documentation, and file policy gates pass.

The compiler archive contains 3,042,281 bytes with SHA-256 `558349990437121f1373bf7f170b834ec2988dcca9eaba7163a86510f1b15e13`. Its root manifest identity is `8962ebe16abd6dfded197083072e90e32795a6526dbcaf2e06afe4398f264d81`.

## Rejected alternatives

### Test only named source forms

Rejected. The resolved path owns the imported arity edge.

### Test only resolved forms

Rejected. Direct source identities are a separate compiler contract.

### Merge this decoder with ordinary void-call widths

Rejected. Source-local layout and encoded artifact layout are separate authorities.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0293](WIP-0293-native-compiler-call-syntax-suite.md)
- [WIP-0315](WIP-0315-native-compiler-void-call-width-suite.md)
- [WIP-0317](WIP-0317-native-compiler-void-call-source-form-suite.md)
