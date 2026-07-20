# WIP-0034: Structured uncomputation and clean ancilla scopes

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler language, compiler, type-system, verifier, quantum, proof, runtime, and tooling maintainers |
| Created | 2026-07-20 |
| Updated | 2026-07-20 |
| Area | Language, ownership, uncomputation, ancillas, quantum IR |
| Depends on | WIP-0002, WIP-0005, WIP-0011, WIP-0028, WIP-0031, WIP-0033 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler adds a lexical compute–use–uncompute form and clean ancilla declarations for coherent and unitary code. A paired `compute { ... } use { ... }` region executes the compute block, executes the use block, then applies the validated inverse or adjoint of the compute block. Values produced for temporary use must remain available to the generated inverse, and every declared ancilla must return to its stated clean basis before the region exits. The compiler records the structure directly instead of relying on hidden runtime history or a mutable stack of prior calls.

## Motivation

Many quantum and reversible algorithms follow one pattern:

1. Derive a temporary value.
2. Use that value as a control or input.
3. Reverse the derivation.
4. Reuse the temporary storage.

Written by hand, the pattern is easy to get wrong:

```wheeler
lookup(index, table, borrow mut value);
phaseIfEqual(value, target);
reverse lookup(index, table, borrow mut value);
```

The programmer must repeat the call exactly. Generic arguments, implementation choices, classical parameters, ownership, source order, and borrowed resources must all match. A later edit can change the forward call without changing the inverse call.

The compiler also loses the intent that `value` exists only to support the middle operation. That weakens ancilla scheduling, resource analysis, diagnostics, and source-linked circuit views.

A structural region solves both problems. The programmer states the computation only once. Wheeler owns the inverse call and cleanup proof.

This feature is not ordinary exception cleanup. It cannot run arbitrary user code during scope exit, and it cannot repair a measurement or external effect. It is an exact semantic form over reversible or unitary operations.

## Use cases

### Lookup, use, and cleanup

```wheeler
unitary void markMatchingRecord(
    borrow QIndex<8> index,
    borrow ClassicalTable<8> table,
    borrow QWord<8> target,
    borrow mut QBit marked
) {
    compute {
        ancilla qvalue<BitInt<8>> value = clean(0);
        lookup(index, table, borrow mut value);
    } use {
        xorIfEqual(
            value,
            target,
            borrow mut marked
        );
    }
}
```

The compiler applies `lookup`, executes `xorIfEqual`, then applies the exact inverse of `lookup`. `value` returns to zero and leaves scope.

### Arithmetic workspace

A modular multiplication routine may allocate several clean scratch registers inside one lexical ancilla scope. The registers are visible to nested coherent calls but unavailable after the scope closes.

### Generic implementation choice

A generic routine receives one statically selected lookup implementation. The compute region records the exact closed callable identity, so generated cleanup uses the same specialization.

### Rejection after measurement

A use block that measures the computed value cannot be followed by exact uncomputation. Wheeler rejects the region instead of calling measurement “cleanup.”

### Nested conjugation

One compute–use region may appear inside another. The compiler preserves lexical nesting and emits inverse operations in the required order.

## Goals

- Add one lexical source form for compute, use, and generated uncomputation.
- Define the form over `coherent rev` and `unitary` semantics.
- Introduce compiler-owned clean ancilla declarations with fixed type, width, initial basis, and lifetime.
- Require every ancilla to return to its declared clean basis before scope exit.
- Preserve exact generic, class-evidence, callable, and parameter identity between compute and uncompute.
- Let the use block read or coherently use computed values without invalidating their inverse requirements.
- Give the compiler enough structure for ancilla reuse and peak-width analysis.
- Support nested regions and generated adjoints.
- Produce direct diagnostics for dirty values, aliasing, measurement, and changed inverse dependencies.
- Keep history, reset, measurement-assisted cleanup, and external compensation separate.

## Non-goals

- Add general `defer`, destructors, finalizers, or exception cleanup.
- Run cleanup after arbitrary traps or process failure.
- Treat reset or measurement as uncomputation.
- Let the use block perform target submission, file I/O, network I/O, randomness, or other host effects.
- Add nonlexical compute receipts in the first profile.
- Permit dynamic ancilla allocation with unknown width.
- Keep dirty ancillas alive across a measurement or job boundary.
- Select a physical ancilla allocator or fault-tolerant layout in source.
- Promise optimal ancilla scheduling.
- Define higher-level QROM, arithmetic, or search routines. Those belong in libraries.

