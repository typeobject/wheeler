# WIP-0033: Typed coherent values and explicit reversible embeddings

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler language, type-system, compiler, verifier, quantum, proof, runtime, and tooling maintainers |
| Created | 2026-07-20 |
| Updated | 2026-07-20 |
| Area | Language, types, coherent values, quantum IR, proofs |
| Depends on | WIP-0002, WIP-0005, WIP-0011, WIP-0013, WIP-0017, WIP-0028, WIP-0029, WIP-0030, WIP-0031 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler adds typed coherent values and an explicit reversible embedding for ordinary bounded predicates. A `qvalue<T>` is an affine quantum resource whose basis states represent one finite Wheeler type through certified encoding evidence. The compiler may turn a total, effect-free predicate `T -> boolean` into a marking operation only through the explicit `oracle(predicate)` form. The source predicate remains ordinary code, while the generated marking operation preserves its input, toggles one result bit, returns all temporary resources clean, and carries exact basis-equivalence evidence.

## Motivation

Wheeler currently exposes logical quantum registers and coherent lifting, but a raw register does not tell the type checker what its bits mean. A programmer may already know that five qubits encode a schedule, an enum, or a protocol state while the compiler sees only five positions.

That gap causes several problems.

- Generic quantum code falls back to manual register offsets.
- Record and enum invariants do not cross the coherent boundary.
- The compiler cannot relate a measured result to the source type without a separate decoder.
- Libraries cannot state that an operation acts on `T` rather than on an arbitrary bit layout.
- Proofs and resource reports cannot bind one source type to one basis mapping.

A second gap appears when a programmer writes an ordinary predicate:

```wheeler
pure boolean unsafe(borrow Schedule schedule) {
  ...
}
```

The function is not reversible. Many schedules may return the same Boolean. Adding `coherent` to its name would not repair the lost information.

Quantum search and several other algorithms still need a coherent operation based on that predicate. The correct operation retains the input and toggles a separate result bit:

```text
(schedule, marked)
    ->
(schedule, marked XOR unsafe(schedule))
```

This proposal gives that transformation a direct, checked meaning. The conversion is explicit because its cost, cleanup, and proof duties are different from an ordinary call.

## Use cases

### Typed search candidate

A search routine owns a value whose logical type is `Schedule`, not an untyped five-qubit register:

```wheeler
qvalue<Schedule> candidate;
qvalue<boolean> marked;
```

The compiler knows the width, basis order, ownership, valid values, and result type before lowering.

### Predicate embedding

The programmer writes and tests one normal predicate:

```wheeler
pure boolean unsafe(borrow Schedule schedule) {
  WarehouseState state = initialState();

  for (long i = 0; i < schedule.commands.length; i += 1)
    limit schedule.commands.length
  {
    state = step(state, schedule.commands[i]);
  }

  return state.robotA.inside && state.robotB.inside;
}
```

Quantum code requests an explicit marking operation:

```wheeler
PredicateOracle<Schedule> unsafeOracle = oracle(unsafe);
unsafeOracle.apply(borrow mut candidate, borrow mut marked);
```

The compiler checks the predicate, constructs a reversible embedding, and records its relationship to the classical body.

### Classical and coherent parity

The same predicate remains callable on ordinary values. A finite proof fixture can compare all classical inputs with the generated basis-state action.

### Typed preparation and measurement

A classical value may prepare a typed coherent value:

```wheeler
prepare(candidate, knownSchedule);
```

Measurement consumes or transitions the coherent owner and returns an ordinary `Schedule` with the same canonical type identity:

```wheeler
Schedule observed = measure(candidate);
```

### Rejection before target planning

A predicate that reads the clock, allocates without a static cleanup plan, may trap on an admitted value, or has an unbounded loop fails during coherent embedding. Wheeler does not submit a target job and hope the provider rejects it later.

## Goals

