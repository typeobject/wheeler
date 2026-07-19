# WIP-0031: Effect-, reversible-, coherent-, and unitary-polymorphic callables

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler language, type-system, compiler, bytecode, verifier, quantum, proof, runtime, and library maintainers |
| Created | 2026-07-19 |
| Updated | 2026-07-19 |
| Area | Effects, higher-order calls, reversibility, coherent lifting, unitary operations, generics |
| Depends on | WIP-0001, WIP-0002, WIP-0004, WIP-0005, WIP-0011, WIP-0021, WIP-0028, WIP-0029, WIP-0030 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler supports generic abstraction over callable behavior without collapsing ordinary functions, reversible functions, coherent permutations, unitary operations, measurements, and host effects into one universal function type.

A callable signature records parameter/result types and ownership modes, effect row, trap contract, callable kind, inverse/adjoint/controlled availability, capture ownership, and static resource bounds. Initial callable kinds are:

```text
Function
ReversibleFunction
CoherentFunction
UnitaryOperation
```

Hybrid and asynchronous work remains ordinary effectful callable code using WIP-0004 lifecycle values. It does not become unitary because a queue eventually returned something.

Effect variables support bounded row-like propagation. A higher-order wrapper may expose the effects of an argument but cannot erase them or forge the required capabilities.

Generic reversible, coherent, and unitary code resolves all WIP-0029 arguments, WIP-0030 evidence, associated constants, callable specializations, and quantum shapes before inverse generation or semantic quantum lowering. The first coherent/unitary profile has no runtime class or callable dispatch.

Accepted generic transformations satisfy canonical commutation laws:

```text
instantiate(inverse(g), arguments)
    == inverse(instantiate(g, arguments))

instantiate(adjoint(u), arguments)
    == adjoint(instantiate(u, arguments))
```

A name or annotation cannot confer reversible, coherent, or unitary authority. Bodies, effects, ownership, finite encoding, and required WIP-0011 evidence must agree.

## Motivation

Wheeler already distinguishes ordinary forward calls, generated inverses, VM rewind, coherent lifting, unitary application, generated adjoints, measurement, replay, retry, and host/target effects. Generic programming must preserve the distinctions rather than putting them in a bag marked `Function`.

A Java-style `Function<A, B>` omits moves and borrows, allocation/history/measurement/host effects, inverse or adjoint identity, controlled support, and quantum resource bounds. Dynamic trait objects defer choices the compiler needs before verified `.wbc`, inverse generation, and quantum-region emission.

Duplicating every algorithm for ordinary, reversible, coherent, and unitary calls is no better. The library needs safe reusable composition, repetition, apply-to-each, effect propagation, caller-owned clean workspace, generic circuits, and adjoint/controlled transformations.

Q# usefully places adjoint and controlled characteristics in operation types. Wheeler needs a broader contract because classical inverse, coherent lifting, VM history, affine ownership, proof evidence, and hybrid effects are separate things.

## Representative source

### Effect-polymorphic map

```wheeler
public Vec<B> map<A, B, effect E>(
  Vec<A> values,
  Function<A, B, E> transform,
  borrow mut Allocator allocator
) effects E + allocate {
  ...
}
```

The caller sees both `transform` effects and allocation. The callable type does not grant an allocator capability.

### Reversible values and composition

```wheeler
public ReversibleFunction<A, C> compose<A, B, C>(
  ReversibleFunction<A, B> first,
  ReversibleFunction<B, C> second
) {
  ...
}

public rev void swap<T>(borrow mut T left, borrow mut T right) {
  ...
}
```

The composed inverse invokes `second.inverse` and then `first.inverse`. Generic swap needs disjoint exclusive loans, not `Copy`.

### Coherent and unitary operations

```wheeler
public coherent rev void repeatPermutation<T, F, const long N>(
  borrow mut T value,
  F operation
) where F: CoherentAction<T>
 where N >= 0 {
  ...
}

public unitary void applyEach<Target, Op, const long N>(
  borrow mut Qreg<N> register,
  Op operation
) where Op: UnitaryElementOperation<Target> {
  ...
}

UnitaryOperation<Shape> inverse = adjoint(operation);
```

All evidence, shape, adjoint, and controlled behavior closes before lowering.

### Capturing closure

A closure capturing a move-only owner is move-only. One capturing an exclusive loan cannot outlive the origin. One capturing a must-consume value becomes must-consume. A unitary closure may capture finite immutable classical parameters but not a mutable host capability.

## Goals

