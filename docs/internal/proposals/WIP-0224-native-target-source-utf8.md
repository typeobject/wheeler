# WIP-0224: Native target source UTF-8 validation

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and package maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, target sources, UTF-8 |
| Depends on | WIP-0009, WIP-0018, WIP-0223 |
| Supersedes | Byte-opaque source payloads in validated target plans |
| Superseded by | None |

## Summary

Require strict UTF-8 source payloads in native target-source plans.

WIP-0223 validated canonical path and length framing but treated each source payload as opaque bytes. Stage-0 package discovery rejects malformed UTF-8 before compilation. `TestSourcePlan.w` now applies the same scalar validity boundary before the runner hashes the plan or derives any case identity.

## Accepted encoding

The validator accepts:

- single-byte ASCII
- two-byte sequences beginning at `C2`
- three-byte sequences with overlong and surrogate exclusions
- four-byte sequences from `U+10000` through `U+10FFFF`

It rejects isolated continuation bytes, `C0` and `C1`, truncated sequences, overlong forms, UTF-16 surrogate encodings, values above `U+10FFFF`, and lead bytes above `F4`.

NUL remains a valid UTF-8 scalar at this layer. Wheeler lexical policy may reject it later with a source diagnostic. Encoding validity and language syntax are separate checks.

## Bounds

Validation walks each source once under the existing 32,768-byte total plan limit. It retains one pending second byte and allocates no storage.

Every accepted source boundary still comes from the big-endian WIP-0223 frame. A multibyte sequence cannot consume bytes from the next entry.

## Failure behavior

UTF-8 validation precedes source-plan hashing, descriptor processing, shard selection, artifact verification, and execution. Rejection leaves output untouched.

## Evidence

The canonical fixture contains three ASCII Wheeler modules in one source entry and retains the same source-plan identity and semantic reports.

`NativeCoverageRunExampleTest` replaces the first source byte with `FF` while preserving every frame length. The native runner rejects the malformed sequence before publication.

The runtime archive contains 199,201 bytes with SHA-256 `5f03b0bf85901a6f21533af5637ea8e1c7d31010fc235304f58cd266c953432f` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1`. Its lock names the new runtime archive exactly and retains root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`.

## Acceptance

- [x] Every source payload receives strict UTF-8 validation.
- [x] Overlong, surrogate, truncated, continuation, and out-of-range forms reject.
- [x] Validation cannot cross an entry boundary.
- [x] Work remains bounded and allocation-free.
- [x] A malformed source fixture publishes no output.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Let the compiler discover malformed UTF-8

Rejected. Package source selection defines text input before compiler syntax.

### Replace malformed sequences

Rejected. Replacement changes source bytes, identities, diagnostics, and potentially syntax.

### Validate only ASCII bootstrap fixtures

Rejected. Package framing promises strict UTF-8, not a temporary ASCII dialect.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0223](WIP-0223-native-target-source-plan-validation.md)
