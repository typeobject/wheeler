# WIP-0253: Native parameterless test compilation

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Self-hosting, native testing, source compilation |
| Depends on | WIP-0237, WIP-0247, WIP-0252 |
| Supersedes | Transported artifacts for one parameterless root test |
| Superseded by | None |
| Follow-up | WIP-0254 native imported test compilation |

## Summary

Compile and execute one native-discovered parameterless root test without a Java-supplied artifact.

A zero-length artifact beside one exact descriptor now has two source modes:

- a source with no test declaration compiles its canonical entry and requires `<target>::entry`
- a source with one parameterless test compiles that declaration and requires `<target>::<declaration>`

The second path consumes only the validated manifest, lock, source plan, descriptor frame, and source bytes. Java does not provide the artifact accepted by the verifier or interpreter.

## Test lowering

The fixed physical compiler accepts one canonical `entry void main()` root. It does not yet emit test descriptors or synthetic test entries. `TestSourceTests.w::copyParameterlessEntrySource` performs a bounded test-only lowering before compiler dispatch.

The operation invokes the canonical lexer over the validated root and requires the one declaration already authorized by discovery. It copies every original source byte exactly except two semantic tokens:

```text
test  -> entry
<discovered-name> -> main
```

The output length is derived exactly from the source length and declaration-name length. Comments, strings, UTF-8 bytes, whitespace, body bytes, module bytes, and class bytes remain unchanged. The operation copies source bytes from the validated transport rather than indexing UTF-8 continuation bytes.

This is compiler lowering, not input repair. Discovery still rejects malformed declarations, duplicate names, parameter rows, and descriptor mismatches before lowering.

## Compilation authority

`TestSourceCompilation.w::compileValidatedParameterlessTest` owns:

- the one-source and root-zero bound
- exact transformed source allocation
- source lowering
- UTF-8 freezing
- `compileMinimal` dispatch
- transformed source lifetime
- committed artifact length

The existing `compileValidatedSourcePlan` operation remains the entry-source path. The test runner selects the new operation only when native discovery reports one parameterless case and the descriptor artifact length is zero.

The compiler writes into the same 32,768-byte recovery storage. The runner copies only the committed prefix into exact artifact storage before its single verifier and interpreter attempt.

## Report semantics

The case retains the original manifest identity, source-plan identity, discovered name, case identity, and shard assignment. Lowered source bytes do not replace source identity.

The native compiler is the artifact authority for this mode. Transported artifact function and synthetic-row authorization do not apply to its direct-entry product. Verification, execution, coverage, result reduction, and profile-2 summary remain canonical runtime operations.

## Bounds

The initial profile accepts:

- exactly one validated source
- the manifest-selected root at ordinal zero
- exactly one parameterless test declaration
- exactly one descriptor
- zero transported artifact bytes
- at most 4,096 original source bytes
- at most 32,768 committed artifact bytes

Imports, multiple declarations, and parameter rows remain separate compilation WIPs. They reject before compiler dispatch.

## Evidence

`compilesOneDiscoveredParameterlessTestNatively` supplies `test::passes`, the validated source containing `test void passes()`, and zero artifact bytes.

The native runner discovers the declaration, lowers its exact token ranges, invokes the physical compiler, verifies the committed native artifact once, executes it once with fresh storage, and publishes one selected and one passed case.

The same focused suite retains byte-identical entry-source parity for one through eight sources, transported parameterless and parameter-row execution, foreign-function rejection, swapped-row rejection, and duplicate-row rejection.

The runtime archive contains 282,262 bytes with SHA-256 `a028849840ef2ee6cc3b90c0469425ffc667460db88977d9755d1e8567684984` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,094 bytes with SHA-256 `b866164f0216db3c6b2e0662e0c36510863a4324a0481b4a4831b3890c0d5a3b` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the new runtime archive exactly.

## Acceptance

- [x] Zero artifact length selects native compilation for one discovered test.
- [x] Discovery owns the exact declaration and descriptor name.
- [x] Lowering uses lexer token ranges rather than raw substring search.
- [x] Only `test` and declaration-name token bytes change.
- [x] UTF-8 and all untouched source bytes copy exactly.
- [x] `TestSourceCompilation.w` owns source lifetime and compiler dispatch.
- [x] Java supplies no artifact consumed by native source mode.
- [x] The committed artifact is verified once and executed once.
- [x] The original source plan remains report identity authority.
- [x] One passing declaration publishes one canonical summary.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Compile the `test` declaration directly

Rejected for this slice. The fixed physical compiler has no test-declaration frontend yet.

### Search and replace raw source text

Rejected. Comments and strings cannot become lowering authority.

### Retain the declaration name as the compiler entry

Rejected. The fixed compiler profile requires canonical `main`.

### Hash the lowered source as package source

Rejected. Lowering is an internal compiler product. The original locked source remains identity authority.

### Accept a Java-built artifact as native compilation

Rejected. Differential artifacts may supply evidence, not runtime input.

## References

- [WIP-0237](WIP-0237-native-compiled-test-reports.md)
- [WIP-0247](WIP-0247-native-parameterless-test-discovery.md)
- [WIP-0252](WIP-0252-native-artifact-row-binding.md)
- [WIP-0254](WIP-0254-native-imported-test-compilation.md)
