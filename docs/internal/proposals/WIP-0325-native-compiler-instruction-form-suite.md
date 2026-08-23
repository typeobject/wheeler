# WIP-0325: Native compiler instruction-form suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0324 |
| Supersedes | Product-only instruction-form evidence |
| Superseded by | Broader physical compiler package suites |

## Summary

Execute the physical `InstructionForms.w` operand-count authority through the native compiler package suite.

The package case asks for `OPCODE_RECORD_GET`. This reaches the private storage classifier after every ordinary opcode branch misses. The complete three-source production graph remains present, including both canonical opcode tables.

## Graph

The selected source graph is:

```text
NativeCompilerInstructionFormTests -> InstructionForms
InstructionForms -> Opcodes
InstructionForms -> StorageOpcodes
```

The test root does not import `StorageOpcodes.w`. A second direct edge would grant unnecessary visibility and give the graph executor redundant root authority. The case passes the canonical numeric input `1281`. The production owner still resolves the matching constant from `StorageOpcodes.w`.

## Coverage boundary

A package case using `OPCODE_MAP_HAS` traversed the complete ordinary and storage tables but exceeded the representable 255-transition coverage frame. The runner rejected that artifact after execution. Raising the bound is impossible without changing the one-byte coverage format, so the case moved to the first private storage branch.

This is not truncated evidence. `NativeCompilerNestedHelperEntryExampleTest` compiles one physical entry that checks the final storage opcode and an unknown opcode. The artifact matches stage 0 byte for byte and executes successfully. The native package case supplies bounded report and coverage evidence for the same public query.

## Evidence

`nativecompilerinstructionformtests` publishes one case with these identities:

| Field | Identity |
| --- | --- |
| Case | `99841921d0a7dc548fbd7a3c9f6a99c274aa9b1b5466dca28438d433035265e8` |
| Source | `6105ae31a98e7088ae75b14baa22ad226a0abadba2cfaef12a0282aecedda31e` |
| Artifact | `7a0446872379d9e739bc1c8ee4ba276cccd06ae54d55306102a078772e45be72` |
| Execution | `0f1bc184b5b66fd08376c79e30a7a922c7fa7906fc8071251be9178775cb50ae` |
| Coverage | `b57c8113ffcd5e32253f98991add75ed07167654b44a0688ee2c57180c3ec5f3` |

`wheeler test wheeler-compiler --format json` publishes fifty-nine selected, fifty-nine passed, and zero failed cases with report identity `189971fefaf91824f29311f19b5b2a60eba2b368a6f96c2c3a95e7ea92192536`. The canonical workspace checks 123 targets.

## Acceptance

- [x] The complete physical instruction-form owner compiles from its two canonical dependencies.
- [x] A native package case reaches the private storage classifier.
- [x] The selected artifact executes once and publishes complete coverage.
- [x] A byte-identical differential artifact reaches the final storage branch.
- [x] The differential artifact also checks the unknown-opcode verdict.
- [x] JSON, terminal, and JUnit adapters consume the same fifty-nine native rows.
- [x] Compiler, package, workspace, documentation, and file policy gates pass.

The compiler archive contains 3,052,805 bytes with SHA-256 `6414be88c9e1237ff301d8bbaae1f0137bf0e09fd979771e8a7c8c3b49397593`. Its root manifest identity is `5ffa197577e24dfd70a0a06337ba33dbacadca6e9375819aefb75cba5e8eed26`.

## Rejected alternatives

### Widen coverage past 255 transitions

Rejected. The current frame carries one unsigned byte. A wider profile needs a format change, not an integer with better manners.

### Publish truncated coverage

Rejected. Partial transition evidence would make the report valid and the claim false.

### Import the storage table from the test root

Rejected. The instruction-form owner already has that direct dependency. Root visibility is not inherited and should not be enlarged for spelling convenience.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0314](WIP-0314-native-255-transition-coverage.md)
- [WIP-0324](WIP-0324-native-compiler-wide-return-source-suite.md)
