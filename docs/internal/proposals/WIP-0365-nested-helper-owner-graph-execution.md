# WIP-0365: Nested helper-owner graph execution

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, linker, and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Self-hosting, module graphs, helper linking, compiler package tests |
| Depends on | WIP-0043, WIP-0143, WIP-0343, WIP-0364 |
| Supersedes | Deferred helper counts for nested executable-owner chains |
| Superseded by | Broader physical compiler graph execution |

## Summary

Count each physical executable owner's complete function group before graph mutation. This removes a circular dependency in nested helper linking and admits `constants -> predicates -> classifier -> test` without source projection or host intervention.

The old executor learned an owner's function count from a successful direct import plan. That worked for a helper source consumed by the root. It failed when unresolved constants prevented the initial import probe and another helper consumed that source before the root. Owner filtering then received a zero count and rejected the unconsumed member prefix.

## Design

`ExecutableOwnerKinds.w` now scans the physical class after its bounded constant prefix. It walks complete brace-balanced function bodies, admits at most the fixed 23-function compiler profile, and records the exact helper count beside the module identity and executable bit.

The graph executor installs that count during initial owner classification. Later import plans must reproduce it through `recordOwnHelperCount`. They no longer establish it. Owner filtering therefore has complete physical boundaries before the first executable edge is linked.

This is not a recovery path. Malformed functions, excess members, private substitutions, unresolved imports, inconsistent later counts, and noncanonical owner orders still reject. The executor neither guesses boundaries nor repairs the graph.

## Evidence

`NativeCompilerImportedHelperExampleTest` links the physical graph in both source-frame orders:

```text
ResolvedStatements
  -> ResolvedEarlyComparisonKinds
       -> EarlyComparisonForms
            -> EarlyComparisonUse
```

The native artifact is byte-identical to stage 0. It retains both predicate identities, the combined classifier identity, and the final wrapper identity in canonical order.

The compiler package then replaces the wrapper with a test root. Two cases enter `resolvedEarlyComparisonReturn` through its equality and ordering branches. Both compile from complete physical sources, execute once with fresh storage, and publish canonical rows.

The complete compiler package publishes 222 selected, 222 passed, and zero failed cases across 69 native targets. The canonical workspace checks 175 targets. The full run completes in thirty-one minutes and fifty-five seconds under a forty-one-minute guard.

The canonical compiler manifest contains 36,867 bytes with identity `760cc6739bca301a59e6b9f236d2462acc77953da9f85dd6d51e6ae099526d0e`. The compiler archive contains 3,125,302 bytes with SHA-256 `83cd07c21fc17dada65196897c4b8bd4375c81f316da63de1e6a32066f686fef`.

## Acceptance

- [x] Physical helper counts exist before executable-edge linking.
- [x] Counts include complete public and private function groups.
- [x] The fixed 23-function source profile remains the only admitted bound.
- [x] A two-edge executable-owner chain links in either source-frame order.
- [x] Native and stage-0 artifacts are byte-identical.
- [x] Private target substitution still rejects.
- [x] Equality and ordering branches execute through the package runner.
- [x] Every selected package case executes exactly once with fresh storage.
- [x] Compiler, package, workspace, documentation, archive, and file policy gates pass.

## Rejected alternatives

### Treat zero as one owner

Rejected. It would skip an unknown member boundary and make later owner identities depend on source layout accidents.

### Reprobe after each edge

Rejected. A deeper executable chain remains circular: filtering needs the owner count before the edge that would make the source importable.

### Project helper signatures into the test

Rejected. Projection avoids the graph under test and discards private-owner evidence.

### Special-case the early-comparison graph

Rejected. Owner counting belongs to physical source classification, not one topology or module name.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0043](WIP-0043-bounded-generic-compiler-module-graph-execution.md)
- [WIP-0143](WIP-0143-direct-early-comparison-form-product.md)
- [WIP-0343](WIP-0343-native-compiler-resolved-early-comparison-suite.md)
- [WIP-0364](WIP-0364-native-compiler-helper-value-suite.md)
