# WIP-0035: Reversible and coherent control flow

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler language, compiler, type-system, verifier, reversible-runtime, quantum, proof, and tooling maintainers |
| Created | 2026-07-20 |
| Updated | 2026-07-20 |
| Area | Language, control flow, reversibility, coherent control, proofs |
| Depends on | WIP-0002, WIP-0005, WIP-0011, WIP-0013, WIP-0017, WIP-0028, WIP-0031, WIP-0033, WIP-0034 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler adds exact control-flow rules for `rev`, `coherent rev`, and `unitary` bodies. A reversible conditional is accepted when its branch choice can be reconstructed from the post-state or from an explicit retained witness. A reversible counted loop runs its validated inverse body in reverse iteration order. Coherent control uses the structural `controlled (control) { ... }` form rather than a classical branch or hidden measurement. The first profile keeps all bounds static, rejects `break`, `continue`, and data-dependent `while` in reversible or coherent code, and records enough control metadata for verification, proof, resource analysis, and generated inverse or adjoint behavior.

## Motivation

Straight-line reversible code is useful, but it cannot express most data structures or algorithms.

A reversible map needs to choose a search path. A trie follows key bits. A bounded parser loops over input. A coherent arithmetic routine repeats a bit operation. A controlled quantum routine applies an operation only when a coherent bit is set.

Ordinary control flow cannot be copied into those contexts without new rules.

This branch is not automatically reversible:

```wheeler
if (state.ready) {
    state.ready = false;
    stepA(state);
} else {
    stepB(state);
}
```

After the body runs, the inverse may no longer know which branch was taken. Guessing would make the inverse relation partial or wrong.

This quantum branch is also invalid:

```wheeler
if (control) {
    operation();
}
```

Reading `control` as a classical Boolean would measure it. Treating the source `if` as coherent control without saying so would overload one syntax with two different observations.

The language therefore needs separate, checkable rules for:

- classical reversible branch reconstruction;
- fixed-count inverse traversal;
- static classical circuit construction;
- coherent controlled application.

## Use cases

### Protected reversible branch

```wheeler
rev void moveByMode(borrow mut State state) {
    if (state.mode == Mode.Left) {
        moveLeft(borrow mut state);
    } else {
        moveRight(borrow mut state);
    }
}
```

The compiler accepts the branch when both paths preserve `state.mode`. The generated inverse evaluates the same predicate on the post-state and invokes the matching branch inverse.

### Explicit branch witness

A branch that changes the original predicate retains its decision in ordinary reversible state:

```wheeler
rev void transition(borrow mut State state) {
    state.branchWitness ^= shouldTakeFastPath(state);

    if (state.branchWitness) {
        fastStep(borrow mut state);
    } else {
        slowStep(borrow mut state);
    }
}
```

Both branches preserve `branchWitness`. A later inverse can reconstruct the choice exactly. The caller may clear the witness after reversing the transition.

### Fixed-count reversible loop

```wheeler
rev void applyRounds<const long N>(borrow mut State state) {
    for (long round = 0; round < N; round += 1) limit N {
        roundStep(borrow mut state, round);
    }
}
```

The inverse executes `roundStep` inverses for `N - 1` down to `0`.

### Coherent controlled application

```wheeler
unitary void applyWhen(
    borrow mut qvalue<boolean> control,
    borrow mut qvalue<State> state
) {
    controlled (control) {
        step(borrow mut state);
    }
}
```

The block does not inspect or measure `control`. It lowers to a controlled semantic operation.

### Static circuit selection

A unitary generic may branch on a compile-time or immutable classical parameter before quantum-region emission:

```wheeler
unitary void transform<const boolean INVERSE>(borrow mut qreg<8> q) {
    if (INVERSE) {
        inverseTransform(borrow mut q);
    } else {
        forwardTransform(borrow mut q);
    }
}
```

The selected branch becomes part of the closed routine identity. No runtime coherent branch remains.

## Goals

