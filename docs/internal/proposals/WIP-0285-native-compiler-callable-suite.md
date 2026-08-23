# WIP-0285: Native compiler callable suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, coverage, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, compiler testing, imported callables |
| Depends on | WIP-0284 |
| Supersedes | Constant-only native compiler spine imports |
| Superseded by | Broader native callable compiler modules |

## Summary

Compile and execute a physical imported compiler function in every native compiler package case.

The spine replaces `LoopKinds.w` with `BooleanTokens.w`. That production module owns two constants and `booleanTokenHash(long)`. Every focused case calls the imported function with the canonical `true` token hash before checking its owner-specific constant. The Boolean-token case consists solely of the callable check.

The fixed package adapter now admits one public signed or Boolean function in a constant import module. It still rejects multiple functions, entries, tests, and modules with no public constants.

## Callable graph

Every selected declaration references `booleanTokenHash`. This matters because the recovery graph compiler treats executable imports as live dependency products. Leaving the function unreferenced would not prove mixed constant and callable graph composition.

The imported function executes its equality guard and early Boolean return. Native traces therefore add:

- `CALL_VALUE`.
- `JUMP_IF_ZERO`.
- `RETURN_VALUE`.

`BootstrapCoverageFragments.w` names all three exactly. Existing `LOCAL_EQ`, constant, move, assertion, and ordinary return events complete the call path.

## Package profile

`NativePackageTestRunner.fixedImportProfile` counts exact public constants and scalar functions. One imported module may carry 1 through 64 signed constants and at most one public signed or Boolean function. Native compilation remains the semantic authority for signatures, bodies, graph edges, types, and call resolution.

The adapter does not whitelist `BooleanTokens.w` by path or module. It enforces the bounded structural profile used by this suite.

## Evidence

`wheeler test wheeler-compiler --format json` publishes seven selected and seven passed native rows. The combined report identity is `e1e34a0b79920ede1b4b1041bf30a9ea63c99ea4c75c3391c55d9be89ded272f`.

The Boolean-token row has one assertion and coverage identity `6cca774d49d0a601d44dacce563e47e907b8f97c1978b1c33a3583eb35cf040d`. Constant-owner rows have two assertions because they check the callable and their constant. The encoding row has ten assertions and preserves the scalar operation chain.

## Acceptance

- [x] One physical compiler import owns a public scalar function.
- [x] Every selected case references that imported function.
- [x] Native graph compilation mixes callable and constant imports.
- [x] Native execution performs `CALL_VALUE`.
- [x] The imported guard executes `JUMP_IF_ZERO`.
- [x] The imported result executes `RETURN_VALUE`.
- [x] Coverage reduction names all three forms exactly.
- [x] Seven package rows pass under the callable graph.
- [x] The adapter has no module-specific allowlist.
- [x] Compiler, runtime, conformance archives and consumer locks are rebuilt exactly.
- [x] Focused compiler package, coverage, tools, documentation, workspace, and file-length policy pass.

The compiler archive contains 3,024,011 bytes with SHA-256 `f368a20b722ed114247166df99f4a482fb099041d5ebfa4858a0c192429da70f` and root manifest identity `9b2cebe76654d6f2cb4d2ec3e3c2762bfc8e72009a796f7e28adf5903428bb99`.

The runtime archive contains 380,690 bytes with SHA-256 `30c615304d671c9ce7e72acbfb1f350e3d48817b12e7350035ef47ffc8657550` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 132,872 bytes with SHA-256 `1beb2c57f29a587e5d05ed20152204d38769556d3a63550fce3c0d01b21d82be` and root manifest identity `b9beb8697bb55c654a74476b69a5a21fbcded9791e04f771ab4b25186d2d1349`.

## Rejected alternatives

### Call a test-local helper

Rejected. The suite must execute physical compiler source.

### Import a callable without referencing it

Rejected. Presence is not callable graph evidence.

### Allow arbitrary imported functions in the adapter

Rejected. The fixed profile admits one scalar function per imported module. The compiler still decides whether it is valid.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0020](WIP-0020-semantic-coverage-and-evidence-accounting.md)
- [WIP-0284](WIP-0284-native-compiler-constant-suite.md)
