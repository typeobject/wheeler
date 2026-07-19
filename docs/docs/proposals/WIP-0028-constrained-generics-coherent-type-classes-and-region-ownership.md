# WIP-0028: Constrained generics, coherent type classes, and region ownership

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler language, type-system, compiler, bytecode, verifier, runtime, standard-library, quantum, proof, package, and tooling maintainers |
| Created | 2026-07-19 |
| Updated | 2026-07-19 |
| Area | Generics, type classes, ownership, borrowing, memory, reversible and quantum typing |
| Depends on | WIP-0005, WIP-0013, WIP-0017 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler shall support constrained parametric polymorphism, coherent Haskell-style type classes, bounded compile-time value parameters, and a region-and-loan ownership model. It shall not acquire a general C++ template language while nobody is looking.

The accepted direction is:

- generic records, variants, functions, methods, type classes, instances, and selected proof and quantum declarations;
- explicit type, compile-time value, region, and lifetime parameters;
- a kinded type system with reserved identities for higher-kinded constructors;
- class constraints, superclasses, multi-parameter classes, associated types, constrained defaults, and class laws;
- globally coherent, package-visible, terminating instance selection with no overlap;
- definition-site checking of every generic body against declared constraints;
- canonical compile-time instance evidence and deterministic specialization;
- affine ownership, moves, shared loans, exclusive loans, and bounded region allocation;
- no required tracing collector, hidden shared mutable heap, implicit reference counting, user finalizers, ambient object identity, runtime reflection, substitution-failure metaprogramming, template macros, arbitrary type-level execution, or first-profile dynamic class dispatch.

Generic reversible, coherent, and unitary declarations obey stronger universal rules. A generic `rev` body must be invertible for every argument satisfying its constraints and may not duplicate, discard, overwrite, implicitly destroy, or hide allocation of an unknown value. A generic `coherent rev` body requires an exact finite canonical basis and a permutation of the complete basis. A generic `unitary` body may use static shapes, dimensions, gate families, and bounds; all class selection finishes before quantum lowering, and runtime dictionaries, type tests, measurement, allocation, and effectful dispatch remain forbidden.

Final runnable `.wbc` artifacts contain no unresolved generic parameter or class search. Package-library `.wbc` may carry canonical verified generic bodies and constraints used to produce exact closed instances. Canonical `.wbc` format 1.0 remains the semantic authority; this WIP adds versioned sections rather than a second artifact format.

## Recommendation

Generics are necessary for Wheeler. Coherent type classes are useful when selection is terminating, package-visible, and static. Full template metaprogramming is not useful.

The standard library, proof kernel, package manager, and self-hosted compiler need abstractions such as:

```text
Option<T>                 Result<T, E>
Pair<T, U>                Array<T, N>
Slice<'a, T>              Vec<'r, T>
Map<'r, K, V>             BitInt<N>
ModInt<M>                 Complex<T>
Qreg<N>                   Circuit<Shape>
Unitary<In, Out>
```

Copying each abstraction by payload type would create a large drifting API. C++-style templates would instead defer body errors to distant uses, turn substitution failure into overload behavior, make lookup depend on distant declarations, invite unbounded compile-time execution, obscure artifact identity, and make reversible or quantum validity depend on textual substitution. That is not a trade; it is two problems in a trench coat.

Wheeler should take constrained polymorphism, classes, superclasses, associated types, and explicit evidence from Haskell, and affine ownership plus exclusive mutation from Rust. It should not copy either language wholesale. Lifetime names remain uncommon, loans remain capabilities rather than pointer-like values, and a universal heap discipline does not become observable source semantics.

## Motivation

WIP-0012 anticipates generic algebraic values, collections, finite arithmetic, quantum registers, circuits, and unitary composition. WIP-0013 establishes bounded owned storage, verified moves/borrows/drops, and exclusion of ambient collection or raw pointers. WIP-0017 supplies bounded constants and finite nominal values for dimensions, widths, moduli, and coherent bases. WIP-0022 supplies direct package visibility needed for coherent instances. These directions need one type-system contract.

