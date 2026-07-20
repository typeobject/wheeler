# WIP-0036: Symbolic resource contracts and compositional cost evidence

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler language, compiler, verifier, proof, quantum, runtime, target, tooling, and documentation maintainers |
| Created | 2026-07-20 |
| Updated | 2026-07-20 |
| Area | Language, resource bounds, proofs, quantum planning, diagnostics |
| Depends on | WIP-0001, WIP-0002, WIP-0003, WIP-0011, WIP-0017, WIP-0029, WIP-0030, WIP-0031, WIP-0034, WIP-0035 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler adds symbolic resource contracts to declarations and canonical resource evidence to closed callables and semantic regions. A contract may state an exact value or upper bound for compiler-owned dimensions such as steps, storage, history, logical qubits, clean ancillas, semantic operations, depth, measurements, and target submissions. Formulas use bounded const-generic expressions and are checked after specialization. The compiler composes resources according to the semantics of calls, branches, loops, controls, ancilla lifetimes, and compute–use regions. Exact, proved, modeled, and empirical claims remain distinct, and Wheeler does not replace Big-O notation with a new asymptotic language.

## Motivation

Wheeler already treats limits as part of execution. Functions have step and storage bounds. Reversible code has history and workspace costs. Quantum regions have qubit, gate, depth, and measurement requirements. Hybrid runs have submissions, shots, result bytes, retries, and cost ceilings.

Today those facts are scattered across descriptors, target reports, proof sketches, and implementation-specific counters.

That is not enough for generic coherent code.

A routine such as an `N`-bit adder needs to state a bound before `N` is known:

```text
clean ancillas <= N
semantic depth <= 12 * N + 4
```

A caller must combine that formula with its own repetitions and sibling scratch. A target planner must compare the closed result with device limits. A proof certificate must name the same metric and model. A tool must also explain which source routine dominates the total.

One scalar “cost” would be misleading. Different implementations trade qubits, depth, compilation time, and error. Wheeler therefore needs a typed resource vector with separate dimensions and an explicit evidence level.

The language does not need to invent new asymptotic notation. `O(n)` remains useful in papers and documentation. Executable planning needs finite formulas and checked bounds for one closed program.

## Use cases

### Generic resource contract

```wheeler
coherent rev void add<const long N>(
    borrow mut BitInt<N> left,
    borrow mut BitInt<N> right,
    borrow mut BitInt<N + 1> carry
)
resources {
    logical_qubits <= 3 * N + 1;
    clean_ancillas <= N;
    semantic_operations <= 24 * N + 8;
    semantic_depth <= 12 * N + 4;
    measurements == 0;
    history_bytes == 0;
}
{
    ...
}
```

The compiler checks every symbolic formula for each closed `N` before coherent lowering.

### Implementation tradeoff

Two adders may satisfy the same semantic class but publish different resource profiles. A planning layer chooses one explicit strategy before the unitary region closes.

### Compute–use composition

For a region with compute `C`, use `U`, and generated cleanup `C†`, Wheeler derives count and depth expressions for `C + U + C†` while calculating peak ancillas from overlapping lifetimes rather than adding every child width.

### Reversible history budget

A classical reversible operation may declare:

```wheeler
resources {
    history_bytes <= 64;
    region_bytes <= 4096;
}
```

A stronger coherent contract requires `history_bytes == 0`.

### Target rejection

A target planner receives a closed semantic resource profile. It rejects a plan requiring 70 logical qubits when the selected target descriptor offers 64. No provider submission begins.

### Exact and empirical separation

The compiler may prove an exact logical T count. A fault-tolerant architecture model may estimate physical qubits. A hardware experiment may measure runtime. These results appear together in a report, but they keep different types and evidence.

## Goals

