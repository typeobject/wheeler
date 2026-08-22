# WIP-0256: Native test lowering authority

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and runtime maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, native testing, compiler structure |
| Depends on | WIP-0249, WIP-0255 |
| Supersedes | Test lowering inside discovery authority |
| Superseded by | None |

## Summary

Move source-to-entry lowering out of native test discovery and into one focused runtime compiler module.

`TestSourceTests.w` had accumulated two unrelated jobs. It discovered source cases and also rewrote one selected declaration for the fixed physical compiler. Parameter-row lowering would have coupled more compiler product logic to descriptor discovery.

`TestSourceLowering.w` now owns the complete lowering boundary. `TestSourceTests.w` only scans declarations, validates rows, binds descriptors, and publishes case kinds and values. `TestSourceCompilation.w` imports lowering directly.

## Module boundary

`wheeler.runtime.testing.runners.test_source_lowering` owns:

- exact selected-name comparison against lexer token ranges
- balanced declaration-body extent
- selected `test` and declaration-name replacement
- peer declaration blanking
- exact lowered output length and cursor checks
- validated source-byte copying

It imports the canonical lexer, compiler token limits, keyword and punctuation vocabularies, token helpers, and validated source-plan projection. It does not parse descriptors, select shards, invoke the compiler, verify artifacts, or publish reports.

`test_source_tests` retains:

- test declaration recognition
- parameter grammar and scalar validation
- duplicate declaration and row rejection
- exact descriptor matching
- case kind and value products

`test_source_compilation` retains private plan construction, UTF-8 freezing, fixed graph dispatch, artifact recovery storage, and committed length.

## Deletion

The lowering helpers were moved, not copied. No compatibility import, forwarding operation, or second lowering path remains in `TestSourceTests.w`.

The canonical test-runner closure names `TestSourceLowering.w` explicitly. Runtime package reachability follows `TestSourceCompilation.w`. No deployable target carries a private copy.

## Evidence

The focused counted zero-artifact fixture still lowers source declaration order `beta`, `alpha` into canonical execution order `alpha`, `beta` and publishes two passing cases.

The maximum fixed graph fixture still lowers one selected root beside seven imports and publishes a passing case. Source syntax and line policy pass with `TestSourceTests.w` reduced from 613 lines to 434 and `TestSourceLowering.w` at 195 lines.

The runtime archive contains 287,594 bytes with SHA-256 `b3ccf93c07ba541a5eefec5d2b5b9da1c064cda3a586493cab14ad519dc0b6e3` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,094 bytes with SHA-256 `b866164f0216db3c6b2e0662e0c36510863a4324a0481b4a4831b3890c0d5a3b` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the new runtime archive exactly.

## Acceptance

- [x] Discovery and lowering have separate module owners.
- [x] Lowering helpers exist in one module only.
- [x] Compilation imports lowering directly.
- [x] The native runner closure includes the new module explicitly.
- [x] Counted source compilation behavior remains unchanged.
- [x] Eight-source fixed graph behavior remains unchanged.
- [x] Every affected source remains below 1,000 lines.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Leave lowering in discovery

Rejected. Descriptor validation and compiler source products change for different reasons.

### Add forwarding operations under the old owner

Rejected. A compatibility alias would preserve two apparent authorities.

### Move lowering into the fixed graph dispatcher

Rejected. Graph dispatch owns source arity and root permutation, not source syntax.

## References

- [WIP-0249](WIP-0249-native-parameter-row-discovery.md)
- [WIP-0255](WIP-0255-native-counted-test-compilation.md)