Without generics Wheeler would duplicate options, results, collections, encoders, comparators, iterators, algebra, shapes, circuit helpers, and compiler internals. Without complete ownership, generic containers would force pervasive copying, hidden sharing, a collector, unchecked pointers, runtime borrow failure, leaks, implicit finalizers, or one universal heap layout.

An unknown `T` cannot be presumed copyable or harmless to destroy. It may own a qubit, region, native handle, capability, clean-workspace witness, or another affine value. A coherent basis cannot derive from native layout, source order, wire encoding, or an assertion. A unitary operation cannot dispatch through an ordinary vtable without introducing hidden classical control.

Generic code therefore exposes ownership, effects, traps, bounds, inverse behavior, and quantum eligibility at its declaration and rechecks closed artifacts independently.

## Representative source forms

### Algebraic values and movement

```wheeler
public record Pair<T, U>(T first, U second) {}

public variant Option<T> {
    case None();
    case Some(T value);
}

public variant Result<T, E> {
    case Value(T value);
    case Error(E error);
}

public T identity<T>(T value) {
    return value;
}
```

Capabilities derive structurally. `Option<long>` is copyable. `Option<region>` is affine. `Option<Qubit<'q>>` cannot be copied, casually dropped, canonically encoded, compared, or coherently lifted merely because `Option<long>` can. `identity` moves a noncopyable argument in and the result out; no retain or drop appears from the undergrowth.

### Classes, laws, and associated types

```wheeler
public typeclass Eq<T> {
    boolean equal(read T left, read T right);

    boolean notEqual(read T left, read T right) {
        return !equal(left, right);
    }

    law reflexive(T value)
        shows equal(read value, read value);
}

public typeclass Ord<T> : Eq<T> {
    Ordering compare(read T left, read T right);
}

public typeclass Index<Collection, Key> {
    associated type Value;
    read<'a> Value get<'a>(read<'a> Collection collection, read Key key);
}
```

Default methods check once under class assumptions. Superclass evidence is canonical and superclass graphs are acyclic. One coherent `Index<Collection, Key>` instance determines `Value`.

```wheeler
public instance<T> Eq<Option<T>>
where T: Eq
{
    boolean equal(read Option<T> left, read Option<T> right) {
        ...
    }
}
```

Search for `Eq<Option<Token>>` reduces structurally to `Eq<Token>`. Alternate semantics use a nominal wrapper, for example `ReverseOrder<T>`, rather than a second overlapping `Ord<T>` found by import accident.

### Bounded value parameters

```wheeler
public record Matrix<T, const ROWS: long, const COLUMNS: long>(
    Array<T, ROWS * COLUMNS> values
)
where ROWS > 0
where COLUMNS > 0
where ROWS * COLUMNS <= MAX_MATRIX_ELEMENTS
{}
```

Value parameters use the checked WIP-0017 constant language. They are not arbitrary dependent values or invitations to run a package manager in the type checker.

### Loans and regions

```wheeler
public read<'a> V lookup<'a, K, V>(
    read<'a> Map<K, V> values,
    read K key
)
where K: Ord
{
    ...
}

public Vec<'r, T> collect<'r, T, I>(
    write<'r> Region region,
    I input,
    long maximum
)
where T: Move
where I: Iterator
where Iterator<I>.Item == T
{
    ...
}
```

Returned loans cannot outlive their origin. Collection storage belongs to a caller-owned bounded region. There is no process-global hidden heap.

### Reversible and quantum generics

```wheeler
public rev void exchange<T>(write T left, write T right) {
    swap(left, right);
}

public coherent rev T applyPermutation<T, P>(T value)
where T: CoherentBasis
where P: PermutationOf<T>
{
    return P.apply(value);
}

public unitary void qft<const N: long>(write Qreg<N> register)
where N > 0
where N <= MAX_QFT_QUBITS
{
    ...
}
```

The call checker proves the exchange loans disjoint. `CoherentBasis` and `PermutationOf<T>` are sealed or proof-carrying classes, not user promises. `Qreg<N>` fixes width and its exclusive affine loan excludes overlapping mutation. Every closed QFT instance carries a resource bound and generated adjoint.

