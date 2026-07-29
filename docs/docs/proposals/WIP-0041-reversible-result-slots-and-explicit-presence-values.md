# WIP-0041: Reversible result slots and explicit presence values

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler language, type-system, compiler, bytecode, verifier, VM, quantum, proof, library, and tooling maintainers |
| Created | 2026-07-28 |
| Updated | 2026-07-29 |
| Area | Language, types, return values, reversibility, ownership, quantum values |
| Depends on | WIP-0001, WIP-0002, WIP-0005, WIP-0011, WIP-0012, WIP-0013, WIP-0028, WIP-0029, WIP-0031, WIP-0033, WIP-0034, WIP-0035, WIP-0038 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler does not add an ambient `null`, `nil`, `none`, or traditional `unit` value.
It distinguishes three concepts:

```text
void
    No value crosses the call boundary.

Done
    A one-value completion type whose sole value is done.

Slot<T>
    An explicit presence value with two source states:
        Vacant
        Holding(T)
```

`Slot<T>` replaces the planned universal `Option<T>` vocabulary. `Vacant` is a typed
state. It is not a null pointer, uninitialized host memory, erased payload, failed
computation, or quantum reset.

A non-`void` reversible function receives one implicit caller-owned mutable result slot.
Source like this:

```wheeler
rev long answer() {
  return -1;
}
```

has this semantic shape:

```wheeler
rev void answer(borrow mut Slot<long> result)
  requires result == Slot.Vacant()
  ensures result == Slot.Holding(-1);
```

`return expression;` fills, exchanges, or moves into the result slot through a checked
reversible instruction. Its inverse checks the exact occupied state and restores the slot
and source state. Language inversion does not read, pop, or otherwise depend on WIP-0001
VM history. A debugger may still record the transition. That record is a rewind aid, not
a rabbit pulled from the inverse hat.

For coherent execution, `qvalue<Slot<T>>` uses a compiler-owned tagged valid subspace.
Slot transitions are complete permutations over the physical basis. They preserve the
valid subspace and act as identity on invalid padding states. A constant return swaps
`Vacant` with one exact `Holding(value)` basis state.

## Motivation

The word "none" has been doing too many jobs in language design. Wheeler needs separate
meanings for:

- a function that returns no value.
- a generic operation that completed without a payload.
- an optional value that is absent.
- a mutable destination that has not received its value.
- clean output workspace for a reversible computation.
- a known clean basis state for a quantum register.
- failure, cancellation, end of input, or resource closure.
- an invalid pointer or foreign handle.

Those meanings cannot share one value without losing type, ownership, effect, or inverse
information.

An ordinary imperative return may overwrite a caller register, discard temporary state,
and destroy the callee frame. VM rewind can restore those values with a `StepRecord`.
That does not make the source function reversible. Wheeler's generated inverse must still
work after history commit and must execute as a new checked instruction sequence.

The call boundary therefore needs an explicit state transition:

```text
Vacant -> Holding(value)
```

and the inverse needs the opposite transition. Optional data then gets the same honest
representation. A lookup produces `Slot.Vacant()` or `Slot.Holding(value)`. Failure
remains `Result<T, E>`. No result remains `void`. Generic successful completion uses
`Done`.

Quantum code needs the same distinctions. A coherent optional value cannot erase a
payload or nominate an invalid bit pattern as "nothing." It needs a declared logical
basis, a valid-subspace rule, and a complete unitary action.

## Use cases

### Constant reversible return

```wheeler
rev long minusOne() {
  return -1;
}
```

The implicit result transition is:

```text
Vacant <-> Holding(-1)
```

Other slot states are outside the callable precondition. Coherent lowering uses the same
transposition and leaves every other basis state unchanged.

### Preserved input and constant result

```wheeler
rev long mark(borrow long input) {
  return -1;
}
```

This relation may be reversible because the input remains available:

```text
(input, Vacant) <-> (input, Holding(-1))
```

### Rejected erasing return

```wheeler
rev long erase(long input) {
  destroy(input);
  return -1;
}
```

