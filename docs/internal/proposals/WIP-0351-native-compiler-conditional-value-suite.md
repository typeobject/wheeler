# WIP-0351: Native compiler conditional value suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0350 |
| Supersedes | Product-only conditional classifier and operand evidence |
| Superseded by | WIP-0352 native compiler conditional classifier suite |

## Summary

Execute three small conditional owners through one native compiler evidence increment:

- `NamedLiteralComparisonKinds.w`,
- `NamedLocalConditionalValues.w`, and
- `ResolvedLocalConditionalOperands.w`.

The unresolved cases reach the final literal-comparison and local-value forms in complete physical `StatementKinds.w`. The resolved case decodes source local 255 from the final Boolean condition column in complete physical `ResolvedStatements.w`.

## Graphs

```text
NativeCompilerNamedLiteralComparisonKindTests
  -> NamedLiteralComparisonKinds -> StatementKinds

NativeCompilerNamedLocalConditionalValueTests
  -> NamedLocalConditionalValues -> StatementKinds

NativeCompilerResolvedLocalConditionalOperandTests
  -> ResolvedLocalConditionalOperands -> ResolvedStatements
```

No test source copies a range, source count, or classifier implementation.

## Evidence

`NativeCompilerConditionalEntryExampleTest` compiles one physical entry per graph. Every native artifact matches stage 0 byte for byte and executes successfully.

| Case | Artifact identity | Coverage identity | Source identity | Execution identity |
| --- | --- | --- | --- | --- |
| `classifiesFinalLiteralComparisonConditional` | `85132fc15904d9c9352f35fbf86ea37c42f0a33ebc0ae1a9198e4cca672f761b` | `b8b2cd7960e48eb160e4c5e1b7bc0a2fbb775c8fa31d16f02f4602c122864fca` | `de202630c7848e2434fd20f66562f210457faa2675597f0e3aef174bc8c168af` | `4f01a2cca0e94c24921b80560769400071684863aef38e29ba6f12853ad4e5a5` |
| `classifiesFinalNamedConditionalValue` | `69119213e03bf8e421a216e14891c4ab4e63c15aea1e578781a6dde9242e9eee` | `b8b2cd7960e48eb160e4c5e1b7bc0a2fbb775c8fa31d16f02f4602c122864fca` | `7c86684d9edf83b27cee78f61b83522a34b91f9e30feaf868268716adac741d5` | `74352e7419501bf5a3d9ad936a92b37aaf4ed4f7efdce48d9c94b117973ee9f1` |
| `decodesFinalConditionalSource` | `871819a8f3f1ef25a4bd12d9d0486161641c697e34b734fb602856244a59fb0f` | `883710c9716284ab8711244b370a58dff909531986bdac504c7755c1a252c67a` | `4b9802ff115aa6bc731d40b581900497a73af7b2a2c803a289840191a3681f6a` | `b03cbc5a8bca5821f90143d50ee1fab0106d85d255e7a173a86e90188ed62f4d` |

`wheeler test wheeler-compiler --format json` publishes 139 selected, 139 passed, and zero failed cases with report identity `81ec7a325e7f27c9a57153d127158944a7b5c49f7272c4cda3f4bb1e81eb8314`. The canonical workspace checks 151 targets.

## Acceptance

- [x] All three public queries have independent native cases.
- [x] Complete resolved and unresolved opcode owners remain input.
- [x] Both final unresolved classifier forms execute.
- [x] The final resolved conditional source decodes to 255.
- [x] All three physical artifacts match stage 0 byte for byte.
- [x] Every selected case executes exactly once.
- [x] JSON, terminal, and JUnit adapters consume the same 139 rows.
- [x] Compiler, package, workspace, documentation, and file policy gates pass.

The complete package run finished in twelve minutes and thirty-one seconds under its fourteen-minute host guard.

The compiler manifest contains 24,643 bytes. The compiler archive contains 3,089,817 bytes with SHA-256 `cdc014baea777dc70fb7a6e45989207fc90bcb85d5687493529810bd198a98e7`. Its root manifest identity is `45b4a76ba22514f9bbcaa30fc56ee28a3ab1bb0740549760c6c78cfd5d0bb429`.

## Rejected alternatives

### Give each one-function owner a separate WIP

Rejected. The owners share one conditional evidence boundary and are too small to justify separate proposals.

### Admit the aggregate early-comparison wrapper

Rejected. Its nested-helper graph still fails ownership preflight. This increment retains only byte-identical executable graphs.

### Copy source-count arithmetic into tests

Rejected. Physical production owners remain decoder and classifier authority.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0350](WIP-0350-native-28k-test-manifest-bound.md)
- [WIP-0352](WIP-0352-native-compiler-conditional-classifier-suite.md)