## Terms and semantic model

### Compute block

A **compute block** is a closed sequence of coherent or unitary operations with a validated inverse or adjoint. It may introduce clean ancillas and temporary bindings whose lexical lifetime extends through the paired use block.

Call its semantic operation `C`.

### Use block

A **use block** is a closed coherent or unitary region that consumes the computed information without destroying the state needed to apply `C^-1` or `C†`.

Call its semantic operation `U` here.

### Structured uncomputation

The complete region has semantics:

```text
C ; U ; inverse(C)
```

for a coherently lifted reversible computation, or:

```text
C ; U ; adjoint(C)
```

for a unitary computation.

The source uses one paired structural form:

```wheeler
compute {
    ...
} use {
    ...
}
```

WIP-0005 and WIP-0006 own the final token spelling. This proposal owns the paired-region meaning.

### Clean basis

A **clean basis** is one exact known basis value required at both ends of an ancilla lifetime.

Examples include:

```text
BitInt<N> value 0
boolean value false
an explicitly named finite basis value
```

Cleanliness is a proof and ownership fact. It is not a request to erase an unknown value.

### Ancilla

An **ancilla** is a compiler-owned affine quantum resource introduced inside a coherent or unitary region with one fixed logical type and initial basis.

Illustrative declarations are:

```wheeler
ancilla qreg<8> scratch = clean;
ancilla qvalue<BitInt<8>> value = clean(0);
```

An ancilla is part of the semantic region shape. It is not an ordinary heap allocation and does not create a provider object.

### Inverse dependency

An **inverse dependency** is a place, classical parameter, callable identity, type-class evidence value, or structural fact required to apply the generated inverse of the compute block.

The compiler derives the dependency set before checking the use block.

### Frame-preserved use

A use operation **frame-preserves** a computed place when its checked semantic relation leaves that place unchanged, even if quantum ownership requires an exclusive borrow while the operation executes.

This distinction lets a computed value control another operation without becoming classically readable or logically modified.

## Ownership and boundaries

The language owns the paired region, its scope, ancilla declarations, and source-level name visibility.

WIP-0028 ownership rules remain authoritative for moves, borrows, disjointness, must-consume values, and use after move. This proposal adds no second aliasing model.

The type checker owns region pairing, scope, callable characteristics, effect exclusion, place overlap, and clean-basis compatibility.

The compiler owns inverse extraction, dependency analysis, frame analysis, ancilla lifetime planning, structural IR emission, and resource bounds.

The verifier owns the exact compute/use/inverse order, callable identities, ancilla initialization and return, disjointness, and prohibited effects.

The proof system owns cleanup, frame, inverse, adjoint, and resource obligations.

The runtime or target owns physical scratch resources. It may reuse physical qubits only when the accepted plan preserves the source clean-lifetime rules.

No host adapter may release, reset, or measure a dirty ancilla and report that exact uncomputation succeeded.

## Design

### Paired source form

The accepted structural shape is equivalent to:

```wheeler
compute {
    compute-statements
} use {
    use-statements
}
```

Both blocks are mandatory. They form one lexical scope.

Names declared in the compute block may be visible in the use block when their declaration explicitly permits that lifetime. They are not visible after the paired form.

Ordinary locals declared in the use block follow normal lexical scope and must satisfy all ownership obligations before the use block ends.

### Execution order

Forward execution is:

```text
enter paired scope
run compute block forward
run use block forward
run compute block inverse or adjoint
check declared ancillas clean
leave paired scope
```

The compiler does not reparse source text to construct the inverse. It uses the closed callable and structural identities produced during type checking and specialization.

### Adjoint of the paired region

For a unitary paired region:

```text
R = C ; U ; C†
```

The generated adjoint is:

```text
R† = C ; U† ; C†
```

The compute block remains in forward order around the adjoint of the use block. The compiler records this structural law instead of flattening the region and rediscovering it from gates.

For a coherent reversible region, the same rule uses the checked language inverse.

### Accepted compute statements

The first profile accepts these statements:

- direct calls to `coherent rev` or `unitary` operations;
- calls through statically closed WIP-0031 callable values;
- nested compute–use regions;
- clean ancilla declarations;
- compile-time or immutable classical parameters;
- fixed coherent control accepted by WIP-0035;
- bounded repetition accepted by WIP-0035.

It rejects these statements:

- measurement;
- reset;
- target submission;
- host effects;
- runtime undo history;
- dynamic callable dispatch;
- ordinary allocation whose release is not part of the exact inverse;
- admitted-input traps;
- unbounded recursion or loops.