The compiler rejects this when the post-state or explicit source witness cannot
reconstruct `input`. A reversible final instruction does not repair information loss in
an earlier instruction.

### Moved owner return

```wheeler
Buffer makeBuffer(borrow mut Region region) {
  Buffer value = allocate(region, 128);
  return value;
}
```

Returning an affine owner moves ownership into the caller result slot. The callee source
place becomes vacant at IR level. The inverse moves the same owner back.

### Ordinary optional lookup

```wheeler
Slot<Token> findToken(borrow TokenMap tokens, Symbol name) {
  if (tokens.contains(name)) {
    return Slot.Holding(tokens[name]);
  }

  return Slot.Vacant();
}
```

Map decoding failure and resource exhaustion use `Result`, not `Vacant`.

### Generic completion

```wheeler
Result<Done, CloseError> close(File file) {
  ...
  return Result.Value(done);
}
```

`Done` reports successful completion without another payload. `void` means no result
value exists.

### Coherent presence

```wheeler
qvalue<Slot<BitInt<4>>> result;
prepare(result, Slot.Vacant());
computeValue(borrow input, borrow mut result);
```

The operation may place the slot in a superposition or entangle it with `input`.
Classical inspection requires measurement.

## Goals

- Reject ambient null values and null references.
- Keep no-result, completion, presence, failure, and clean quantum state distinct.
- Name the one-value completion type `Done` and its value `done`.
- Name the explicit-presence carrier `Slot<T>` and its states `Vacant` and `Holding(T)`.
- Replace planned standard `Option<T>` APIs instead of publishing two absence dialects.
- Give every non-`void` reversible call a caller-owned result slot.
- Lower source returns to checked reversible slot operations.
- Make generated return inversion independent of retained VM history.
- Preserve copy, affine move, loan, must-consume, and quantum ownership rules.
- Define exact literal typing, including `return -1;`.
- Define the coherent encoding and padding behavior of `qvalue<Slot<T>>`.
- Give bytecode, verifier, native, proof, and tooling layers one contract.
- Reject malformed forward and inverse states before partial mutation.

## Non-goals

- Add a universal nullable reference.
- Treat `Vacant` as failure, cancellation, end-of-stream, false, zero, closed, or invalid.
- Treat `Done` as another spelling of `void`.
- Make every value-returning function reversible.
- Infer whole-function reversibility from its final return.
- Use `StepRecord` values as a source-language inverse.
- Overwrite an arbitrary occupied result slot.
- Permit silent numeric narrowing.
- Hide allocation, I/O, measurement, reset, submission, or cleanup in a slot transition.
- Store ordinary loans in `Slot<T>`.
- Make `qvalue<Slot<T>>` copyable or classically inspectable.
- Let a provider choose padding-state behavior.
- Add exception semantics.
- Admit general non-power-of-two coherent types beyond this exact slot construction.
- Freeze generic constructor punctuation ahead of WIP-0005 and WIP-0006.

## Terms and semantic model

### `void`

`void` means no result value crosses the call boundary. A `void` function uses
`return;`, or falls through when its control-flow contract permits that path.

`void` has no runtime inhabitant. It cannot be a field, local, generic argument, array
element, proof value, or quantum logical value. A reversible `void` function may still
modify explicit state under an accepted inverse relation.

### `Done`

`Done` is a closed type with one value:

```wheeler
done
```

Conceptually it is a one-case enum, but the built-in value is not constructed with
`new`. It means that a result exists and carries no additional payload. It does not mean
failure, absence, cancellation, end of input, or resource closure.

`Done` is valid in generic types such as `Result<Done, E>`, `Slot<Done>`, and
`Array<Done, N>`. Its cardinality is one and its coherent width is zero. A
`qvalue<Done>` may remain as a compile-time ownership fact without owning a qubit.
`Slot<Done>` has two logical states and coherent width one.

### `Slot<T>`

`Slot<T>` is Wheeler's standard presence value:

