# WIP-0264: Native fixed-import package test gate

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler package, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Self-hosting, package testing, local imports |
| Depends on | WIP-0245, WIP-0262 |
| Supersedes | One-source-only native package gating |
| Superseded by | None |
| Follow-up | WIP-0265 multi-target gating, then general imports and locked dependencies |

## Summary

Extend the `wheeler test` native gate from one source to the fixed one-root-plus-seven-import compiler profile.

The native source graph already validates and compiles up to eight local modules. Package invocation had conservatively gated only one-source targets. It now admits two through eight sources when every non-root module stays inside the fixed constant-import profile.

The adapter still sends one complete source plan, mode 254, and no case names or artifacts. Native module graph, descriptor construction, compilation, execution, and summary reduction remain authority.

## Eligibility

The package adapter admits:

- One manifest-selected root source.
- Zero through seven local imported sources.
- At most 4,096 bytes per source.
- At most 32,768 bytes in the complete source plan.
- Exactly one `public const long` declaration in each non-root source.
- No callable, test, or entry declaration in a non-root source.

The final two checks select the physical compiler dispatch already proven by WIP-0238 through WIP-0245. They do not authorize imports. Native module declaration, uniqueness, source order, import order, resolution, cycle, manifest, and root checks still run over the complete transport.

A source outside the fixed import profile does not claim native evidence. Stage 0 continues to test it until the physical compiler admits general imported callables.

## Host boundary

`NativePackageTestRunner.java` performs only profile dispatch for non-root source shapes. It cannot add a source, change module text, select a root, repair import order, provide an artifact, or alter native results.

The adapter reads physical nonsymlink source files before profile dispatch. It emits every selected path and byte exactly once in lexical path order.

The source-plan identity covers root and imports. Native report and case identities therefore change when an imported constant module changes, even when the selected test body does not reference that constant.

## Evidence

`invokesNativeDiscoveryAcrossCanonicalLocalImports` creates a dependency-free tool package with one root and one local constant module. The root imports that module and declares one parameterless test.

Direct mode-254 invocation discovers, constructs, compiles, and passes one case without caller-supplied names or artifacts. `PackageProject.test` invokes the same native gate and requires one selected, one passed, and zero failed case before returning the stage-0 rendering adapter.

The complete zero-through-seven imported compiler matrix remains covered by `NativeCompiledTestRunnerExampleTest`. Multi-source package invocation reuses that exact runtime dispatch rather than adding a package-specific compiler.

## Acceptance

- [x] One through eight local sources may enter native package gating.
- [x] Every non-root source must fit the fixed constant-import profile.
- [x] The complete source plan remains native-validated.
- [x] Manifest root and module selection remain native authority.
- [x] Imported source bytes enter source and case identity.
- [x] Java supplies no case name or artifact.
- [x] One imported package test passes direct and command invocation.
- [x] General imported callables remain outside the claimed profile.
- [x] Runtime and conformance archives and dependent locks remain exact.
- [x] Package, workspace, documentation, source, and layout policy pass.

The runtime archive remains 330,739 bytes with SHA-256 `70a04c8b16f70d57d4b81e7cb088a1f9df729864d6d3c30000f9a1dcf8f0e30a` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,221 bytes with SHA-256 `c8225a24f2dc0c2d9cffe708b25e1fa662ba6a771d1a85fbc63d188c0ffc7ea5` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the runtime archive exactly.

## Rejected alternatives

### Attempt every imported package and catch a compiler trap

Rejected. Unsupported physical compiler shapes are not test failures.

### Send only the root source

Rejected. Import authorization and source identity require the complete target graph.

### Compile imported artifacts in Java

Rejected. Native source mode consumes no host compiler product.

### Claim general import support

Rejected. Imported callables remain outside the fixed physical dispatch.

## References

- [WIP-0245](WIP-0245-native-eight-source-test-compilation.md)
- [WIP-0262](WIP-0262-native-one-source-package-test-gate.md)
- [WIP-0234](WIP-0234-native-canonical-import-order.md)
- [WIP-0265](WIP-0265-native-multi-target-package-test-gate.md)
