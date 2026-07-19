# WIP-0030: Coherent type classes, associated types, instances, and laws

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler language, type-system, compiler, proof, package, library, bytecode, quantum, and tooling maintainers |
| Created | 2026-07-19 |
| Updated | 2026-07-19 |
| Area | Type system, ad-hoc polymorphism, type classes, instances, laws, packages |
| Depends on | WIP-0005, WIP-0011, WIP-0012, WIP-0028, WIP-0029 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler uses Haskell-style type classes as its primary mechanism for coherent ad-hoc polymorphism.

A type class declares methods, associated types or finite constants, superclasses, ownership/effect requirements, and laws. An instance supplies one canonical implementation for a class head. The active implicit instance set is exact, target-scoped, package-visible, bounded, and independent of source/import/traversal order.

The initial rules are deliberately dull where dullness is a security feature:

- at most one matching active instance for a ground class head;
- package-level orphan ownership;
- no overlapping or incoherent implicit instances;
- direct, explicit activation of adapter instances;
- structurally terminating bounded resolution;
- canonical class, member, instance, and evidence identities;
- explicit strategy values when one type legitimately needs several orderings, encoders, allocators, or policies.

Implicit evidence resolves statically. WIP-0029 normally monomorphizes generic calls to direct static methods. Runtime dictionary dispatch is absent from reversible, coherent, unitary, proof, and bootstrap-trusted code.

Wheeler distinguishes:

1. **operational classes** for ordinary methods such as formatting or comparison;
2. **lawful classes** whose algebraic laws are documented, tested, or proved;
3. **certified semantic classes** whose use for ownership, canonical identity, reversibility, coherent representation, unitary behavior, or proof authority requires compiler verification, a trusted intrinsic, or WIP-0011 evidence.

An instance named `Copy`, `Drop`, `CanonicalEncode`, `Reversible`, `Coherent`, or `Unitary` does not confer the advertised power by typography. The compiler has met strings before.

## Motivation

Wheeler needs reusable algorithms over equality, ordering, deterministic hashing, canonical codecs, formatting, iteration, allocation, finite encodings, inverse-bearing transformations, coherent permutations, unitary operations, and decidable propositions.

Object inheritance is a poor primary fit. Records and variants are values; built-in and third-party types need independent protocols; generic code needs static constraints; package identity matters; and reversible/quantum code requires proof-bearing operations rather than virtual calls.

Type classes separate a type from overloaded operations and elaborate constraints into evidence. Unrestricted instance extensions, however, invite distant orphans, overlap, import-sensitive behavior, solver loops, and downstream changes that silently pick a new implementation. Wheeler's exact lock and reproducible artifact model requires one coherent active evidence graph.

The distinction between operational and certified evidence matters. A questionable `Eq` can break an application. A questionable canonical encoder can break artifact identity. A questionable unitary can break the claim that there was a unitary. Those are different blast radii and deserve different admission rules.

## Representative source

This series uses `typeclass` rather than `class`: Wheeler already has Java-shaped classes, while a type class is compile-time evidence and not an object hierarchy.

### Equality and laws

```wheeler
public typeclass Eq<T> effects none {
  boolean equal(borrow T left, borrow T right);

  law reflexive(T value)
    shows equal(borrow value, borrow value);

  law symmetric(T left, T right)
    shows equal(borrow left, borrow right)
      == equal(borrow right, borrow left);
}

public instance Eq<Span> {
  boolean equal(borrow Span left, borrow Span right) {
    return left.start == right.start
      && left.end == right.end;
  }

  proof reflexive = spanEqualityReflexive;
  proof symmetric = spanEqualitySymmetric;
}
```

Exact proof syntax remains WIP-0011 work. Method effects and WIP-0028 passing modes are part of the class contract.

### Generic use and alternate strategy

```wheeler
public boolean contains<T>(
  borrow Slice<T> values,
  borrow T needle
) where T: Eq {
  ...
}

Order<Version> canonical = VersionOrder.canonical();
Order<Version> prereleaseFirst = VersionOrder.prereleaseFirst();
sort(versions, using prereleaseFirst);
```

One global `Ord<Version>` remains canonical. A second ordering is an explicit ordinary value, not an overlapping instance smuggled in by import order.