```wheeler
public Pair<T, T> duplicate<T>(T value)
where T: Move
{
    return new Pair(value, value);
}
```

This is rejected after the first move. Requiring `T: Copy` admits only structurally copyable classical values; qubits, registers, regions, native handles, capabilities, and composites containing them cannot satisfy `Copy`.

## Goals

- Add generic records, variants, functions, methods, type classes, instances, fixed acyclic aliases, and selected theorem/quantum declarations.
- Add explicit type, bounded value, region, lifetime, and eventually constructor parameters under canonical kinds.
- Add coherent classes, superclasses, multiple parameters, associated types/constants, constrained defaults, and law obligations.
- Check abstract bodies at definition sites and preserve exact ownership/effects/traps/bounds/reversibility/quantum semantics.
- Infer local non-lexical loans while spelling public escaping relationships.
- Keep borrowed views second-class initially.
- Deterministically monomorphize runnable roots and deduplicate equal closed instances.
- Export canonical generic bodies and constraints in library artifacts.
- Bound solver depth, candidates, reductions, instantiations, generated bytes, proofs, diagnostics, memory, and total work.
- Support generic algebraic values, collections, encoders, iterators, arithmetic, reversible algorithms, coherent permutations, and shaped unitary circuits.
- Integrate class laws and sealed capabilities with WIP-0011.
- Keep package identities, native lowering, and reproducible builds deterministic.
- Keep a tracing collector, hidden allocation/sharing/dispatch/type data, and implicit external cleanup out of the required runtime and bootstrap closure.

## Non-goals

The first profile has no general templates, arbitrary compile-time execution, source macros, Turing-complete type reduction, substitution-failure overloads, argument-dependent lookup, overlap, import-order instances, runtime type tests/reflection, erased generics as the only model, inheritance, runtime class objects, local or negative instances, higher-rank or impredicative polymorphism, general existentials/GADTs/dependent types, variadics, open type families, unrestricted associated recursion, generalized unsafe escape, raw pointers, ambient identity, required collector, implicit reference counting, user finalizers, or hidden user cleanup.

Higher-kinded constructors and generic associated types have reserved identities but are not first-milestone execution requirements. Generic mutable state is deferred until initialization, region, package ABI, and inverse behavior are complete. A future explicit `GcRegion` or `Shared<T>` needs another WIP and cannot become the portable default.

User code cannot assert sealed capabilities such as `Copy`, `CoherentBasis`, `QuantumResource`, `PermutationOf<T>`, `UnitaryEvidence`, or trusted native layout. A class name alone proves neither reversibility nor unitarity. Duplicate nongeneric collection APIs are deleted when their generic replacements pass acceptance.

## Terms and semantic model

### Kinds and parameters

A kind classifies a compile-time parameter. Canonical metadata reserves:

```text
Type  Region  Lifetime  Nat  Shape  Effect
Type -> Type
(Type, Type) -> Type
```

The first executable implementation may stop at `Type`, `Region`, `Lifetime`, `Nat`, and `Shape`. Kinds are never runtime values. Every public parameter has an explicit kind; constructor parameters arrive only under a later bounded profile.

A constraint is a class application, associated-type equality, bounded value relation, region-outlives relation, effect bound, ownership capability, or sealed semantic capability. Solving is decidable and bounded.

### Classes, instances, and evidence

A type class is a compile-time interface over kinded parameters. It may contain required/default methods, associated types/constants, superclasses, laws, and ownership/effect/reversible/coherent/unitary requirements. It is not an object hierarchy.

An instance records class identity, head, constraints, associated definitions, methods/default choices, law evidence, package/module identity, visibility, and canonical identity. Compiler-generated dictionary-like instance evidence is immutable semantic compile-time data. It may appear in generic metadata or proof terms but is not a first-profile source value or runtime dispatch object.

An associated type is uniquely determined by one coherent instance. Reduction occurs only through that selected instance. There are no standalone open families.