- Define callable kinds separately from nominal value classes.
- Record ownership, borrows, origins, effects, traps, captures, characteristics, and bounds in signatures.
- Support ordinary higher-order functions and WIP-0028-safe closures.
- Support bounded effect variables, union, subset constraints, and honest propagation.
- Define reversible callable values with exact inverse evidence and composition.
- Define coherent callable values with finite permutation evidence.
- Define unitary callable values with adjoint and optional controlled evidence.
- Resolve every generic/evidence choice statically before coherent or unitary lowering.
- Preserve inverse/adjoint behavior through WIP-0029 specialization.
- Expose allocation, release, history, measurement, host, target, workflow, and failure honestly.
- Prevent class wrappers or effect variables from masking effects or granting capabilities.
- Bind callable/effect/resource/proof metadata into `.wbc` and package compatibility.
- Keep runtime dispatch out of first-profile coherent/unitary code.
- Emit bounded diagnostics explaining exactly which characteristic or effect failed.

## Non-goals

This WIP does not define one universal callable, infer semantic authority from provider behavior, permit dynamic dispatch in quantum regions, trust named class instances without evidence, hide measurement/allocation/target/history/host effects, equate rewind or compensation with inverse, treat cleanup callbacks as inverse evidence, admit arbitrary host callbacks in semantic code, add unrestricted effect handlers, let a `Monad` erase effects, violate capture ownership, adjoint measurement, reflect on callable characteristics at runtime, leave quantum bounds unresolved, or require heap allocation for every higher-order call.

## Callable model

### Kinds

A **Function** performs ordinary forward execution under an effect row.

A **ReversibleFunction** has a checked language-level inverse relation. It is not WIP-0001 rewind.

A **CoherentFunction** is a reversible callable whose closed finite behavior is an exact WIP-0002 permutation suitable for coherent lifting.

A **UnitaryOperation** lowers to a verified backend-neutral quantum region and has an adjoint.

These are semantic callable kinds, not ordinary classes. WIP-0030 classes may constrain values that provide operations, but privileged conversion to a callable kind requires admitted evidence.

### Canonical signature

```text
CallableSignature {
    kind
    generic_parameters
    parameter_types_and_modes
    result_types_and_modes
    effect_row
    trap_contract
    capture_mode
    inverse_descriptor
    coherent_descriptor
    adjoint_descriptor
    controlled_descriptor
    resource_bound_descriptor
}
```

Unused descriptors are absent. Callable equality, if exposed, uses declaration/instance identity rather than a code pointer.

Illustrative source may use:

```text
Function<A, B, E>
ReversibleFunction<A, B>
CoherentFunction<A, B>
UnitaryOperation<Shape>
```

or a future arrow notation. Declarations retain `rev`, `coherent rev`, and `unitary`. WIP-0005/WIP-0006 choose punctuation once semantics and parser ambiguity are settled.

A declaration becomes a callable value only after overload, generic, ownership, effect, and characteristic resolution. Partial application creates a closure. In coherent/unitary code it must be statically eliminated and may capture only permitted finite immutable parameters.

## Effects

### Sets and rows

An **effect set** is a canonical finite set of labels. An **effect variable** ranges over sets under explicit bounds. An **effect row** is a set expression containing zero or more variables.

The initial namespace includes at least:

```text
allocate    release     history     state       trap
prepare     measure     reset       target      event
file        network     process     clock       random
ffi         blocking    async
```

`target` includes submission/materialization, not ownership of credentials or target capability. Exact parameter payloads and effect ownership are frozen with the first executable descriptor profile.

`rev`, `coherent`, and `unitary` are callable characteristics, not effect labels. `pure` means an empty ordinary effect row; the final trap model is explicit in the separate trap contract. WIP-0002 preparation, measurement, reset, and target boundaries map to these labels.

### Propagation

Calling operations forms canonical set union in source evaluation order. For example:

```wheeler
public B apply<A, B, effect E>(
  A value,
  Function<A, B, E> operation
) effects E {
  return operation(value);
}
```

The body performs no effects outside `E`. Bounds may require `E subset deterministic`, exclude `measure`, or exclude named host effects. Named sets are preferred to arbitrary Boolean effect formulas.

A public callable exposes its complete row; broadening it may be a compatibility break. A wrapper cannot declare fewer effects than its body. Transforming or handling an effect requires a separately specified checked boundary, not a smaller annotation.

An effect label grants no capability. A `file` row without a file capability remains unable to open anything, which is the correct amount of magic.

## Ordinary higher-order calls and closures

