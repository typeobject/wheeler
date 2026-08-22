# WIP-0198: Runtime test-summary authority

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and conformance maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, runtime library, canonical reduction |
| Depends on | WIP-0018, WIP-0196, WIP-0197 |
| Supersedes | Conformance-owned test summary semantics |
| Superseded by | None |

## Summary

Move canonical test-outcome ordering and summary reduction into the Wheeler runtime library.

`TestSummary.w` now owns the stable radix sort, duplicate rejection, status validation, and selected, passed, failed, and successful fields. `NativeTestSummary.w` is a thin executable publication boundary.

## Boundary

The runtime operation accepts the complete WIP-0196 outcome frame and writes the seven-byte summary only after canonical reduction succeeds. It returns the exact output length.

The conformance entry point calls that operation and publishes the returned extent. It owns no bucket, ordering, duplicate, status, or count rule.

## Package graph

`RuntimeLibrary.w` imports `wheeler.runtime.testing.test_summary`. The operation ships beside runtime-owned test identity and shard assignment from WIP-0197.

`wheeler.conformance` retains the `nativetestsummary` target as an executable differential boundary. Its exact lock names the rebuilt runtime archive.

## Failure behavior

Malformed framing, duplicate identities, unknown statuses, exhausted staging, and wrong output capacity still trap inside the runtime operation before publication.

Private radix buffers and counts remain unobservable. The conformance wrapper cannot publish a partial sort or count.

## Evidence

`NativeTestSummaryExampleTest` now compiles the runtime authority and conformance wrapper together. Arrival-order, empty-report, all-pass, duplicate, unknown-status, and untouched-output evidence remains unchanged.

The runtime archive contains 129,978 bytes with SHA-256 `aa5159d8dc78433e43d8416d280dd4ba7c0978750df1dea8501c4a471b5421e0`. Its schema-3 lock retains root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 121,902 bytes with SHA-256 `d4646a68080a6c6070c51dbde1d3204ceabf7a773c1f389aefde884f414e9228`. Its lock retains root manifest identity `222af1d3f845c82713bfb26842f676fa29fcea5bd666d2a09c8ed63ac598b4d2` and names the rebuilt runtime archive exactly.

## Acceptance

- [x] The runtime library owns canonical test summary reduction.
- [x] The conformance target contains no duplicate reduction logic.
- [x] `RuntimeLibrary.w` exports the operation.
- [x] Existing differential and failure evidence passes through the new boundary.
- [x] Runtime and conformance archives are rebuilt and locked exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Leave sorting in conformance

Rejected. Executable fixtures do not own runtime semantics.

### Keep a second small-report reducer

Rejected. One implementation already covers the full 65,535-case profile.

### Publish sorted scratch rows

Rejected. WIP-0196 defines the closed seven-byte summary product. Full profile-2 report bytes remain separate WIP-0018 work.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0196](WIP-0196-native-test-summary-reduction.md)
- [WIP-0197](WIP-0197-runtime-test-selection-authority.md)