```wheeler
public variant Slot<T> {
  case Vacant();
  case Holding(T value);
}
```

The name describes its job at call boundaries. A caller offers a vacant destination. A
callee places or moves one result into it. The inverse restores vacancy. `Option`,
`Maybe`, `None`, `Nil`, and `Null` do not communicate that exchange role.

A source `Slot<T>` is a nominal value type. A VM frame register is an implementation
location. Diagnostics say `result Slot<T>` or `frame register` when confusion is
possible.

### Result slot

A result slot is an exclusively borrowed caller-owned `Slot<R>` associated with one
non-`void` reversible call.

```text
before forward:  result == Vacant
 after forward:  result == Holding(value)
before inverse:  result == Holding(the exact forward result)
 after inverse:  result == Vacant
```

The caller owns the slot throughout the call.

### Source place and vacancy

A return source may be a literal, compiler constant, copyable place, immutable loan,
affine owner, reversible temporary, origin-bearing returned loan, or coherent value
under an accepted relation.

An affine source local may become vacant after a move. That vacancy is verifier-owned
initialization and ownership state. It is not a source `null`. Code cannot read, borrow,
drop as occupied, or move that place again until an accepted transition fills it.

### Whole-callable reversibility

A return instruction can be reversible when its enclosing function is not. A
`ReversibleFunction` must define an injective relation across parameters, preserved
values, modified state, result slots, ownership, control witnesses, and traps. The
compiler never concludes this:

```text
reversible return => reversible function
```

### Checked partial inverse

`Vacant <-> Holding(-1)` is a checked partial bijection. Its inverse is defined only for
`Holding(-1)`. Calling the inverse with `Holding(7)` traps before mutation. Wheeler does
not require an invented meaning for every bad pre-state.

## Values in `return expression;`

The expression must match the declared result type under exact type and ownership rules.
There is no universal set of reversible values. The transition and complete callable
relation determine reversibility.

### Literals

The expected result type determines literal typing:

```wheeler
long f() {
  return -1;
}

boolean g() {
  return false;
}
```

A literal must fit the exact result type without silent narrowing or reinterpretation.
`return -1;` is invalid for an unsigned result unless source code names an explicit
checked conversion and that conversion succeeds under the declaration contract.

Wheeler has no `null`, `nil`, `none`, or `undefined` literal.

### Reversible constant return

A reversible `return -1;` is valid when the complete body loses no other information.
The generated inverse checks `Holding(-1)` and restores `Vacant` without history. A body
that first erases an input remains invalid. An unchanged borrowed input remains part of
the relation and need not prevent reversal.

### Copyable value

A preserved copyable source may use this relation:

```text
(value, Vacant) <-> (value, Holding(value))
```

The inverse checks the source and held result. The source must remain available or be
reconstructible when inverse execution needs it.

### Affine owner

An affine return moves ownership:

```text
(source = Holding(value), result = Vacant)
    <->
(source = Vacant, result = Holding(value))
```

No copy occurs. Source syntax may omit `move` only when ordinary ownership rules make
the transfer unambiguous. Typed IR records the move explicitly.

### Borrowed result

A returned loan does not enter `Slot<T>`. WIP-0028 loans are second-class and retain an
origin. Their result ABI records mode, origin, range or projection, lifetime, and
mutability. The inverse consumes or ends the loan and restores the pre-call borrow state.

An optional borrowed result needs a separate origin-bearing presence descriptor.
`Slot<borrow T>` is invalid because ordinary loans cannot enter aggregates.

### Must-consume value

A must-consume value can return only through ownership transfer. The return does not
claim that an I/O operation completed, a file closed, a transaction committed, or a
quantum submission finished. A reversible callable cannot hide external creation,
destruction, submission, close, or commit behind the return.

### Nested slot result

A function may return `Slot<T>`. Its call ABI then has an outer carrier:

```text
Slot<Slot<T>>
```

Returning `Slot.Vacant()` produces `Holding(Vacant)`, not outer vacancy. Diagnostics
must distinguish "produced the value Vacant" from "has not produced a result."

