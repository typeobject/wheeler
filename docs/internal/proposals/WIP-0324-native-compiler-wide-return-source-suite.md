# WIP-0324: Native compiler wide-return source suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0323 |
| Supersedes | Stub-only wide-return source evidence |
| Superseded by | WIP-0325 native compiler instruction-form suite |

## Summary

Execute every public source packer and decoder in `WideReturnSources.w` through an independent native compiler package case.

The first attempt exposed a compiler defect rather than a test limit. A three-local value call reserved eight local registers but the entry type emitter reached a narrower unrelated classifier before its generic width fallback. The descriptor advertised the correct frame while emission omitted four type rows. Native verification rejected the truncated functions section.

`StatementLocalTypes.w` now handles the complete three- through seven-local signed call family before unrelated scalar statement classifiers. It emits the canonical statement-local count, `2 * arity + 2`, equal to the code generator's source copies, argument transfers, call result, and final move.

## Graph

All cases retain two physical sources:

```text
NativeCompilerWideReturnSourceTests -> WideReturnSources
```

The packers receive distinct prior locals. Repeated operands would not prove source order or the fixed three-local type window. Decoder cases use the exact packed values `168496141` and `921360`.

## Evidence

`NativeCompilerNestedHelperEntryExampleTest` independently compiles and executes all nine calls. Every artifact matches stage 0 byte for byte. The three-local packer is the regression boundary: its entry has seventeen typed locals and nineteen instructions, including eight call locals.

The complete 376-module archive closure retains 2,038 scalar symbols and 1,528 callable products after the wide-call type dependency enters `StatementLocalTypes.w`.

`nativecompilerwidereturnsourcetests` publishes nine cases with source identity `47e016dc480945ce0c575ea8c52d8e426d175c1ede70a1e41382b057a41f76dd` and execution identity `f918bc1e7a09ff2dfb7076f42e06e5c0d50fd5bab0133a8e0f27d7b698f29874`.

| Query | Artifact identity | Coverage identity |
| --- | --- | --- |
| Leading packer | `4e0fbaebd388b598e29c8783c2280dbd8382af9fed0998005a922a2ffc734675` | `027dd2a448ca90b926daefa4ef7f755c2a87fed261f263e02cb57e897b633c67` |
| Trailing packer | `fb2157e531cb4362160e37123d9a9c193017b68f0dddb0fe5cd7e689b8dc03a6` | `7bc79c67778336263ead0c7d328ab6e667e12a2008608a747b44321a4a17df4c` |
| First source | `504e7d6be9095517df9f144ff4ef19465aea82ef5d256820ee61339b353f29fd` | `fdce511d0cae086adfad9336b38e74d3b5e90eef844a4badd2f657e7d7f848e8` |
| Second source | `ad550ea912fe0884c99ad632ed05eea7c7417fedaa54f1659b2e1a23ddc6d600` | `9872de13b0a1a863b87d47e67b3eef8727e2a91b563d02a8a9646a2138777fc9` |
| Third source | `45e18641e6881b6136a1a78961348ddac16a1852db94662d0cc507a0fd07c468` | `301b5fda33bfd0d3bed17375d3589d07fba189389b95764379729b4406c97db4` |
| Fourth source | `2bdccbc85a7709e0268fa949ac178d3f138ec491483cc67075d811e9014a054e` | `71ffaf0b99a0608fd84c1ae2eb0fc10e55912a7d5ac7766545348f48a8be5a07` |
| Fifth source | `8e12b935fe82c3bdf71e7607ef99a3942977367473bd49fe385bdd2c551c91d1` | `7145c536a2e9b4d2ec97a17d0d45bece8453d32872ba662fe5740d89e3e44463` |
| Sixth source | `bcb6614cbc2326e176891c4ee1d876fbf164e23994916e4c835b9900eb42130e` | `29686344b416f953a24e2cfa0f930bb3b1348ad40bde561328cda33fc89c7678` |
| Seventh source | `a8fbe5be394752c5ee06ea617b7298e90a4b2b9764caf35ad5315b8f2f77ee4b` | `8d576a2370c7a37fe1d0a153a07e76610c689dbd6c94a82f93100fcd5d5982a0` |

`wheeler test wheeler-compiler --format json` publishes fifty-eight selected, fifty-eight passed, and zero failed cases with report identity `bf59d68d0509a7a00cca634d61c912cdc93860541f67dae90b26cfb6db04a6d6`. The canonical workspace checks 122 targets.

## Acceptance

- [x] The entry type emitter owns the complete three- through seven-local call family.
- [x] Three distinct source locals emit eight signed type rows.
- [x] Both physical source packers execute through independent native cases.
- [x] All seven source decoders execute through independent native cases.
- [x] Every focused artifact matches stage 0 byte for byte.
- [x] Every focused artifact executes exactly once.
- [x] JSON, terminal, and JUnit adapters consume the same fifty-eight native rows.
- [x] Compiler, package, workspace, documentation, and file policy gates pass.

The compiler archive contains 3,051,805 bytes with SHA-256 `16b12ff24abe4c5e67eab74ef03e96972923755b304156ca13bca4829e0f1644`. Its root manifest identity is `a6ceb125fd466262071b4d29f13117828a1ebc1229f51e29006bd216a0f987b7`.

## Rejected alternatives

### Repeat one source local

Rejected. Equal operands conceal source-order defects in both packed operands.

### Trust the descriptor local count

Rejected. A frame claim is not an emitted type table. The verifier was right to reject the short section.

### Special-case only three arguments

Rejected. Entry typing owns one signed wide-call family. Keeping four through seven on a fallback would preserve the same ordering hazard under another identity.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0323](WIP-0323-native-compiler-helper-signature-suite.md)
- [WIP-0325](WIP-0325-native-compiler-instruction-form-suite.md)