An ordinary higher-order function may borrow, move, or—when structurally `Copy`—copy a closure; receive an explicit WIP-0030 strategy; or refer to a static declaration. Ordinary classical execution may use a verified closure environment plus callable-table identity. Indirect call targets are exact descriptors, never native addresses.

Capture ownership follows WIP-0028:

- all-copy captures may make a closure `Copy`;
- an owned move-only capture makes it move-only;
- a borrow capture binds closure lifetime to origin;
- an exclusive capture suspends competing access;
- a must-consume capture makes the closure must-consume;
- closure drop requires every capture to be droppable;
- external resource obligations cannot hide in a droppable environment.

## Reversible callables

A `ReversibleFunction<A, B>` carries forward/inverse identities and a checked relation. Simple value functions have `forward: A -> B` and `inverse: B -> A`; stateful descriptors additionally record owner/frame pre- and postconditions.

A generic `rev` body checks under abstract constraints. Every called class method requires certified reversible evidence. Inverse generation before and after monomorphization must agree:

```text
Monomorph(inverse(G), args, evidence)
==
inverse(Monomorph(G, args, evidence))
```

Composition reverses order:

```text
inverse(second ∘ first) = inverse(first) ∘ inverse(second)
```

A reversible signature names preconditions and trap exclusions; arbitrary trapping calls are not presumed reversible. Legal implementation tools include moves, swaps, loans, clean caller-owned workspace, and certified reversible collections/allocators. It may not discard information, close external resources, or allocate and abandon storage.

## Coherent callables

A `CoherentFunction<A, B>` is a closed exact finite permutation accepted by WIP-0002. Every type has certified cardinality, basis mapping, width, ownership, and validity evidence.

The first profile follows WIP-0017 and accepts exact power-of-two bases with no invalid bit patterns. A later subspace profile may admit non-power-of-two domains only with a complete valid-subspace permutation, leakage behavior, and target/lowering contract. Padding states never receive “whatever the backend did” semantics.

Allowed operations are coherent primitives, certified static calls, finite control, and clean workspace. Disallowed behavior includes unmodeled allocation/release, history, measurement, host/target effects, clock/random, FFI, admissible-input traps, runtime dispatch, and shared mutable state.

Generic coherent code closes finite encoding, operation evidence, ownership, total basis behavior, and bounds before lowering. Every called class method is exact certified evidence.

## Unitary operations

A `UnitaryOperation<Shape>` ordinarily takes disjoint exclusive quantum loans and returns no classical observation. Immutable classical parameters may configure gates.

Every unitary operation has an adjoint, generated structurally, supplied as a declared specialization, or checked from evidence:

```text
adjoint(adjoint(U)) == U
```

Generic adjoint generation commutes with monomorphization:

```text
Monomorph(adjoint(G), args, evidence)
==
adjoint(Monomorph(G, args, evidence))
```

A declared controlled specialization has exact identity and resource contract. When both characteristics exist, accepted evidence establishes:

```text
controlled(adjoint(U))
==
adjoint(controlled(U))
```

Descriptors bind shape, qubit/ancilla count, clean-ancilla obligations, gate count, depth bound, zero measurement count, and target capability requirements. Generic associated constants and proofs may contribute bounds.

Runtime selection among unitary bodies is excluded inside semantic region IR. Ordinary classical planning may select one concrete operation before circuit construction; the selected identity enters plan and circuit identity.

Generic algorithms include apply-to-each, repeat, compose, conjugation, controlled application, register permutation, QFT, and finite arithmetic oracles. Provider qubit objects and native gate handles remain unavailable to source.

## Measurement, workflows, and replay

Measurement is not unitary and cannot hide behind `UnitaryOperation`. Ordinary/hybrid callables may measure under explicit effects and return provenance-bearing classical results.

WIP-0004 target submission, event recording, polling, acceptance, replay, and retry remain lifecycle operations. Effect variables preserve their labels. Replay-only code rejects a callable row that may perform fresh `target`, `ffi`, or other prohibited host effects.

## Class evidence and conversion

WIP-0030 may define classes such as:

```text
Callable<F, A, B, E>
ReversibleAction<F, A>
CoherentAction<F, A>
UnitaryAction<F, Shape>
Adjointable<F>
Controllable<F>
```

Operational instances help typecheck ordinary source. Certified instances reference exact inverse, finite-permutation, adjoint, controlled, effect, and ownership evidence. Names alone grant nothing.

Explicit strategy values enter coherent/unitary code only when statically known, immutable, certified, and erased or monomorphized before region lowering. Runtime-selected evidence cannot change a verified circuit.