- Add a canonical source form for symbolic resource contracts.
- Support exact equality and checked upper bounds.
- Evaluate formulas over const generics, shapes, associated constants, and finite compiler-known values.
- Define one initial set of compiler-owned resource dimensions.
- Compose resources through calls, branches, loops, controlled regions, adjoints, ancilla scopes, and compute–use regions.
- Distinguish cumulative resources from peak resources.
- Bind every formula to a resource-model profile.
- Carry resource expressions and closed values in canonical `.wbc` metadata.
- Generate WIP-0011 proof obligations for declared bounds.
- Keep ideal semantic resources separate from target-qualified and empirical resources.
- Give tools enough identity to attribute costs to source routines.
- Fail before publication when formulas overflow, remain unresolved, or contradict derived bounds.

## Non-goals

- Add a replacement for Big-O, Theta, or Omega notation.
- Prove asymptotic lower bounds for arbitrary algorithms.
- Collapse all costs into one score.
- Standardize one fault-tolerant architecture, error-correction code, provider billing model, or physical-runtime model.
- Permit arbitrary user code during resource evaluation.
- Treat a sampled target result as an exact resource theorem.
- Let a target adapter weaken a source contract.
- Promise globally optimal ancilla allocation, routing, or implementation selection.
- Define high-level optimizer policies. Those belong in libraries and tools.
- Make every modeled or empirical metric part of core source syntax.

## Terms and semantic model

### Resource dimension

A **resource dimension** is one named nonnegative quantity with one declared composition model and profile identity.

The initial compiler-owned dimensions are grouped by domain.

Classical execution:

```text
steps
call_depth
frame_slots
stack_bytes
region_bytes
live_objects
history_bytes
```

Reversible and coherent execution:

```text
clean_workspace_bits
retained_witness_bits
hidden_history_bytes
```

Ideal quantum regions:

```text
logical_qubits
clean_ancillas
semantic_operations
semantic_two_qubit_operations
semantic_depth
measurements
resets
```

Hybrid execution:

```text
target_submissions
shots
result_bytes
retries
pending_jobs
```

The exact first list may be reduced before acceptance. Each admitted dimension has one stable semantic definition.

### Resource expression

A **resource expression** is a bounded canonical expression over:

- nonnegative integer literals;
- const-generic parameters;
- shape dimensions;
- accepted associated constants;
- closed resource expressions from callees;
- checked `+` and `*`;
- a small closed set of total intrinsics such as `max`, `ceilDiv`, and `powerOfTwoCeil`;
- conditionals whose condition is a compile-time Boolean.

Expressions are not runtime values. They cannot read state, measurement, clocks, target queues, provider data, or arbitrary function results.

### Resource contract

A **resource contract** attaches one or more claims to a declaration:

```wheeler
resources {
    logical_qubits <= 3 * N + 1;
    measurements == 0;
}
```

The first relation forms are:

```text
metric == expression
metric <= expression
```

An equality claim requires exact derivation or proof. An upper-bound claim may permit a smaller derived value.

### Derived resource profile

A **derived resource profile** is the compiler’s canonical expression or closed value for each resource dimension after analyzing the declaration body.

It is not automatically a theorem. The verifier may check local structural composition, while stronger user claims may require proof evidence.

### Closed resource profile

A **closed resource profile** contains only finite concrete values. It is produced after generic, type-class, shape, effect, and callable specialization.

Target planning consumes a closed profile.

### Evidence level

A resource claim has one evidence level:

```text
Exact
ProvedUpperBound
CompilerUpperBound
ModeledEstimate
EmpiricalEstimate
Assumption
```

The first three may participate in verified source and target admission under their stated relation. Modeled, empirical, and assumed values remain planning or experiment evidence.

### Cumulative resource

A **cumulative resource** adds across sequential work. Examples include operation count, measurements, and target submissions.

### Peak resource

A **peak resource** depends on overlapping lifetimes. Examples include live region bytes, logical qubits, clean ancillas, stack depth, and pending jobs.

Peak resources do not compose through naive addition.

### Resource model profile

A **resource model profile** gives each metric its exact meaning and structural composition rules.

For example, `semantic_depth` is depth in Wheeler’s ideal semantic operation model, not depth after one provider’s gate decomposition.

## Ownership and boundaries

The language owns resource-clause syntax and the exact-versus-upper-bound distinction.

WIP-0017 and WIP-0029 own finite expression evaluation, const generics, associated reductions, and specialization.

