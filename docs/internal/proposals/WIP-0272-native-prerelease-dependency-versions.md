# WIP-0272: Native prerelease dependency versions

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler package, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, package locks, native testing |
| Depends on | WIP-0271 |
| Supersedes | Stable-only native dependency constraints |
| Superseded by | Native archive-source binding |

## Summary

Complete native semantic-version comparison for manifest-to-lock dependency binding.

The native runner now validates dotted prerelease identifiers and applies SemVer precedence before exact, caret, or tilde range policy. It matches the stage-0 rule that a stable minimum cannot begin selecting preview releases merely because a repository added one.

## Grammar

A version remains three canonical decimal release components. It may add `-` and one or more dot-separated prerelease identifiers.

Identifiers contain ASCII letters, digits, or hyphen. Empty identifiers reject. Numeric identifiers have no leading zero unless they are exactly zero. Build metadata is outside the package schema and rejects.

Comparison follows these rules:

1. Compare major, minor, and patch numerically.
2. A stable release follows every prerelease of the same release tuple.
3. Compare prerelease identifiers in order.
4. Numeric identifiers compare numerically and precede nonnumeric identifiers.
5. Nonnumeric identifiers compare by ASCII bytes.
6. When a common identifier prefix is equal, the shorter prerelease list comes first.

Canonical numeric identifiers need no arbitrary-precision conversion. Length and lexical comparison produce numeric order without overflow.

## Constraint policy

The exact, tilde, and caret release windows from WIP-0271 remain unchanged. The complete candidate must not precede the minimum.

A candidate carrying a prerelease is rejected when the minimum is stable, including a preview of a later release tuple within an otherwise valid caret or tilde window. A prerelease minimum may select a later prerelease or stable candidate inside its release window.

## Evidence

`enforcesNativePrereleaseDependencyConstraints` accepts `^1.0.0-beta.2` with locked `1.0.0-beta.11` through native discovery, compilation, execution, and report publication.

The same fixture supplies stable `^1.0.0` with locked `1.1.0-beta`. Native policy rejects the transport and leaves all 39 output bytes zero. A release-only range cannot acquire an unstated preview policy.

Stable exact, tilde, caret, mismatch, and dependency-free fixtures continue through the same comparator.

## Acceptance

- [x] Prerelease identifiers use the strict package grammar.
- [x] Numeric prerelease identifiers reject leading zeroes.
- [x] Numeric and nonnumeric precedence matches stage 0.
- [x] Identifier-list length participates in precedence.
- [x] Stable releases follow matching prereleases.
- [x] Stable minima reject every prerelease candidate.
- [x] Prerelease minima admit later compatible prereleases.
- [x] Accepted prerelease constraints reach a passing native report.
- [x] Rejected preview selection publishes no output.
- [x] Runtime and conformance locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

The runtime archive contains 361,881 bytes with SHA-256 `fbf85e5a557b24df0b6a89b1c3ea79e57b5109eb5fa6cc7bb48c4c06c29d3bc0` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 132,064 bytes with SHA-256 `6e266b64bacfe415c957fcaae5f697656a708af06d2e8f271b25d0417778341e` and root manifest identity `e15c8483d406c7367d5c5e38867909304aeee418444112f0de10dab47a6a9e11`. Its lock names the runtime archive exactly.

## Rejected alternatives

### Compare prerelease text as one string

Rejected. `beta.11` follows `beta.2`, and numeric identifiers precede alphabetic identifiers.

### Admit every prerelease in a caret window

Rejected. Stable constraints do not silently opt into previews.

### Parse build metadata and ignore it

Rejected. Ignored bytes would create distinct lock transports with equal package meaning.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0271](WIP-0271-native-stable-dependency-versions.md)