- Add one source-level type for a coherent value of finite Wheeler type `T`.
- Bind each coherent value to one canonical finite encoding and width.
- Reuse WIP-0028 affine ownership and must-consume rules.
- Define typed basis preparation, coherent application, measurement, reset, and release transitions.
- Define `oracle(predicate)` as an explicit Boolean XOR embedding.
- Preserve the source predicate as ordinary callable code.
- Require total, bounded, effect-free behavior on every admitted input.
- Generate exact basis-action and clean-workspace obligations.
- Record encoding, embedding, callable, resource, and proof identities in canonical Wheeler IR.
- Keep physical qubit placement and provider objects outside source meaning.
- Give diagnostics in source terms such as input type, effect, trap, loop, or temporary value.

## Non-goals

- Infer that every pure function is reversible.
- Treat a predicate as a permutation merely because its domain is finite.
- Add arbitrary amplitude encodings, analog encodings, or state-preparation algorithms.
- Standardize QRAM or quantum-accessible heap memory.
- Admit non-power-of-two coherent value spaces in the first profile.
- Let packages forge coherent encoding evidence through an ordinary type-class instance.
- Expose physical qubit indices, provider registers, or target-native layouts.
- Permit ordinary equality, hashing, printing, serialization, or cloning of a live coherent value.
- Define quantum search, optimization, or sampling APIs. Those belong in libraries.
- Hide measurement, reset, target submission, or replay behind a normal value conversion.

## Terms and semantic model

### Finite logical type

A **finite logical type** is a closed Wheeler type with a certified finite cardinality and canonical value identity.

At first, the coherent profile accepts only types whose cardinality is exactly `2^width` for one bounded nonnegative `width`. Every bit pattern then names one value. There are no invalid padding states.

Examples may include:

- `boolean`;
- `BitInt<N>`;
- power-of-two enums;
- fixed arrays and records whose admitted encodings compose to a power-of-two cardinality;
- closed generic specializations with resolved finite evidence.

A classical protocol codec does not define the coherent basis. Wire numbers, enum ordinals, memory layout, and provider display order are not basis authority.

### Coherent encoding

A **coherent encoding** is certified compile-time evidence containing:

```text
CoherentEncodingDescriptor {
    logical_type_id
    width
    cardinality
    canonical_basis_order
    encode_identity
    decode_identity
    proof_identity
    compiler_profile
}
```

The evidence establishes:

```text
decode(encode(value)) == value
cardinality(T) == 2^width
encode is a bijection between T and BitInt<width>
```

The first profile may derive evidence structurally for compiler-owned scalar and aggregate forms. User-defined certified evidence follows WIP-0030 admission rules and WIP-0011 proof rules.

### Typed coherent value

A **typed coherent value** is an affine logical quantum resource:

```text
qvalue<T>
```

Its logical basis is `T`. Its physical representation is owned by a `Qreg` or target region, but raw provider identity is not observable.

A live `qvalue<T>`:

- implements neither `Copy` nor ordinary `Drop`;
- cannot be compared, hashed, printed, serialized, or branched on classically;
- may move, split only through admitted typed projections, borrow under quantum ownership rules, participate in coherent operations, be measured, be reset, or be returned under its contract;
- cannot survive an ordinary remote job boundary unless a target-session capability explicitly permits it.

### Predicate oracle

A **predicate oracle** is a compiler-produced coherent callable for one ordinary predicate:

```text
f: T -> boolean
```

Its basis action is:

```text
O_f(x, b) = (x, b XOR f(x))
```

`O_f` is a permutation even when `f` is not injective. The input remains present, and the result bit retains enough information for exact inversion.

The proposal uses `PredicateOracle<T>` as an illustrative sealed callable view. WIP-0005 and WIP-0006 own final surface punctuation. WIP-0031 remains authoritative for callable descriptors.

### Basis preparation

**Basis preparation** creates a coherent owner from a known classical value under the `prepare` effect:

```text
classical T --prepare--> qvalue<T>
```

Preparation is not an ordinary allocation or reversible function call.

### Basis measurement

**Basis measurement** consumes or transitions a coherent owner and creates a classical observation:

```text
qvalue<T> --measure--> Observation<T>
```