### `Done` and `Never`

A `Done` function returns `done`. A `void` function returns no expression. `Never` is
uninhabited and admits no reachable return. It is not vacancy.

### Quantum value

A live `qvalue<T>` is affine. A coherent return must move its owner, exchange it with a
compatible vacant quantum slot, preserve the source through a certified basis-copy
embedding, or explicitly measure outside a coherent callable. Basis copying may entangle
the source and destination. It never creates two independent quantum values.

## Return elaboration

### Ordinary ABI

An ordinary non-`void` function may retain the direct result ABI when reversibility is
not required. A compiler may choose result slots internally only when that choice leaves
source semantics, traps, ownership, and artifact identity unchanged under an accepted
encoding rule.

### Reversible ABI

```wheeler
rev R f(P1 p1, P2 p2) {
  ...
}
```

elaborates semantically to:

```wheeler
rev void f(
  P1 p1,
  P2 p2,
  borrow mut Slot<R> result
)
  requires result == Slot.Vacant()
  ensures result is Slot.Holding(R);
```

The result place is compiler-owned typed IR state, not a hidden history channel.

### Evaluation order

For `return expression;`, Wheeler:

1. evaluates the expression left to right under ordinary effect and trap rules.
2. validates result-slot vacancy.
3. validates ownership and source state.
4. performs one accepted result transition.
5. transfers control to the caller.

Expression failure leaves the slot unchanged. Slot validation failure leaves source
ownership unchanged. IR orders the transition and control transfer so the inverse
restores both.

### Result operation families

A constant fill performs:

```text
Vacant <-> Holding(k)
```

A preserved-source fill performs:

```text
(source = v, Vacant) <-> (source = v, Holding(v))
```

An owner move performs:

```text
(Holding(v), Vacant) <-> (Vacant, Holding(v))
```

Computed expressions may use a compiler temporary, but inverse and clean-workspace rules
still own that temporary. The compiler cannot abandon it because source code cannot see
it.

### Multiple and early returns

All reachable returns target the same result type and slot. Reversible functions also
need a reconstructible path decision through a protected predicate, explicit WIP-0035
witness, disjoint post-state relation, or another accepted control rule.

Different constants may distinguish paths, but unequal constants alone do not prove that
all other state is reversible. The first implementation may restrict reversible value
returns to tail position. Ordinary functions keep their existing early-return behavior.

## Ownership of `Slot<T>`

Ownership derives structurally from `T`.

- `Slot<T>` is `Copy` only when `T` is `Copy`.
- Moving a slot moves the active state and any owner.
- Automatic drop is legal only when `T` is droppable and no must-consume duty is hidden.
- `Holding(T)` is must-consume when `T` is must-consume.
- Borrowing a held payload yields a loan tied to the slot origin.
- Borrowing a vacant payload as `T` fails.
- A live payload loan prevents moving, emptying, or dropping the slot.

Copyability never permits two mutable aliases to one result place. Automatic drop is not
a source inverse. A reversible body cannot discard a filled slot because its payload is
droppable.

The standard library may provide checks, payload borrowing, exchange, constant fill, and
move-between-slots. It does not provide a universal `clear(slot)`. Clearing an unknown
held value would erase information, which is precisely the sort of convenience Wheeler
can do without.

## Pattern matching

Classical code may match both states exhaustively:

```wheeler
match (slot) {
  case Slot.Vacant() {
    ...
  }
  case Slot.Holding(T value) {
    ...
  }
}
```

A reversible match preserves or reconstructs its tag under WIP-0035. A coherent slot
uses coherent control or measurement rather than a classical match. Affine payload
bindings move or borrow according to the pattern. They never copy an owner implicitly.

## Coherent slot semantics

### Eligibility

`qvalue<Slot<T>>` is admitted only when:

- `T` has one accepted WIP-0033 coherent encoding.
- `T` has one exact WIP-0034 clean basis value.
- every used slot primitive defines valid-subspace and padding behavior.
- ownership and resource bounds close before lowering.

### Logical and physical encoding

