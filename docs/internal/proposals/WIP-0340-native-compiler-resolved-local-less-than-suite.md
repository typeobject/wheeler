# WIP-0340: Native compiler resolved local less-than suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0339 |
| Supersedes | Product-only resolved local less-than evidence |
| Superseded by | Broader physical compiler package suites |

## Summary

Execute `ResolvedLocalLessThanKinds.w::resolvedLocalLongLessThan` through an independent native compiler package case.

The case reaches the last opcode in the 256-entry signed local less-than column. `ResolvedStatements.w` remains complete physical input.

## Graph

```text
NativeCompilerResolvedLocalLessThanTests
  -> ResolvedLocalLessThanKinds
       -> ResolvedStatements
```

The test does not copy the base or source count into its owner.

## Evidence

`NativeCompilerNestedHelperEntryExampleTest` compiles a physical entry that calls the classifier. The native artifact matches stage 0 byte for byte and executes successfully.

The native case has source identity `bafe42ee876aeac8e1471acd7f5d72d9185478dde492c3c947415d66fde56866`, execution identity `d63ce0416b18007450eb8641e58196d6458b79d76ce10ef3026a49e95707a6cc`, artifact identity `a9762f3af8f6d03d0dd9f3a3c4a01c66fe26cffe6316fa6352c416d6b5af7222`, and coverage identity `88996b97c03a03ff773eebbbff0a7d1228b38d9d68a5ffb87b086ce9845d9cbb`.

`wheeler test wheeler-compiler --format json` publishes ninety-three selected, ninety-three passed, and zero failed cases with report identity `02b4b5bc837e40c06fdaca860c950e8b009d30dd2c7e322cb7bc6168c0ac1bb3`. The canonical workspace checks 135 targets.

## Acceptance

- [x] The public classifier has an independent native case.
- [x] The complete physical opcode owner remains input.
- [x] Classification reaches the final admitted source local.
- [x] The physical artifact matches stage 0 byte for byte.
- [x] The artifact executes exactly once.
- [x] JSON, terminal, and JUnit adapters consume the same ninety-three rows.
- [x] Compiler, package, workspace, documentation, and file policy gates pass.

The complete package run finished in six minutes and twenty-five seconds under its seven-minute host guard.

The compiler manifest contains 16,469 bytes. The compiler archive contains 3,068,101 bytes with SHA-256 `457423d64f39f7f9bc15bef0bcb8a578737c5ddf5610034b02a1a7c7649bae1d`. Its root manifest identity is `54562a486b20ce546b24d97a58bd24c75b11dbaf33f3765e323dd47c8e0418cc`.

## Rejected alternatives

### Check the first opcode

Rejected. The final opcode proves the upper half-open range rather than only the lower guard.

### Infer less-than from equality classification

Rejected. The physical columns have different bases and consumers.

### Copy the range into test source

Rejected. The production owner and archive remain semantic authority.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0339](WIP-0339-native-20k-test-manifest-bound.md)