### Associated members

```wheeler
public typeclass Iterator<I> {
  associated type Item;
  Option<Item> next(borrow mut I iterator);
}

public certified typeclass CoherentEncoding<T> {
  associated const long width;
  BitInt<width> encode(T value);
  T decode(BitInt<width> bits);

  theorem roundTrip(...);
  theorem completeOrValidSubspace(...);
}
```

An instance fixes `Item` or `width`. Associated reduction is canonical and compile-time only.

### Higher-kinded class

```wheeler
public typeclass Functor<F<Type -> Type>> {
  F<B> map<A, B, effect E>(
    F<A> values,
    Function<A, B, E> transform
  ) effects E;
}
```

WIP-0029 owns constructor kinds. WIP-0031 owns callable and effect rows. `Functor` gets no waiver to hide allocation or measurement.

## Goals

- Add named type-class and global instance declarations with Tree-sitter, formatter, documentation, and package support.
- Support generic constraints, superclasses, associated types/constants, defaults, multiple parameters, and constructor-kinded parameters.
- Resolve implicit evidence coherently and independently of source/import/package traversal order.
- Enforce orphan ownership, direct adapter activation, nonoverlap, structural termination, and hard work limits.
- Give classes, members, laws, instances, defaults, and evidence canonical identities.
- Make public instance changes visible to compatibility and lock tooling.
- Permit explicit evidence/strategy values where plurality is intentional.
- Monomorphize implicit evidence to static calls under WIP-0029.
- Integrate laws with WIP-0018 tests and WIP-0011 proofs without mistaking one for the other.
- Prevent ordinary instances from forging ownership, canonical identity, reversible, coherent, unitary, native-layout, or proof authority.
- Preserve all Wheeler ownership, effect, trap, and resource transitions through class methods.
- Delete duplicate protocol tables and import-order prototypes after migration.

## Non-goals

This WIP does not copy every GHC extension; permit `OVERLAPPING`, `OVERLAPPABLE`, or `INCOHERENT`; select by imports; allow unrestricted orphans, negative/local implicit instances, undecidable search, arbitrary code during resolution, or method-body-based selection; infer lawfulness from names; turn classes into runtime objects; grant `Monad` control over Wheeler effects; serialize implicit dictionaries as portable state; expose native reflection; or treat property tests as proof of a certified law.

Not every class needs multiple parameters or higher kinds. Not every strategy belongs in the global implicit set. “Pass it explicitly” remains a feature, not an admission of defeat.

## Semantic model

### Classes and heads

A **type class** is a nominal package declaration containing parameter kinds, method signatures, associated members, superclass constraints, effect/ownership requirements, laws, and certification policy.

A **class head** is a class and its type-level arguments:

```text
Eq<Span>
Functor<Option>
Convert<Bytes, Utf8>
```

Kinds are checked before resolution. Methods retain complete ordinary signatures: generic parameters, ownership modes, result origins, effects, traps, reversibility characteristics, and resource bounds. An instance method may not widen effects, weaken ownership, or reduce a promised characteristic.

### Instances and evidence

An **instance** supplies members for one head pattern. A ground instance has no unresolved variable after substitution. An active global instance participates in implicit resolution for one exact target graph.

An **instance dictionary** is canonical compiler evidence containing method identities, associated results, superclass evidence, and certificate references. It is compile-time semantic data, not an ordinary source object by default.

An **explicit evidence value** is an ordinary typed strategy selected at a call site. It has normal ownership/effects and never enters global implicit resolution. It may pass through generic code. WIP-0031 restricts its use in coherent/unitary code to immutable, certified, statically known evidence erased before lowering.

### Coherence

Coherence means each implicit ground constraint in a complete selected target has one canonical instance independent of declaration, import, graph traversal, repository response, map, or task order.

Two heads overlap when some substitution makes them equal. The initial profile rejects both, even if one looks “more specific”:

```wheeler
instance<T> Show<List<T>> where T: Show
instance Show<List<long>>
```

Named functions, nominal wrappers, explicit strategies, or semantics-preserving compiler optimization replace overlapping specialization.

## Superclasses, associated members, and defaults

A superclass declaration such as:

```wheeler
typeclass Ord<T> extends Eq<T> {
  Ordering compare(borrow T left, borrow T right);
}
```