The compiler owns all body analysis, call-graph composition, lifetime analysis, closed profiles, and diagnostics.

The verifier owns metadata well-formedness, numeric limits, descriptor consistency, and structurally checkable composition.

The proof system owns nontrivial exactness and upper-bound certificates.

WIP-0003 target planning owns target-qualified decomposition, routing, scheduling, architecture models, and physical estimates. It may add costs, but it may not reinterpret ideal metrics.

WIP-0004 owns run-time observations such as queue time, device time, shots received, retries, and provider cost receipts.

Tools own asymptotic summaries, Pareto comparison, flame graphs, and human rendering. Those views are derived from canonical formulas and profiles.

Packages may define strategy values and additional modeled metrics outside the compiler-owned core. They cannot create a new verifier-trusted metric by naming it `exact`.

## Design

### Source placement

A resource clause appears after the declaration signature and contracts, before the body:

```wheeler
public unitary void transform<const long N>(
    borrow mut qreg<N> q
)
resources {
    logical_qubits == N;
    clean_ancillas == 0;
    semantic_depth <= N * N;
    measurements == 0;
}
{
    ...
}
```

WIP-0005 and WIP-0006 own final punctuation and ordering relative to `requires`, `ensures`, `effects`, and proof clauses.

A declaration without a source resource clause still receives compiler-derived metadata where possible. The absence of a clause means the user did not publish a stronger contractual bound.

### Expression language

Resource expressions use nonnegative bounded arithmetic.

Subtraction is unavailable in the first profile unless normalization proves the result nonnegative for every admitted instantiation. A caller should prefer equivalent positive formulas.

Multiplication is accepted only when overflow and artifact limits are decidable under the generic constraints.

The first closed intrinsics are expected to include:

```text
max(a, b)
min(a, b)
ceilDiv(a, b)
powerOfTwoCeil(a)
bitWidth(a)
```

Every intrinsic is total on its admitted domain and has a canonical identity.

No user-defined const function runs during resource evaluation.

### Metric definitions

Each compiler-owned metric has this descriptor:

```text
ResourceMetricDescriptor {
    metric_id
    name
    unit
    domain
    composition_profile
    exactness_policy
    verifier_rules
    compiler_profile
}
```

The unit is semantic. Examples include `steps`, `bytes`, `bits`, `logical_qubits`, `operations`, and `shots`.

Two metrics with the same rendered word but different profile identity are not interchangeable.

### Sequential composition

For two sequential operations `A ; B`, cumulative resources usually compose as:

```text
count(A ; B) = count(A) + count(B)
```

Sequential depth composes as follows:

```text
depth(A ; B) = depth(A) + depth(B)
```

Peak resources use liveness:

```text
peak(A ; B) = max(
    peak(A),
    live_at_boundary(A, B) + peak_local(B)
)
```

The exact formula depends on owner transfer and resource lifetime. The compiler records boundary live sets rather than reducing every routine to one peak scalar too early.

### Calls

A call imports the closed or symbolic profile of the exact selected callable.

All generic and type-class evidence must resolve before a unitary or coherent body closes. A resource contract cannot refer to a different implementation than the callable selected for execution.

Recursive calls need a verified finite recurrence or a statically bounded expansion. The first coherent profile may reject recursive resource equations and require finite specialization or iteration.

### Branches

For a static branch whose condition resolves before emission, the profile is the selected branch profile.

For a reversible runtime branch, a worst-case upper bound uses this form:

```text
metric(if p then A else B)
    <=
condition_cost + max(metric(A), metric(B))
```

for cumulative path metrics such as executed steps and depth.

Artifact size may use the sum of both branch bodies because both are emitted. The metric name must distinguish execution cost from code size.

An exact expected cost is not inferred without an explicit probability model. The core language does not guess branch probabilities.

### Counted loops and repetition

For a fixed count `N`:

```text
cumulative(repeat N body) = N * cumulative(body)
```

Peak local workspace normally remains the body peak plus loop-control state, provided each iteration returns its local resources clean.