- Permit reversible `if` and exhaustive `match` when branch choice is reconstructible.
- Let the compiler derive simple protected-predicate proofs.
- Let programs retain explicit branch witnesses in normal reversible state.
- Permit fixed-count `for` loops in reversible and coherent bodies.
- Generate inverse loops in reverse iteration order.
- Permit static classical conditionals and matches during unitary or coherent construction.
- Add explicit coherent controlled application.
- Preserve control resources and prevent measurement or mutation of the control.
- Reuse custom or compiler-generated controlled callable descriptors from WIP-0031.
- Record branch, loop, control, inverse, and resource metadata in Wheeler IR.
- Give source-located diagnostics that explain which value lost the branch or loop decision.

## Non-goals

- Make arbitrary `while`, recursion, early return, `break`, or `continue` reversible in the first profile.
- Add hidden branch or iteration logs to `coherent rev` or `unitary` code.
- Treat a coherent control as a classical Boolean expression.
- Permit measurement-conditioned host control inside a unitary body.
- Define target-resident dynamic-circuit feedback. WIP-0002 and WIP-0003 own that boundary.
- Infer that every ordinary conditional is protected.
- Promise optimal synthesis of controlled operations.
- Add unrestricted runtime polymorphism in controlled or repeated regions.
- Define parallel shared-memory execution.
- Add general quantum loops with a coherent iteration count.

## Terms and semantic model

### Protected predicate

A **protected predicate** is a deterministic Boolean expression whose truth value is the same at the corresponding forward and inverse branch boundaries.

For a branch predicate `p` and branch operation `B`, Wheeler needs:

```text
p(pre_state) == p(post_state)
```

for every successful execution of that branch under its precondition.

The predicate may read immutable values, frame-preserved fields, or explicit witnesses. It may not depend on a value that the branch destroys or changes in a way that loses the original truth value.

### Branch witness

A **branch witness** is ordinary retained state that records enough information to choose the inverse branch.

A witness is not hidden VM history. It is visible in the source type and participates in the operation’s forward and inverse contracts.

### Reversible conditional

For:

```text
if p then A else B
```

forward execution is ordinary branch selection. The generated inverse is:

```text
if p then inverse(A) else inverse(B)
```

The form is valid only when `p` is protected across `A` and `B`, ownership joins are valid, and both branches have accepted inverses.

### Reversible match

An exhaustive `match` over a finite protected scrutinee follows the same rule. Each arm must preserve the discriminant or retain an explicit witness sufficient to reconstruct the selected case.

### Reversible counted loop

A **reversible counted loop** has one fixed finite iteration count and a reversible body.

Forward iteration order is:

```text
0, 1, ..., count - 1
```

The generated inverse iteration order is:

```text
count - 1, ..., 1, 0
```

The count and any immutable range values must be available with the same meaning during inverse execution.

### Static classical control

**Static classical control** chooses quantum or coherent region structure from a compile-time constant or immutable classical parameter before semantic region emission.

It is normal classical planning. It does not create a coherent branch.

### Coherent control

**Coherent control** applies a unitary or coherent operation conditioned on a live coherent Boolean without observing it.

The structural source form is:

```wheeler
controlled (control) {
    ...
}
```

Its basis semantics are:

```text
|0>|x> -> |0>|x>
|1>|x> -> |1>|U(x)>
```

The control is preserved and may become entangled with the target.

### Controlled implementation

A **controlled implementation** is either:

- a compiler-synthesized controlled form of one accepted operation; or
- a declared specialization with exact controlled-equivalence evidence.

The selected implementation is derived planning data. The source controlled semantics remain fixed.

## Ownership and boundaries

The language owns the classification of ordinary `if`, reversible branch, static classical branch, and `controlled` region.

WIP-0013 remains authoritative for ordinary classical control-flow syntax, bounds, frames, and verifier dataflow.

The type checker owns predicate typing, place reads and writes, protected-predicate analysis, ownership joins, loop bounds, control ownership, and effect restrictions.

The compiler owns inverse branch and loop generation, static branch elimination, controlled callable selection, source mapping, and resource composition.

The proof system owns protected-predicate, branch-discriminant, loop-inverse, controlled-equivalence, and resource obligations.

The verifier owns branch metadata, loop direction, callable characteristics, control-resource preservation, absence of prohibited effects, and closed dispatch.

