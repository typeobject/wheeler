# WIP-0349: Native compiler named return suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0348 |
| Supersedes | Product-only unresolved return classification evidence |
| Superseded by | Broader physical compiler package suites |

## Summary

Execute every public classifier in three unresolved return owners through native compiler package cases:

- `NamedBooleanReturnKinds.w`,
- `NamedReturnArithmeticKinds.w`, and
- `NamedSignedReturnKinds.w`.

The eight cases reach each owner's final local, pair, equality, inequality, less-than, or aggregate comparison form. The complete 139-constant `StatementKinds.w` owner remains physical input.

## Graphs

```text
NativeCompilerNamedBooleanReturnKindTests
  -> NamedBooleanReturnKinds -> StatementKinds

NativeCompilerNamedReturnArithmeticKindTests
  -> NamedReturnArithmeticKinds -> StatementKinds

NativeCompilerNamedSignedReturnKindTests
  -> NamedSignedReturnKinds -> StatementKinds
```

No test source copies a range or classifier implementation.

## Evidence

`NativeCompilerResolvedReturnEntryExampleTest` compiles one physical entry per graph. Every native artifact matches stage 0 byte for byte and executes successfully.

| Case | Artifact identity | Coverage identity |
| --- | --- | --- |
| `classifiesFinalBooleanEqualityReturn` | `9719f705825191b00be95888afda8560ca15dd28876185fbc08b01606ce20a2e` | `3433006767935567b5ac8f3cd55730cf0cd9c6094e4df81826e70563a03d5473` |
| `classifiesFinalBooleanInequalityReturn` | `a1b23f11e9af2939e410a40c78f8cc26093dd4a8ee21af71a591d953f8132102` | `35fa52dae6c97e442df9a9edfce756ba8071b71f0fe4c7724bb372c880735770` |
| `classifiesFinalBooleanComparisonReturn` | `1cea856bdd5fa2b3c4c9165027429ec806ceca7d9afd3765f49c0985eb09babd` | `85ed84d898e4a75ce02bb70224f620f7d791d5180fad5db75d7d28b22bfdc996` |
| `classifiesFinalLocalBinaryReturn` | `7f0dc1472d9872793ffcb3db5263263469a96d1d5200362e562cb0b105e8e92c` | `0919f1433f96591b96cffcbad6f6dbf1f3d56012e3d117db39cc5dbd8468c690` |
| `classifiesFinalLocalPairReturn` | `52ad95be7fe46ae17cf6438c62fef28fbea1500b44c17e8165f6be7ec50cebb5` | `7b94a372c16278e0f6db6501fb24c1558767e546e62c46cb042b2fd6e6ecb02d` |
| `classifiesFinalSignedEqualityReturn` | `486c761e3ff51786cbc7829b284b9e025a7f2952b18a7358ffc67fbea6ecbed5` | `3433006767935567b5ac8f3cd55730cf0cd9c6094e4df81826e70563a03d5473` |
| `classifiesFinalSignedInequalityReturn` | `e8a77d3045e2958c0ea64460bf2edf9595e7572fea031bdcdfe9099ce813ae95` | `35fa52dae6c97e442df9a9edfce756ba8071b71f0fe4c7724bb372c880735770` |
| `classifiesFinalSignedLessThanReturn` | `a6c714514131c949b5e7f220e60a71abc6d7a607cf54f2e32a070ea298c7f80e` | `3f516702b95f2a2c50771cd4d704cd2f0122f11fc6fea4948b86eb61d72f1c34` |

Boolean cases share source identity `dde1a35c5bb210ad3f0ddcfc5c4ce88c01a2d9d6bf77851880461790efa99305` and execution identity `e35f64f6a369271dc7ae347061f4eece96c6201d058af678bea51e29644b5966`. Arithmetic cases share source identity `d54d0d5d80cfe3d2839f77e20b14fcebbc002040f81f37475b0546f55a8df98d` and execution identity `1d2ed80a232a21f2d1556a535cae6076caa29973535a28ad9384c60cd72bc291`. Signed cases share source identity `2abe5ad9a62db2801ef986db3b7ea5773675635eebbd8766ea4adae0c88ae32f` and execution identity `5d978776a9462ac1fbcbcbfa4c0994fe43f35fbd6027a7be418426bc28653857`.

`wheeler test wheeler-compiler --format json` publishes 136 selected, 136 passed, and zero failed cases with report identity `ea0f1ce526ac7b06d7f0b6b65051f792b65fbe2c65d027c2e7f9bb7f36a1b583`. The canonical workspace checks 148 targets.

## Acceptance

- [x] All eight public classifiers have independent native cases.
- [x] The complete physical unresolved opcode owner remains input.
- [x] Every final admitted classifier form executes.
- [x] All three physical artifacts match stage 0 byte for byte.
- [x] Every selected case executes exactly once.
- [x] JSON, terminal, and JUnit adapters consume the same 136 rows.
- [x] Compiler, package, workspace, documentation, and file policy gates pass.

The complete package run finished in twelve minutes and seventeen seconds under its thirteen-minute host guard.

The compiler manifest contains 23,039 bytes. The compiler archive contains 3,086,374 bytes with SHA-256 `72677071dc85e36fdd4ccdbc698eaed37cbd95958877bfffe6f6295916ac2637`. Its root manifest identity is `542c41b4f212ce83dec7b899cddaa85bcb35e93c3e9e59f306b1b33ecb53789d`.

## Rejected alternatives

### Give each classifier owner a separate WIP

Rejected. The owners share one unresolved return-opcode authority and one native evidence boundary.

### Check only literal forms

Rejected. Final local and pair forms prove each complete classifier branch.

### Copy constants into a projected owner

Rejected. The canonical 139-constant statement owner remains archive-backed input.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0348](WIP-0348-native-255-case-test-profile.md)
