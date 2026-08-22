# WIP-0246: Native entry-case identity

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, package, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, native testing, case discovery |
| Depends on | WIP-0212, WIP-0225, WIP-0237, WIP-0245 |
| Supersedes | Caller-selected source-mode case names |
| Superseded by | WIP-0247 native parameterless test discovery |

## Summary

Derive the only accepted source-mode entry case name from the validated package target.

A zero-artifact descriptor compiles one executable root and runs its entry. Its case name is therefore not caller policy. `TestDescriptors.w` now requires the exact byte sequence:

```text
<target-name>::entry
```

The target name comes from the run header and is already bound to the selected canonical manifest. The runtime rejects any other source-mode case name before case identity, shard assignment, compilation, execution, or publication.

Transported artifact descriptors retain their discovered names. This WIP changes only the direct native entry profile.

## Validation

`validEntryCaseName` accepts the descriptor bytes, exact range, and validated target-name bytes. It requires `targetLength + 7` bytes, compares the target byte for byte, and checks the literal ASCII suffix `::entry`.

The function does not normalize Unicode, case, separators, or punctuation. General case-name validation has already established the bounded display-name alphabet. Entry-case validation narrows that accepted set without repairing input.

`TestRunner.w` invokes the check for the single zero-artifact source descriptor after copying the name into attempt-owned storage. The check still precedes shard assignment and compilation. Report case identity therefore consumes the derived name, not an arbitrary caller label.

## Discovery boundary

This is native discovery for the runnable entry profile, not source-level `test` declaration discovery. The selected deployable target contributes exactly one entry case. The compiler remains responsible for requiring and compiling a valid executable entry.

The next discovery step must parse canonical test declarations, cases, tags, and limits into descriptors owned by the compiler or runtime. It must not weaken this entry profile back into a caller-selected name.

## Evidence

Every one-through-eight-source parity fixture now uses `test::entry`, derived from target `test`. Native source mode and independently compiled transported artifact mode still produce identical complete 39-byte products.

`rejectsCallerNamedNativeEntryCases` mutates the final suffix byte while retaining a generally valid case name. The runtime traps and leaves all 39 output bytes zero. This distinguishes derived entry identity from generic syntax validation.

The existing nine-source rejection continues to prove that case-name validation does not move compilation before the fixed source-count bound.

The runtime archive contains 252,633 bytes with SHA-256 `26425f1e8d2245fbe7e92e14fedecadc94997b4a660fbbc3c50e206b7b8ba341` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the new runtime archive exactly.

## Acceptance

- [x] Source-mode case name is exactly target plus `::entry`.
- [x] Comparison uses complete unsigned bytes without normalization.
- [x] Caller-selected but syntactically valid names reject.
- [x] Rejection precedes shard assignment, compilation, and publication.
- [x] One-through-eight-source report parity remains byte-identical.
- [x] Transported artifact names retain their existing profile.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Keep `test::source`

Rejected. A hard-coded fixture label is not package discovery and cannot bind another target.

### Trust any valid descriptor name

Rejected. The caller would retain semantic authority over case and report identity.

### Read the target name in Java

Rejected. The runtime already validates exact target bytes against the manifest.

### Claim general test discovery

Rejected. Entry-case derivation does not parse source-level test declarations or parameter rows.

## References

- [WIP-0212](WIP-0212-native-runner-case-identities.md)
- [WIP-0225](WIP-0225-native-case-discovery-order.md)
- [WIP-0237](WIP-0237-native-compiled-test-reports.md)
- [WIP-0245](WIP-0245-native-eight-source-test-compilation.md)
- [WIP-0247](WIP-0247-native-parameterless-test-discovery.md)
