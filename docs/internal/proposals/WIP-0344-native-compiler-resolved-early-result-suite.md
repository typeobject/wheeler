# WIP-0344: Native compiler resolved early-result suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0343 |
| Supersedes | Product-only resolved early-result evidence |
| Superseded by | WIP-0345 native 24 KiB test-manifest bound |

## Summary

Execute every public classifier in `ResolvedEarlyResultKinds.w` through independent native compiler package cases.

The eight cases reach terminal forwarding, helper, signed, local, computed, addition, remainder, and division forms. `ResolvedStatements.w` remains complete physical input. No test owner copies its bases, ends, or source count.

## Graph

```text
NativeCompilerResolvedEarlyResultTests
  -> ResolvedEarlyResultKinds
       -> ResolvedStatements
```

## Evidence

`NativeCompilerResolvedReturnEntryExampleTest` compiles one physical entry that invokes all eight classifiers. The native artifact matches stage 0 byte for byte and executes successfully.

| Case | Artifact identity | Coverage identity |
| --- | --- | --- |
| `classifiesFinalHelperForwardingReturn` | `c9366009185cdc23bd185a036e5e6dcd2d3b18b96ad01d58a03358f91163e185` | `6e7b4a1667cdadfb2e9667015856d124ac71716b70ad38365f0408428d9dd1eb` |
| `classifiesFinalHelperReturn` | `7db06cf5ef55bea77710c9dd1acedc703ce1f1d410c7f76233f7ca67d0d0eb92` | `b5d964de065288cf569e62c47aae9461a263d9714bfa1f338b86fa70dac4b426` |
| `classifiesFinalSignedReturn` | `48b330916f107e568d8b93ede7a082dcbb7f8e8b61944b1a4c5c824d62edbc55` | `1a8cd9e056d6e9eede6ab883568d72b0b51868c4c491af371ded13c0598c7682` |
| `classifiesFinalLocalReturn` | `0a8ee88115dbd10b57e53e1a236f0ecda987441f0b251b2129dc8454435c1d71` | `4d9fba229dd49e0ab1ffde3bf7e94121e979e285c7779ccaf5606517a8e1dee4` |
| `classifiesFinalComputedReturn` | `4381b804d50003b426ffb9e49ea161c96f1656e5d661d81317643300452b4793` | `24d623f21dd7de6e8c25fe788b4264b5e853ffa561928843bea676373c5bfd94` |
| `classifiesFinalAdditionReturn` | `b9c6dc7005f8a324743f5f3602be9a3e44d29abb5d8321d3929ae29b242a7a95` | `ccb9a0481d6bdb53cc0c0b501b49583f54bb90c36f51886a56acc01a876dc606` |
| `classifiesFinalRemainderReturn` | `578ad0cdcd9745dc5ab29c6700569e044072cf43ead7cd08efe57137de0432a5` | `edf011a7cbaa4f425f2c36112ba9f5094bcd6ce455183e2a8362f995db04e9ed` |
| `classifiesFinalDivisionReturn` | `c9531b6cddf48138c3c8dcba7c3f76550583d715a118382018583bbd640665d3` | `35fb30e51e6537e7815dfe4883ec239814cb72f75f5f2756376b32f7ff41bae6` |

All cases share source identity `3224f014c3d922a0ccf5a77f7b48f1ad52da078a1ff7e6c1b279cbbb46bf45c9` and execution identity `46cd446f5db05b4e0f72043d990dd9a7611b14f2f3adc66d68d429535b375d28`.

`wheeler test wheeler-compiler --format json` publishes 119 selected, 119 passed, and zero failed cases with report identity `72e78107de38ff77a93c0d1b01aed375a20525643875ad8003903f37c5137831`. The canonical workspace checks 142 targets.

## Acceptance

- [x] All eight public classifiers have independent native cases.
- [x] Complete physical opcode ownership remains input.
- [x] Every terminal early-result family executes.
- [x] The physical artifact matches stage 0 byte for byte.
- [x] Every selected case executes exactly once.
- [x] JSON, terminal, and JUnit adapters consume the same 119 rows.
- [x] Compiler, package, workspace, documentation, and file policy gates pass.

The complete package run finished in nine minutes and thirty-five seconds. Its host guard is eleven minutes.

The compiler manifest contains 20,094 bytes, leaving 386 bytes under the 20,480-byte native bound. The compiler archive contains 3,078,445 bytes with SHA-256 `a94cc3582c33a306b00f77fb35c6bfc740de94b6078229e395c425ea1d3a1ff4`. Its root manifest identity is `331343ae1bf73fa36ae753530384906525fd421ef9da768c4cad50babc1792ad`.

## Rejected alternatives

### Infer narrow classifiers from the aggregate signed query

Rejected. Public narrow queries have independent ranges and consumers.

### Project only one opcode family

Rejected. The complete physical owner has discontiguous helper, comparison, arithmetic, and local-return columns.

### Keep the ten-minute host guard

Rejected. The complete suite came within twenty-five seconds of it without exhausting a native execution bound.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0343](WIP-0343-native-compiler-resolved-early-comparison-suite.md)
- [WIP-0345](WIP-0345-native-24k-test-manifest-bound.md)
