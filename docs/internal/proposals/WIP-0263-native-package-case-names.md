# WIP-0263: Native package case names

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler package, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, native testing, case identity |
| Depends on | WIP-0261, WIP-0262 |
| Supersedes | Declaration-only display names for package invocation |
| Superseded by | Full native package report parity |

## Summary

Construct module-qualified case names for native package invocation.

WIP-0261 mode 255 remains the compact conformance profile:

```text
<target>::<declaration>[<row>]
```

Mode 254 now requests package-qualified construction:

```text
<target>::<root-module>::<declaration>[<row>]
```

`wheeler test` uses mode 254. Stage 0 already renders package cases with the root module between target and declaration. Native package case identity now binds the same display-name domain rather than dropping module provenance.

## Authority

The module bytes come from `validatedSourceModuleText` over the manifest-selected root. The adapter does not send a module-qualified case name. It sends the manifest and source plan already required by package authorization.

`TestDiscoveredDescriptors.w` inserts exact root-module bytes and a canonical `::` separator before the lexer-selected declaration token. Parameter-row suffixes retain the native-discovered ordinal.

Name length remains bounded by 255 bytes. The sorter still moves fixed name bytes, exact length, case kind, row value, and effective step limit as one product.

## Compilation

A module-qualified display name is not a declaration token. Before source lowering, `TestRunner.w` scans backward within the validated constructed name to the final `::` and passes only the declaration suffix to `TestSourceLowering.w`.

The artifact program identity remains `<root-module>::<declaration>`. Display qualification therefore changes case identity without inventing another compiler symbol.

Explicit descriptor mode and mode 255 retain their existing lowering rules. Only mode 254 may strip the constructed module prefix.

## Report boundary

Module qualification aligns package case naming and case-identity input. It does not by itself prove complete report identity parity.

The physical native compiler and stage-0 package compiler may still emit different artifact bytes for a test declaration. Artifact, execution, and coverage identities enter the profile-2 report. WIP-0262 therefore continues to gate selected, passed, and failed counts while Java renders complete rows.

Full parity requires byte-identical artifacts or a proven canonical projection shared by both compilers. The command must not compare report identities until that boundary is closed.

## Evidence

`NativePackageTestRunnerTest` sends no descriptor names or artifacts. Mode 254 obtains `demo.native.tests` from the validated root source, discovers `passes`, lowers only the declaration suffix, compiles and executes one passing case, and returns one native report identity plus summary.

The same package runs through `PackageProject.test` and passes mandatory summary parity with the stage-0 rendering adapter.

Mode 255 parameter-row evidence remains byte-identical to explicit declaration-only descriptors in `constructsCanonicalNativeParameterRowDescriptors`.

The runtime archive contains 330,739 bytes with SHA-256 `70a04c8b16f70d57d4b81e7cb088a1f9df729864d6d3c30000f9a1dcf8f0e30a` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,221 bytes with SHA-256 `c8225a24f2dc0c2d9cffe708b25e1fa662ba6a771d1a85fbc63d188c0ffc7ea5` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the new runtime archive exactly.

## Acceptance

- [x] Mode 254 selects module-qualified native construction.
- [x] Mode 255 retains declaration-only conformance names.
- [x] Root-module bytes come from validated source authority.
- [x] Module qualification precedes canonical name sorting and case identity.
- [x] Parameter-row ordinals remain exact.
- [x] Source lowering receives only the declaration token suffix.
- [x] Explicit and declaration-only modes retain existing behavior.
- [x] Package invocation transports no case name or artifact.
- [x] Documentation does not claim full report-identity parity.
- [x] Runtime and conformance archives and dependent locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Send the module-qualified name from Java

Rejected. The root module is already native-validated source data.

### Treat the full display name as a compiler declaration

Rejected. Display identity and symbol identity have different domains.

### Change mode 255 in place

Rejected. Existing conformance vectors require stable declaration-only names.

### Compare report identities after changing names alone

Rejected. Artifact, execution, and coverage products remain in the report domain.

## References

- [WIP-0261](WIP-0261-native-test-descriptor-construction.md)
- [WIP-0262](WIP-0262-native-one-source-package-test-gate.md)
- [WIP-0195](WIP-0195-native-test-case-identity.md)
