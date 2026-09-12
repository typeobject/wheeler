# WIP-0511: Counted call global destinations

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler, runtime, and bootstrap maintainers |
| Created | 2026-09-12 |
| Updated | 2026-09-12 |
| Area | Self-hosting, counted calls, declared globals |
| Depends on | WIP-0049, WIP-0499, WIP-0507, WIP-0509, WIP-0510 |
| Supersedes | None |
| Superseded by | None |

## Boundary

A counted call must store its result at the declared destination, not at a fixed
state index or a synthetic local. This task joins ordinary root call statements
to the global locations from [WIP-0509](WIP-0509-root-scalar-global-locations.md).
It does not close [WIP-0507](WIP-0507-native-source-global-access-products.md).

[WIP-0499](../WIP-0499-native-global-call-assignments.md) covers a bounded
state-zero assignment family. Do not clone that family for each declaration
ordinal. Reuse counted call coordinates, signatures, argument products, and the
shared global-name authority. Do not pass dependency bodies across the source
compilation boundary.

Conditions over globals, nested stores, complete scope precedence, native entry
and nominal composition, and retained instruction relocation remain separate
joins. The intact mixed-member runner still fails at its minimal dispatcher
after commit `13164625a`. This task must not erase its members or substitute a
smaller runner fixture.

## Reproduction

The archive regression keeps both states and one terminating recursive callable.
Its outer call receives 5 or 8. The inner call receives zero and returns the
counted constant. The outer store must change `Alpha` from 8 to 3 and leave
`Zulu` unchanged.

```wheeler
state long Zulu = -9223372036854775808;
state long Alpha = example.values::LIMIT + 5;

public long compute(long mod) {
  long zero = 0;
  if (mod == 0) { return LIMIT; }
  Alpha = compute(zero);
  assert(Alpha == LIMIT);
  return Alpha;
}
```

The dependency exports signed `LIMIT = 3`. Stage 0 accepts the complete source
before native execution starts. The initial native value plan returned
`[valueCount=0, failureFunction=0, failureStatement=2, failureCode=2, valid=0]`.
An execution observer identified statement 2 as `Alpha = compute(zero);`.
The following assertion and conditional child return occupy distinct statement
rows. The structured compiler rejected the plan at instruction 705, local 697.

`SourceValueProducts.w` already recognized the counted call. Its complete-statement
check admitted bare calls, returns, and declarations, but left the assignment
prefix at an invalid head count. The current implementation joins both that width
and its actual destination. The reproduction now matches complete artifacts and
runtime state.

## Contract

1. Validate the whole counted call and statement envelope before reserving its
   result. A root assignment has an identifier, assignment punctuation, the call,
   and a final semicolon. Do not reinterpret unknown prefixes as declarations.
2. Reserve the existing argument materialization and ABI windows plus one scalar
   result local. Derive the width from the argument count. A global destination
   contributes no named local and no second result move.
3. Bind the callee through counted signatures and the destination through
   `SourceGlobalReferences.w`. Validate the complete copied-name window, including
   unused later rows. Reject absent or ambiguous destinations.
4. Require an ordinary signed result for a signed state. Reject void, Boolean,
   nominal, and unjoined reversible result forms before code publication.
5. Emit canonical argument preparation, `CALL_VALUE`, and `LOCAL_STORE_GLOBAL`.
   Use the validated declaration ordinal. Preserve local and imported call
   coordinates for their owning relocation paths.
6. Validate complete frame, code, type, and statement windows before writing any
   caller-visible product. Construct result records before publication. Later
   malformed statements must preserve earlier caller buffers and identities.

Use the current eight source-global slots, 256 source calls, 64 functions, 4,096
statements, and 262,144 code bytes. Do not grow a limit to accommodate the join.
Measure physical bytes and raw tokens after extracting any coherent call owner.
A scratch arena must name its columns, capacities, byte widths, and allocation
count. Remove any scalar-call branch that the shared destination owner replaces.

## Current implementation

`SourceCallArgumentProducts.w` owns prefix selection and complete call envelopes.
Width planning shares that owner and reserves evaluation, transfer, and result
locals. It rejects assignment heads outside the function root until the nested
lowering path can bind stores. It does not create a named destination value.