If `cardinality(T) = N`, then `cardinality(Slot<T>) = N + 1`. This proposal defines one
specific non-power-of-two subspace. It does not admit arbitrary finite sums.

For `width(T) = w` and `clean(T) = c`, a coherent slot uses `w + 1` qubits:

```text
Vacant:     0 || encode(c)
Holding(v): 1 || encode(v)
```

States `0 || encode(v)` where `v != c` are padding, not source values.

### Padding rule

Every compiler-owned coherent slot primitive:

- maps valid states to valid states.
- never leaks valid state into padding.
- never maps padding into valid state.
- acts as identity on padding in the first profile.
- preserves those rules under adjoint and controlled lowering.

Targets cannot substitute another padding action.

### Constant and source-controlled fills

A constant fill swaps `Vacant` with `Holding(k)` and leaves every other basis state
unchanged. It is a complete permutation. Applying it twice restores the slot.

For a coherent preserved source, the operation maps:

```text
(v, Vacant) <-> (v, Holding(v))
```

for every valid `v` and acts as identity elsewhere. Superposed input may entangle source
and result. A coherent owner move swaps `Holding(v)` with vacancy across compatible
source and destination slots.

### Measurement and reset

A coherent slot may be superposed or entangled. Classical inspection requires explicit
measurement and returns a classical `Slot<T>` observation with WIP-0002 and WIP-0004
provenance. Padding outcomes are invalid execution evidence after valid-subspace proof.

Resetting a coherent slot to vacancy is a reset effect. It is not unfill, inverse return,
uncomputation, or drop.

`Done` needs no payload qubits. `Slot<Done>` uses one tag qubit and remains nominally
distinct from `boolean`.

## Callable and proof implications

An ordinary `Function` may return any supported type under ordinary ownership and effect
rules. Its relation need not be injective.

A `ReversibleFunction` with result `R` carries a relation that includes `Slot<R>`. Its
descriptor records the source signature, result type, slot precondition and postcondition,
operation forms, inverse body, ownership transitions, control witnesses, and trap
contract.

A `CoherentFunction` may use a slot only when the result encoding closes, every return is
a complete permutation, no history or forbidden effect appears, WIP-0035 control rules
hold, and every temporary returns clean.

A `UnitaryOperation` normally mutates caller-owned quantum resources and returns no
ordinary classical value. This proposal does not dress measurement as a unitary return.

Proof evidence checks these laws:

```text
Vacant != Holding(v)
Holding(v1) == Holding(v2) iff v1 == v2
inverse_f(forward_f(state, Vacant)) == (state, Vacant)
```

It also proves constant-fill and move round trips, coherent bijection, valid-subspace
preservation, padding identity, declared adjoints, clean temporaries, and absence of any
history read in generated inverse code. Committing VM history before inverse invocation
must not change the result.

## Bytecode and compatibility

### Type and function metadata

Canonical type metadata gains compiler-owned identities for `Done` and `Slot<T>`. The
classical logical encoding uses a tag and includes a payload only for `Holding`. A
classical `Vacant` has no unused payload bytes. Coherent descriptors separately record
the tag-plus-payload subspace.

A reversible value-returning function records:

```text
result_type
implicit_result_slot = true
result_slot_mode
result_slot_precondition
result_slot_postcondition
inverse_body
```

Ordinary functions may retain the direct result descriptor.

### Instructions

WIP-0038 assigns exact identities and operand roles. The first signed result slices use:

```text
0x0205 CALL_RESULT_SLOT(function, argument_base, argument_count, result_slot)
0x0206 UNCALL_RESULT_SLOT(function, argument_base, argument_count, result_slot)
0x0207 RESULT_FILL_CONSTANT(result_slot, immediate)
0x0208 RETURN_RESULT_SLOT(result_slot)
0x0209 RESULT_FILL_SOURCE(result_slot, source)
```