A convenience form may return `T` when the surrounding result type retains the required observation provenance. The semantic IR still records measurement, target, basis, schema, and ownership transition.

### Reset

**Reset** consumes unknown coherent state and establishes a known basis state through the explicit `reset` effect. It is not inverse execution or uncomputation.

## Ownership and boundaries

The language owns the `qvalue<T>` source category, affine use, preparation, measurement, reset, and callable application forms.

The type checker owns finite-type resolution, coherent encoding selection, width normalization, ownership, and static callable compatibility.

The compiler owns oracle construction, reversible lowering, temporary workspace planning, source mapping, and resource inference.

The proof system owns exact encoding, basis-action, permutation, cleanup, and resource certificates.

The bytecode verifier owns descriptor consistency, affine resource use, operation legality, result width, and evidence references.

The runtime owns preparation, simulator execution, target-region materialization, measurement result validation, and owner transitions.

Target adapters own physical layout and provider translation. They may not change the logical type, basis order, or predicate meaning.

Packages may supply ordinary predicates and certified encoding evidence under WIP-0030. A package cannot create a `qvalue<T>` from bytes, cast a `Qreg` to an unrelated `T`, or declare an unchecked instance that grants coherent authority.

## Design

### Source shape

The first profile accepts declarations equivalent to:

```wheeler
qvalue<Schedule> candidate;
qvalue<boolean> marked;
```

`qvalue<T>` is compiler-owned syntax or a sealed built-in type. It is not an ordinary generic class whose constructor can be called from user code.

A `qvalue<T>` declaration is legal only when one exact `CoherentEncoding<T>` is selected before emission.

### Preparation

Preparation uses call-shaped syntax because it consumes value expressions and creates no nested source region:

```wheeler
prepare(candidate, knownSchedule);
```

The destination must be uninitialized or already in the exact state required by the operation contract. The source classical value remains available unless its ordinary ownership mode requires a move.

Preparation records:

- coherent type identity;
- encoding identity;
- basis value or canonical parameter identity;
- destination owner identity;
- target or semantic-region identity;
- source location.

A target may implement basis preparation through direct initialization, X gates, state loading, or another exact lowering. The source result is the same.

### Measurement

Measurement is explicit:

```wheeler
Schedule observed = measure(candidate);
```

The compiler lowers this to a typed observation transition. The old coherent identity becomes unavailable unless the target contract specifies a different consuming transition.

Measurement validates:

- register width;
- declared basis;
- little-endian or typed layout mapping;
- result schema;
- target and job identity;
- admitted value decoding.

The first profile has no invalid bit patterns because all coherent types use a full power-of-two basis.

### Coherent callable application

A `CoherentFunction<T, T>` may act on a `qvalue<T>` when its exact encoding evidence matches:

```wheeler
candidate.apply(permutation);
```

The actual spelling may remain call-shaped:

```wheeler
apply(permutation, borrow mut candidate);
```

The selected callable must be statically closed. Runtime provider-name dispatch, runtime type-class selection, and dynamic closure dispatch are forbidden in the emitted quantum region.

### Explicit predicate embedding

The source form is:

```wheeler
PredicateOracle<Schedule> unsafeOracle = oracle(unsafe);
```

`oracle` is a compiler intrinsic. It receives one resolved static callable and returns one sealed coherent callable descriptor.

The accepted predicate must satisfy all of these conditions:

1. The input type has accepted coherent encoding evidence.
2. The result type is `boolean`.
3. The ordinary effect row is empty.
4. The trap contract proves total behavior for every admitted input.
5. Every loop and recursive path has a finite static bound.
6. Every reachable call is deterministic and semantically available to the oracle builder.
7. Temporary storage has a static bound.
8. Generated cleanup can return every temporary coherent resource to its required clean state.
9. Generic, type-class, and callable choices resolve before oracle construction.

A predicate may use ordinary non-injective operations internally. The compiler does not pretend those operations are reversible. It creates a reversible embedding through one of these admitted strategies:

