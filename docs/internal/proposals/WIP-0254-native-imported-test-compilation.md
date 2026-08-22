# WIP-0254: Native imported test compilation

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, native testing, source compilation |
| Depends on | WIP-0245, WIP-0253 |
| Supersedes | WIP-0253 one-source compilation bound |
| Superseded by | Counted native test compilation |

## Summary

Compile one native-discovered parameterless root test with zero through seven canonical local imports.

WIP-0253 lowered an isolated root into the physical compiler's fixed entry profile. The first implementation invoked `compileMinimal` directly and rejected every imported source. The runtime now lowers the root inside an exact private source plan and delegates to the existing one-through-eight-source compiler dispatcher.

## Private plan lowering

`TestSourceCompilation.w::compileValidatedParameterlessTest` derives:

```text
lowered_source_length = source_length + 5 - declaration_name_length
lowered_plan_length = plan_length + lowered_source_length - source_length
```

It allocates the exact lowered root and exact lowered plan. The operation:

1. copies all plan bytes before the root source length
2. writes the lowered root length in canonical big-endian form
3. copies the lexer-lowered root source
4. copies every byte after the original root source
5. requires the committed cursor to equal the derived plan length
6. invokes `compileValidatedSourcePlan` over the private plan

Path order, non-root source bytes, import order, source count, and manifest-selected root ordinal remain unchanged. The lowered plan never becomes package, lock, source, or report identity input.

## Dispatcher authority

`compileValidatedSourcePlan` remains the only fixed-arity dispatch table. The imported-test path does not duplicate its root permutations or compiler API selection.

The dispatcher admits one root plus up to seven imports and selects the existing `compileMinimalWithSevenConstantImports` ceiling. More than eight sources still reject during source-mode preflight, before lowering or compiler invocation.

The private plan may grow by at most four bytes when a one-byte declaration name becomes `main`. Its explicit ceiling is 32,772 bytes. The lowering arena owns one root of at most 4,100 bytes and one plan of at most 32,772 bytes.

## Atomicity

Complete transport, manifest, lock, source-plan, module, import, cycle, descriptor, and test discovery validation precede lowering. Shard assignment precedes private plan allocation and compiler invocation.

The compiler writes into 32,768-byte recovery storage. Only its committed prefix enters exact verifier storage. A failed lowering, compilation, verification, or execution publishes no partial report.

## Evidence

`compilesOneImportedParameterlessTestNatively` supplies one constant module, one importing test root, descriptor `test::imported`, and no artifact. Native lowering preserves the import and the runner publishes one selected and one passed case.

`compilesTheManifestRootWithSevenLocalImports` now repeats its maximum fixed-graph evidence with a discovered test root and zero artifact bytes. The native runner lowers the manifest-selected eighth source, dispatches seven imports plus root, and publishes one passing case.

Existing one-through-eight-source entry parity proves that private-plan delegation preserves every fixed root permutation. Nine-source rejection remains before compiler dispatch.

The runtime archive contains 283,861 bytes with SHA-256 `0728172fd05ebb43523105f6459ffec6da7c5506fd2c0c367b3e5cdd6b67dcb8` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,094 bytes with SHA-256 `b866164f0216db3c6b2e0662e0c36510863a4324a0481b4a4831b3890c0d5a3b` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the new runtime archive exactly.

## Acceptance

- [x] One discovered test compiles with zero through seven local imports.
- [x] Lowering changes only the root source length and root source bytes.
- [x] Non-root source bytes and canonical order remain exact.
- [x] Manifest-selected root ordinal survives private lowering.
- [x] One dispatcher owns all fixed compiler arities.
- [x] The private plan has an explicit 32,772-byte bound.
- [x] Shard selection precedes lowering and compilation.
- [x] The committed artifact is verified and executed once.
- [x] One-import and seven-import fixtures publish passing summaries.
- [x] Nine-source input still rejects before compilation.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Duplicate every compiler arity for tests

Rejected. Root permutation and dispatch must have one authority.

### Rebuild all source paths and frames

Rejected. Only one source length and source payload change.

### Publish the lowered plan identity

Rejected. It is an internal compiler input, not locked package source.

### Raise the fixed source ceiling

Rejected. Counted graph compilation remains separate work.

## References

- [WIP-0245](WIP-0245-native-eight-source-test-compilation.md)
- [WIP-0253](WIP-0253-native-parameterless-test-compilation.md)
