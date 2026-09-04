# WIP-0315: Native compiler void-call width suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-09-04 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0313, WIP-0314 |
| Supersedes | Standalone void-call width evidence |
| Superseded by | None |
| Follow-up | WIP-0316 native compiler void-call source-width suite |

## Summary

Compile and execute both physical ordinary void-call width decoders through the native compiler package suite.

`VoidCallWidths.w` owns the encoded-byte and instruction-count functions. Each calls `voidCallArity` from the three-member `VoidCallKinds.w` owner. The two package cases select the seven-argument form and require exact results of 368 bytes and fifteen instructions.

## Graph

The target carries three physical sources:

```text
NativeCompilerVoidCallWidthTests -> VoidCallWidths -> VoidCallKinds
```

The linker retains both width functions under one owner and all three shape queries under another. Each selected test lowers independently, resolves one exact imported width function, and executes the nested arity call. No production visibility changes.

## Evidence

`NativeCompilerNestedHelperEntryExampleTest` compiles an entry that calls both physical width functions. Its artifact matches stage 0 byte for byte and executes successfully.

`nativecompilervoidcallwidthtests` publishes two native cases with source identity `3c09d223e0e10b19bb333065a2c259e9edc96b31e0bee0b03153e59c99e211c6`.

The code-width case has artifact identity `22c0ec18b7f2298a91aef2516df2082c2cdf74eab2ed23aaafdcd8d40e9de9aa`, execution identity `e7d9b55331ea95da8c908b547eeecb6fdbe6a1a1116383c1c983934820a62861`, and coverage identity `00cf0f6d623d11c25bbc2c5beee70f4e175db832d581ec725a50f62d18948439`.

The instruction-width case has artifact identity `647de7a348558ac0bea705b3b798232b8d71b43309db921aa47b4954988c7465`, the same execution identity, and coverage identity `08ab0cae0852fcc8d70d8092506b370f2ffbd7e0b1b5df8937d2ac210a41884c`.

`wheeler test wheeler-compiler --format json` publishes twenty-six selected, twenty-six passed, and zero failed cases with report identity `4f59b80f5ed25c4eb58e49d9ca87c3c49a599a9134a7ce5a26dd446c7640282d`.

## Acceptance

- [x] One canonical target carries the complete three-source graph.
- [x] Both physical width functions retain one owner.
- [x] Both functions resolve the imported arity query exactly.
- [x] Seven arguments publish 368 encoded bytes and fifteen instructions.
- [x] The physical graph compiles byte for byte against stage 0.
- [x] The resulting combined artifact executes exactly once.
- [x] Both selected native cases compile and execute independently.
- [x] JSON, terminal, and JUnit adapters consume the same twenty-six native rows.
- [x] Compiler, package, workspace, documentation, and file policy gates pass.

The compiler archive contains 3,041,063 bytes with SHA-256 `134f69f968513f05d679f5292e788f47b9566ef037ef0cea7883b035500e9d63`. Its root manifest identity is `0ef9faf7da9b27e5d1433730f81abedf722706254f6eb9bc99771be9983291c8`.

## Rejected alternatives

### Infer instruction count from encoded width in the test

Rejected. Both physical functions own compiler policy and need executable evidence.

### Copy the arity table into the width source

Rejected. The physical dependency edge is part of the compiler graph.

### Merge the two package cases

Rejected. Independent lowering keeps each selected artifact and coverage identity auditable.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0293](WIP-0293-native-compiler-call-syntax-suite.md)
- [WIP-0313](WIP-0313-native-compiler-void-call-operand-suite.md)
- [WIP-0314](WIP-0314-native-255-transition-coverage.md)
- [WIP-0316](WIP-0316-native-compiler-void-call-source-width-suite.md)