- direct reversible lowering when the body already retains the needed information;
- compute, copy the Boolean result into the marked bit, then apply the generated inverse;
- exact finite-table synthesis under hard domain and artifact limits;
- a separately certified implementation with matching basis semantics.

The chosen strategy is derived implementation data. The semantic oracle identity remains tied to the source predicate and the standard XOR embedding rule.

### Oracle application

Applying the oracle requires two disjoint coherent places:

```wheeler
unsafeOracle.apply(
    borrow mut candidate,
    borrow mut marked
);
```

The frame relation is:

```text
candidate' == candidate
marked' == marked XOR unsafe(candidate)
```

The source ownership mode may remain exclusive because coherent use can entangle the two resources even when the logical basis value of `candidate` is preserved.

The callable descriptor records that `candidate` is frame-preserved. That fact supports later structured uncomputation and controlled composition.

### Classical interpretation

The generated oracle has a classical basis interpretation for testing and proof elaboration:

```text
applyClassically(x, b) = (x, b XOR f(x))
```

This does not make the live `qvalue<T>` classically readable. It gives the verifier and finite proof tools one exact relation over ordinary values.

### Generic predicates

A generic predicate can be embedded only after monomorphization:

```wheeler
public pure boolean contains<T, const long N>(
    borrow Array<T, N> values,
    borrow T needle
) where T: Eq + CoherentEncoding {
    ...
}
```

Each closed oracle identity includes:

- generic declaration identity;
- concrete type and const arguments;
- selected class evidence;
- associated widths and reductions;
- source predicate identity;
- oracle embedding profile.

No unresolved type, width, effect, or class dictionary reaches quantum IR.

### Type projections

The first profile treats `qvalue<T>` as one logical owner. It does not allow arbitrary field projection or indexing into a coherent aggregate.

Operations over records and arrays are written as coherent callables over the whole type. A later proposal may add certified disjoint projections when layout, ownership, and recomposition are fully defined.

This restriction avoids turning source record layout into public physical qubit offsets.

### Encoding changes

Changing a public coherent encoding is a semantic compatibility change. It changes basis identity, generated oracle identity, circuit identity, certificates, and target artifacts.

A package update cannot silently choose a different basis order for an existing locked type instance.

## Reversibility and history

A `qvalue<T>` is not restored through WIP-0001 machine history. It participates in a coherent permutation, unitary operation, measurement, reset, or target transition.

The predicate oracle is self-inverse:

```text
O_f(O_f(x, b)) == (x, b)
```

because the same Boolean is XORed twice.

The compiler may use temporary classical planning values and temporary coherent workspace while constructing or executing the oracle. Coherent workspace must return clean before the operation exits. Runtime undo logs are forbidden inside the oracle.

Preparation, measurement, and reset remain separate explicit nonunitary transitions. Replaying a recorded measurement does not recreate the old `qvalue<T>`.

A failed preparation or measurement publishes no partial typed coherent owner transition. A target failure remains a target or workflow failure, not a partially created source value.

## Concurrency and determinism

Encoding selection, basis order, oracle identity, monomorphization, finite-table construction, proof obligations, and diagnostics are deterministic for the same locked package graph and compiler profile.

Parallel compiler work reduces in canonical type and callable identity order.

Independent target jobs may execute concurrently under WIP-0004. Result delivery remains correlated by submission identity. Arrival order cannot change the basis mapping or typed decoding.

Hardware measurement is nondeterministic. That nondeterminism begins at the explicit measurement boundary. It never weakens Wheeler's exact oracle semantics.

## Quantum and proof implications

For each accepted encoding, Wheeler generates or checks these obligations:

```text
forall value: T:
    decode(encode(value)) == value

forall bits: BitInt<width>:
    encode(decode(bits)) == bits
```

For each accepted predicate oracle, Wheeler generates or checks:

```text
forall x: T, b: boolean:
    oracle(x, b) == (x, b XOR predicate(x))

oracle >> oracle == identity

all borrowed ancillas return clean

input frame is preserved
```