The runtime owns ordinary reversible branch execution and inverse execution. Quantum targets own physical controlled lowering after Wheeler planning.

No target may measure a coherent control merely because its hardware implementation lacks a direct controlled operation. It must lower exactly, use an accepted decomposition, or reject the plan.

## Design

### Reversible `if`

A normal source `if` may appear in a `rev` method when the compiler proves both branches preserve the predicate’s truth value.

```wheeler
rev void update(borrow mut State state) {
    if (state.direction == Direction.Left) {
        leftUpdate(borrow mut state);
    } else {
        rightUpdate(borrow mut state);
    }
}
```

The compiler derives the predicate read set and each branch frame relation.

The branch is accepted when:

```text
all predicate reads are available at the inverse boundary
both branches preserve predicate truth
both branches have exact inverse bodies
both branches leave compatible owner, borrow, and clean states
neither branch hides a barrier
```

A syntactically unchanged field is not enough when a called operation may alias and change it. Frame evidence follows places and origins, not names.

### Automatic protected-predicate analysis

The first profile automatically accepts predicates over:

- immutable parameters;
- compile-time constants;
- fields or locals untouched by either branch;
- fields passed only to certified frame-preserving calls;
- explicit witness values preserved by both branches.

More complex preservation may use a WIP-0011 theorem.

The compiler reports the exact predicate place and branch operation that prevented reconstruction.

### Explicit witnesses

Wheeler does not add a second hidden branch-log syntax.

When the original predicate cannot be preserved, the program records a witness using ordinary reversible operations and branches on that witness.

For a Boolean witness initialized to false:

```wheeler
witness ^= predicate;
```

retains the decision reversibly. The body must preserve `witness` until inverse branch selection is complete.

The witness may later be cleared only after the computation that depended on it has been reversed or otherwise transformed under an exact contract.

### Reversible `match`

An exhaustive match is accepted when its scrutinee tag is protected:

```wheeler
rev void act(borrow mut State state) {
    match (state.mode) {
        case Mode.Read() {
            readStep(borrow mut state);
        }
        case Mode.Write() {
            writeStep(borrow mut state);
        }
    }
}
```

The inverse evaluates the same protected scrutinee and invokes the matching arm inverse.

Payload bindings follow ordinary ownership rules. An arm cannot move or destroy a payload needed to reconstruct the match unless the value remains present elsewhere under the declared inverse relation.

### Fixed-count reversible `for`

The first loop profile accepts a canonical counted range with no `break`, `continue`, or early return:

```wheeler
for (long i = start; i < end; i += step) limit count {
    body(i);
}
```

The compiler proves:

- `count` is finite and exact;
- `start`, `end`, `step`, and `count` are immutable or reconstructible;
- the sequence contains exactly `count` indices;
- the body is reversible or coherent as required;
- each iteration leaves compatible owner and clean states;
- the loop body cannot change the iteration descriptor.

The generated inverse enumerates the same indices in reverse order and invokes the body inverse.

The initial accepted source may be narrower:

```wheeler
for (long i = 0; i < N; i += 1) limit N {
    ...
}
```

WIP-0005 and WIP-0006 own the exact first grammar slice.

### Loop index

The loop index is an immutable compiler-owned local for each iteration. The inverse reconstructs it from the iteration descriptor.

The index may be passed to a reversible body as immutable classical data. It may not escape the iteration scope, become an external observation, or be overwritten.

### Reversible `while`

The first profile rejects `while` in `rev`, `coherent rev`, and `unitary` bodies.

A later extension may admit a witnessed loop with:

- a bounded iteration count;
- an explicit retained exit trace or reconstructible termination predicate;
- an inverse traversal law;
- a static history or workspace bound.

Rejecting the form now avoids hidden per-iteration history.

### `break`, `continue`, and early return

The first reversible and coherent loop profile explicitly rejects:

```text
break
continue
early return
```

Each form changes the iteration trace. Supporting it requires an explicit control witness or a stronger structural loop form.

Ordinary classical methods keep WIP-0013 behavior.

### Static control in unitary and coherent bodies

A unitary or coherent body may use ordinary `if` or `match` when the condition is known classical planning data and resolves before region emission.

