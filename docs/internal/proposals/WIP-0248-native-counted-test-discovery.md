# WIP-0248: Native counted test discovery

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, native testing, source discovery |
| Depends on | WIP-0218, WIP-0225, WIP-0247 |
| Supersedes | WIP-0247 one-declaration discovery bound |
| Superseded by | Native parameter-row discovery |

## Summary

Discover and bind every parameterless root test in a zero-to-64-case descriptor transport.

`TestSourceTests.w` scans the validated root once, counts each `test void` declaration, rejects unsupported parameter lists and duplicate declaration names, and matches every declaration against exactly one complete descriptor name. Discovery count must equal descriptor count.

Descriptor order remains the authority established by WIP-0225: strict unsigned case-name order. Declaration order does not enter identity. A source may declare `beta` before `alpha`. Descriptors must still arrive as `<target>::alpha`, then `<target>::beta`.

## Complete matching

For each discovered declaration, the runtime scans the completely preflighted descriptor frame. It compares exact target bytes, the `::` separator, and exact lexer name bytes. Descriptor traversal uses the existing one-byte name length and little-endian artifact length to skip each complete payload.

The bounded matching cost is 64 declarations by 64 descriptors. No hash table, collision rule, or mutable name copy enters authority.

The runtime also compares every declaration name against prior test-name tokens with the compiler's exact token comparator. Duplicate source declarations reject even if a malicious descriptor set tries to hide one behind another name.

Discovery succeeds only when:

- every `test void` declaration is parameterless
- declaration names are unique
- each declaration matches exactly one descriptor
- discovered declaration count equals complete descriptor count

Sources with no test declarations retain transported entry-artifact behavior. Native zero-artifact entry mode retains `<target>::entry`.

## Atomicity

Complete transport framing, source-plan validation, manifest and root selection, and lock-root validation precede discovery. Discovery precedes source identity, case identity, shard assignment, artifact verification, execution, and report publication.

A missing, extra, duplicate, parameterized, or mismatched declaration traps with untouched output. Unselected cases are still discovered and authorized but their artifacts are neither copied, verified, nor executed.

## Evidence

`discoversMultipleRootTestsInCanonicalDescriptorOrder` declares `beta` before `alpha`. Stage 0 independently compiles one artifact per declaration. The transport presents `test::alpha` then `test::beta`.

The native lexer discovers both declarations, proves complete set equality against descriptors, executes each artifact once with fresh storage, and publishes a two-selected, two-passed summary. Existing one-declaration mismatch evidence remains.

The runtime archive contains 260,182 bytes with SHA-256 `976f45b72d104aa3b0a8c6197e85c37f76ab37aff47ed62eb3a65260ef7a882c` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the new runtime archive exactly.

## Acceptance

- [x] Discovery accepts zero through 64 parameterless declarations.
- [x] Complete declaration count equals complete descriptor count.
- [x] Every declaration matches exactly one descriptor.
- [x] Duplicate declaration names reject without hash authority.
- [x] Parameterized declarations reject closed.
- [x] Descriptor order remains strict canonical name order.
- [x] Declaration order does not enter report identity.
- [x] Shard selection still precedes artifact copy and execution.
- [x] Two discovered artifacts execute once and publish one canonical summary.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Require declaration order to match descriptor order

Rejected. Source declaration order is not canonical case order.

### Hash declaration names into a set

Rejected. The bounded profile admits exact collision-free rescans.

### Discover only selected shard cases

Rejected. Complete package authorization must precede shard selection.

### Ignore parameterized declarations

Rejected. Silent omission would preserve Java discovery authority.

## References

- [WIP-0218](WIP-0218-bounded-native-descriptor-runner.md)
- [WIP-0225](WIP-0225-native-case-discovery-order.md)
- [WIP-0247](WIP-0247-native-parameterless-test-discovery.md)
