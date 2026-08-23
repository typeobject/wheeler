# WIP-0304: Native compiler type-kind suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, package, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, compiler testing, imported callables |
| Depends on | WIP-0293 and WIP-0303 |
| Supersedes | Seventeen-case native compiler package suite |
| Superseded by | WIP-0305 native compiler call-arity suite |

## Summary

Add a fourth native compiler package-test partition for the physical aggregate type decoder.

`nativecompilertypekindtests` compiles `TypeCodes.w`, `TypeKinds.w`, and one test root. The test executes `typeDescriptor(long)` over a record type carrying descriptor seven, then checks the physical `TYPE_RECORD` constant separately.

The target raises the checked-in suite from seventeen to eighteen production compiler modules and from seventeen to eighteen native cases.

## Function-only imports

`TypeKinds.w` exports one scalar function and no public constant. The package adapter previously required every imported source module to carry at least one public signed constant, even when the module carried one admitted scalar function.

The fixed source gate now accepts either one through sixty-four public signed constants or exactly one public scalar function. It still rejects an empty exported module, a second public scalar function, test declarations, and entry declarations. Native source parsing, module linking, lowering, compilation, verification, and execution retain semantic authority after this physical admission gate.

The test passes decimal literal `268435463` into the imported decoder. The production function masks it with imported `TYPE_DESCRIPTOR_MASK` and returns seven. A separate assertion checks `TYPE_RECORD == 268435456`. No imported constant enters the call-argument path rejected by WIP-0293.

## Evidence

`testsThePhysicalCompilerSpineNatively` now requires eighteen selected and eighteen passed native cases and names the type-kind case explicitly. Java frames physical sources and adapts native rows. It does not discover the declaration, compile its artifact, execute the function, or construct its assertions.

`wheeler test wheeler-compiler --format json` publishes report identity `a62e2ed117791f9a3b6a78a832e605613607f52c945ea207539206a70c1ffde6`. The new target has source identity `feb42df3fb6c044933687b72c8d320ecb3784e4772aedb55c6cdae159a657cc4`, artifact identity `066a0506aef2788561cf040b886b9db47a0fb5027730d75cc473770d109f49ec`, and two passing assertions.

The compiler manifest contains 4,222 bytes. WIP-0303's shared 8,192-byte native manifest bound admits it without relaxing the source-plan or eight-source limits.

## Acceptance

- [x] A fourth canonical compiler test target is checked in.
- [x] `TypeKinds.w` enters the native package suite as a physical module.
- [x] One function-only imported module passes the bounded physical source gate.
- [x] Empty modules and modules with two public scalar functions remain outside the profile.
- [x] The imported decoder executes over a literal record type.
- [x] The physical record type constant is checked separately.
- [x] Eighteen package cases execute exactly once.
- [x] The native JSON adapter publishes the exact combined report identity.
- [x] Compiler archive and consumer locks are rebuilt exactly.
- [x] Compiler package, tools, documentation, workspace, and file-length policy pass.

The compiler archive contains 3,028,632 bytes with SHA-256 `9734bcc62cc1f3ecc447d4ddb01e79b4de18a65872d7c82df4f82191bb7f6014` and root manifest identity `c55ad22b38e5b7bf7ab7b09c68f17a95801e900f3164629a6065399bf54639be`.

## Rejected alternatives

### Add a dummy public constant to `TypeKinds.w`

Rejected. Production modules do not carry ceremonial exports to satisfy an adapter heuristic.

### Recompute the descriptor mask in the test root

Rejected. That would test copied arithmetic rather than the physical decoder and type-code table.

### Pass `TYPE_RECORD` directly into the imported function

Rejected. WIP-0293 keeps imported constants out of imported call arguments until that binding path has independent evidence.

### Fold the target into the full spine partition

Rejected. The spine already occupies the eight-source compiler boundary with its test root.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0293](WIP-0293-native-compiler-call-syntax-suite.md)
- [WIP-0303](WIP-0303-native-test-manifest-bound.md)
- [WIP-0305](WIP-0305-native-compiler-call-arity-suite.md)