Accepted conditions include:

- const generic values;
- compile-time constants;
- immutable classical parameters captured by a closed operation;
- target capability choices resolved before the canonical semantic operation is selected, when the source contract permits distinct implementations.

No runtime classical branch instruction remains inside the emitted unitary body. The selected branch identity contributes to routine and circuit identity.

A branch on a measurement result is hybrid control, not static control.

### Coherent controlled block

The accepted structural form is:

```wheeler
controlled (control) {
    body
}
```

`control` must be one live coherent Boolean value or admitted one-bit view. It cannot be an ordinary Boolean, measurement result, or host value.

The control place is borrowed exclusively for the duration of the block under quantum ownership rules. The block must frame-preserve it.

The body may contain:

- direct unitary calls;
- coherent callable applications;
- nested compute–use regions;
- fixed-count loops;
- nested controlled blocks;
- clean ancilla scopes.

The body may not contain:

- measurement;
- reset;
- target submission;
- host effects;
- ordinary runtime branch on the control;
- mutation of the control;
- dynamic callable dispatch;
- admitted-input traps.

### Controlled callable selection

For each operation inside the block, the compiler selects one closed controlled implementation.

Selection order follows named planning policy but must choose among exact implementations:

1. use a declared certified controlled specialization when selected by policy;
2. synthesize a controlled form from the semantic operation when supported and within bounds;
3. decompose through accepted controlled primitives;
4. reject the plan.

The compiler cannot silently measure the control, approximate the operation without an error budget, or switch to host control.

### Nested controls

Nested positive controls compose semantically:

```wheeler
controlled (left) {
    controlled (right) {
        operation();
    }
}
```

The operation runs only when both controls are one.

The first profile may lower nested controls directly or combine them into a multi-control descriptor. Both forms must preserve exact source behavior and resource identity.

Negative control and arbitrary Boolean control expressions are deferred. A programmer may express a negative control through explicit reversible basis changes when valid.

### Controlled compute–use regions

A controlled paired region may exploit conjugation structure.

For:

```text
C ; U ; C†
```

controlling only `U` is semantically valid when `C` is unconditional and the complete region has the required conjugation form.

Wheeler may use this structure under exact transformation evidence. It must not control every gate by default when a cheaper exact structured implementation exists, nor assume the optimization without proof.

WIP-0034 provides the structure. WIP-0037 records the derived transformation.

### Coherent repetition

A fixed-count loop in a unitary or coherent body lowers to repeated application.

The count must be classical and resolved before execution. The compiler may retain a symbolic repeat node rather than unroll it immediately.

A coherent loop count in superposition is not accepted by this proposal. It needs a different semantic operation over a counter register.

## Reversibility and history

Protected branches and counted loops use exact language inverses. They do not require WIP-0001 step history to choose the path.

An explicit branch witness is ordinary program state. It is not a hidden undo record.

A `rev` method may still contain logged operations when its declared history contract permits them under WIP-0001. Such a method is not coherently eligible, and this proposal does not make the logged control path a coherent branch.

Coherent control is unitary. It does not observe the control.

Measurement-conditioned behavior remains an explicit nonunitary boundary. Replay may reproduce the later classical branch, but it does not turn the measured control back into a coherent value.

## Concurrency and determinism

Protected-predicate analysis, branch inverse selection, loop index order, static branch elimination, controlled implementation selection, and diagnostics are deterministic for one closed artifact and named policy.

Parallel compilation reduces branch and loop obligations by canonical callable and source identity.

A target may schedule operations on disjoint resources concurrently. It must preserve control dependencies and declared barriers.

Physical completion order does not alter semantic branch order. This proposal adds no shared classical concurrency or per-thread reverse stack.

## Quantum and proof implications

A reversible branch produces obligations equivalent to:

```text
forall state satisfying precondition:
    if p(state) then
        p(A(state)) == true
        and inverse(A)(A(state)) == state
    else
        p(B(state)) == false
        and inverse(B)(B(state)) == state
```

A reversible match extends the rule to every case.

A reversible counted loop produces:

```text
inverse(repeat_forward(body, indices))
    ==
repeat_reverse(inverse(body), reverse(indices))
```

The compiler also checks owner and frame invariants at each iteration boundary.

A controlled operation produces the exact basis obligation:

```text
Controlled(U)(false, x) == (false, x)
Controlled(U)(true, x) == (true, U(x))
```

A custom controlled specialization must establish controlled equivalence, not merely ordinary equality up to global phase when that weaker relation is insufficient under control.

Hardware samples cannot prove branch protection, loop inversion, or controlled equivalence.

## Bytecode, persistence, and compatibility

Canonical `.wbc` extends classical and quantum body metadata with required control descriptors.

Each reversible branch descriptor records:

```text
ReversibleBranchDescriptor {
    predicate_body_id
    predicate_read_places
    true_body_id
    false_body_id
    preservation_evidence
    owner_join_summary
    inverse_mapping
    source_map
}
```

Each reversible loop descriptor records the following:

```text
ReversibleLoopDescriptor {
    iteration_domain
    count_expression
    forward_body_id
    inverse_body_id
    index_binding
    loop_invariant_evidence
    resource_bound_id
}
```

A coherent controlled node records all these fields:

```text
ControlledRegion {
    control_place
    body_id
    selected_controlled_descriptors
    preservation_evidence
    resource_bound_id
    source_map
}
```

Physical decompositions remain derived target artifacts.

Existing artifacts without these required features remain valid. Loaders that do not understand a required reversible-control or coherent-control form reject the artifact before execution.

No branch witness or loop trace is serialized unless it is ordinary source state or a separately declared history record.

## Safety, limits, and failures

Limits cover:

- branch nesting;
- predicate expression size;
- read and write places;
- frame facts;
- match arms;
- loop count and range expressions;
- repeated body size;
- controlled nesting;
- controlled synthesis size;
- ancillas and depth;
- proof obligations;
- compiler time and memory;
- diagnostics.

The first stable diagnostic families should include:

```text
WRCF001 reversible branch predicate is not protected
WRCF002 branch destroys or moves a predicate dependency
WRCF003 branch owner states do not join
WRCF004 reversible match scrutinee is not reconstructible
WRCF005 reversible loop has no exact fixed iteration domain
WRCF006 break, continue, early return, or while is unsupported here
WRCF007 loop body changes its iteration descriptor
WRCF008 loop body has no accepted inverse

WCTL001 coherent control requires a live coherent Boolean
WCTL002 controlled block changes or consumes its control
WCTL003 prohibited effect in controlled block
WCTL004 no exact controlled implementation is available
WCTL005 dynamic dispatch remains inside controlled region
WCTL006 controlled synthesis exceeds resource limits
WCTL007 custom controlled evidence is missing or too weak
WCTL008 classical if cannot branch on a coherent value
```

Failure during checking emits no partial inverse branch, inverse loop, controlled body, proof certificate, or target plan.

## Migration and deletion

1. Add protected-predicate and branch-frame summaries to typed IR.
2. Add reversible `if` over simple untouched predicates.
3. Add protected exhaustive `match`.
4. Add fixed-count reversible `for` and reverse iteration generation.
5. Add proof hooks for branch preservation and loop invariants.
6. Add static classical branch elimination in coherent and unitary bodies.
7. Add `controlled` source and semantic-region nodes.
8. Add controlled callable selection through WIP-0031 descriptors.
9. Add nested control and compute–use integration.
10. Add parser, Tree-sitter, formatter, disassembly, documentation, and diagnostics.
11. Migrate one reversible tree or trie traversal and one controlled arithmetic fixture.
12. Delete temporary branch-history annotations, duplicated inverse loops, and gate-by-gate control prototypes replaced by the accepted forms.

## Progress

- [ ] Protected reversible `if` is accepted.
- [ ] Explicit branch witnesses work through ordinary state.
- [ ] Protected reversible `match` is accepted.
- [ ] Fixed-count reversible loops execute and invert.
- [ ] Static classical control closes before quantum emission.
- [ ] Coherent controlled blocks execute in the semantic simulator.
- [ ] Custom controlled specializations can be selected with evidence.
- [ ] Nested controls and compute–use regions compose.
- [ ] Resource and proof metadata integrate.
- [ ] Temporary control-flow prototypes are deleted.