requires one exact `Eq<T>` evidence path. Superclass graphs are acyclic; conflicting inherited members/laws fail at declaration time.

An associated type or constant is uniquely fixed by the selected instance. Constants use WIP-0017/WIP-0029 finite evaluation. Equations cannot overlap or depend on runtime values. Reduction participates in generic normalization and proof identity.

A default method checks once using only class methods, superclasses, declared constraints, and allowed Wheeler code. An instance either uses that exact body or supplies a conforming replacement. Default selection and body identity enter instance, package, and downstream build identity. A default implementation is not a default proof.

Multiple-parameter classes such as `Convert<From, To>` and `Index<Collection, Key>` are allowed when every parameter affects a method, associated member, law, or explicit determination rule. The first profile may reject inference that does not determine all parameters. Associated types and explicit determination replace first-profile functional dependencies.

Constructor-kinded classes initially support `Type -> Type`. Type-level lambdas, arbitrary kind polymorphism, and impredicativity are deferred. A library may eventually define `Monad<M>`; it still cannot make file I/O or measurement pure by applying enough category theory.

## Instance ownership and visibility

An implicit instance is legal when declared by:

1. the exact package instance owning the class;
2. the exact package instance owning the designated principal outermost nominal type in the head; or
3. an adapter package that is a direct declared dependency and is explicitly activated in source.

For multiple principal nominal arguments, the class declaration fixes the owner-selection rule before instances are published. Heads containing only structural built-ins belong to the class package unless a compiler rule names another owner.

Class-package and principal-type-package instances are intrinsic to those exact package instances. Adapter instances never propagate transitively. A package's public generic API exports required constraints, not the accidental evidence used to compile its own body. If two directly activated declarations unify, compilation reports both exact package-instance identities and dependency paths.

The WIP-0022 resolver computes the complete active instance set before generic emission and rejects overlap across the selected graph. Locks record every exact package instance supplying selected evidence. Adding or removing a public instance is therefore a compatibility event even when no method signature changed.

## Resolution and termination

For a constraint, the compiler:

1. kind-checks and normalizes aliases and known associated results;
2. considers local declared constraints or explicit evidence;
3. loads the canonical active global set from the target graph;
4. matches heads without inspecting method bodies;
5. requires exactly one match;
6. recursively resolves its context and superclasses;
7. checks structural decrease and hard limits;
8. records exact selected evidence and reduction identities.

A generic body's local constraint remains fixed when instantiated downstream; it does not switch to a more specific instance later.

Recursive contexts must decrease under a fixed measure over constructor depth, unresolved variables, proved finite values, and class dependency order. `Eq<Option<T>>` requiring `Eq<T>` is the usual acceptable example. Cycles or expansion fail; there is no `UndecidableInstances` trapdoor.

Limits cover classes, methods, associated members, active instances, candidates, match attempts, resolution depth, normalized type size, reductions, proof obligations, diagnostics, memory, and total work. Exhaustion is a source-located error, not an excuse to choose whichever candidate remained in the iterator.

## Dictionary elaboration

Each class has one canonical dictionary shape and stable member IDs. In the initial executable profile:

- dictionaries are compile-time evidence;
- generic code is monomorphized;
- calls become direct static calls;
- unused evidence has no runtime payload;
- evidence identities remain in package/debug/proof metadata.

A later verified optimization may share an ordinary classical body behind a hidden dictionary reference only when ownership, effects, traps, source maps, ABI, and identity remain equivalent. Runtime dictionary dispatch is forbidden in `rev`, coherent, unitary, proof, and bootstrap-trusted verifier code.

## Laws and authority

A law is a named proposition with one declared policy:

- **Documented:** API contract, not mechanically required.
- **Tested:** every published instance supplies deterministic WIP-0018 evidence.
- **Certified:** every instance supplies a WIP-0011 proof or admitted certificate.

Test evidence never satisfies a certified obligation. Policy and exact evidence identity are public API.

Compiler-privileged classes include concepts equivalent to `Copy`, `Drop`, `MustConsume`, finite/coherent encoding, canonical artifact encoding, reversible actions, unitary operations, and proof-kernel interfaces.