One result slot names adjacent Boolean-tag and typed-payload frame registers. Function flag
`0x8` combines with reversible and value-result flags as `0xd`. The final two callee
registers hold the implicit slot. `RESULT_FILL_CONSTANT` checks `Vacant` in forward code
and exact `Holding(k)` in inverse code before changing either register.
`RESULT_FILL_SOURCE` applies the same exchange against one preserved signed parameter.

The Wheeler-native compiler now emits this complete first vertical slice. It accepts one
`rev long` helper with up to two signed parameters returning a signed literal, evaluated
constant, or preserved signed parameter. It accepts an optional generated-inverse theorem
and entry result calls interleaved with signed checks against constants or results already
produced. Differential tests compare the complete artifacts with stage 0 before running
them. Boolean results, computed result expressions, and extra body statements still fail
without publication. That boundary is dull on purpose. A reversible
ABI is a poor place to improvise jazz.

`RESULT_FILL_SOURCE` now owns the preserved-copy relation as `0x0209`. Move and loan
families receive identities when they execute. The registry does not reserve vague numbers
and call that architecture. Existing
`RETURN_VALUE` artifacts keep their current meaning. The implementation does not smuggle
a new inverse under an old opcode and hope disassemblers look away.

Each transition still receives an ordinary WIP-0001 event record for rewind. Generated
language inverses never reference that record.

### Persistence and compatibility

Persisted slots use canonical logical encoding. Live loans do not persist as slots. Live
coherent slots follow target-session persistence rules rather than ordinary classical
serialization.

The change is additive until a standard API replaces draft `Option<T>` prototypes. Once
this WIP reaches Review, unreleased `Option`, `None`, and `Some` source migrates without a
compatibility alias. Old `.wbc` remains valid under its original metadata. Loaders reject
unsupported required result-slot or coherent-subspace features before execution.

## Safety, limits, and failure

The compiler or verifier rejects:

- null-like literals.
- value returns from `void` and bare returns from value functions.
- wrong result types and implicit numeric narrowing.
- negative literals for incompatible unsigned results.
- return from an uninitialized or ownership-vacant source.
- overwrite of a nonvacant reversible result slot.
- inverse return with the wrong held value.
- copied affine or quantum owners.
- `Slot<borrow T>` and incomplete returned-loan origins.
- escaped must-consume obligations.
- unreconstructible reversible return paths.
- coherent slots without encoding and clean-basis evidence.
- coherent transitions that enter, leave, or reinterpret padding.
- classical inspection without measurement.
- reset presented as inverse.
- VM history presented as source inverse evidence.
- malformed slot metadata, tags, payloads, or descriptors.
- exhausted result, proof, expression, or resource limits.

Every transition validates required state before mutation. Failure leaves result and
ownership unchanged, stops at the last successful control transition, emits one stable
diagnostic or trap, and publishes no partial result.

## Migration and deletion

1. Add compiler-owned `Done`, `done`, `Slot<T>`, `Vacant`, and `Holding(T)`.
2. Add canonical classical encoding, equality, ownership derivation, matching, and diagnostics.
3. Migrate planned `Option<T>` APIs and examples.
4. Add ordinary returns of `Done` and `Slot<T>`.
5. Add implicit result-slot metadata for one closed scalar reversible function.
6. Execute constant fill and prove `return -1;` without retained history.
7. Add preserved-copy and affine-move result forms.
8. Add origin-bearing returned-loan descriptors without `Slot<borrow T>`.
9. Add aggregate, array, variant, and closed generic results.
10. Integrate WIP-0035 multiple and early return witnesses.
11. Add proof metadata and no-history checks.
12. Add the coherent slot subspace and padding rules.
13. Add simulator, adjoint, controlled, measurement, and malformed-target tests.
14. Add native lowering and differential trace parity.
15. Delete draft `Option`, `None`, `Some`, null-like prototypes, overwrite inverses, and history-reading generated inverses.

## Progress

