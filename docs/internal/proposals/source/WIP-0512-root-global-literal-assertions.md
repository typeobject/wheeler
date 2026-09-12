# WIP-0512: Root global literal assertions

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-12 |
| Updated | 2026-09-12 |
| Area | Self-hosting, canonical assertions, frame products |
| Depends on | WIP-0509, WIP-0510 |
| Supersedes | None |
| Superseded by | None |

## Failure

The imported zero-argument case in WIP-0511 exposes a byte-parity defect after
its call and store already match. For `assert(Alpha == 17)`, stage 0 emits
`EXPECT_EQ [1, 17]`. Native lowering emits a global load, a literal, a comparison,
and `EXPECT_TRUE`, with three additional frame locals. The complete artifacts
differ by 80 bytes. Both sequences read runtime state, but semantic equivalence
does not establish canonical byte equality.

Keep the original failing source and its complete independent reference. Do not
replace the literal with a local, reverse the operands, remove the assertion,
or normalize away the extra instructions in the comparison.

## Contract

1. Recognize only an exact root assertion whose left operand names a declared
   global and whose equality right operand is a signed literal. Reuse the shared
   assertion front and counted global-name authority. The declaration must precede
   the assertion in the immutable source, matching stage 0's current source-order
   selection. A named constant is not a literal, even if evaluation produces the
   same value.
2. Reserve zero frame locals for that canonical instruction. Carry the counted
   global context and original declaration coordinates into value planning instead
   of reparsing state declarations or guessing that every nonlocal name denotes a
   global.
3. Retain final location and scope checks. A colliding local or parameter cannot
   become an accepted global access merely because width planning found a state.
4. Emit `EXPECT_EQ` with the declaration ordinal and full signed literal. Derive
   its length from the canonical instruction form and encoding widths. Validate
   complete output/type windows and construct results before caller publication.
5. Preserve the distinct generic Boolean assertion path. Nonliteral right
   operands, other comparisons, and literal-left predicates keep their canonical
   scalar instructions. Do not change stage 0 to match an unjoined native path.
6. Keep nested assertion lowering separate until its owner consumes the same
   profile. Root recognition must not silently alter nested frame products.

No source-global, frame, scanner, statement, or artifact limit may grow. Reuse
caller-owned empty products on state-free paths without allocating global scratch.

## Implementation

Stage 0's `simpleGlobalAssertionAhead` consults declarations already parsed.
A state after the callable therefore keeps the generic scalar assertion. The
first native prototype missed that distinction. The existing archive case
`assert(Alpha == 9); return mod;` failed complete byte comparison. Keep both
orders. No stage-0 code changed to make these tests agree.

`SourceGlobalSchema.w` now has four declaration columns: copied name start,
name length, initial value, and original declaration-name byte start. Canonical
name IDs follow those columns. Shared member fronts supply the new coordinate.
The source binder stages and publishes it with the other fields. This adds
`8 * 8 = 64` bytes, not another owned buffer or a larger global limit.

`SourceGlobalAssertionProfile.w` validates every declaration range and joins
shared assertion syntax with counted name lookup and source order. Both value
planning APIs now receive the same global context. Their call-free adapters use
existing caller storage for empty products. The aggregate adapter does not add
global scratch. Planning still leaves final scope admission to scalar binding.

`DirectGlobalLiteralAssertions.w` measures and emits the canonical two-operand
instruction. `DirectAssertionProducts.w` keeps complete type/code/frame preflight
and constructs the caller's result before emission. Zero-local assertions admit
the frame-end cursor, but reject positions beyond it. Generic scalar predicates
retain their separate operand and Boolean-result locals.

## Evidence

The preserved imported source calls a zero-argument signed dependency, stores its
result at ordinal one, asserts the literal value 17, and returns the actual global.
Native input contains only the caller source and detached target products. The
complete transient artifact comparison fails before oracle-side dependency body
binding or execution. The failure is not a missing imported call or store.

Test ordinals zero, nonzero, and seven, signed endpoints, zero, true and false
assertions, prior locals and subsequent calls. Compare complete code and frame
metadata, all output tails, cleanup, rejection, and representative replay.
Reject malformed later names and token/output windows before publication. Retain
named-constant and literal-left controls so recognition cannot broaden silently.

The affected 96-example selection passes with no failures, errors, or skips.
It includes the original before-declaration and after-declaration regressions,
complete source-global column publication, and generic assertion controls.
The later 41-example selection passes the extended ordinal, signed endpoint,
runtime failure, and declaration-coordinate matrix, with no failures, errors, or
skips. Its longest method takes 4.241 seconds. Twelve documentation methods pass.
These selections overlap and are not additive coverage counts.

Independent package and identity reconstruction passed before the physical check
exposed lifetime-buffer exhaustion during source scheduling. WIP-0513 removes
those temporary lease buffers. Fresh archive and graph measurements now agree,
and the original physical selection passes. A locked consumer publishes the
recursive call/store and canonical assertion in a complete 952-byte artifact.
The final affected-adapter selections pass, including the shared retained-call
driver and state-free aggregate path. Exact-tree and hosted verification remain open. This is not native retained instruction
linking, native entry composition, or compiler fixed-point evidence.

## Acceptance

- [x] Shared syntax and counted globals determine the exact zero-local profile.
- [x] Complete artifacts match stage 0, including the original imported case.
- [x] Signed endpoints, runtime failures, scope rejection, bounds, and replay pass.
- [x] Source budgets, affected adapters, identities, locks, and documentation agree.
- [ ] The feature and its verification identify an exact committed and pushed tree.
