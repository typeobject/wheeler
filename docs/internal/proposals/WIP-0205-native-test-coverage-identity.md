# WIP-0205: Native test coverage identity

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and conformance maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, semantic coverage, report composition |
| Depends on | WIP-0018, WIP-0020, WIP-0204 |
| Supersedes | Java-only test coverage identity derivation |
| Superseded by | None |

## Summary

Derive the stage-0 semantic coverage identity inside the Wheeler runtime.

`TestCoverageIdentity.w` prefixes one canonical bounded transition report with `wheeler-transition-coverage-1` and its terminating zero byte, then hashes the exact combined bytes. This supplies the final passing-case identity component that remained private to Java.

## Input and transcript

The input is one complete canonical report emitted by `CoverageReducer.w`. Its 32,768-byte bootstrap ceiling matches the native coverage report buffer.

The hash transcript is:

1. 29 ASCII domain bytes
2. one zero separator
3. every canonical report byte

No length prefix, newline normalization, decoding, or renderer pass occurs.

The operation owns 33,886 private bytes in four allocations, including the 33,798-byte maximum transcript and SHA-256 state.

## Boundary

This operation hashes an already canonical report. It does not accept coverage fragments, sort points, or decide which transitions count. `CoverageReducer.w` retains those semantics under WIP-0020.

The conformance wrapper only publishes the 32-byte digest. WIP-0209 adds a range form so a native runner can hash the measured report prefix without copying it into a second exact-sized buffer.

## Failure behavior

A report above 32,768 bytes or output capacity other than 32 bytes traps before publication. Empty input is hashable at this layer, although package testing obtains reports from the nonempty canonical reducer.

## Evidence

`NativeCoverageRunExampleTest` hashes the exact Wheeler-produced profile-1 report independently with Java SHA-256 and compares all 32 bytes. A 32,769-byte input traps with every output byte untouched.

The existing source-through-native coverage report and unsupported-trace atomicity fixtures remain unchanged.

The runtime archive contains 153,059 bytes with SHA-256 `24c9b689af4d7925babf672e616808767f653b4b0c2c892a62166aae91d7e435`. Its schema-3 lock retains root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 123,290 bytes with SHA-256 `a03d38ed0806366b0ebc44f5b2cdc13cca59f0174ebd4c3edb6e36b216adf934`. Its lock names root manifest identity `90843d43b350acd5ae5945dfaa01df26702c003edba9993b896235d7a774b39d` and the rebuilt runtime archive exactly.

## Acceptance

- [x] Native identity matches the stage-0 domain and report bytes.
- [x] The complete 32,768-byte bootstrap report range is admitted.
- [x] Oversized input rejects before publication.
- [x] Coverage reduction and identity derivation remain separate operations.
- [x] Runtime and conformance archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Hash rendered coverage without the domain

Rejected. Stage 0 domain-separates semantic coverage identities.

### Reimplement coverage sorting here

Rejected. One canonical reducer must own transition order and counts.

### Keep the digest in Java report construction

Rejected. Native passing-case reports require the same identity without a host callback.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0020](WIP-0020-semantic-coverage-and-evidence-accounting.md)
- [WIP-0204](WIP-0204-native-test-execution-identity.md)
- [WIP-0209](WIP-0209-native-one-case-test-runner.md)
