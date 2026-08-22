# WIP-0196: Native test summary reduction

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and conformance maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, canonical reduction, Java-free execution |
| Depends on | WIP-0018, WIP-0195 |
| Supersedes | None |
| Superseded by | WIP-0198 runtime library ownership |

## Summary

Reduce a complete bounded set of test outcomes without host collections.

`TestSummary.w` sorts raw case identities, rejects duplicates and unknown statuses, and writes selected, passed, failed, and successful fields. `NativeTestSummary.w` publishes the result. Input arrival order does not affect the product.

This closes the ordering and summary kernel. Profile-2 case payload hashing, diagnostic reduction, rendering, discovery, and execution remain with WIP-0018.

## Input

The input starts with a two-byte little-endian case count. Exactly that many 33-byte rows follow:

| Row offset | Width | Product |
| ---: | ---: | --- |
| 0 | 32 | raw SHA-256 case identity |
| 32 | 1 | status: zero for pass, one for fail |

The physical input length must equal two plus 33 times the case count. Empty reports are valid. A report contains at most 65,535 rows.

Raw digest order is identical to lowercase hexadecimal order because hexadecimal preserves unsigned octet order.

## Canonical reduction

The reducer performs a stable least-significant-digit radix sort over all 32 identity octets. Each pass has 256 buckets. Thirty-two passes produce ascending identity order without a host map, comparison callback, or quadratic case scan.

Adjacent equal identities reject after sorting. This catches duplicates even when workers deliver them far apart.

Status validation and counting happen only after canonical order is complete.

## Output

The seven-byte summary contains:

| Offset | Width | Product |
| ---: | ---: | --- |
| 0 | 2 | selected count |
| 2 | 2 | passed count |
| 4 | 2 | failed count |
| 6 | 1 | one exactly when failed is zero |

Counts use little-endian unsigned encoding. The empty report is successful, matching stage 0.

## Bounds

Two 2,162,655-byte row buffers carry the maximum report. A 256-word bucket table carries counts and stable target offsets. Private staging owns 4,327,358 bytes in three allocations.

Each radix pass reads every active row and copies 33 bytes. Work is linear in the case count under fixed identity and row widths. Worst-case capacity and behavior remain explicit.

## Failure behavior

A truncated or extended frame, unknown status, duplicate identity, oversized count, wrong output capacity, or exhausted staging traps before output length changes.

Rows, bucket counts, and sorted order remain invocation-owned. The caller sees only a complete seven-byte summary.

## Package boundary

`wheeler.runtime` owns summary reduction under WIP-0198. `wheeler.conformance` exports the `nativetestsummary` deployable boundary. It reads no package graph, source tree, environment, clock, random source, worker identity, or network state.

## Evidence

`NativeTestSummaryExampleTest` reduces the same mixed outcomes in two arrival orders. It covers empty and all-passing reports, duplicates separated by another identity, and an unknown status.

Duplicate and status failures leave all seven caller bytes unchanged.

The conformance archive contains 131,046 bytes with SHA-256 `c3bb8f54bce317638da5ddff27ab05684d5826609348b363cef7dd2e2f6981bc`. Its schema-3 lock binds root manifest identity `222af1d3f845c82713bfb26842f676fa29fcea5bd666d2a09c8ed63ac598b4d2`.

## Acceptance

- [x] Reduction accepts the full 65,535-case profile.
- [x] Case identities sort canonically without host collections.
- [x] Duplicate identities fail independently of arrival order.
- [x] Pass, fail, and successful fields match stage-0 semantics.
- [x] Empty reports are successful.
- [x] Failure publishes no partial summary.
- [x] Focused native evidence passes.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Require pre-sorted worker output

Rejected. Arrival order is not semantic evidence.

### Use insertion sort

Rejected. The accepted 65,535-case bound makes quadratic reduction indefensible.

### Hash rows before duplicate validation

Rejected. A duplicate terminal row must never enter report identity or counts.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0195](WIP-0195-native-test-case-identity.md)
- [WIP-0198](WIP-0198-runtime-test-summary-authority.md)
- [Package testing reference](../../public/reference/packages.md#tests)