### Accepted use statements

The use block may perform:

- call unitary or coherent operations on disjoint target resources;
- use a computed value as a coherent control;
- frame-preserve a computed value through a certified operation;
- introduce nested ancilla and paired regions;
- modify designated result resources that are disjoint from inverse dependencies.

The use block cannot:

- measure, reset, release, move, or overwrite a computed value;
- change an immutable classical parameter captured by the compute block;
- replace a strategy or callable identity used by the compute block;
- create an alias that outlives the paired scope;
- perform an operation whose frame relation leaves the computed value unknown;
- cross a target or workflow boundary.

### Dependency and frame checking

For each compute block, the compiler derives:

```text
ComputeSummary {
    read_places
    written_places
    produced_places
    inverse_dependencies
    introduced_ancillas
    required_entry_clean_states
    required_exit_clean_states
    effects
    callable_and_evidence_ids
    resource_expression
}
```

For each use block, it derives a frame summary.

The region is accepted only when:

```text
use preserves every inverse dependency
use does not consume any produced place needed by inverse(C)
use writes only disjoint or explicitly frame-compatible places
all introduced owners are consumed or returned by the scope end
```

Simple cases are decided by ownership and frame metadata. Harder accepted cases may use WIP-0011 evidence.

A shared source spelling such as `borrow` does not by itself prove frame preservation for a live quantum value. Quantum operations generally require exclusive ownership while they execute. The callable’s certified frame relation supplies the semantic preservation fact.

### Ancilla declaration

An ancilla declaration names:

- the logical resource type;
- the clean entry basis;
- the required clean exit basis;
- the lexical origin;
- an optional source name;
- a static width or shape.

For example:

```wheeler
ancilla qvalue<BitInt<8>> value = clean(0);
```

The initializer must be a compile-time known admitted basis value. It cannot read runtime measurement, host state, or another unknown coherent value.

A raw register declaration:

```wheeler
ancilla qreg<8> scratch = clean;
```

means all eight logical qubits begin and end in the canonical zero state.

The source does not select physical qubits. The target plan may assign and reuse physical resources after checking lifetimes.

### Ancilla lifetime

An ancilla declared in a compute block remains live through the use block and generated uncompute. It becomes unavailable immediately after the compiler verifies its clean exit.

An ancilla declared in a nested scope cannot escape through:

- a return value;
- a closure capture;
- an aggregate field;
- a target submission;
- a measurement result;
- a persisted continuation;
- an outer borrowed view whose origin would outlive the scope.

### Clean-state proof

The compiler may establish clean exit through:

- structural inverse composition;
- a callable’s certified frame and cleanup contract;
- finite exact proof;
- a WIP-0011 certificate.

Testing a few basis states is not enough to release the ancilla in verified code.

### Nested regions

Paired regions nest lexically.

```wheeler
compute {
    outerCompute();
} use {
    compute {
        innerCompute();
    } use {
        body();
    }
}
```

Forward order is:

```text
outerCompute
innerCompute
body
inverse innerCompute
inverse outerCompute
```

The verifier records the nesting directly.

### Relationship to reverse blocks

A `reverse { ... }` block runs the inverse of calls listed in the block in reverse lexical order. It is explicit inverse execution.

A compute–use region instead declares a conjugation-shaped lifetime and asks the compiler to generate the cleanup portion.

The two forms are not aliases. `reverse` may appear where the programmer wants inverse execution as the primary action. `compute/use` is for temporary information that must be cleaned after another operation uses it.

### Compiler scheduling

The source semantics places the generated inverse immediately after the use block.

A verified optimizer may move all or part of cleanup within the same enclosing coherent or unitary region only when it preserves:

- semantic equivalence;
- ownership;
- control dependencies;
- ancilla cleanliness;
- declared barriers;
- resource contracts;
- source-level debugging guarantees selected by policy.

Any movement appears in a derived transformation report under WIP-0037. It does not change the canonical source region.

### No nonlexical receipt in the first profile

This proposal does not add:

```wheeler
ComputeReceipt receipt = compute operation();
...
uncompute(receipt);
```

A nonlexical receipt would need suspension, storage, branch, aliasing, and must-consume rules. The lexical form covers the common case and gives the compiler a simpler trusted boundary.

A later proposal may eventually add affine receipts after the lexical model is implemented and measured.

## Reversibility and history

The generated cleanup uses a language inverse or unitary adjoint. It does not consume WIP-0001 step records.