Ownership properties are compiler-derived or sealed. A native handle cannot become `Copy` by instance declaration. An encoder used for package/artifact identity requires certified deterministic, bounded, schema-appropriate behavior; an ordinary formatter or uncertified encoder cannot affect identity. Reversible, coherent, and unitary evidence binds exact ownership/effect/frame/finite-basis/adjoint facts under WIP-0031.

User-defined certified instances are allowed only through their class's admission policy. “Certified” means checked evidence, not that the author used a confident adjective.

## Core library classes

`Eq<T>` defines deterministic semantic equality without address/allocation-order observation. `Ord<T>` defines one canonical total order for canonical collections; alternatives are explicit strategies. `Hash<T>` is compatible with `Eq<T>` under tested or certified law, explicit algorithm/seed policy, and iteration independent of randomized bucket order.

Potential collection classes include `Iterator<I>`, `IntoIterator<C>`, `Collection<C>`, `Sequence<C>`, `MapLike<M>`, and `Allocator<A, R>`. Consuming iteration moves elements; borrowed iteration returns owner-tied loans; mutable iteration sequences disjoint exclusive loans; affine quantum collections use stricter classes. No iterator is presumed copyable or restartable.

## Reversible IR, effects, quantum semantics, and proofs

A class method elaborates to the same Wheeler reversible typed IR as a direct declaration. Its dictionary member records the exact callable kind, ownership relation, effects, traps, inverse/adjoint/coherent evidence, and bounds; instance selection cannot replace an IR operation with a host callback or erase a reversal class. Monomorphization resolves calls before coherent or unitary region emission.

A class method's WIP-0031 effects are part of its signature and cannot be masked. Effect-polymorphic methods expose variables/bounds. An instance may not broaden them.

A method used by generic `rev` code requires certified inverse behavior. Before coherent/unitary lowering, all constraints and associated members are concrete, no runtime dispatch remains, and every selected method satisfies exact finite/effect/resource rules. Dynamically selected `UnitaryOperation` evidence is not admitted inside a unitary region.

WIP-0011 propositions may quantify over constraints, associated members, instance identities, and laws. Certificates bind exact class/instance/body/package identities; the kernel checks proof terms, not compiler dictionary layout.

## Package, bytecode, documentation, and determinism

Package metadata records classes, stable member IDs, superclasses, associated members, laws/policies, instances/heads/contexts, certificate identities, owner classification, and adapter activation. Tools report instance-set changes and conflicts.

Concrete executable `.wbc` contains static methods selected from instances. Metadata may retain class/instance descriptors, evidence identity, associated reductions, generic source relation, and certificates. The verifier checks privileged use against admitted evidence and rejects forged IDs.

`wheeler doc` renders methods, associated members, superclasses, law policy, legal active instances, owner package, and proof links. Editor tooling explains selected evidence and overlap/orphan/termination failures. Formatting remains fixed and minimally diffable.

Every identifier and ordering uses canonical qualified names and structural encodings. Parallel checking reduces in evidence identity order.

## Safety and failures

Malformed metadata, duplicate member IDs, kind mismatch, orphan violation, undeclared adapter, overlap, ambiguity, superclass/associated cycle, nondecreasing context, law mismatch, effect widening, ownership forgery, corrupt evidence ID, and bound exhaustion fail before artifact publication. No arbitrary candidate is selected and no partial instance table escapes.

## Migration and deletion

1. Add `typeclass`/`instance` source, Tree-sitter, formatter, and documentation nodes.
2. Add kinds, methods, superclasses, and generic constraints.
3. Add coherent one-parameter `Eq`, `Ord`, `Hash`, formatting, and codec helpers.
4. Enforce package ownership, direct adapters, and nonoverlap.
5. Add bounded resolution and stable explanation diagnostics.
6. Add associated constants/types and defaults.
7. Add explicit strategy values.
8. Integrate law tests and certified proof evidence.
9. Add constructor-kinded classes and generic collections.
10. Add WIP-0031 certified reversible/coherent/unitary classes.
11. Delete duplicate operation-specific APIs, ad-hoc trait tables, import-order prototypes, and compatibility readers for replaced schemas.

## Progress