## Testing and acceptance

- [ ] A branch over an unchanged mode field executes forward and inverse without history.
- [ ] A branch that changes its predicate is rejected.
- [ ] The same branch succeeds when the programmer retains an explicit witness.
- [ ] Exhaustive reversible match selects the same arm in forward and inverse directions.
- [ ] A counted loop executes body inverses in exact reverse index order.
- [ ] `break`, `continue`, early return, and `while` fail in the first reversible profile.
- [ ] Ownership, borrows, and clean states join across every accepted branch and iteration.
- [ ] A unitary branch on a const parameter is eliminated before semantic region emission.
- [ ] A classical `if` on a coherent value is rejected with guidance to use `controlled`.
- [ ] A controlled block preserves the control and applies the body only on the one basis state.
- [ ] Measurement, reset, host effects, and dynamic dispatch are rejected inside a controlled block.
- [ ] Declared and synthesized controlled forms agree with the source semantic operation.
- [ ] Controlled paired regions may use an accepted structure-aware lowering.
- [ ] VM inverse execution, semantic simulation, generated circuits, and proof certificates agree.
- [ ] Current reference docs describe the forms only after implementation.

## Alternatives

### Log every branch decision

Rejected as the default reversible rule. It turns control flow into hidden history, blocks coherent lifting, and obscures the information cost.

### Require a new keyword for every reversible branch

Rejected initially. Ordinary `if` can retain its familiar meaning when the compiler proves the stronger inverse rule. Diagnostics explain why a particular use fails.

### Let the inverse guess the branch

Rejected. Guessing is not an exact inverse relation.

### Treat coherent control as ordinary `if`

Rejected. A classical condition observes a Boolean. Coherent control preserves and may entangle a quantum resource.

### Always control every generated gate

Rejected. It can be much more expensive than a structure-aware controlled implementation and may lose useful routine hierarchy.

### Add arbitrary coherent Boolean expressions as controls now

Rejected for the first profile. Single positive controls and nesting establish the semantic base without adding another expression language.

### Permit dynamic `while` with an emergency limit

Rejected. A runtime ceiling does not provide the iteration trace needed for inverse execution.

## Open questions

- Should protected-predicate syntax remain implicit, or should source allow an optional `preserving` clause for difficult diagnostics and proofs? **Owner:** language and proof maintainers. **Decide by:** before Review.
- Which counted-range forms beyond `0 .. N` belong in the first reversible loop profile? **Owner:** language, compiler, and formatter maintainers. **Decide by:** before parser implementation.
- Should negative controls be first-profile syntax or an immediate library pattern over X conjugation? **Owner:** quantum and teaching maintainers. **Decide by:** before controlled syntax freeze.
- Under what policy may the compiler synthesize a controlled form instead of requiring a declared specialization? **Owner:** compiler, quantum, and resource maintainers. **Decide by:** before target planning implementation.
- Which global-phase equivalence rules are sufficient for an uncontrolled implementation but insufficient for its controlled form? **Owner:** proof and quantum maintainers. **Decide by:** before custom controlled certificates are accepted.

## References

- [WIP-0002](WIP-0002-unified-classical-quantum-semantics.md)
- [WIP-0005](WIP-0005-wheeler-source-language.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0013](WIP-0013-typed-frames-control-flow-and-storage.md)
- [WIP-0017](WIP-0017-compile-time-constants-and-finite-enums.md)
- [WIP-0028](WIP-0028-deterministic-ownership-borrowing-and-regions.md)
- [WIP-0031](WIP-0031-reversible-quantum-and-effect-polymorphism.md)
- [WIP-0033](WIP-0033-typed-coherent-values-and-reversible-embeddings.md)
- [WIP-0034](WIP-0034-structured-uncomputation-and-clean-ancilla-scopes.md)
- [WIP-0036](WIP-0036-symbolic-resource-contracts-and-compositional-cost-evidence.md)
- [WIP-0037](WIP-0037-hierarchical-semantic-routine-graphs.md)