`DirectCallDestinations.w` binds root destinations after counted signature layout.
It checks bare calls, returns, and declarations without running a scalar emitter
only to discard its output. Signed stores share `DirectScalarLocations.w` and
select `CALL_STORE_GLOBAL_SIGNED`. The existing per-call result-operand column
carries the declaration ordinal. Conditional child values retain their separate
selector meanings in that same column.

`SourceCallLayoutProducts.w` owns the call kinds and derives encoded lengths from
canonical instruction forms. Signature result types map explicitly to void,
signed, or Boolean calls. They cannot masquerade as destination kinds.
`LoopCallProducts.w` emits the call and store, omits an extra local type, validates
result operands, and constructs its result before caller publication. The direct
arena remains 726,528 bytes and twelve buffers. The call join adds no owned table
or larger limit. WIP-0512 separately adds one declaration-coordinate column to
the source-global product, without adding a buffer.

Local artifact cases cover ordinals zero, one, and seven, repeated stores, zero
and 64 arguments, and an `entry` helper with an ordinary step claim. Wrong result
types, absent or local destinations, malformed suffixes, and nested assignments
preserve publication. The raw encoder reaches local 255 with 64 arguments and
rejects the first excess. Complete code, types, relocations, identities, input
rows, cleanup, and representative publication replay pass.

The 64-argument API fixture measured 6,737,747 compiler transitions before the
later nested-assignment guard. Its preemptive two-minute JUnit deadline bounds
this history-free API test. This evidence does not certify the synthetic compiler
driver's default four-million-step manifest or a native command at that capacity.
Do not silently widen the manifest or reinterpret the measurement as a proof.

The earlier affected matrix passes 170 examples. A later delta passes 26 examples,
14 source checks, and twelve documentation checks. Two subsequent archive methods
cover the contextual helper claim and nested rejection. These selections overlap.
Direct binder cases now cover every joined head, wrong result kinds, reversible
stores, ordinals zero, one, and seven, local ambiguity, unused malformed names,
and invalid value counts. Every caller buffer survives lookup and replay.

Imported cases supply detached signatures, qualifier names, and target identities
without dependency body source. Complete transient artifacts, native digests,
inactive tails, all relocation rows, and caller input buffers match independent
oracles. Tests bind a real, nonzero dependency body on the oracle side to execute
unchanged native callers. This is not native retained instruction linking.

The zero-argument case exposed a distinct assertion mismatch, now tracked in
[WIP-0512](WIP-0512-root-global-literal-assertions.md). Both declaration orders
retain their complete references. A later 41-example selection passes the extended
ordinal and declaration-coordinate matrix. The selected physical check then
exhausts lifetime buffers during source scheduling. [WIP-0513](WIP-0513-immutable-source-lease-ranges.md)
removes the redundant lease copies. The original physical selection now passes,
and fresh archive, graph, and lock measurements agree. A locked consumer publishes
and independently checks the recursive call/store and literal assertion in a
952-byte artifact. The final affected selections pass 131, 64, and 32 examples
with no failures, errors, or skips. They cover the shared driver and state-free
adapters. Exact-commit and hosted verification remain open.

## Required evidence

Compare complete native artifacts with independently compiled sources before
running them. Check destination ordinals zero, a nonzero ordinal, and the final
source-global slot. Exercise local and counted imported callees without reopening
dependency source. Keep arguments, metadata, strings, globals, and inactive bytes
in the comparison.

Cover zero and supported maximum arities, previous locals, repeated stores, later
actual reads, and a later assertion. The recursive reproduction must execute its
call and store, not return before either. Compare complete runtime state and
rewind/replay. Keep capacity cases history-free rather than retaining an oversized
history.

Reject malformed late names, unknown destinations, local/global ambiguity,
wrong result types, excess frame/code windows, and malformed trailing statements.
Check the entire unpublished artifact, native digest, product metadata, and tails.
Selected archive or physical checks remain bounded evidence, not a compiler
fixed point or complete source-independent global relocation.

## Acceptance

- [x] Exact counted call assignments reserve widths without synthetic locals.
- [x] Shared global binding selects validated declaration ordinals.
- [x] Canonical calls and stores pass complete artifact and execution comparisons.
- [x] Invalid later inputs preserve complete caller publication.
- [x] Frame, code, arity, name, cleanup, and replay boundaries have direct evidence.
- [x] Affected adapters, physical budgets, packages, locks, and a locked consumer agree.
- [ ] Documentation and hosted verification identify the exact committed tree.