A generic body is parsed, resolved, kinded, ownership/effect checked, and typed once against abstract parameters. A closed instantiation substitutes exact types, values, region shapes, and evidence with no unresolved variable.

### Sealed semantic classes

Compiler or kernel authority alone admits safety classes equivalent to `Copy`, `Affine`, `TriviallyRelease`, `Send`, `Share`, `CoherentBasis`, `QuantumResource`, `PermutationOf<T>`, `UnitaryEvidence<In, Out>`, and trusted canonical-layout/FFI capabilities. Ordinary user classes include `Eq`, `Ord`, `Hash`, `Iterator`, `CanonicalEncode`, and application protocols.

Capabilities derive structurally unless a sealed rule says otherwise:

```text
Pair<T, U>: Copy          iff T: Copy and U: Copy
Option<T>: Affine         if T: Affine
Array<T, N>: TriviallyRelease iff T: TriviallyRelease
```

An instance cannot make an affine field disappear.

### Regions, owners, and loans

A region is an owned bounded allocation domain with byte/object ceilings and no portable native address. Reclamation is legal only after owned values and loans end.

An owner is the unique authority to move, mutate, release, or lend an affine resource. Owned parameters move unless structurally `Copy` or explicitly loaned.

`read<'a> T` is a shared observational loan; several may coexist. `write<'a> T` is one exclusive mutable loan excluding owner use and overlap. Shared quantum access permits only explicitly shared metadata/operations, never amplitude observation.

Loan scopes are proven dynamic extents. Local scopes use path-sensitive non-lexical dataflow and end after last use. Public signatures name relationships when a returned/stored view derives from input.

Initial loans are second-class: they cannot enter ordinary owned aggregates, persistent state, certificates, encodings, FFI retention, escaping closures, other tasks, asynchronous suspension, target submission, measurement transitions, or `commit`; and cannot return without an explicit origin relationship.

## Ownership and component boundaries

The parser owns generic/class/instance/associated/region/loan syntax. The kind checker owns kinds and constructor application. The resolver owns names, active instance visibility, and package-qualified identity. The class solver owns coherent evidence and associated reduction. Type checking owns universal body validity. Ownership checking owns moves, paths, loans, disjointness, regions, escapes, cleanup, and affine state. Effect checking owns allocation, release, traps, external effects, and reversible/coherent/unitary eligibility.

The proof elaborator and kernel own law evidence and sealed proof capabilities. The bytecode verifier owns generic metadata integrity, closed signatures, transitions, evidence identities, and executable body validity. WIP-0022 package graphs own API/instance visibility and compatibility. WIP-0025 owns one-call native span lowering. Native backends derive layout only after semantic verification; layout is not source identity.

## Design

### Source and inference

Proposed spellings are `<T>`, `<const N: long>`, `<'r>`, `where T: Eq`, `where N > 0`, `read<'a> T`, `write<'a> T`, `typeclass`, `instance`, `associated type`, and `law`. Exact punctuation remains parser work, but distinctions are semantic. Generic parsing must remain formatting-independent and must not import angle-bracket ambiguity into arbitrary expressions.

Local arguments may infer from call arguments, expected results, and uniquely reduced associated types. Public declarations list parameters and constraints. Public signatures are not inferred across modules. Ambiguity is a diagnostic except for a small documented literal default set.

### Classes and laws

Class methods may themselves be generic and ordinary, `rev`, `coherent rev`, or `unitary`. Subclasses cannot weaken superclass ownership/effect/semantic contracts. Defaults check once under class/superclass assumptions; an instance either uses that exact body or replaces it with a conforming method. Default choice and body identity enter instance/package identity.

Every multi-parameter class parameter affects a method, associated type, or law. Associated equations are canonical, bounded, nonoverlapping, and part of public API. Superclass graphs are acyclic and evidence cannot be selected independently through competing paths.

Class laws state their required evidence category: kernel certificate, compiler-derived certificate, bounded executable conformance, or documentation-only under a profile making no proof claim. Coherent basis, permutation, and unitary classes require compiler/kernel evidence. An ordinary `Eq` may start with conformance evidence. Evidence policy is API identity.

