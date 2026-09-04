# WIP-0194: Native test shard assignment

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and conformance maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Native testing, deterministic sharding, Java-free execution |
| Depends on | WIP-0018 |
| Supersedes | None |
| Superseded by | None |
| Follow-up | WIP-0197 runtime library ownership |

## Summary

Move deterministic test-case shard assignment across the Wheeler boundary.

`TestShard.w` accepts one complete lowercase SHA-256 case identity, a little-endian shard index, and a little-endian shard count. `NativeTestShard.w` publishes its Boolean result through a one-byte conformance boundary.

This is not a test runner. Discovery, case execution, report reduction, and adapters remain with WIP-0018.

## Input

The executable accepts exactly 68 bytes:

| Offset | Width | Product |
| ---: | ---: | --- |
| 0 | 64 | lowercase hexadecimal case identity |
| 64 | 2 | little-endian shard index |
| 66 | 2 | little-endian shard count |

The shard count is between one and 65,535. The index is less than the count.

Uppercase hexadecimal, punctuation, truncated identities, zero shard counts, and out-of-range indices trap before publication.

## Assignment

The reducer reads the identity from left to right as 32 octets:

```text
remainder = (remainder * 256 + octet) % shardCount
```

The case belongs to the shard exactly when the final remainder equals `shardIndex`.

This is the stage-0 `TestReport.assignedToShard` rule. It preserves leading zeroes and consumes the final octet. No host integer conversion, locale, hash table, filesystem order, or arrival order participates.

## Bounds

Work is fixed at 32 octets. Intermediate values remain below 16,777,215, so signed 64-bit arithmetic cannot overflow.

The output buffer has one byte. Success publishes zero or one and sets the exact output length. Failure leaves the caller-owned output unchanged.

## Package boundary

`wheeler.runtime` owns shard assignment under WIP-0197. `wheeler.conformance` exports the `nativetestshard` deployable boundary. Neither operation reads a package graph, source tree, environment, clock, random source, or network state.

## Evidence

`NativeTestShardExampleTest` checks all seven shards for one physical closure identity and requires exactly one selection. Separate fixtures distinguish final octets `01` and `ff` behind sixty-two leading zeroes.

Uppercase identity text, a zero count, and an index equal to the count trap before changing the output byte.

The conformance archive contains 121,149 bytes with SHA-256 `5e8ee60387cb349971d308688005c7513dca7a74cf37dc983a0d30c8800cc5f2`. Its schema-3 lock binds root manifest identity `98a3eba9ba2cbe9875f34fcd98d4914b7d2238a7ebc1065ea2205cca2460805b`.

## Acceptance

- [x] Wheeler computes the profile-2 stage-0 shard rule.
- [x] The complete 256-bit identity participates.
- [x] Exactly one shard is selected for a valid partition.
- [x] Canonical identity and shard bounds fail closed.
- [x] The conformance package exports one deployable target.
- [x] Focused differential evidence passes.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Parse the identity as one signed integer

Rejected. The accepted profile is an octet stream and must not depend on host big-integer behavior.

### Hash the hexadecimal text again

Rejected. Assignment consumes the case-identity digest itself.

### Assign by case arrival order

Rejected. Worker and discovery order are not semantic inputs.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0197](WIP-0197-runtime-test-selection-authority.md)
- [Package testing reference](../../public/reference/packages.md#tests)
