# WIP-0262: Native one-source package test gate

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler package, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, package testing, native invocation |
| Depends on | WIP-0261 |
| Supersedes | Example-only native test invocation for the fixed profile |
| Superseded by | Native multi-source and locked-dependency package testing |

## Summary

Invoke the canonical native runner from `wheeler test` for the first closed package profile.

An eligible package has:

- One test-selected target.
- A `deployable` or `tool` target kind.
- One exact modular source.
- No package dependencies.
- At most 4,096 source bytes and a source plan no larger than 32,768 bytes.
- No more than 64 native-discovered cases or selected tags.

The tools adapter builds only manifest, empty root lock, source plan, shard, and sorted tag transport. It requests WIP-0261 mode 255. It supplies no case name and no artifact.

The native runner discovers, selects, constructs, compiles, verifies, executes, reduces, and publishes the 39-byte report identity and summary product. The existing stage-0 report remains the rendering adapter. The command rejects when selected, passed, or failed counts differ.

## Runner acquisition

`NativePackageTestRunner.java` locates the checked-out `wheeler-conformance` package, resolves its exact locked runtime and compiler sources, and compiles `nativetestrunner` through the normal package target path. One process caches the immutable program by canonical package root.

The gate returns unsupported rather than inventing semantics when the conformance package is absent or the package falls outside the fixed profile. This keeps installed stage-0 tools usable while the native profile grows. Eligible checked-out workspace tests cannot silently skip the gate.

A later package artifact distribution must carry the runner without requiring checkout source. This WIP does not embed an untracked build product.

## Transport authority

The adapter reads the exact package manifest bytes and exact target source bytes from physical nonsymlink files. It emits source paths in lexical order and uses the manifest-authorized root and module.

For a dependency-free package it derives the canonical empty lock directly from the manifest bytes. Native lock validation remains authority. The adapter does not parse declarations, cases, tags in source, limits, entry functions, or artifacts.

Selected command tags are sorted before transport. Native tag framing rejects malformed values, duplicate values, unknown values, and mismatched descriptor sets.

## Target kinds

`TestManifest.w` now admits exact canonical `tool` target lines beside `deployable`. Both are runnable package kinds. Library targets remain closed.

Manifest package, version, target, root, module, source list, test selector, dependencies marker, and source plan retain their existing exact validation. Adding the target kind does not weaken any field or line-order check.

## Production entries

A test-selected runnable source may retain its production `entry void` declaration. Native selected-test lowering now blanks every production entry body at exact original width before installing the selected test entry.

Peer tests and production entries therefore cannot create a second physical entry. Their bytes remain represented in source identity but do not reach the fixed compiler for a selected case.

## Rendering boundary

Native output currently carries report identity and summary counts, not complete case rows. Java still compiles and executes an independent stage-0 run to render terminal, JSON, and JUnit XML adapters.

For the eligible profile, native selected, passed, and failed counts are a mandatory gate. A disagreement rejects instead of publishing either rendering. Case-name and full report-identity parity remain separate work because stage 0 currently renders module-qualified display names while the native profile uses target-qualified declaration names.

The Java run is not an artifact provider for native mode. Native compilation has already consumed only validated Wheeler source.

## Evidence

`NativePackageTestRunnerTest` creates one dependency-free tool package with one modular source, one tagged and limited test, and no descriptor or artifact fixture. Direct native invocation publishes one selected, one passed, and zero failed case plus a 64-digit report identity.

The same test invokes `PackageProject.test`. The command path recompiles and renders stage-0 rows, requires exact summary parity, and returns one passing case. The native runner program comes through `PackageProject.compileRunnable("nativetestrunner")`, proving package lock and source closure use rather than an example-only builder.

`selectsCanonicalNativeTestTags` retains a production entry that would fail if executed. Native lowering blanks it, compiles the selected tagged test, and preserves explicit-versus-constructed output parity.

Focused command tests retain nonmodular, multi-source, compile-failure, runtime-failure, tag, shard, and adapter behavior outside or beside the new closed gate.

The runtime archive contains 328,980 bytes with SHA-256 `6b565c17de2940c560904e3681948a7821f61bfeaaecfd6cbe1580d0d8a4ea9f` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,221 bytes with SHA-256 `c8225a24f2dc0c2d9cffe708b25e1fa662ba6a771d1a85fbc63d188c0ffc7ea5` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the new runtime archive exactly.

## Acceptance

- [x] `wheeler test` invokes native mode for one-source dependency-free modular targets.
- [x] The adapter transports no test case name or artifact.
- [x] The runner resolves through the canonical conformance package target.
- [x] `tool` and `deployable` manifests validate natively.
- [x] Production entries are blanked before selected-test compilation.
- [x] Sorted command tags enter native selection.
- [x] Native summary disagreement rejects report rendering.
- [x] Direct invocation proves one selected and passing package test.
- [x] Command invocation retains terminal rendering after native parity.
- [x] Unsupported package shapes do not claim native evidence.
- [x] Runtime and conformance archives and dependent locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Feed stage-0 artifacts into the native runner

Rejected. Package invocation must exercise native source compilation.

### Bundle a generated runner without package provenance

Rejected. Build products need exact package and lock identity.

### Compare only command exit status

Rejected. Selected, passed, and failed counts must agree independently.

### Claim complete rendering parity from summary bytes

Rejected. Full native case rows and module-qualified naming are not yet published.

### Run production entry beside each test

Rejected. One selected case owns one direct physical entry.

## References

- [WIP-0261](WIP-0261-native-test-descriptor-construction.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
