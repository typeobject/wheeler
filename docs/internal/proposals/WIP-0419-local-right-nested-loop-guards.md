# WIP-0419: Local-right nested loop guards

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-28 |
| Updated | 2026-08-28 |
| Area | Self-hosting, structured loops, nested guards, Boolean assignment |
| Depends on | WIP-0052, WIP-0417, WIP-0418 |
| Supersedes | Literal-only signed nested loop guards |
| Superseded by | None |

## Summary

Lower one-arm nested loop equality and less-than guards with a prior signed local on the right. Preserve both source coordinates through physical projection and loop rebasing. Fix Boolean literal assignment recognition in guarded loop bodies.

## Problem

`LoopNestedConditions.w` accepted a signed local compared with one literal. A guard such as:

```wheeler
if (leftScalar < rightScalar) {
  same = false;
}
```

failed before body products. Rewriting the right local as a literal is not semantics preserving.

The child assignment exposed a second defect. `DirectLoopBodyProducts.w` looked for Boolean literal hashes only inside the identifier-token branch. A scanner token classified outside that branch could make `same = false` fail after the target and value had already resolved.

## Design

Nested condition kinds 5 and 6 represent signed local equality and less-than respectively. The existing nested condition row carries the left local. Its former literal column carries the right logical local for these two kinds.

`LoopNestedConditions.w` resolves the right identifier against values visible at the guard ordinal and requires signed type. Literal and Boolean guard kinds keep their existing rows.

`PhysicalLoopBodyProducts.w` maps both local coordinates. `LoopNestedLoopProducts.w` rebases both when loop frame insertion shifts source locals. `LoopNestedBlockProducts.w` emits a `LOCAL_MOVE` for the right source instead of `LOCAL_CONST`, followed by the existing equality or less-than instruction. Both local-right guards keep the three-local, four-instruction, 104-byte guard extent.

`LoopLocalTypeProducts.w` already assigns two signed operand rows and one Boolean result row to every non-Boolean nested guard. No second type path is added.

Boolean assignment now computes the source hash before token-kind dispatch. `true` and `false` select the literal assignment column directly. Named Boolean sources and signed literal or local assignments retain their existing checks.

## Evidence

`NativeCompilerStructuredComparisonSourceProductExampleTest` compiles both local-right forms around `same = false` inside a bounded loop. Each complete artifact matches stage 0 byte for byte.

A negative fixture uses the prior Boolean `same` value as the right operand of signed less-than. It traps before artifact length, code, identity, or publication changes.

Existing Boolean-only, Boolean-literal equality, signed literal equality, and signed literal less-than guards retain their kind values and byte layouts.

## Bootstrap identities

The compiler graph remains at 387 modules and 1,931 imports. Its 181,926-byte canonical manifest has SHA-256 `b4177555becec1116ea2f9e30a04f2b49e5c99db1c9108ea82624db9fe978ebd`. Native validation halts after 75,749,210 transitions. Wheeler SHA-256 consumes the same bytes in 34,817,790 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,203,250-byte compiler archive has SHA-256 `58892027464909b28b0445f45adb22191d900c8ee8533749b1c73927c0c4f67b`. Every dependent lock names the new archive.

The selected physical product set remains at the WIP-0416 boundary. This WIP extends structured control products and does not add a retained module.

## Failure boundary

Reject an unknown right name, non-signed right value, coordinate above 255, malformed comparison, failed physical mapping, over-bound nested local base, unsupported condition kind, malformed child block, or stale source identity before code or publication. Runtime comparison remains pure and carries no new effect.

## Acceptance

- [x] Equality-local and less-than-local guards have distinct closed kinds.
- [x] Both logical operands map to physical locals before code emission.
- [x] Loop insertion rebases left and right locals independently.
- [x] Guard instruction and local-type extents remain exact.
- [x] Boolean literal assignment no longer depends on scanner token kind.
- [x] Equality and less-than positive artifacts match stage 0 byte for byte.
- [x] A Boolean right operand publishes no artifact.
- [x] Manifest, archive, SHA-256, and dependent locks name the new source.

## Rejected alternatives

### Copy the right value into a literal slot

A runtime local is not a compile-time literal.

### Pack both locals into the condition kind

The nested product already has separate condition and operand columns. Packing would add another coordinate codec and complicate rebasing.

### Treat Boolean values as signed zero and one

The type system keeps signed and Boolean locals disjoint. A comparison cannot erase that boundary.

### Keep literal recognition under identifier dispatch

Token kind and semantic Boolean identity answer different questions. Hash the source first and classify the value once.

## References

- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0417](WIP-0417-utf8-loop-projection-products.md)
- [WIP-0418](WIP-0418-focused-loop-arithmetic-declarations.md)