Operators may map to a closed documented set of classes. No argument-dependent lookup exists. Primitive operators remain authoritative until class replacements have complete parser/verifier/proof coverage, after which primitive duplicate paths are deleted.

### Coherence, visibility, and termination

For one closed class application, at most one active instance exists. Source/import/dependency/repository order cannot choose it. An instance lives in the class package, principal nominal-type package, or a directly imported adapter package. Adapter instances never enter transitively. Unifying active instances fail with both identities and paths. Alternate semantics use nominal wrappers.

A package's public generic API records required constraints, not whichever evidence happened to satisfy its own build. Locks record exact package instances supplying selected evidence.

Recursive instances must require structurally smaller class applications under the accepted metric (`Eq<Option<T>>` to `Eq<T>`). Cycles without decrease fail. There is no `UndecidableInstances` switch, overlap, “most specific wins,” or specialization by source proximity. Named functions, wrappers, associated values, or audited intrinsics express specialization.

### Const generics

Const parameters extend WIP-0017 with nonnegative lengths, widths, moduli, shapes, bounded resources, and finite-enum cardinalities. Expressions are deterministic, terminating, checked, side-effect free, and bounded. Initial constraints use normalized decidable arithmetic. Failed constraints stop before code generation.

### Region-and-loan model

1. Values are owned by default. Noncopyable calls, assignments, and returns move; later use fails.
2. Dynamic storage belongs to an explicit or compiler-elided bounded region. Reclamation is memory-only after owners/loans end; it runs no user code.
3. Loans are scoped path capabilities, not pointer values, and expose no portable address.
4. Ordinary graphs are trees, region-indexed DAGs, or explicit graph owners. Cycles use stable indices/generational handles under one owner rather than a collector.
5. Files, sockets, target sessions, handles, and credentials close/commit/abort/release explicitly. Function exit with a live external owner fails.

The checker tracks fields, statically distinct indices, proven-disjoint slice ranges, refined variant payloads, region handles, and quantum partitions. Shared/exclusive overlap fails. Disjointness is representation-independent.

Large immutable values are moved, borrowed, arena-interned, indexed, or rebuilt. No implicit reference count exists. A future explicit `Shared<T>` must expose allocation/decrement/atomicity, reject external finalizers, and define cycles.

Loans do not cross suspension initially. Async operations own or copy retained values. Scoped-concurrency loans require a later WIP with static join evidence.

WIP-0025 may lower a loan to one bounded native span only when descriptor lifetime/mutability/aliasing agree, storage is stable or copied, callbacks cannot invalidate it, and the callee cannot retain it. Retained native pointers are affine foreign owners.

## Universal generic checking

A body over unknown `T` cannot discard a live branch value merely because every current caller uses `long`. Every operation follows structural ownership, a class method, sealed capability, proof contract, or compiler intrinsic with the same public declaration.

```wheeler
public T choose<T>(boolean first, T left, T right) {
    if (first) { return left; }
    return right;
}
```

This leaves one affine value live on each branch. It must return/consume both, borrow, require safe sealed release, or return the unselected value too.

### Reversible declarations

A generic `rev` body proves an invertible owned parameter/result relation abstractly. It cannot copy without valid reversible capability, discard/release, select different evidence forward/inverse, call an ordinary class method where `rev` is required, leave dirty scratch, or hide allocation without a reversible region/witness contract. Branches and loops retain ordinary witnesses. Inverse evidence includes exact instance identities.

Each closed instance rechecks ownership transitions, selected inverses, value coverage, bounds, and generated inverse body. A class `rev` requirement can be satisfied only by a valid `rev` implementation/default.

### Coherent declarations

`CoherentBasis<T>` evidence fixes finite cardinality, canonical case/basis map, qubit width, invalid-state policy, ownership/no-cloning class, and basis identity. The first profile accepts cardinality `2^N`; subspace/leakage semantics need another WIP.

A coherent generic body uses only coherent primitives/methods, complete permutations, static evidence, proven clean workspace, and nonobserving coherent control. It has no runtime dictionary/type test, observing match, allocation, measurement, host effect, hidden drop, or wire-layout basis. Closed artifacts carry exact permutation/region, basis, inverse, and certificate identities.