A round-trip analysis of a reversible loop includes both its forward and inverse body profiles. A declaration’s own forward profile counts only its forward execution unless the metric or wrapper explicitly asks for a round trip.

### Adjoint and inverse

For ideal semantic metrics, an adjoint or exact inverse normally has the same logical width and operation count as the original body with operation identities reversed.

A custom inverse or adjoint may publish a different profile when its semantic relation is accepted and its callable descriptor names it.

Target-native decomposition may give an adjoint a different physical cost. That belongs in a target-qualified profile.

### Controlled application

A controlled operation uses the resource profile of the selected controlled descriptor. Wheeler does not derive cost by multiplying the uncontrolled gate count by a constant unless an accepted synthesis rule says so.

A custom controlled implementation may trade ancillas for depth. Both dimensions remain visible.

### Compute–use regions

For:

```text
C ; U ; C†
```

cumulative semantic counts derive from:

```text
count(C) + count(U) + count(C†)
```

Peak qubits and ancillas derive from the paired lifetime graph. Declared ancillas introduced by `C` remain live through `U` and `C†`.

A structure-aware controlled lowering may control only `U`. The derived plan records the changed profile and equivalence evidence under WIP-0037.

### Parallel or disjoint scheduling

The core semantic profile may record a disjoint operation group when the compiler proves resource separation.

For such a group:

```text
operation_count = sum(children)
depth_upper_bound = max(children) when the semantic model permits parallel issue
peak_width = sum(simultaneously live widths)
```

The first implementation may report only conservative sequential depth. Claiming parallel depth requires a declared composition profile and evidence that operations commute or act on disjoint resources.

### History and witnesses

`history_bytes` counts WIP-0001 undo payload retained for rewind.

`hidden_history_bytes == 0` is a coherent-eligibility requirement. Visible branch witnesses or result registers are ordinary logical state and count in their respective storage or qubit dimensions, not hidden history.

This distinction prevents a reversible structure from making information costs disappear by renaming a witness.

### Exact and upper-bound checking

For a declaration claim:

```text
metric == bound
```

Wheeler requires:

```text
derived_metric == bound
```

under accepted normalization or proof.

For:

```text
metric <= bound
```

Wheeler requires:

```text
derived_metric <= bound
```

The compiler may usually discharge simple arithmetic. Stronger symbolic inequalities use WIP-0011 evidence.

A declaration cannot publish a smaller value than the body requires.

### Target-qualified resources

Target planning starts from an accepted semantic profile and adds a target-qualified report:

```text
semantic logical qubits
routed physical or logical qubits
native operation count
native depth
error-correction distance
factory count
physical qubits
cycles
modeled failure probability
estimated runtime
```

Together, these values name the target descriptor, lowering pipeline, model, assumptions, and freshness identity.

A target estimate never rewrites the source resource theorem.

### Asymptotic views

Wheeler does not add source syntax such as:

```text
complexity O(N log N)
```

Tools may normalize symbolic formulas and render an asymptotic summary. A proof package may separately express and prove such asymptotic propositions.

Executable admission uses finite formulas and closed bounds.

### Pareto comparison

The core stores resource vectors. It does not define one total order over them.

A planning library may compare implementations under an explicit objective or Pareto rule:

```text
minimize logical_qubits
subject to depth <= D
```

That policy is not an implicit type-class instance and does not alter callable semantics.

## Reversibility and history

Resource evaluation is compile-time or planning-time deterministic work. It does not change program state and needs no language inverse.

The resources being described include inverse, history, and cleanup behavior.

A reversible operation must report retained history separately from explicit logical witnesses and clean workspace.

Deleting history through `commit` changes future rewind availability. It does not retroactively reduce the peak history used before the commit.

A compute–use region reports clean ancilla lifetime. Resetting a dirty ancilla may reduce physical liveness but carries a different effect and cannot satisfy the exact clean resource contract.

## Concurrency and determinism

Resource expressions, normalization, callable import, composition, proof obligations, and closed profiles are deterministic for one locked package graph, compiler profile, and named planning policy.

Parallel compiler analysis reduces by canonical declaration and instantiation identity.

Runtime queue time, provider load, and hardware noise are nondeterministic observations. They appear only in empirical run evidence.

