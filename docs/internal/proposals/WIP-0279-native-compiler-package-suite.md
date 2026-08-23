# WIP-0279: Native compiler package suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, package, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, compiler, package testing |
| Depends on | WIP-0018, WIP-0245, WIP-0278 |
| Supersedes | Compiler packages with no native test-selected target |
| Superseded by | WIP-0280 imported constant assertion, then WIP-0330 256-constant owners |

## Summary

Add the first checked-in compiler package suite discovered, compiled, executed, reduced, and rendered from native case rows.

The `nativecompilerspinetests` target selects seven physical self-hosted compiler constant modules and one test root. The native runner validates the compiler manifest and nonempty core lock, compiles the complete eight-source graph, discovers the test declaration, executes one fresh artifact, reduces its report, and returns the row to `wheeler test`.

Java launches the Wheeler programs and renders JSON. It does not discover, compile, execute, classify, or reduce this case.

## Physical compiler spine

The target compiles these production modules:

- `compiler/backend/EncodingWidths.w`.
- `compiler/ir/Opcodes.w`.
- `compiler/ir/ProofRules.w`.
- `compiler/ir/TypeCodes.w`.
- `compiler/ir/limits/CompilerProgramLimits.w`.
- `compiler/syntax/LoopKinds.w`.
- `compiler/syntax/tokens/CompilerTokenLimits.w`.

Together they exercise the full seven-import source-count boundary and 100 public compiler constants. `Opcodes.w` crosses the former 4,096-byte package adapter ceiling.

The test root carries a harmless production entry because a tool target remains independently buildable. Native test lowering blanks that entry and compiles only `compilesPhysicalCompilerSpine` as the selected case.

The initial assertion is deliberately structural. Successful native compilation proves module declarations, imports, constant tables, source framing, package selection, lock policy, lowering, artifact verification, and execution. Imported-constant value assertions remain blocked by the current minimal test-expression compiler and are not claimed.

## Bounds

The package adapter now admits one source up to the existing 32,768-byte plan ceiling. `TestSourceCompilation.w` applies the same 32,768-byte per-source bound. The complete plan remains capped at 32,768 bytes and eight sources.

Imported modules remain constant-only with 1 through 64 public signed constants and no functions, entries, or tests. This broadens the proven fixture-only one-constant adapter rule without admitting general external callables.

## Package identities

Adding a test target and source changes the compiler manifest and archive. Every direct consumer lock now names the exact compiler archive and manifest identity. Runtime and conformance products retain their source archive identities except where runtime source bounds changed.

No compatibility target or old test file remains.

## Evidence

The following command succeeds from the repository root:

```text
wheeler test wheeler-compiler --format json
```

It publishes one selected and one passed case named:

```text
nativecompilerspinetests::wheeler.compiler.tests.native_compiler_spine::compilesPhysicalCompilerSpine
```

The native report identity is `23badc87db7bf6e4344602dd29328251217a994e7c3453087034f86a72e888c4`. The case carries native artifact, execution, coverage, source, case, and report identities.

## Acceptance

- [x] The compiler package contains one test-selected native target.
- [x] The target selects seven physical production compiler modules.
- [x] The plan reaches the fixed eight-source boundary.
- [x] One selected source exceeds 4,096 bytes.
- [x] Imported constant modules admit up to 64 constants.
- [x] Production entry and test declaration remain distinct.
- [x] `wheeler test wheeler-compiler` uses native discovery and case rows.
- [x] The command publishes one passing JSON case.
- [x] No Java test discovery or execution follows native success.
- [x] Compiler archive and all consumer locks are rebuilt exactly.
- [x] Runtime and conformance locks are rebuilt exactly.
- [x] Focused compiler, runtime, tools, documentation, package, workspace, and file-length policy pass.

The complete self-hosted compiler graph remains outside this spine WIP. WIP-0007 and WIP-0018 retain that acceptance boundary.

The compiler archive contains 3,022,437 bytes with SHA-256 `c923d1a513b880bf13205de8232925be14062160dd869f49496f8409ee091ead` and root manifest identity `8ca1126edccaa2e857e34d7b186bb7eeb445a2ade52707d093b50799b31ab719`.

The runtime archive contains 378,531 bytes with SHA-256 `3d6cbd76ac492a9262d9a656666d040c7d080f44e82c494ac33b163f9a1c9d9d` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 132,872 bytes with SHA-256 `1beb2c57f29a587e5d05ed20152204d38769556d3a63550fce3c0d01b21d82be` and root manifest identity `b9beb8697bb55c654a74476b69a5a21fbcded9791e04f771ab4b25186d2d1349`.

## Rejected alternatives

### Keep compiler tests only in JUnit

Rejected. Bootstrap cannot retire Java while compiler package discovery belongs to JUnit.

### Copy compiler constants into the test root

Rejected. That would test a fixture, not physical compiler source.

### Mark a test-only tool as entryless

Rejected. Ordinary package builds still require a runnable tool artifact.

### Claim imported constant expression coverage

Rejected. The current native test-expression compiler does not prove it.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0245](WIP-0245-native-eight-source-test-compilation.md)
- [WIP-0278](WIP-0278-native-package-row-reduction.md)
- [WIP-0280](WIP-0280-native-compiler-constant-assertion.md)
- [WIP-0284](WIP-0284-native-compiler-constant-suite.md)
- [WIP-0292](WIP-0292-native-compiler-syntax-suite.md)