The exact proof may be compositional, finite exhaustive, or supplied through accepted certified evidence. The certificate binds the closed predicate, encoding, embedding rule, resource profile, semantic region, and compiler profile.

A simulator comparison or hardware sample is test or experiment evidence. It cannot replace the exact basis-action theorem.

The first profile deliberately excludes invalid basis states. A later non-power-of-two proposal must define valid-subspace preservation, behavior on unused bit patterns, leakage, and complete unitary extension before such a value can cross a coherent boundary.

## Bytecode, persistence, and compatibility

Canonical `.wbc` adds required feature metadata for typed coherent values and explicit predicate embeddings within the existing type, callable, quantum-region, proof, and manifest sections.

A coherent value descriptor records:

```text
CoherentValueDescriptor {
    logical_type_id
    encoding_id
    width
    cardinality
    ownership_mode
    required_features
}
```

An oracle descriptor records:

```text
PredicateOracleDescriptor {
    oracle_id
    source_callable_id
    input_type_id
    encoding_id
    embedding_kind = XOR_BOOLEAN
    coherent_body_id
    inverse_id
    resource_bound_id
    certificate_ids
}
```

Physical qubit positions, provider register IDs, credentials, and job handles are not canonical fields.

Existing `.wbc` artifacts without these required features remain valid. A loader that does not recognize a required coherent-value or oracle feature rejects the artifact before execution. It does not reinterpret the data as a raw `Qreg`.

Persisted hybrid observations use ordinary typed result schemas and WIP-0004 provenance. Live coherent owners are never serialized as ordinary values.

## Safety, limits, and failures

Limits cover:

- coherent type width;
- cardinality evaluation;
- encoding proof size;
- predicate source size;
- loop and recursion bounds;
- finite-table entries;
- generated operations;
- ancilla count;
- circuit depth;
- compiler time and memory;
- proof obligations and certificate bytes;
- diagnostics.

The first stable diagnostic families should include:

```text
WQVL001 no coherent encoding for type
WQVL002 coherent cardinality is not a power of two
WQVL003 coherent width exceeds profile limit
WQVL004 illegal copy, comparison, serialization, or drop
WQVL005 coherent owner used after measurement or move
WQVL006 encoding evidence is ambiguous or uncertified

WORB001 oracle requires one total Boolean predicate
WORB002 predicate has a prohibited effect
WORB003 predicate may trap for an admitted input
WORB004 predicate has no finite execution bound
WORB005 generated workspace cannot be returned clean
WORB006 oracle resource limit exceeded
WORB007 source and generated basis behavior are not equivalent
WORB008 dynamic dispatch remains after specialization
```

A failed `oracle(predicate)` conversion emits no partial coherent body, callable descriptor, certificate, or target artifact.

## Migration and deletion

1. Add canonical coherent-encoding descriptors and structural derivation for accepted built-in finite types.
2. Add verifier-readable `qvalue<T>` descriptors and affine owner transitions.
3. Add typed preparation, measurement, reset, and simulator behavior.
4. Add static coherent callable application over one whole typed value.
5. Add the explicit Boolean XOR oracle transformer and closed callable descriptor.
6. Add basis-equivalence, inverse, frame, cleanup, and resource proof obligations.
7. Add source parser, Tree-sitter, formatter, documentation, and stable diagnostics.
8. Add generic and type-class specialization fixtures.
9. Migrate coherent examples from manual register-width assumptions where the typed form is accepted.
10. Delete temporary typed-register wrappers, unchecked width annotations, duplicate decoders, and any prototype that treats a provider register as the logical type.

## Progress

- [ ] Coherent encoding descriptor and admission rules are accepted.
- [ ] `qvalue<T>` ownership and bytecode descriptors are accepted.
- [ ] Typed preparation and measurement execute in the semantic simulator.
- [ ] Closed coherent callables apply to typed values.
- [ ] `oracle(predicate)` constructs a Boolean XOR embedding.
- [ ] Generated oracle workspaces return clean.
- [ ] Basis-equivalence certificates check.
- [ ] Generic closed predicates specialize before embedding.
- [ ] Current examples use the accepted source profile.
- [ ] Temporary typed-register prototypes are deleted.