The compute block may not depend on bounded logged history. A computation that needs logged overwrite is not coherently uncomputable through this form.

Ancilla release is valid only after exact clean-state evidence. Releasing memory that held a classical clean value and returning a quantum ancilla to a clean basis are different operations, even when both free implementation resources.

Measurement-assisted cleanup, reset, branch discard, compensation, replay, and retry are nonunitary workflow actions. They require separate source forms and effect rows.

A trap inside an admitted coherent or unitary region indicates malformed verified IR or a failed implementation invariant. The paired form is not a hidden exception handler. It does not promise to execute the inverse after arbitrary runtime failure.

## Concurrency and determinism

Pairing, inverse generation, dependency analysis, ancilla identities, and source diagnostics are deterministic for one closed specialization.

The compiler may analyze independent nested regions in parallel. It reduces those summaries by canonical routine and source identity.

Operations on disjoint quantum resources may be scheduled in parallel by a target. The scheduling plan must still respect compute/use/inverse dependencies and ancilla lifetime overlap.

Physical reuse may differ across targets. The logical ancilla high-water mark and clean-lifetime graph remain stable for the same semantic region and policy.

No shared mutable classical state or cross-task ancilla borrowing is introduced by this proposal.

## Quantum and proof implications

For each paired region, Wheeler creates the core obligation:

```text
R = C ; U ; inverse(C)
```

or:

```text
R = C ; U ; adjoint(C)
```

It also checks:

```text
all compute inputs required by inverse(C) are preserved by U
all introduced ancillas finish in their declared clean basis
all non-ancilla frame locations satisfy the declared postcondition
R contains no measurement, reset, target, or host effect
```

A callable used in the use block may carry a frame theorem such as:

```text
preserves(control_value)
```

That theorem allows coherent use of a computed value without preventing later uncomputation.

Proof certificates bind the closed compute and use bodies, selected generic and type-class evidence, source region identity, resource profile, and compiler profile.

A hardware experiment may report whether measured outputs match expectations. It cannot prove that an unmeasured ancilla was clean on every execution.

## Bytecode, persistence, and compatibility

Canonical `.wbc` records paired-region metadata in quantum or coherent body IR.

The semantic form contains:

```text
ComputeUseRegion {
    region_id
    compute_body
    use_body
    inverse_or_adjoint_body
    dependency_summary
    ancilla_descriptors
    frame_evidence
    resource_bound_id
    certificate_ids
    source_map
}
```

The inverse or adjoint identity is explicit. A loader never reconstructs it from source order or a method name.

Ancilla descriptors contain logical type, width, clean entry and exit basis, origin, and lexical lifetime. They contain no physical coordinates.

Existing artifacts without this required feature remain valid. Loaders that do not understand the paired-region feature reject an artifact that requires it before execution.

The feature does not create persisted live quantum values. Hybrid runs persist only ordinary continuation state and observations under WIP-0004.

## Safety, limits, and failures

Limits cover:

- nesting depth;
- statements per block;
- introduced ancillas;
- logical ancilla width;
- total and peak logical width;
- dependency places;
- frame facts;
- generic specializations;
- generated inverse size;
- proof obligations;
- resource expressions;
- compiler time and memory;
- diagnostics.

The first stable diagnostic families should include:

```text
WUNC001 compute block has no exact inverse or adjoint
WUNC002 prohibited effect in compute block
WUNC003 prohibited effect in use block
WUNC004 use block changes an inverse dependency
WUNC005 computed value is moved, measured, reset, or released
WUNC006 ancilla is not clean at scope exit
WUNC007 ancilla escapes its lexical scope
WUNC008 compute and generated inverse select different specialization evidence
WUNC009 overlapping quantum places in paired region
WUNC010 paired-region resource limit exceeded
WUNC011 unsupported trap or dynamic dispatch remains
WUNC012 missing frame or cleanup evidence
```

A failed check emits no partial paired region, generated inverse body, proof certificate, or target plan.

## Migration and deletion

1. Add paired-region nodes to typed source and semantic IR.
2. Add compute-block inverse and adjoint extraction over closed callables.
3. Add inverse-dependency and frame summaries.
4. Add clean ancilla declarations over `qreg` and accepted `qvalue<T>` types.
5. Add lexical lifetime and escape checking.
6. Add semantic simulator and verifier support.
7. Add cleanup, frame, adjoint, and resource proof obligations.
8. Add parser, Tree-sitter, formatter, documentation, disassembly, and diagnostics.
9. Migrate one QROM-like fixture and one arithmetic-workspace fixture.
10. Delete duplicated manual forward/reverse call pairs and temporary cleanup annotations replaced by the accepted form.

