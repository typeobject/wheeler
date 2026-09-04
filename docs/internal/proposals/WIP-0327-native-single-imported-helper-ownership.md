# WIP-0327: Native single imported helper ownership

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-09-04 |
| Area | Self-hosting, compiler linking, package tests |
| Depends on | WIP-0326 |
| Supersedes | Root-qualified one-helper imports |
| Superseded by | None |
| Follow-up | WIP-0328 native 128-case test profile |

## Summary

Preserve the physical owner name when exactly one imported helper precedes an entry, then execute `IdentifierStarts.w` as the sixty-fourth native compiler package case.

The one-helper graph already retained the right code and call target. Its string-table branch did not retain imported-owner metadata. The emitted function was named under the root module, so the artifact was valid and executable but eight bytes shorter than stage 0. A working call does not excuse a false symbol identity.

## String planning

`CompilerCore.w` now selects library string planning whenever imported helper owners are present. Helper count alone no longer decides whether ownership exists.

`LibraryStrings.w` accepts one through twenty-three helpers. The one-helper form plans the class, helper, and entry candidates without reading a nonexistent second helper. Local one-helper programs with no imported owners keep the focused string-table path.

## Graph

The selected package graph has two physical sources:

```text
NativeCompilerIdentifierStartTests -> IdentifierStarts
```

The case passes scalar `122`, the final lowercase ASCII identifier start. It reaches every earlier range guard before acceptance.

## Evidence

`NativeCompilerNestedHelperEntryExampleTest` compares the physical two-source artifact with stage 0 byte for byte. The imported function is `wheeler.compiler.identifier_starts::identifierStart`, not `example.identifier_start_entry::identifierStart`, and the artifact executes successfully.

The complete 376-module physical closure remains byte-identical. Its archive join retains 2,038 scalar symbols and 1,528 callable products.

`nativecompileridentifierstarttests` publishes one case with these identities:

| Field | Identity |
| --- | --- |
| Case | `f0e44fd40fc67c31485e59a1ba5ae716f29b5b13ab5484666665f6e3211b8975` |
| Source | `357d51ae7a36efacf39a7c4d35e12089ddbeaa6f82c605301cf56c6544b0e078` |
| Artifact | `c72550f75c09025c3d653361d6442c0bb4b2952ab542890af60f234f164f8d3c` |
| Execution | `5f42ae1330813251a891ba8bfc47e19c7b59b9af5ef2e9d99c2c37988be4e55b` |
| Coverage | `8031e3f9d06aa8ee8c4f0bc4ae2ad9f51eeb02763615f81b92e54d51f33e5d55` |

`wheeler test wheeler-compiler --format json` publishes sixty-four selected, sixty-four passed, and zero failed cases with report identity `c8f7bb1cbcf6d424cc3ef0ae451852df7f08b96c104ff0d86800000cd80b9b50`. The canonical workspace checks 125 targets.

## Acceptance

- [x] One imported helper selects canonical owner-aware string planning.
- [x] One-helper planning does not read a second helper candidate.
- [x] The physical imported function keeps its module-qualified name.
- [x] The two-source artifact matches stage 0 byte for byte.
- [x] The artifact executes exactly once.
- [x] The native package case reaches the final lowercase boundary.
- [x] JSON, terminal, and JUnit adapters consume the same sixty-four native rows.
- [x] Compiler, package, workspace, documentation, and file policy gates pass.

The compiler package now occupies all sixty-four bounded native case slots. Another case requires a proven case-transport extension or a deliberate suite partition. Silent omission is not spare capacity.

The compiler archive contains 3,055,084 bytes with SHA-256 `9b1ea285c9f25333b469e18fceb9856577d0a5efbae36e377ab1b09dc7b86f63`. Its root manifest identity is `ca3f89fbf2295969398f82adffb5b5e88779bd33c19d9ebadc017deafdd158d6`.

## Rejected alternatives

### Accept the root-qualified function

Rejected. Function names enter canonical artifact bytes, call diagnostics, metadata, and identities. Valid bytecode can still be the wrong bytecode.

### Add a dummy helper

Rejected. Padding the source would hide the one-owner defect and create a second function with no semantic job.

### Special-case `IdentifierStarts.w`

Rejected. Imported ownership belongs to the compiler core and string planner, not to one source filename.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0310](WIP-0310-native-multi-helper-entry-programs.md)
- [WIP-0326](WIP-0326-native-compiler-opcode-kind-suite.md)
- [WIP-0328](WIP-0328-native-128-case-test-profile.md)
