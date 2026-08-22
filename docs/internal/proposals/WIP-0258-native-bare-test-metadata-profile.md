# WIP-0258: Native bare test metadata profile

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, native testing, metadata validation |
| Depends on | WIP-0249, WIP-0257 |
| Supersedes | Implicit acceptance of unimplemented test metadata |
| Superseded by | WIP-0259 native limits and WIP-0260 native tags |

## Summary

Reject test metadata that the native runner cannot yet enforce.

The source compiler accepts `tags(...)` and `limits(...)`. Native discovery previously stopped after the parameter list or `cases(...)` rows. It could therefore authorize a descriptor, strip trailing metadata during source lowering, and execute with neither tag selection nor declared limits.

The initial native source profile required the declaration body opening brace immediately after:

- `test void name()`
- `test void name(type value) cases(...)`

WIP-0259 admits exact canonical `limits(...)` syntax. WIP-0260 admits canonical tags with an explicit selection frame. Every unknown suffix still rejects before identity, sharding, lowering, compilation, verification, execution, or publication.

## Parser boundary

`SourceTestRows` now retains the token after the canonical closing `cases` parenthesis. Discovery requires that token to be the opening body brace. Parameterless discovery performs the same check at the fixed token offset after `)`.

This closed valid and malformed metadata alike before WIP-0259 and WIP-0260 split supported limits and tags from unknown suffixes. It does not search raw source for `tags` or `limits`, and it does not silently ignore unknown suffixes. The canonical lexer and punctuation vocabulary remain authority.

The profile is intentionally narrower than stage 0. Native tags require selection transport and canonical set validation. Native limits require interpreter step and history enforcement. Those features must cross the complete boundary before this rejection is relaxed.

## Atomicity

Metadata rejection occurs during complete root discovery. Even unselected shard cases must have supported declaration syntax. No unsupported metadata can hide behind shard selection or a transported artifact.

A rejected declaration leaves all output bytes untouched. Java cannot make metadata effective by supplying an artifact compiled with host-side limits or tags.

## Evidence

The original bare-profile evidence inserted metadata between the discovered declaration and body while retaining a valid zero-artifact descriptor. Native discovery rejected before compiler invocation with all 39 output bytes zero. WIP-0259 and WIP-0260 replace that broad rejection with focused positive and negative metadata evidence.

Parameterless, counted, imported, and mixed scalar-row source compilation remain green under the explicit metadata profile.

The runtime archive contains 298,415 bytes with SHA-256 `33256baca89da2bc97d99ac155f6eb91cc62512be8da570c59fafd83b1d82707` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,094 bytes with SHA-256 `b866164f0216db3c6b2e0662e0c36510863a4324a0481b4a4831b3890c0d5a3b` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the new runtime archive exactly.

## Acceptance

- [x] Parameterless declarations require an immediate body brace.
- [x] Parameterized declarations require an immediate body brace after `cases(...)`.
- [x] Unknown declaration suffixes reject.
- [x] Rejection precedes identity, sharding, compilation, and execution.
- [x] Transported artifacts cannot bypass source metadata validation.
- [x] Rejection leaves all output bytes untouched.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Ignore tags and limits

Rejected. Source identity alone does not enforce selection or resource semantics.

### Trust stage-0 artifact metadata

Rejected. The native runner must own authorization and execution limits.

### Validate metadata only for selected shards

Rejected. Complete package discovery precedes scheduling.

### Accept syntax now and enforce it later

Rejected. A feature cannot be half-effective in canonical reports.

## References

- [WIP-0249](WIP-0249-native-parameter-row-discovery.md)
- [WIP-0257](WIP-0257-native-parameter-row-compilation.md)
- [WIP-0259](WIP-0259-native-test-step-limits.md)
- [WIP-0260](WIP-0260-native-test-tag-selection.md)