### Unitary declarations

Unitary parameters may cover register width, shape, exact scalar model, gate family, ancilla shape, resources, and target-independent operation classes. Class/associated selection finishes before lowering. Unitary methods preserve register ownership, no measurement, no forbidden allocation/effect, exact adjoint, clean ancillas, basis/shape, and bounds. Emitted quantum regions contain no ordinary dictionary.

### Proofs

Generic theorems quantify over explicit parameters and class-law assumptions. Constraints elaborate to explicit evidence; the kernel checks associated reduction using canonical instance identities. Ordinary dictionaries cannot forge sealed basis/permutation/unitary certificates. Proof irrelevance may erase duplicate proof payloads, but differing method or associated-type instance identity remains semantic.

## Artifact and identity model

A library artifact may carry descriptors for kinded parameters, constraints, generic typed body IR, effects/ownership, classes/instances, associated equations, defaults, laws/evidence, and source/package identity. A runnable artifact carries closed types/functions/quantum regions, selected evidence identities, associated results, instantiation table, and certificates—with no unresolved search.

The verifier rechecks closed bodies and metadata rather than trusting substitution.

Generic declaration identity includes package instance, module/name, kind schema, public signature, constraints, associated types, modifiers, and canonical body. Instance identity adds class/head, constraints, associated definitions, method/default identities, law policy/evidence, and package instance. Closed identity adds ordered type/value/semantic-region arguments, selected instances, associated reductions, and compiler profile. Physical addresses and inferred local loan IDs are excluded.

The first executable profile monomorphizes all instances reachable from selected roots. The complete set is computed before emission and sorted by closed identity, never first-use traversal. Equal identities share bodies. Recursive expansion repeats an existing identity or decreases under a checked metric. Polymorphic recursion needs an explicit finite instance set; unbounded type growth fails.

Limits cover declarations, parameters, constraints, active candidates, solver/reduction depth, instantiations, generated functions/bytes, proofs, quantum regions, diagnostics, memory, and total work. Exhaustion reports the bounded chain and emits nothing partial.

## Package and compatibility policy

Public API identity includes generic declarations, constraints, classes/instances, associated types, laws/defaults, ownership/effects, and sealed requirements. Adding a required constraint, removing an instance, changing an associated result/superclass/default/effect/lifetime/const condition/basis/evidence, or introducing overlap changes compatibility. WIP-0022 direct dependencies identify adapter instances and prevent transitive activation.

This repository is pre-release: implementation migrations replace old schemas and duplicated APIs outright. There is no legacy generic mode, erased fallback, duplicate collection family, or compatibility parser.

## Reversibility, history, concurrency, quantum, and persistence

Moves/loans are typed transitions. VM rewind restores exact ownership, loan, region, local, and frame state above the commit horizon; language inverse remains distinct. Scope reclamation is not inverse execution, and `rev` cannot use cleanup to lose information. `commit` ends history and forbids loans spanning the changed horizon.

Selection, reduction, inference, enumeration, emission, and diagnostics are deterministic; parallel work reduces by identity. There is no ambient shared mutable heap. Task transfer/sharing requires sealed or proven `Send`/`Share` independently from `Copy`.

Class syntax never weakens no-cloning, measurement, clean-ancilla, target, or proof rules. Generic quantum code closes before region emission. Measurement changes ownership and cannot hide behind an ordinary coherent method.

Generic persisted values record closed nominal type identity and schema, not source text or search state. There is no universal boxed representation. Native layout is target-derived. Canonical encoding requires explicit `CanonicalEncode<T>` evidence over semantic fields, never native memory.

## Safety and failures

Reject kind mismatch, ambiguity, missing/overlapping/invisible instance, undeclared adapter activation, cyclic superclass, nonterminating search, unconstrained/conflicting associated type, failed const relation, code explosion, use after move, live overwrite, loan overlap/escape/forbidden crossing, region release with live state, implicit external destruction, body validity dependent on current uses, noninvertible `rev`, missing coherent basis, runtime coherent/unitary dispatch, unitary measurement/allocation/effect, forged sealed evidence, malformed metadata, and exhausted bounds.