The initial profile avoids broad callable subtyping. Safe explicit views may widen an effect allowance, view reversible/coherent as ordinary, or view coherent as reversible. Reverse conversions require evidence. Viewing a unitary as a classical circuit builder is an explicit conversion with builder effects.

## Proof and package identity

WIP-0011 propositions may establish inverse round trips, finite permutations, adjoint/controlled laws, effect subsets, frame conditions, clean workspace, bounds, and specialization commutation. Certificates bind generic declaration, closed instantiation, selected evidence, effect row, semantic region, and compiler profile. One monomorph proof does not prove all instantiations without a valid parametric proof.

Public higher-order APIs record callable kind, ownership, effects, traps, generic/class constraints, characteristics, bounds, and evidence. Changes may be package compatibility breaks. Runtime closures are not canonically serializable unless a separate schema admits the exact callable and capture types; function pointers and addresses never enter package identity.

## Reversible IR, bytecode, and native lowering

Callables are typed edges in Wheeler's reversible IR. An ordinary edge declares forward effects plus inverse/log/barrier class; a reversible edge binds an exact inverse relation; a coherent edge binds a complete finite permutation; a unitary edge binds a semantic quantum region and adjoint. Measurement, reset, target work, replay, and compensation remain explicit nonunitary edges. No lowering pass may flatten these into an untyped call and reconstruct semantics from a method name later.

Canonical `.wbc` callable metadata records kind, ownership, effect row, direct/indirect target descriptor, closure layout, inverse/adjoint/controlled IDs, evidence, bounds, and generic relation. Indirect calls use bounded verified callable tables.

The verifier checks effect compatibility and characteristics at every call. First-profile coherent/unitary bodies contain only direct statically resolved semantic operations. Forged effect rows or characteristic IDs fail before execution.

Native lowering preserves the same descriptors. WIP-0025 foreign callables are ordinary effectful calls unless a separately certified deterministic build-tool profile says otherwise. A native function pointer cannot cast itself into reversibility or unitarity. Embedding APIs export concrete closed callables only.

## Determinism, limits, and failures

Callable, row, characteristic, evidence, closure-layout, and specialization identities use canonical encodings. Rows are ordered canonically but semantically set-like. Parallel lowering/proof checking reduces by callable and instantiation identity. Runtime address and hash order are excluded.

Limits cover parameters/results, labels/variables, captures, indirect targets, inverse/adjoint/controlled variants, generic callable instances, proof obligations, resource expressions, diagnostics, memory, and total inference work.

Ambiguous conversion, unresolved variable, masking, invalid capture, missing inverse, incoherent evidence, nonfinite coherent type, invalid adjoint/control, measurement in unitary code, dynamic quantum dispatch, resource overflow, malformed metadata, and limit exhaustion fail before publication. No partial callable table or circuit is emitted.

## I/O effects and indexed actions

WIP-0032 operations carry explicit host or target effects and suspension behavior. Higher-order I/O may propagate effect variables, but it cannot erase capability use, cancellation, uncertainty, persistence stages, measurement, or target submission.

An optional `IoAction<Effects, Result>` or `QuantumAction<Input, Output, Effects, Result>` is a library and semantic view. Direct request/scope style remains authoritative. Quantum state is not a conventional duplicable state monad, no matter how charming the notation looks on a whiteboard.

## Migration and deletion

1. Define canonical effect rows and callable descriptors.
2. Add ordinary function values and WIP-0028-owned closures.
3. Add effect variables and higher-order propagation.
4. Add reversible callable values and composition.
5. Add WIP-0030 certified callable evidence.
6. Add generic inverse/instantiation commutation fixtures.
7. Add coherent callable types and exact finite evidence.
8. Add unitary operation values, adjoint, and controlled characteristics.
9. Add generic shape/operation quantum algorithms.
10. Add proof and resource certificates.
11. Add native lowering and package metadata.
12. Delete duplicate ordinary/reversible/unitary helper families, runtime characteristic strings, dynamic quantum prototypes, and compatibility readers for replaced schemas.

## Progress

- [ ] Callable signature and effect-row model is accepted.
- [ ] Ordinary function values and closures execute.
- [ ] Closure ownership follows captures.
- [ ] Effect variables propagate through higher-order functions.
- [ ] Reversible callable values and composition execute.
- [ ] Generic inverse commutation passes.
- [ ] Coherent callable evidence and lowering execute.
- [ ] Unitary operation values and adjoints execute.
- [ ] Controlled specializations execute where supported.
- [ ] Generic adjoint commutation passes.
- [ ] Bounds and proof evidence integrate.
- [ ] Semantic quantum IR contains no dynamic dispatch.
- [ ] Duplicate helper APIs are deleted.