Stage 0 now accepts typed parameters on a `rev long` function whose tail return is a
signed literal, evaluated class constant, or preserved signed parameter. It emits the five
regular result-slot forms, canonical `0xd` function metadata, and a generated inverse. The
Wheeler-native compiler matches the zero-, one-, and two-parameter forms byte for byte,
including a preserved signed parameter. The VM executes both `return -1;` and a preserved
copy, commits all rewind history, then uncalls each relation back to vacancy. A wrong held
constant or source traps before the call stack or slot changes. The Wheeler-native verifier
independently accepts both artifacts and their generated-inverse certificates. The bounded
Wheeler interpreter executes both call directions and agrees with the Java VM on every
global. Wheeler-native lowering and execution cover the same bounded constant and
preserved-copy relations.

- [x] `Done` and `done` parse, typecheck, encode, execute, and reject nonzero physical constants.
- [x] Closed classical `Slot<T>`, `Vacant`, and `Holding(T)` parse, typecheck, encode, and execute.
- [x] Planned `Option<T>` APIs and examples use `Slot<T>` or domain-specific result names.
- [x] Ordinary functions return `Done` and closed classical slots.
- [x] Reversible scalar result-slot ABI executes.
- [x] `return -1;` runs forward and inverse without VM history.
- [x] Preserved-copy signed return forms execute.
- [ ] Affine-owner return forms execute.
- [ ] Borrowed results retain exact origins.
- [ ] Multiple return paths integrate with WIP-0035.
- [x] Compiler-owned closed classical slots specialize to canonical variant descriptors.
- [ ] Coherent encoding and padding rules execute.
- [ ] Coherent fills, moves, and measurement execute.
- [ ] Proof and resource metadata pass.
- [x] Wheeler verifier and bounded interpreter agree with the Java VM on the signed constant form.
- [x] Native lowering and interpreted traces agree.
- [ ] Duplicate absence and history-dependent inverse paths are deleted.

## Testing and acceptance

- [ ] `void` has no value and is invalid as a generic argument.
- [ ] `Done` has one value and coherent width zero.
- [ ] `Slot<Done>` has two logical states and coherent width one.
- [x] Classical `Vacant` and `Holding(value)` compare and encode canonically.
- [ ] Slot ownership derives from its payload.
- [ ] Filled affine slots cannot copy and filled must-consume slots cannot drop.
- [ ] `return -1;` is accepted for `long` and rejected for unsigned output without a valid conversion.
- [x] Null-like literals fail with one stable source diagnostic.
- [x] Reversible constant return fills a vacant result and exact inverse restores vacancy.
- [x] The inverse succeeds after VM history commit.
- [x] Wrong held constants trap before mutation.
- [x] Preserved-source fill round-trips exactly.
- [ ] Affine moves round-trip exactly.
- [ ] Returned loans retain origin and `Slot<borrow T>` is rejected.
- [x] Nested classical slots distinguish outer vacancy from `Holding(Vacant)`.
- [x] Information-losing bodies remain rejected despite a reversible return.
- [ ] Trapping return expressions leave the result vacant.
- [ ] Multiple reversible returns require a reconstructible decision.
- [ ] Classical matching is exhaustive and coherent matching requires control or measurement.
- [ ] Every coherent primitive preserves valid states and acts as identity on padding.
- [ ] Constant coherent fill is a transposition and applying it twice restores state.
- [ ] Source-controlled coherent fill may entangle but does not clone.
- [ ] Coherent move preserves affine ownership.
- [ ] Measurement returns classical `Slot<T>` and rejects padding evidence.
- [ ] Reset remains a reset effect rather than inverse return.
- [x] Existing ordinary artifacts retain their meaning.
- [x] Unsupported result-slot features reject before execution.
- [x] Reference docs describe only the implemented classical `Done` and closed-slot slices.

## Alternatives

### Universal `null`

Rejected. It conflates absence, pointer invalidity, no result, failure, and ownership
vacancy while exporting the confusion to every generic API.

### `None` and `Some`

Rejected as standard Wheeler names. They describe an optional algebra but not the
reversible destination role.

### Traditional `unit`

Rejected as source terminology. Wheeler uses `Done` for an actual completion value and
`void` for no value.

