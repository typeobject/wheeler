# WIP-0353: Native 40 KiB source-plan bound

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, package, and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Native testing, source plans, package execution |
| Depends on | WIP-0309, WIP-0352 |
| Supersedes | Native 32,768-byte source-plan bound |
| Superseded by | WIP-0354 native compiler conditional mapping suite |

## Summary

Raise the canonical native package-test source-plan limit from 32,768 to 40,960 bytes.

The next physical conditional targets require both `StatementKinds.w` and `ResolvedStatements.w`. Their complete immutable source graphs contain 33,607 and 33,426 framed bytes. The old profile rejects both before compilation. Individual sources remain bounded to 32,768 bytes, and the compiler still accepts at most eight sources.

## Authorities

The package adapter and runtime share the 40,960-byte complete-plan boundary. `TestRunner.w` separates source-plan capacity from the unchanged 32,768-byte artifact capacity. `TestSourcePlan.w` owns framing, `TestSourceModules.w` owns module and import validation, and `TestExternalSourcePlan.w` owns package-qualified composition. `TestSourceCompilation.w` retains the complete admitted plan in one 40,960-byte source arena.

The lowered-plan ceiling becomes 41,240 bytes. Its two-allocation arena retains that complete plan beside one complete 32,768-byte lowered root. Per-source lowering arenas and compiler artifact storage do not change.

## Boundary evidence

`NativePackageTestRunnerTest.enforcesNativeSourcePlanByteLimit` constructs three canonical physical sources whose framed plan is exactly 40,960 bytes. The package adapter transports the complete plan. Native framing, UTF-8 checks, module validation, import validation, discovery, lowering, compilation, execution, and report publication succeed.

A second host-valid package differs by one trailing source byte. Its 40,961-byte plan rejects in package preflight before native transport, compilation, or publication. Neither boundary fixture truncates or repairs source bytes. The canonical workspace checks 155 targets.

## Acceptance

- [x] A complete 40,960-byte plan compiles and executes natively.
- [x] A 40,961-byte plan rejects before transport and publication.
- [x] Runtime framing admits the exact bound.
- [x] Module, import, and UTF-8 scans retain the complete plan.
- [x] Local and external plan composition use one bound.
- [x] Individual sources remain bounded to 32,768 bytes.
- [x] Source count remains bounded to eight.
- [x] Artifact storage remains bounded to 32,768 bytes.
- [x] Manifest, lock, archive, case, coverage, and report bounds do not change.
- [x] Focused runtime, package, documentation, and file policy gates pass.

The runtime archive contains 438,017 bytes with SHA-256 `75c5bd2447f931c87e84923224a0a4520bd57001c93f2293d344bb5d80d7b5a0`. Its root manifest identity remains `42011c887d887364ca16bc2255bc28374882559192e9ab6dbf5f674ce0ae1f49`.

## Rejected alternatives

### Copy only used constants

Rejected. Physical package tests retain complete source owners. Projected declarations would test a different compiler graph.

### Concatenate or compress source text

Rejected. Canonical source identities bind exact physical paths and bytes.

### Raise the per-source or source-count limits

Rejected. Neither boundary is exhausted.

### Reuse artifact capacity

Rejected. Source transport and compiled artifacts have separate validation and storage authority.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0309](WIP-0309-native-transitive-source-plan-bound.md)
- [WIP-0352](WIP-0352-native-compiler-conditional-classifier-suite.md)
- [WIP-0354](WIP-0354-native-compiler-conditional-mapping-suite.md)
