# WIP-0292: Native compiler syntax suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, package, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, compiler testing, physical source coverage |
| Depends on | WIP-0291 |
| Supersedes | One-target native compiler package suite |
| Superseded by | WIP-0293 native compiler call syntax suite |

## Summary

Add a second checked-in native compiler package-test target over seven more physical production modules.

The compiler package now selects two independent eight-source graphs. Each graph has one test root and seven production imports. The package runner discovers, compiles, executes, orders, reduces, and renders fourteen cases without Java discovery or test execution.

## Syntax graph

`nativecompilersyntaxtests` imports:

- `StorageOpcodes.w`.
- `LoopKinds.w`.
- `HelperAbi.w`.
- `BorrowedIntrinsicKinds.w`.
- `LoopBodyOpcodes.w`.
- `KeywordTokens.w`.
- `SourceScalars.w`.

Each module owns one checked constant in an independent declaration. The test root also carries the required inert entry used when the compiler package is consumed as a locked dependency. Native test lowering blanks that entry before compiling each selected declaration.

The target stays below the fixed source-count and 32,768-byte plan limits. It does not concatenate sources or bypass package selection.

## Package profile repair

`NativePackageTestRunner.fixedImportProfile` now counts public signed and Boolean functions directly. The old expression subtracted constant declarations from a pattern that never included them, allowing a negative function count. The corrected gate admits at most one public scalar function and cannot hide additional callables behind constants.

## Evidence

`wheeler test wheeler-compiler --format json` publishes fourteen selected and fourteen passed cases with report identity `b509218ba5e667911354348ff3aef376aa7ec804bed33cf26d16fcc771d11edc`.

The second target has source identity `eb0ae7750421b7ec552b745d7f219019708b5aa9d89473be779abb93a8ce09e2`. Its seven artifacts carry independent case identities and one assertion each. Native package reduction interleaves both targets by case identity rather than target arrival order.

## Acceptance

- [x] A second canonical compiler test target is checked in.
- [x] Seven additional physical compiler modules compile natively.
- [x] Every added module owns one executable assertion.
- [x] Fourteen package cases execute exactly once.
- [x] Package rows from both targets reduce in canonical case order.
- [x] All three adapters render the combined native report.
- [x] Locked dependency compilation accepts each test root's inert entry.
- [x] The fixed import gate counts scalar functions correctly.
- [x] Compiler archive and consumer locks are rebuilt exactly.
- [x] Focused compiler package, tools, adapters, documentation, workspace, and file-length policy pass.

The compiler archive contains 3,026,112 bytes with SHA-256 `9271950d4ef7f461a429b71876e1ab05656acf9f0fbf5b06ebabcf443105010f` and root manifest identity `96d9ba9ff123788bfdd6253d46ccd968116426059f0f30e8d77cece5d5ff8180`.

The runtime archive remains 415,390 bytes with SHA-256 `8d209a6e58ca4c8091f4b12e2f651d8e4825e179c42e17c4c3c77de8523c6b60` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

## Rejected alternatives

### Enlarge the fixed source graph

Rejected. Independent target partitions preserve the proven eight-source compiler boundary.

### Add Java tests for the same constants

Rejected. The package suite must discover and execute Wheeler declarations natively.

### Treat a negative function count as zero

Rejected. Structural gates must represent the source they admit.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0279](WIP-0279-native-compiler-package-suite.md)
- [WIP-0285](WIP-0285-native-compiler-callable-suite.md)
- [WIP-0291](WIP-0291-native-test-junit.md)
- [WIP-0293](WIP-0293-native-compiler-call-syntax-suite.md)