### `Empty` and `Full`

Reasonable, but `Vacant` and `Holding` better describe ownership and do not suggest that
an unknown quantum payload was erased.

### Sentinel values

Rejected. `-1` is an ordinary signed value. A domain type may assign it a meaning, but
the language does not call it vacancy.

### Uninitialized register as absence

Rejected. Definite initialization is verifier state, not a portable value or coherent
basis state.

### `Option<T>` plus special result registers

Rejected. Two absence models would make libraries, ownership, coherent encoding, proofs,
and diagnostics disagree.

### Hidden payload in every vacant value

Rejected for the logical model. It would give vacancy invisible identities. Coherent
padding bits are invalid physical states with fixed behavior, not source values.

### Overwrite and use VM rewind

Rejected. It works only while history survives and cannot define coherent execution.

### Always return `(input, output)`

Safe in some pure designs, but too intrusive as the only API. The slot relation preserves
required information while retaining ownership-aware return syntax.

### Separate classical and quantum presence types

Rejected initially. One logical `Slot<T>` plus explicit coherent evidence keeps basis
identity connected while `qvalue<Slot<T>>` enforces stricter ownership.

### Total behavior on every occupied slot

Rejected. Checked partial bijections already fit Wheeler. Inventing useful behavior for
bad call states would hide caller mistakes and add little besides meetings.

## Open questions

- Should all diagnostics say `result slot` despite VM frame-register terminology. **Owner:** language and tooling maintainers. **Decide by:** before Review.
- May packages define domain-specific option-like variants without prelude aliases. **Owner:** library maintainers. **Decide by:** before library stabilization.
- Which explicit source slot operations ship beyond compiler-lowered return. **Owner:** language and library maintainers. **Decide by:** before parser implementation.
- Does the first reversible result profile allow only tail return. **Owner:** reversible-control maintainers. **Decide by:** before implementation.
- Which instruction forms minimize registry surface without weakening diagnostics. **Owner:** bytecode and VM maintainers. **Decide by:** before WIP-0038 allocation.
- Must coherent slots always reuse the payload clean basis. **Owner:** quantum type and proof maintainers. **Decide by:** before descriptor freeze.
- Is padding identity permanent or merely the first extension profile. **Owner:** quantum semantics maintainers. **Decide by:** before this WIP leaves Draft.
- How should callable documentation render the implicit stateful result relation. **Owner:** WIP-0031 and documentation maintainers. **Decide by:** before callable docs.
- Are `Done` and `done` the final source spellings. **Owner:** language and formatter maintainers. **Decide by:** before parser acceptance.

## References

### Wheeler proposals

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0002](WIP-0002-unified-classical-quantum-semantics.md)
- [WIP-0005](WIP-0005-wheeler-source-language.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0012](WIP-0012-wheeler-standard-library.md)
- [WIP-0013](WIP-0013-typed-frames-control-flow-and-storage.md)
- [WIP-0028](WIP-0028-deterministic-ownership-borrowing-and-regions.md)
- [WIP-0029](WIP-0029-parametric-polymorphism-and-bounded-specialization.md)
- [WIP-0031](WIP-0031-reversible-quantum-and-effect-polymorphism.md)
- [WIP-0033](WIP-0033-typed-coherent-values-and-reversible-embeddings.md)
- [WIP-0034](WIP-0034-structured-uncomputation-and-clean-ancilla-scopes.md)
- [WIP-0035](WIP-0035-reversible-and-coherent-control-flow.md)
- [WIP-0038](WIP-0038-regular-instruction-forms-and-extension-registry.md)

### Related language research

- [Qunity: A Unified Language for Quantum and Classical Computing](https://arxiv.org/abs/2204.12384)
- [Semantics for a Turing-complete Reversible Programming Language with Inductive Types](https://arxiv.org/abs/2309.12151)
- [Categorical Semantics of Reversible Pattern-Matching](https://arxiv.org/abs/2109.05837)
- [Quantum Programming with Inductive Datatypes](https://arxiv.org/abs/1910.09633)