## Testing and acceptance

- [ ] `qvalue<boolean>`, `qvalue<BitInt<N>>`, and one finite aggregate prepare, execute, and measure correctly.
- [ ] Copy, ordinary equality, hashing, printing, serialization, and implicit drop of live coherent values fail statically.
- [ ] Use after move, measurement, reset transition, or release fails verification.
- [ ] Encoding identities are deterministic under source, import, allocation, and worker-order changes.
- [ ] A normal predicate remains callable as ordinary classical code.
- [ ] The generated oracle preserves its input and toggles the result bit for every basis value in a finite acceptance domain.
- [ ] Applying the oracle twice restores both values exactly.
- [ ] Every generated ancilla returns clean.
- [ ] Effects, traps, unbounded loops, dynamic dispatch, and excessive resources reject oracle construction before publication.
- [ ] Generic, associated-width, and class-evidence choices are closed before coherent lowering.
- [ ] The VM basis interpreter, semantic simulator, proof kernel, and generated circuit agree.
- [ ] Existing raw `qreg` programs remain valid and do not gain an implicit logical type.
- [ ] Current reference docs describe the feature only after implementation.

## Alternatives

### Treat every finite pure function as coherent

Rejected. Finiteness does not make a many-to-one function reversible. The output embedding and retained input must be explicit.

### Require users to write a second oracle by hand

Rejected as the only path. It duplicates business logic and weakens the relationship between classical verification and quantum execution. Wheeler may still accept a certified custom implementation when resource needs justify one.

### Encode logical values as raw register offsets

Rejected. It exposes representation details, blocks generic code, and disconnects measurement from the source type.

### Use protocol encoders as coherent encodings

Rejected. Wire identity and coherent basis identity have different compatibility and proof requirements.

### Allow invalid padding states immediately

Rejected for the first profile. A correct design needs total behavior over the full Hilbert space, valid-subspace preservation, leakage rules, and proof support.

### Make `qvalue<T>` an ordinary standard-library generic

Rejected. Construction, ownership, measurement, coherent application, and verification need compiler and IR authority that an ordinary class cannot grant.

### Infer oracle conversion from call context

Rejected. The transformation has distinct cost and proof duties. An explicit form gives diagnostics a stable source location and keeps ordinary calls ordinary.

## Open questions

- Should the first source spelling be `qvalue<T>`, `QValue<T>`, or another form consistent with the final `qreg` spelling? **Owner:** language and formatter maintainers. **Decide by:** before Review.
- Should `PredicateOracle<T>` be visible source syntax or a documentation alias for a closed WIP-0031 callable signature? **Owner:** language and type-system maintainers. **Decide by:** before parser implementation.
- Which aggregate forms receive structural coherent encoding in the first profile? **Owner:** type-system, verifier, and proof maintainers. **Decide by:** before acceptance fixtures freeze.
- Which exact finite-table limit is small enough for deterministic compilation and large enough for conformance tests? **Owner:** compiler and proof maintainers. **Decide by:** before implementation.
- Does basis measurement return `T` directly in source while retaining hidden typed observation metadata, or return an explicit `Observation<T>`? **Owner:** language, runtime, and hybrid maintainers. **Decide by:** before measurement syntax freeze.

## References

- [WIP-0002](WIP-0002-unified-classical-quantum-semantics.md)
- [WIP-0005](WIP-0005-wheeler-source-language.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0013](WIP-0013-typed-frames-control-flow-and-storage.md)
- [WIP-0017](WIP-0017-compile-time-constants-and-finite-enums.md)
- [WIP-0028](WIP-0028-deterministic-ownership-borrowing-and-regions.md)
- [WIP-0029](WIP-0029-parametric-polymorphism-and-bounded-specialization.md)
- [WIP-0030](WIP-0030-coherent-type-classes-and-associated-types.md)
- [WIP-0031](WIP-0031-reversible-quantum-and-effect-polymorphism.md)
