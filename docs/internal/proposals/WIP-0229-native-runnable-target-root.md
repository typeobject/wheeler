# WIP-0229: Native runnable target root

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and package maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Native testing, package manifests, runnable targets |
| Depends on | WIP-0009, WIP-0018, WIP-0228 |
| Supersedes | Name-only native target selection |
| Superseded by | None |
| Follow-up | WIP-0230 native root module binding |

## Summary

Require the selected native test target to be deployable and require its root to belong to the exact selected source set.

Earlier native selection matched target name and `test: true`. The source list was exact, but the target kind and root were not semantic inputs to acceptance. `TestManifest.w` now retains kind and root state across the selected target block and closes both gaps.

## Runnable target

The accepted profile requires the canonical line:

```yaml
  - kind: "deployable"
```

A target with the requested name under another kind is not a runnable test artifact. The validator clears runnable-kind state at every target boundary and admits the name only while the kind is deployable.

This restriction matches the current native artifact executor. Library, compiler, documentation, aggregate, and quantum target execution need their own runtime contracts rather than aliases to classical deployables.

## Root membership

The validator retains the complete selected `root` value as a borrowed manifest range. As it consumes each exact source-plan path under WIP-0228, it records whether one path equals the root. `test: true` requires:

- every manifest source consumed
- exact source-plan exhaustion
- root membership in that source set
- deployable target kind

The root comparison is allocation-free and uses complete path bytes. Empty roots reject.

## Failure behavior

A wrong kind, missing root, or root outside the selected source set rejects before manifest hashing, source hashing, lock validation, descriptor identity, shard assignment, artifact verification, execution, or publication.

## Evidence

The accepted fixture selects deployable target `test`, rooted at `src/Pass.w`, from the exact three-module plan.

`NativeCoverageRunExampleTest` builds two structurally valid alternative manifests. One changes the root to normalized unselected `src/Xass.w`. The other changes the kind to `xxxloyable`. For each fixture Java recomputes the lock root from the changed manifest. The native target check therefore owns rejection rather than observing a stale lock identity. Both runs leave output untouched.

The runtime archive contains 209,169 bytes with SHA-256 `75f9ace6d3606a11c6a16ea9979c1aaf4287156f6bb2e8e58fb5f71d936860bc` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1`. Its lock names the new runtime archive exactly and retains root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`.

## Acceptance

- [x] Native selection requires exact deployable target kind.
- [x] The selected root is nonempty and belongs to the selected source set.
- [x] Kind and root state reset at each target boundary.
- [x] Root comparison is bounded and allocation-free.
- [x] Repaired-lock wrong-root and wrong-kind fixtures publish no output.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Infer deployability from `test: true`

Rejected. Test authorization and execution kind are separate manifest fields.

### Require the root to be the first source

Rejected. Sources sort by logical path. Root choice does not alter package order.

### Let artifact metadata define the root

Rejected. The selected package target authorizes compilation before an artifact exists.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0228](WIP-0228-native-multi-source-selection.md)
- [WIP-0230](WIP-0230-native-root-module-binding.md)