Target planners that permit nondeterministic heuristics record the seed, implementation identity, and resulting plan. Their output is not canonical semantic IR.

## Quantum and proof implications

A resource theorem may state:

```text
forall N satisfying constraints:
    resource(add<N>, logical_qubits) <= 3 * N + 1
```

WIP-0011 certificates bind:

- declaration identity;
- generic parameters and constraints;
- selected class evidence;
- callable and controlled identities;
- semantic operation profile;
- resource metric profile;
- proof assumptions;
- compiler profile.

The proof kernel checks accepted arithmetic and structural composition. It does not trust a provider report because the field is named `depth`.

A hardware or simulator experiment records measured runtime, samples, error, or memory use with confidence and provenance. It cannot inhabit an exact logical resource theorem.

Approximate circuit synthesis always carries an explicit error budget. Its resource profile and approximation evidence remain paired. Wheeler does not compare an approximate plan to an exact contract without the contract permitting that error model.

## Bytecode, persistence, and compatibility

Canonical `.wbc` records:

```text
ResourceExpressionTable
ResourceMetricProfileTable
DeclarationResourceContracts
DerivedResourceProfiles
ClosedResourceProfiles where available
ProofCertificateReferences
```

Expressions use canonical DAG encoding with bounded node count, checked arithmetic, stable metric IDs, and deterministic operand order for commutative forms.

A declaration descriptor references its public resource contract. A closed callable or quantum body references its resolved profile.

Target-qualified plans and empirical run data remain separate versioned runtime artifacts. They identify the canonical semantic region and resource profile they were derived from.

Adding or tightening a public resource guarantee may affect package compatibility. Weakening a promised upper bound is a breaking semantic change.

Existing artifacts without resource contracts remain valid when no selected target or caller requires them. An artifact using required resource-contract features is rejected by an unaware loader before execution.

## Safety, limits, and failures

Limits cover:

- resource dimensions per declaration;
- expression nodes and depth;
- generic variables;
- associated reductions;
- arithmetic magnitude;
- call-graph edges;
- loop and branch composition;
- liveness sets;
- proof obligations;
- certificate bytes;
- target report size;
- compiler time and memory;
- diagnostics.

The first stable diagnostic families should include:

```text
WRES001 unknown or unavailable resource metric
WRES002 resource expression is not finite or nonnegative
WRES003 resource arithmetic overflow
WRES004 unresolved generic, shape, or associated value
WRES005 declaration understates derived resource use
WRES006 exact claim cannot be established
WRES007 resource model profile mismatch
WRES008 recursive resource equation has no accepted bound
WRES009 peak resource lifetime cannot be bounded
WRES010 target requirement exceeds closed resource limit
WRES011 empirical or modeled evidence used where exact proof is required
WRES012 resource expression or proof limit exceeded
```

A failed resource check emits no partial verified callable, proof certificate, target executable, or package artifact.

## Migration and deletion

1. Define compiler-owned resource dimensions and profile identities.
2. Add canonical resource-expression parsing, normalization, and `.wbc` encoding.
3. Add source resource clauses over closed nongeneric declarations.
4. Add symbolic const-generic and associated-constant formulas.
5. Add call, branch, loop, inverse, adjoint, control, ancilla, and compute–use composition.
6. Add lifetime-based peak resource analysis.
7. Add WIP-0011 obligations and certificate checking.
8. Add target-plan comparison against closed profiles.
9. Add disassembly, documentation, report, and source-attribution tooling.
10. Migrate existing hard-coded qubit, gate, step, history, and storage annotations into the accepted model.
11. Delete duplicate resource counters, string-keyed metric maps, and provider reports that are treated as semantic authority.

## Progress

- [ ] Core resource metric profiles are accepted.
- [ ] Resource expressions parse and encode canonically.
- [ ] Closed declarations receive derived profiles.
- [ ] Generic formulas close after specialization.
- [ ] Calls, branches, loops, controls, and paired regions compose.
- [ ] Peak ancilla and storage liveness analysis executes.
- [ ] Exact and upper-bound proof obligations check.
- [ ] Target planning rejects unsupported closed profiles.
- [ ] Reports attribute resources to source declarations.
- [ ] Duplicate resource metadata paths are deleted.