## Progress

- [ ] Paired source and IR structure is accepted.
- [ ] Closed compute blocks generate exact cleanup.
- [ ] Use-block frame checking executes.
- [ ] Clean `qreg` ancillas execute and verify.
- [ ] Clean typed `qvalue<T>` ancillas execute and verify.
- [ ] Nested regions generate the correct order.
- [ ] Generated adjoints preserve paired structure.
- [ ] Ancilla lifetime and peak-width reports are deterministic.
- [ ] Cleanup certificates check.
- [ ] Manual duplicate cleanup paths are deleted from migrated fixtures.

## Testing and acceptance

- [ ] A compute–use region produces the same semantic action as the explicit forward/use/inverse sequence.
- [ ] The programmer writes the compute call only once.
- [ ] Generic arguments, associated types, evidence, and callable identities match between compute and cleanup.
- [ ] A computed value may control a frame-preserving operation and still uncompute.
- [ ] Mutation, move, measurement, reset, or release of an inverse dependency is rejected.
- [ ] Every declared ancilla returns to its exact clean basis in the ideal simulator.
- [ ] The proof kernel accepts the corresponding cleanup certificate.
- [ ] Nested regions uncompute in the required order.
- [ ] The adjoint of a paired region uses the compute block, adjoint use block, and cleanup block in the correct order.
- [ ] Measurement, host effects, history, and target submission fail before publication.
- [ ] Ancilla escape through return, aggregate, closure, or continuation is rejected.
- [ ] Peak logical width is stable under parser, allocation, and compiler-worker order changes.
- [ ] Existing explicit `reverse` behavior remains unchanged.
- [ ] Current reference docs describe the form only after implementation.

## Alternatives

### Require explicit forward and inverse calls

Rejected as the only form. It duplicates source and hides the temporary lifetime from the compiler.

### Use a mutable call stack like an object-level `uncompute()` method

Rejected. Cleanup identity would depend on runtime object history and call order. It would also interact poorly with aliasing, generic specialization, nested calls, and compiler scheduling.

### Add general `defer`

Rejected. General scope-exit code would mix exact uncomputation with traps, I/O, cancellation, and cleanup effects. Wheeler needs a narrower semantic form.

### Treat reset as acceptable cleanup

Rejected. Reset is an explicit nonunitary effect. It cannot satisfy an exact clean-ancilla theorem.

### Make ancillas normal droppable values

Rejected. Automatic drop cannot prove that unknown quantum state returned to the required basis.

### Add nonlexical compute receipts first

Rejected. They add ownership and suspension problems before the lexical contract is proven useful.

### Infer compute–use patterns from optimized IR

Rejected. Source intent, diagnostics, proof identity, and resource lifetime should not depend on a pattern-matching optimization.

## Open questions

- Should the source keywords be `compute` and `use`, `within` and `apply`, or another paired spelling? **Owner:** language, formatter, and teaching maintainers. **Decide by:** before Review.
- Which typed basis initializers are accepted for `ancilla qvalue<T>` in the first profile? **Owner:** type-system and quantum maintainers. **Decide by:** before parser implementation.
- May a verified optimizer delay cleanup across a sibling operation by default, or only under an explicit optimization policy? **Owner:** compiler, debugging, and tooling maintainers. **Decide by:** before optimization acceptance.
- Which frame facts may the compiler derive automatically, and which require WIP-0011 evidence? **Owner:** type-system and proof maintainers. **Decide by:** before implementation.
- Should the first profile permit the form in ordinary noncoherent `rev` code, or restrict it to coherent and unitary bodies? **Owner:** language and reversible-runtime maintainers. **Decide by:** before acceptance.

## References

- [WIP-0002](WIP-0002-unified-classical-quantum-semantics.md)
- [WIP-0005](WIP-0005-wheeler-source-language.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0028](WIP-0028-deterministic-ownership-borrowing-and-regions.md)
- [WIP-0031](WIP-0031-reversible-quantum-and-effect-polymorphism.md)
- [WIP-0033](WIP-0033-typed-coherent-values-and-reversible-embeddings.md)
- [WIP-0035](WIP-0035-reversible-and-coherent-control-flow.md)
- [WIP-0037](WIP-0037-hierarchical-semantic-routine-graphs.md)