## Testing and acceptance

- [ ] Higher-order functions preserve ownership, origins, traps, and effects.
- [ ] Move-only, borrowed, exclusive, and must-consume captures derive the exact closure mode.
- [ ] Effect-polymorphic wrappers cannot hide effects or forge capabilities.
- [ ] An ordinary callable cannot become `ReversibleFunction` without evidence.
- [ ] Reversible composition uses inverse order and generic inverse commutes with specialization.
- [ ] Intrinsic reversible bodies reject arbitrary allocation/release/foreign/measurement effects.
- [ ] Coherent types require admitted exact finite encoding and complete bijection.
- [ ] Coherent output contains no runtime class/callable dispatch.
- [ ] Unitary bodies contain no measurement or host effect.
- [ ] Double adjoint restores exact semantic region identity.
- [ ] Generic adjoint commutes with specialization.
- [ ] Controlled/adjoint specializations commute where declared.
- [ ] Resource bounds close and pass before target submission.
- [ ] Classical operation selection is recorded in circuit identity.
- [ ] Replay-only generic code rejects fresh target/FFI effects.
- [ ] Fake class evidence cannot grant semantic characteristics.
- [ ] Forged callable/effect metadata fails verification.
- [ ] VM, simulator, native runtime, and proof kernel agree on accepted semantics.
- [ ] Generic quantum examples compile without provider-specific dispatch.

## Alternatives

### One universal function type or runtime characteristic tests

Rejected. Both erase facts required before verification, inverse generation, resource accounting, and quantum lowering.

### Duplicate every algorithm

Rejected. Some APIs remain distinct, but static characteristics permit safe common composition.

### Naming conventions for reversibility

Rejected. Inverse availability is a checked relation, not a suffix.

### Treat every circuit builder as unitary

Rejected. Builders may allocate, branch, measure, submit, or perform host effects. `UnitaryOperation` is stricter and carries adjoint evidence.

### Copy Q# characteristics unchanged

Rejected as a direct transplant. Adjoint/control are useful; Wheeler additionally distinguishes classical inverse, coherent lifting, rewind, ownership, proofs, and hybrid effects.

### Use `Monad` as the effect system

Rejected. A library class may compose values, but cannot erase capabilities, measurement, target submission, or replay boundaries.

### Dynamic trait objects in quantum regions or tests as proof

Rejected. Static semantic IR and checked universal evidence are required. Tests remain tests, however vigorous their naming.

## Open questions

- Does the trap contract remain wholly separate from rows, or do selected recoverable traps also carry a row label? — **Owner:** language and runtime maintainers — **Decide by:** effect syntax freeze
- Which callable type syntax avoids punctuation soup while retaining Java-shaped readability? — **Owner:** language and formatter maintainers — **Decide by:** parser implementation
- Is controlled specialization first-profile acceptance or its immediate successor? — **Owner:** quantum and compiler maintainers — **Decide by:** WIP acceptance
- Which acceptance fixtures are mandatory: QFT, arithmetic oracle, apply-to-each, phase estimation, or all four? — **Owner:** quantum and library maintainers — **Decide by:** implementation
- May ordinary classical code share verified runtime closure/dictionary representations, or are all first-profile calls monomorphized? — **Owner:** compiler and native maintainers — **Decide by:** optimization
- Which effect labels are compiler-owned and which may be package-qualified? — **Owner:** type-system and capability maintainers — **Decide by:** public effect APIs

## References

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0002](WIP-0002-unified-classical-quantum-semantics.md)
- [WIP-0004](WIP-0004-hybrid-jobs-history-and-replay.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0017](WIP-0017-compile-time-constants-and-finite-enums.md)
- [WIP-0021](WIP-0021-uniform-call-and-assertion-syntax.md)
- [WIP-0025](WIP-0025-native-ffi-and-system-integration.md)
- [WIP-0028](WIP-0028-deterministic-ownership-borrowing-and-regions.md)
- [WIP-0029](WIP-0029-parametric-polymorphism-and-bounded-specialization.md)
- [WIP-0030](WIP-0030-coherent-type-classes-and-associated-types.md)
- [WIP-0032](WIP-0032-unified-io-fabric-and-durability-receipts.md)
- [Koka: Programming with Row Polymorphic Effect Types](https://arxiv.org/abs/1406.2061)
- [Q# functor application](https://learn.microsoft.com/azure/quantum/user-guide/language/expressions/functorapplication)
- [Q# ApplyToEachCA](https://learn.microsoft.com/qsharp/api/qsharp-lang/std.canon/applytoeachca)
