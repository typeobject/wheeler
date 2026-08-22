# WIP-0238: Native two-source test compilation

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, package, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, native testing, module compilation |
| Depends on | WIP-0233, WIP-0235, WIP-0237 |
| Supersedes | WIP-0237 one-source compilation bound |
| Superseded by | WIP-0239 native three-source test compilation |

## Summary

Compile a canonical two-source local module graph inside the native test runner.

The selected manifest root is no longer assumed to be the first path in the source plan. `TestManifest.w` recovers its exact source ordinal after full manifest and plan validation. `TestSourcePlan.w` exposes bounded ordinal access to previously validated source frames. The runner copies the non-root source and root source into separate UTF-8 values, passes them to the canonical two-module compiler operation, and feeds the committed artifact into profile-2 reporting.

This step accepts one root plus one local imported source. It does not claim counted arbitrary-graph compilation.

## Root selection

`validatedRootSourceOrdinal` scans canonical target lines after `validTestManifest` succeeds. It recognizes the selected deployable target, reads its exact root path, and matches that path against the already validated source plan. It returns a zero-based ordinal or `-1`.

The runner requires an in-range ordinal before allocating compiler input. Source path order remains canonical lexical order. Root selection follows the manifest, not lexical position or import direction.

The helper deliberately does not provide a second manifest validator. Its name and contract require the caller to establish complete manifest and plan validity first.

## Plan projection

`TestSourcePlan.w` provides:

- `validatedSourceCount`
- `validatedSourceLength`
- `copyValidatedSource`

All three consume a previously validated plan. The runtime bounds ordinal scans to 64 sources and byte copies to the 32,768-byte plan limit. The helpers preserve exact source bytes and do not decode, reorder, or repair modules.

The earlier one-source-only helpers are deleted rather than retained as aliases.

## Compiler dispatch

A zero-length one-case descriptor accepts one or two sources. Every source remains bounded to 4,096 bytes.

For one source, the runner calls `compileTestSource` as before. For two sources, it derives `importedOrdinal = 1 - rootOrdinal`, freezes both exact source frames, and calls `compileImportedTestSource`. That operation delegates to `wheeler.compiler.driver::compileMinimalWithConstantImport`.

The current two-module driver accepts the bounded graph profile already proven by native compiler closure tests. Unsupported source shapes trap before artifact publication. General counted graph compilation remains separate work.

## Atomicity

Complete descriptor framing, source framing, UTF-8, module declarations, uniqueness, local import resolution, acyclicity, manifest selection, lock provenance, and shard selection all precede source allocation and compilation.

Compiler output remains in fixed 32,768-byte recovery storage. The runner copies only the committed length into exact storage before verification and execution. Failure publishes neither report identity nor summary.

## Evidence

`NativeCompiledTestRunnerExampleTest` uses a source plan ordered as imported path then root path. The manifest selects the second source as root. The root imports a canonical constant module.

The test compares the complete 39-byte profile-2 product from native two-source compilation with the product from an independently stage-0-compiled artifact descriptor. Byte equality binds root selection, module ordering, artifact identity, execution, coverage, report identity, and summary.

The existing passing and failing one-source parity checks remain in the same executable closure.

The runtime archive contains 238,112 bytes with SHA-256 `3979dab03f8768bfd4ec842f26a264fdebb68a828d53090d2429927a911be0b7` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the new runtime archive exactly.

## Acceptance

- [x] Manifest root selection determines the compiled root ordinal.
- [x] Canonical path order does not substitute for root selection.
- [x] Validated plan projection supports bounded ordinal source access.
- [x] One-source compilation keeps its existing report bytes.
- [x] Two-source compilation delegates to the canonical compiler driver.
- [x] The imported and root UTF-8 values preserve exact plan bytes.
- [x] Execution consumes only the committed artifact prefix.
- [x] Two-source native and transported artifact reports match byte for byte.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Treat the last path as root

Rejected. Canonical path order and manifest root selection are independent authorities.

### Infer the root from import direction

Rejected. A target may carry unused modules, and graph shape does not replace the manifest.

### Keep one-source projection aliases

Rejected. General ordinal projection is smaller and leaves one framing authority.

### Claim arbitrary graph compilation

Rejected. The current public driver call has one imported-source slot. Counted graph dispatch needs its own bounds and evidence.

## References

- [WIP-0233](WIP-0233-native-local-import-resolution.md)
- [WIP-0235](WIP-0235-native-import-cycle-rejection.md)
- [WIP-0237](WIP-0237-native-compiled-test-reports.md)
- [WIP-0239](WIP-0239-native-three-source-test-compilation.md)