Diagnostics identify source, declaration, closed arguments, evidence chain, and ownership path. No failure emits a partial artifact.

## Migration and deletion

1. Define kind, parameter, constraint, class, instance, associated, region, and loan metadata.
2. Add parser and Tree-sitter nodes, then kind and definition-site checking.
3. Add coherent single-parameter classes, superclasses, defaults, laws, generic records/variants, `Option<T>`, and `Result<T,E>`.
4. Add generic region/loan checking and cross-function ownership.
5. Add const-generic arrays, widths, and shapes.
6. Add multiple class parameters and associated types.
7. Add canonical library sections, closed instance tables, and deterministic monomorphization.
8. Port arrays, slices, collections, encoders, iterators, and compiler/package structures; delete type-specific copies in the same patches.
9. Add reversible generics with witnesses, then sealed coherent basis/permutation classes.
10. Add `Qreg<N>`, generic circuits/unitaries, generated adjoints, and class-law proofs.
11. Consider higher-kinded classes and generic associated types only after first-profile acceptance.
12. Delete primitive borrow-position special cases once canonical `read`/`write` covers them. Keep collectors, unrestricted templates, overlap, runtime class objects, and unsafe pointer escape absent.

## Progress

- [ ] Kinds, constraints, and generic identity accepted.
- [ ] Generic records/variants and `Option<T>`/`Result<T,E>` execute and replace copies.
- [ ] Coherent classes, superclasses, defaults, multiple parameters, and associated types execute.
- [ ] Abstract body checking rejects instantiation-only validity.
- [ ] Region/loan ownership supports cross-function generic collections.
- [ ] Const-generic arrays, widths, shapes, and registers execute.
- [ ] Closed instance sets, library linking, and monomorphization reproduce.
- [ ] Generic reversible algorithms pass inverse laws.
- [ ] Generic coherent permutations pass basis/bijection checks.
- [ ] Const-generic unitary circuits produce generated adjoints.
- [ ] Class laws integrate with proof certificates.
- [ ] Duplicated type-specific implementations are deleted.
- [ ] Runtime/bootstrap remain collector-free.

## Testing and acceptance

- [ ] Abstract bodies type-check once; discarding unknown affine `T` fails even when current uses choose `long`.
- [ ] Move, use-after-move, non-lexical loan, disjointness, escape, and region diagnostics are stable.
- [ ] Loans cannot enter persistence, suspension, retained FFI, measurement, target submission, or commit.
- [ ] Region reclamation rejects live owners/loans; compiler-scale cyclic graphs work through owned indices without a collector.
- [ ] Algebraic values, arrays, slices, vectors, maps, and iterators derive ownership structurally.
- [ ] Instance selection ignores source/import order; overlap and transitive adapter activation fail.
- [ ] Recursive search terminates or prints its bounded chain; associated types/defaults/superclasses reduce to exact evidence.
- [ ] Nominal wrappers provide alternate semantics without overlap.
- [ ] Const arithmetic exactly matches WIP-0017.
- [ ] Instantiation order ignores call discovery, equal instances deduplicate, and recursive growth is bounded.
- [ ] Limits fail before partial emission.
- [ ] Generic `rev` preserves owners and composes with its exact inverse; ordinary class calls cannot satisfy `rev` requirements.
- [ ] Sealed coherent basis cannot be forged; complete power-of-two permutations execute and unsupported subspaces fail.
- [ ] Unitary artifacts contain no runtime search and every instance has an exact generated adjoint.
- [ ] Quantum loans reject overlap/copy and generic proofs bind exact evidence.
- [ ] Library order changes still link to byte-identical closed executable artifacts.
- [ ] Stage 0 and Wheeler agree on kinds, evidence, ownership, specialization, diagnostics, and bytes.

## Alternatives

### No generics

Rejected. It duplicates the standard library and forces compiler intrinsics for ordinary abstractions.

