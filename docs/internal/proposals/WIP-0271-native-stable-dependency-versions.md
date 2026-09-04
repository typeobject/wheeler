# WIP-0271: Native stable dependency versions

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler package, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Self-hosting, package locks, native testing |
| Depends on | WIP-0270 |
| Supersedes | Name-only direct dependency binding |
| Superseded by | None |
| Follow-up | WIP-0272 prerelease constraints, then archive-source binding |

## Summary

Check stable direct dependency constraints against the exact version selected by the native runner lock.

`TestPackageVersions.w` finds the package entry already bound by WIP-0270, parses its three-part stable semantic version, parses the manifest constraint, and applies the stage-0 exact, caret, or tilde rule. A package name match no longer authorizes an incompatible locked version.

## Stable profile

Both minimum and candidate use canonical `major.minor.patch` decimal components. Components have no leading zero except zero itself and remain within the bounded native decimal profile. Prerelease identifiers are rejected in this first slice.

Manifest constraints require one explicit operator:

- `=1.2.3` accepts only `1.2.3`.
- `~1.2.3` accepts candidates at least `1.2.3` with major 1 and minor 2.
- `^1.2.3` accepts candidates at least `1.2.3` with major 1.
- `^0.2.3` accepts candidates at least `0.2.3` with major 0 and minor 2.
- `^0.0.3` accepts only patch 3 in the `0.0` line.

The lock version remains an unprefixed semantic version. Unknown operators, missing components, extra components, signs, whitespace, leading zeroes, and unstable versions reject.

Canonical manifests already emit an explicit operator through `VersionConstraint.toString()`. The native runner does not accept stage-0 parser shorthand that canonical bytes cannot contain.

## Ordering and failure

Version checks run after manifest target selection, exact manifest hashing, lock root validation, lock structural validation, and direct-name matching. They run before test discovery, identities, sharding, lowering, compilation, verification, execution, and publication.

The parser borrows the original manifest and lock transports. It does not copy, normalize, or repair version text.

## Evidence

`validatesNativeDependencyLockEntries` accepts `^1.0.0` with locked `1.0.0`. The fixture then changes only the selected version to `2.0.0`. Native policy rejects it and leaves all 39 output bytes zero.

`acceptsNativeStableDependencyConstraintKinds` runs exact and tilde constraints through the complete native discovery, compilation, execution, and report path. Both publish one selected and one passed case. The caret path uses the same report boundary in the first fixture.

The dependency-free matrix bypasses no lock check. It selects the exact empty manifest and lock form before version policy.

## Acceptance

- [x] Stable locked versions require three canonical decimal components.
- [x] Stable manifest minima require an explicit exact, caret, or tilde operator.
- [x] Candidates below the minimum reject.
- [x] Exact constraints require complete equality.
- [x] Tilde constraints retain the minimum major and minor.
- [x] Caret constraints implement the stage-0 major-zero rules.
- [x] A major-incompatible lock publishes no output.
- [x] All three constraint kinds reach the native report path.
- [x] No normalization or fallback parser remains.
- [x] Documentation keeps prerelease and external-source provenance open.
- [x] Runtime and conformance locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

The runtime archive contains 356,335 bytes with SHA-256 `40a2cf87052d3f25cd01193a1f5251baba204fcebbe6fddd7e07b3e5db05e77e` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 132,064 bytes with SHA-256 `6e266b64bacfe415c957fcaae5f697656a708af06d2e8f271b25d0417778341e` and root manifest identity `e15c8483d406c7367d5c5e38867909304aeee418444112f0de10dab47a6a9e11`. Its lock names the runtime archive exactly.

## Rejected alternatives

### Compare version strings

Rejected. Lexical order puts `1.10.0` before `1.2.0`.

### Accept an unprefixed exact constraint

Rejected. Canonical manifests emit `=`. Alternate spellings would create two transports for one constraint.

### Treat every major-zero caret as one line

Rejected. Stage 0 narrows at the first nonzero component.

### Admit prereleases without their ordering rules

Rejected. Stable-only rejection is preferable to false compatibility.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0270](WIP-0270-native-direct-dependency-binding.md)
- [WIP-0272](WIP-0272-native-prerelease-dependency-versions.md)