- [ ] Class and instance syntax is accepted.
- [ ] One-parameter operational classes compile.
- [ ] Generic constraints elaborate.
- [ ] Package ownership, direct adapters, and nonoverlap are enforced.
- [ ] Resolution is terminating, bounded, and deterministic.
- [ ] Instance explanations are stable.
- [ ] Associated members and defaults compile.
- [ ] Explicit evidence supports alternate strategies.
- [ ] Law policies integrate with tests and proofs.
- [ ] Constructor-kinded examples compile.
- [ ] Certified semantic authority cannot be forged.
- [ ] Reversible and quantum evidence passes WIP-0031.
- [ ] Duplicate standard-library protocols are deleted.

## Testing and acceptance

- [ ] Generic `Eq`, `Ord`, `Hash`, and codec examples compile and run.
- [ ] Import, declaration, graph, map, and task order cannot change selection.
- [ ] Overlap and undeclared or transitive adapters fail; class/type-owner instances pass.
- [ ] Recursive contexts terminate or report a stable bounded chain.
- [ ] Associated and superclass cycles fail.
- [ ] Generic local evidence remains fixed downstream.
- [ ] Explicit evidence supplies two orderings without global overlap.
- [ ] Defaults have deterministic identity and exact effects.
- [ ] Instance additions/removals appear in package API diffs and locks.
- [ ] `Hash` compatibility is tested or certified under declared policy.
- [ ] Fake `Copy` cannot copy an owner; fake canonical encoding cannot affect artifact identity.
- [ ] Fake reversible/coherent/unitary evidence cannot enter privileged lowering.
- [ ] Certified laws bind exact body/package identities.
- [ ] Constructor-kinded classes normalize and monomorphize deterministically.
- [ ] Coherent/unitary output contains no runtime dictionary dispatch.
- [ ] Forged evidence metadata fails verification.
- [ ] Self-hosted library/compiler abstractions use classes without host interfaces.

## Alternatives

### Java interfaces or structural duck typing

Insufficient as the primary mechanism. Runtime object hierarchies and accidental method-name matching do not provide static package-qualified evidence and laws over value types.

### Rust traits exactly

Close in spirit, but Wheeler's package-global evidence, class-law certificates, quantum semantics, and source model require an explicit contract. Borrowing good ideas does not require importing every corner case in the shipping crate.

### GHC overlap/incoherence

Rejected initially. Flexibility that changes behavior by module assembly is incompatible with canonical linking.

### Pass every strategy explicitly

Safe but needlessly verbose for one canonical equality/order/hash/encoding. Explicit values remain the answer when plurality is real.

### Compiler magic for every protocol

Rejected. A small sealed safety kernel is necessary; ordinary algebraic protocols belong in libraries.

### Comments or tests as all law evidence

Rejected for privileged semantics. Tests and prose are valuable, but canonical identity and unitary/inverse claims require the declared stronger evidence.

## Open questions

- For multiple principal nominal arguments, which package owns the implicit instance? — **Owner:** package and type-system maintainers — **Decide by:** multi-parameter support
- Which first standard classes require certified rather than tested laws? — **Owner:** proof and library maintainers — **Decide by:** public class stabilization
- Are generic heads such as `Eq<Option<T>> where T: Eq` in the first implementation or immediately after ground heads? — **Owner:** compiler maintainers — **Decide by:** solver implementation
- Which constructor-kinded classes validate the design without bloating the prelude? — **Owner:** library and type-system maintainers — **Decide by:** higher-kinded acceptance
- How does package SemVer classify adding a legal but potentially conflicting instance? — **Owner:** package and compatibility maintainers — **Decide by:** public instance publication

## References

- [WIP-0005](WIP-0005-wheeler-source-language.md)
- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0012](WIP-0012-wheeler-standard-library.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0022](WIP-0022-package-instances-and-resolution.md)
- [WIP-0028](WIP-0028-deterministic-ownership-borrowing-and-regions.md)
- [WIP-0029](WIP-0029-parametric-polymorphism-and-bounded-specialization.md)
- [WIP-0031](WIP-0031-reversible-quantum-and-effect-polymorphism.md)
- [How to make ad-hoc polymorphism less ad hoc](https://doi.org/10.1145/75277.75283)
- [GHC instance declarations and resolution](https://downloads.haskell.org/ghc/latest/docs/users_guide/exts/instances.html)