## Testing and acceptance

- [ ] Exact and upper-bound claims pass when the body satisfies them.
- [ ] An understated bound fails before artifact publication.
- [ ] Generic formulas normalize to the same result independent of source and worker order.
- [ ] Sequential operation count and depth compose by the accepted rules.
- [ ] Static and runtime branch profiles use the correct selected or worst-case form.
- [ ] Fixed-count loop profiles multiply cumulative costs and preserve peak-local rules.
- [ ] Adjoint and inverse profiles use the exact selected body identity.
- [ ] Controlled calls use controlled-descriptor resources rather than a guessed multiplier.
- [ ] Compute–use regions count forward, use, and cleanup while retaining ancillas through the full lifetime.
- [ ] Peak logical qubits differ from the sum of all child qubit counts in an acceptance fixture.
- [ ] History bytes, explicit witnesses, and clean workspace remain separate dimensions.
- [ ] Exact logical resources, modeled physical resources, and empirical runtime remain distinct evidence types.
- [ ] A target plan exceeding qubit, depth, shot, or result limits is rejected before submission.
- [ ] Current reference docs describe the clauses only after implementation.

## Alternatives

### Keep resource numbers in comments and reports

Rejected. Generic composition, target admission, compatibility, and proof checking need canonical semantic identities.

### Add one universal cost number

Rejected. Space, depth, operation count, compilation time, error, and target cost have different units and tradeoffs.

### Extend Big-O notation in the core language

Rejected. Asymptotic notation does not provide the finite closed bounds required for execution and target planning. Existing mathematical notation remains suitable for documentation and proofs.

### Trust provider estimates as exact

Rejected. Provider models and calibration data are target-qualified evidence, not source semantics.

### Let packages define arbitrary verifier-trusted metrics immediately

Rejected for the first profile. The trusted set must have precise composition and proof rules. Packages may attach modeled metadata without gaining verifier authority.

### Add every target-native gate metric to source

Rejected. Source contracts describe stable semantic work. Native gate sets and physical architectures change independently.

### Sum all qubits and workspace

Rejected. Peak resources depend on lifetime overlap. Naive addition would make many useful hierarchical plans look impossible.

## Open questions

- Which dimensions form the smallest mandatory first profile? **Owner:** compiler, VM, quantum, and target maintainers. **Decide by:** before Review.
- Are `max`, `ceilDiv`, `powerOfTwoCeil`, and `bitWidth` sufficient for first-profile formulas? **Owner:** const-evaluation and resource maintainers. **Decide by:** before parser implementation.
- Which resource claims can the verifier check structurally without invoking the proof kernel? **Owner:** verifier and proof maintainers. **Decide by:** before bytecode schema freeze.
- Should public resource bounds participate in semantic version compatibility automatically, or through an explicit stability marker? **Owner:** package and compatibility maintainers. **Decide by:** before acceptance.
- Which exact ideal operation set defines `semantic_operations` and `semantic_two_qubit_operations`? **Owner:** quantum IR maintainers. **Decide by:** before metric profile acceptance.
- Does the first profile encode disjoint parallel groups or report conservative sequential depth only? **Owner:** compiler and quantum scheduling maintainers. **Decide by:** before implementation.

## References

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0002](WIP-0002-unified-classical-quantum-semantics.md)
- [WIP-0003](WIP-0003-quantum-target-and-qiskit-backend.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0017](WIP-0017-compile-time-constants-and-finite-enums.md)
- [WIP-0029](WIP-0029-parametric-polymorphism-and-bounded-specialization.md)
- [WIP-0030](WIP-0030-coherent-type-classes-and-associated-types.md)
- [WIP-0031](WIP-0031-reversible-quantum-and-effect-polymorphism.md)
- [WIP-0034](WIP-0034-structured-uncomputation-and-clean-ancilla-scopes.md)
- [WIP-0035](WIP-0035-reversible-and-coherent-control-flow.md)