### Full templates or fully implicit public inference

Rejected. Wheeler needs neither textual substitution/SFINAE/ADL nor public APIs whose ownership, effects, lifetimes, and quantum constraints were guessed locally.

### Erasure or runtime dictionaries as the only implementation

Rejected. A universal representation hides primitives, ownership, layout, and quantum distinctions. Later representation sharing may use closed proven-compatible dictionary passing, but coherent/unitary code has no runtime dictionary.

### Incoherent or overlapping classes

Rejected. Import- or specificity-selected semantics destabilize packages and artifacts. Wheeler adopts explicit constraints and evidence, not global roulette.

### Copy Rust exactly

Rejected. Rust demonstrates affine ownership and exclusive mutation; Wheeler also has bounded regions, two execution directions, no-cloning, canonical bytecode/proofs, second-class initial loans, and explicit external cleanup. Lifetime punctuation is not the product.

### Default tracing collection or implicit reference counting

Rejected. A collector imports root discovery, pauses, scheduling, pinning, layout, recovery, and runtime closure. Reference counting makes copies/drops hidden mutation, complicates cycles/atomicity, and surprises reversible execution. Explicit future region/library types may propose either without becoming ambient semantics.

### Manual allocation/free everywhere

Rejected. Regions, inferred loans, memory-only structural cleanup, and explicit external release provide deterministic memory without pointer-style source management.

### Make every capability an ordinary class

Rejected. Copyability, coherent basis, quantum-resource status, unitary evidence, and native layout require compiler/kernel authority.

## Open questions

- Final loan spelling: `read`/`write`, `borrow`/`borrow mut`, or another Wheeler form? — **Owner:** language/ownership maintainers — **Decide by:** parser implementation
- Are public region parameters nominal, allocator-derived, or exposed only for escaping loans? — **Owner:** language/library/compiler maintainers — **Decide by:** generic vector stabilization
- Which first classes require formal laws? — **Owner:** proof/library maintainers — **Decide by:** public class stabilization
- How are direct adapter instances activated in source? — **Owner:** package/language maintainers — **Decide by:** cross-package instances
- Are higher-kinded parameters needed before first-class closures? — **Owner:** language/library maintainers — **Decide by:** first generic collection milestone
- Which representation sharing reduces code size without a boxed ABI? — **Owner:** compiler/bytecode/native maintainers — **Decide by:** optimization work
- Can explicit `Shared<T>` use deterministic reference counting, under what cycle rules? — **Owner:** library/ownership/runtime maintainers — **Decide by:** after region-owned compiler collections
- Do non-power-of-two coherent subspaces belong here or in a successor? — **Owner:** quantum/proof maintainers — **Decide by:** coherent stabilization
- Is class evidence retained in executable proof/debug metadata after specialization? — **Owner:** bytecode/proof/tooling maintainers — **Decide by:** schema freeze

## References

- [WIP-0005](WIP-0005-wheeler-source-language.md)
- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0012](WIP-0012-wheeler-standard-library.md)
- [WIP-0013](WIP-0013-typed-frames-control-flow-and-storage.md)
- [WIP-0017](WIP-0017-compile-time-constants-and-finite-enums.md)
- [WIP-0022](WIP-0022-package-instances-and-resolution.md)
- [WIP-0025](WIP-0025-native-ffi-and-system-integration.md)
- [Haskell 2010: declarations](https://www.haskell.org/onlinereport/haskell2010/haskellch4.html)
- [GHC: multi-parameter classes](https://ghc.gitlab.haskell.org/ghc/doc/users_guide/exts/multi_param_type_classes.html)
- [GHC: associated type families](https://ghc.gitlab.haskell.org/ghc/doc/users_guide/exts/type_families.html)
- [Tofte and Talpin, typed call-by-value with regions](https://doi.org/10.1145/174675.177855)
- [Aiken, Fähndrich, and Levien, Better Static Memory Management](https://www2.eecs.berkeley.edu/Pubs/TechRpts/1995/5202.html)
- [Rust reference types](https://doc.rust-lang.org/core/primitive.reference.html)
