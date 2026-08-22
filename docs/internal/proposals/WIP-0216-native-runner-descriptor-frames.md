# WIP-0216: Native runner descriptor frames

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, package, and conformance maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, descriptor discovery, source identity |
| Depends on | WIP-0018, WIP-0212, WIP-0215 |
| Supersedes | Fixture-coded two-case metadata and source identities |
| Superseded by | WIP-0217 canonical runtime runner authority |

## Summary

Replace fixture-coded package metadata, manifest identity, case name, and source identity in the native two-case runner with a bounded descriptor transport.

The runner now receives two complete discovered descriptors beside their artifacts. It validates the transport, hashes exact source bytes, converts raw identities to canonical lowercase text, derives each case identity, assigns shards, executes selected artifacts, and reduces the report and summary. No report metadata depends on constants in the conformance executable.

## Frame

The frame begins with two little-endian shard fields, followed by one-byte-length package name, version, and target UTF-8 fields. Each of two cases then contains:

1. raw 32-byte manifest identity
2. one-byte-length case name
3. four-byte source length and exact source bytes
4. four-byte artifact length and exact artifact bytes

Metadata and case names contain 1 to 255 bytes. Sources and artifacts contain 1 to 32,768 bytes. The parser checks every intermediate boundary before reading the next length. The final artifact must end at the transport boundary.

This is the native runner boundary after package discovery. A later package slice will construct the same frame from a locked target rather than a host conformance fixture.

## Identity derivation

Each source identity is SHA-256 over the exact transported source bytes. `TestIdentityText.w` writes its lowercase hexadecimal form.

The case transcript remains WIP-0195:

- manifest identity
- case name
- source identity

Raw manifest identities prevent text normalization from entering the transport. Package, version, target, case, source, and artifact identities all reach the WIP-0201 report row through Wheeler-owned code.

## Ownership

The runner uses dynamic allocations at validated active lengths. Its outer bound is 90,914 bytes in 30 allocations, including SHA-256 scratch space and the maximum descriptor fields. The two 32,768-byte artifact buffers remain the dominant storage.

Source bytes stay borrowed from the input transport. Only their 32-byte raw and 64-byte text identities are retained.

## Evidence

`NativeCoverageRunExampleTest` constructs the descriptor frame and independently hashes the exact source strings. Its expected report derives both case identities and every report row without native output constants.

The source-derived identities assign the passing, assertion-failing, and interpreter-bound cases to known distinct `1/8` shards. Serial reduction still sorts failure before pass. Corrupted unselected artifacts remain unexecuted.

Truncated transport and an empty package name reject before output publication.

The runtime archive remains 175,011 bytes with SHA-256 `46743bf703f9a3afa4f90baa54b849a69931e3ac5fd87d818c124ed1307b5254` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 143,607 bytes with SHA-256 `57eacd5ce6264bbb30b9e5c1e3ffbf8c3af14f1b5ccc399ec3d84d58c11fb73e`. Its lock names the runtime archive exactly and retains root manifest identity `8e8fe8757e7729a9399b59b2d7ec53170b8828434e9e0268405a1652c3bf3048`.

## Acceptance

- [x] Package, version, and target metadata come from the input frame.
- [x] Manifest identities and case names come from per-case descriptors.
- [x] Source identities derive from exact source bytes inside Wheeler.
- [x] Case, shard, report, and summary semantics consume transported descriptors.
- [x] Every descriptor boundary rejects malformed input before publication.
- [x] Conformance archive and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Keep synthetic digest constants in the runner

Rejected. Constants conceal discovery and can bind unrelated sources to an artifact.

### Send host-computed source identity text

Rejected. Exact source bytes are available, so the native runner must own hashing and hexadecimal encoding.

### Parse host JSON

Rejected. JSON adds escaping and number semantics to a bootstrap transport that needs only bounded binary fields.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0212](WIP-0212-native-runner-case-identities.md)
- [WIP-0215](WIP-0215-native-test-failure-diagnostics.md)
- [WIP-0217](WIP-0217-runtime-test-runner-authority.md)
