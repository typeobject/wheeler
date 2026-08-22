# WIP-0230: Native root module binding

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, compiler, and package maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, package manifests, module identity |
| Depends on | WIP-0009, WIP-0018, WIP-0229 |
| Supersedes | Unchecked native target module fields |
| Superseded by | Native complete module-graph validation |

## Summary

Bind the selected target's canonical `module` field to the exact declaration in its selected root source.

WIP-0229 proved root path membership. It did not prove that the source at that path declared the module named by the target. `TestManifest.w` now retains the selected module value, locates the framed root payload while consuming the source plan, and compares the opening module declaration byte for byte.

## Root source contract

The accepted root starts with:

```text
module <target-module>;
```

The module keyword, one ASCII space, complete module bytes, semicolon, and LF are exact. The source-plan UTF-8 validator runs first. Manifest canonicalization and the compiler remain responsible for the complete dotted-name grammar and later source syntax.

The validator does not search through comments or whitespace for a declaration. Canonical package sources put the module declaration first. Search or repair would let alternate source spellings acquire the same package meaning.

## Implementation

The selected-target scan retains borrowed ranges for root and module. While consuming exact source paths, it records the root payload's bounded start and length. Acceptance after `test: true` requires:

- deployable target kind
- exact source-list exhaustion
- root path membership
- a nonempty module field
- exact root declaration equality

The comparison allocates no storage. It reads only the selected root payload and cannot cross that entry's validated boundary.

## Fixture changes

The three modular fixture sources now declare `pkg.fail`, `pkg.pass`, and `pkg.runtime`. The target root is `src/Pass.w` and its module is `pkg.pass`.

Native compilation of each source retains byte-identical agreement with the independently derived artifact and profile-2 report. The source-plan identity changes as required, and dynamic shard evidence follows the resulting case identities.

## Failure behavior

A missing, empty, displaced, malformed, or mismatched root module rejects before manifest hashing, source hashing, lock validation, case identity, shard assignment, artifact verification, execution, or publication.

## Evidence

`NativeCoverageRunExampleTest` locates the root payload by independently decoding the big-endian source plan. It changes `module pkg.pass;` to `module pkg.xass;` without changing frame lengths, path authorization, manifest bytes, or lock root. Native validation rejects and leaves output untouched.

The runtime archive contains 211,281 bytes with SHA-256 `2ce448f3a1ea6d88005b7d70b52309fb5d4b9d263f1f29169b798bee6598f0b0` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1`. Its lock names the new runtime archive exactly and retains root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`.

## Acceptance

- [x] Native code retains the selected target module as a bounded range.
- [x] The root payload begins with that exact module declaration.
- [x] Comparison cannot cross the root payload boundary.
- [x] The fixture carries three distinct canonical module declarations.
- [x] A length-preserving root-module mismatch publishes no output.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Trust the target module field

Rejected. Package selection must prove that the root source declares it.

### Derive the module from the target name

Rejected. Package target names and source module names are independent coordinates.

### Search for any matching module text

Rejected. Only the canonical opening declaration owns module identity.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0229](WIP-0229-native-runnable-target-root.md)
