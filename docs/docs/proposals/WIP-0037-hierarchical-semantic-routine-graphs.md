# WIP-0037: Hierarchical semantic routine graphs and verified transformations

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler, bytecode, verifier, quantum, proof, target, tooling, and documentation maintainers |
| Created | 2026-07-20 |
| Updated | 2026-07-20 |
| Area | IR, bytecode, routines, transformations, resource analysis, tooling |
| Depends on | WIP-0001, WIP-0002, WIP-0003, WIP-0005, WIP-0011, WIP-0029, WIP-0031, WIP-0034, WIP-0035, WIP-0036 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler preserves closed callable hierarchy and structural control as a canonical semantic routine graph inside `.wbc`. A routine is one closed Wheeler callable instance with exact type, effect, inverse, adjoint, controlled, ownership, proof, and resource identity. The graph retains calls, repetition, adjoint, control, compute–use regions, ancilla scopes, preparation, measurement, reset, and hybrid boundaries instead of flattening every operation into gates or bytecode instructions. Optimized, target-native, and visual forms are derived artifacts. Each derived transformation records its source graph, policy, output graph, semantic relation, resource delta, and accepted evidence.

## Motivation

A flat circuit can execute a small quantum example. It is a poor semantic representation for a large program.

Flattening loses the facts that matter most to Wheeler:

- which source function produced an operation;
- which generic and type-class instance was selected;
- which call has a generated inverse or adjoint;
- which block is controlled;
- which temporary value belongs to one compute–use lifetime;
- which ancillas may be reused;
- which loop represents a billion repeated operations;
- which resource formula belongs to one reusable routine;
- which transformation preserved exact semantics and which introduced approximation;
- which source location dominates the final cost.

A Construct-like resource analyzer, a QREF exporter, a source-linked circuit viewer, and a fault-tolerant planner all need hierarchy. They should not reconstruct it from flattened gates.

The canonical graph also improves trust. A target compiler may rewrite and lower a program, but it should not replace the source-semantic artifact. A later verifier or report should be able to answer:

> Which accepted Wheeler routine did this target operation come from, and what evidence connects them?

This proposal gives that question one artifact-level answer.

## Use cases

### Large repeated routine

A phase-estimation routine calls a controlled evolution `2^i` times for each output bit. Wheeler stores a symbolic repeat node instead of materializing billions of calls during semantic compilation.

### Source-linked resource analysis

A report shows that 38 percent of logical depth comes from one lookup routine. The user can expand that node, compare implementations, and navigate to the exact source declaration.

### Structured control optimization

A controlled compute–use region has form:

```text
C ; U ; C†
```

A verified transformation controls only `U` when the required conjugation theorem applies. The report records the original node, replacement graph, resource change, and controlled-equivalence evidence.

### Fault-tolerant lowering

The canonical graph retains arithmetic, QROM, and phase-estimation calls. A target-qualified planner selects decompositions and architecture models without changing the canonical source graph.

### QREF export

A tool exports routine names, ports, children, repeat expressions, resource formulas, and connections. Imported design-only graphs remain mere specifications until bound to executable Wheeler callables and evidence.

### Debugging a bad rewrite

A derived transformation fails certificate checking. Wheeler rejects the derived plan while keeping the original semantic graph valid and inspectable.

## Goals

- Define a routine as a closed semantic callable instance, not a new source object hierarchy.
- Preserve source call hierarchy in canonical Wheeler artifacts.
- Preserve structural nodes for repetition, adjoint, control, compute–use, ancilla scopes, and irreversible boundaries.
- Keep generic, type-class, callable, proof, resource, and source identity attached to each routine.
- Represent very large bounded programs without eager flattening.
- Make flat circuits and target executables derived artifacts.
- Define transformation receipts with exact input, policy, output, relation, evidence, and resource deltas.
- Distinguish exact equivalence, global-phase equivalence, measurement-distribution equivalence, and bounded approximation.
- Support source-linked resource, circuit, and transformation tools.
- Keep canonical graph encoding deterministic and verifier-readable.
- Reject dynamic dispatch and unresolved specialization in coherent or unitary routine graphs.

## Non-goals

- Add a `routine` keyword to Wheeler source in the first profile.
- Make a visual editor an authority over source semantics.
- Standardize one optimizer, target compiler, or fault-tolerant architecture.
- Store provider circuits, Qiskit objects, native schedules, or credentials in canonical `.wbc`.
- Treat every target rewrite as formally verified.
- Permit arbitrary compiler plugins in the trusted process.
- Promise that every hierarchical node survives every debugging or optimization policy unchanged.
- Define high-level algorithm libraries, QROM catalogs, or optimization solvers.
- Serialize live quantum state.
- Make QREF or another outside format Wheeler’s semantic IR.

## Terms and semantic model

### Routine

A **routine** is one closed Wheeler callable instance admitted to semantic IR.

Its identity includes:

```text
RoutineId = hash(
    declaration identity,
    closed generic arguments,
    selected type-class evidence,
    associated reductions,
    callable kind,
    effect row,
    ownership and frame signature,
    inverse, adjoint, and controlled descriptors,
    resource profile,
    proof profile,
    compiler profile
)
```

An ordinary function, reversible function, coherent function, unitary operation, measurement routine, or hybrid continuation may each become a routine. Their kinds remain distinct.

### Routine instance

A **routine instance** is one call node with exact argument bindings, source location, caller identity, and selected callable descriptor.

Several call sites may reference the same routine identity.

### Semantic routine graph

A **semantic routine graph** is a bounded typed graph whose nodes describe accepted Wheeler operations and whose edges describe execution, ownership, data, control, and effect dependencies.

The graph is authoritative for the selected closed artifact. It is not provider-native.

### Structural node

A **structural node** preserves language meaning that should not be flattened during semantic emission.

The first node kinds are:

```text
Call
Sequence
StaticSelect
Repeat
Adjoint
Controlled
ComputeUse
AncillaScope
DisjointGroup
Prepare
Measure
Reset
TargetBoundary
ClassicalContinuation
```

A node kind may be absent from the first executable slice if its owning WIP is not implemented. The encoding reserves no unverified placeholder semantics.

### Derived graph

A **derived graph** is produced from another graph by one named transformation policy.

Examples include:

- inlining;
- constant propagation;
- inverse cancellation;
- control specialization;
- uncomputation scheduling;
- arithmetic decomposition;
- gate-set lowering;
- routing;
- fault-tolerant expansion.

A derived graph is never silently promoted to canonical source semantics.

### Transformation receipt

A **transformation receipt** is immutable evidence describing one graph transformation:

```text
TransformationReceipt {
    input_graph_id
    transformation_id
    policy_id
    assumptions
    output_graph_id
    semantic_relation
    proof_or_validation_evidence
    resource_delta
    source_mapping
    tool_identity
}
```

### Semantic relation

A transformation states one exact relation:

```text
ExactEquivalent
EquivalentUpToGlobalPhase
BasisEquivalent
MeasurementDistributionEquivalent
ApproximateWithin(error_bound)
RefinesTargetRequirements
ResourceOnly
```

A weaker relation cannot satisfy a caller that requires a stronger one.

### Design-only routine specification

A **design-only routine specification** describes ports, hierarchy, parameters, and resource assumptions without executable Wheeler semantics.

It may support architecture studies and visual design. It cannot enter an executable graph until bound to an accepted routine implementation and the required evidence.

## Ownership and boundaries

The language owns source declarations, structural forms, effects, and callable semantics. This proposal adds no parallel source AST.

WIP-0029 and WIP-0031 own closed specialization and callable identity.

The compiler owns routine extraction, graph construction, canonical identity, source mapping, and derived transformations.

The verifier owns graph well-formedness, node legality, ownership edges, effect order, required evidence references, bounds, and closed dispatch.

The proof system owns accepted semantic-relation certificates.

WIP-0036 owns the symbolic resource expressions and profiles. This proposal attaches them to routine and derived graph nodes.

WIP-0003 owns target-qualified planning, executable materialization, and result provenance.

Tools own visualization, graph diffing, QREF import and export, hotspot analysis, and human reports. They cannot directly edit canonical meaning without producing a new source artifact or accepted transformation.

Hosts and target adapters own provider payloads. Those payloads reference the semantic graph identity but do not replace it.

## Design

### No new source keyword

Every closed callable accepted by Wheeler already has the information needed to become a routine.

The first profile does not add:

```wheeler
routine MyOperation { ... }
```

A source declaration becomes a routine when it is reachable from one selected artifact root and all generic, type-class, callable, ownership, effect, proof, and resource choices are closed.

Documentation or attributes may later add display grouping. They do not create independent semantic authority.

### Graph roots

A graph root is one of:

- a classical entry body;
- a coherent callable body;
- a unitary operation body;
- a target-resident bounded hybrid region;
- an experiment body;
- a proof-referenced semantic region.

The root descriptor names required effects, resource ceilings, target requirements, and result schema.

### Call nodes

A call node records:

```text
CallNode {
    call_site_id
    caller_routine_id
    callee_routine_id
    argument_bindings
    ownership_modes
    frame_summary
    effect_edge
    resource_profile_id
    source_span
}
```

The graph stores a call edge rather than copying the callee body immediately.

Inlining is a derived transformation.

### Sequence nodes

A sequence preserves source evaluation order and effect order.

Independent operations may later appear in a `DisjointGroup` when the compiler proves that they act on disjoint resources and the semantic model permits reordering or parallel issue.

Ordinary source order remains available for diagnostics even after a derived schedule changes physical order.

### Static selection

A `StaticSelect` node records a compile-time or closed immutable classical choice among routine bodies.

Before executable quantum emission, the choice resolves to one selected child. The canonical generic library graph may retain the symbolic alternatives in a non-executable section under WIP-0029.

No runtime provider-name branch remains inside a closed unitary graph.

### Repeat nodes

A repeat node records:

```text
RepeatNode {
    body_routine_id
    count_expression
    index_binding
    direction
    resource_expression
    source_span
}
```

The count is finite and accepted under WIP-0017 and WIP-0029.

A target backend may unroll, stream, synthesize a loop, or use a native repeated operation when its capability contract permits. The semantic repeat identity remains stable.

### Adjoint nodes

An `Adjoint` node references one accepted unitary routine and its generated or declared adjoint descriptor.

The graph never copies and reverses a gate list merely to display that adjoint. A derived backend may materialize it later.

Double adjoint normalizes to the original semantic routine identity under WIP-0031.

### Controlled nodes

A `Controlled` node records:

- control places;
- controlled body identity;
- source controlled region;
- required control semantics;
- selected custom or synthesized descriptor when planning closes;
- controlled-equivalence evidence;
- resource profile.

A derived plan may replace a controlled conjugation with a structure-aware equivalent under accepted evidence.

### Compute–use nodes

A `ComputeUse` node preserves the three-part relation from WIP-0034:

```text
compute
use
inverse or adjoint compute
```

It records inverse dependencies, computed places, ancilla scopes, frame evidence, and cleanup identity.

The node lets tools render temporary computation once and lets planners consider structure-aware controlled or scheduling transformations.

### Ancilla-scope nodes

An `AncillaScope` records:

- logical types and widths;
- clean entry and exit bases;
- lexical lifetime;
- child nodes that use the resources;
- proof evidence;
- peak resource contribution.

Physical qubit allocation remains target-derived.

### Preparation, measurement, and reset

`Prepare`, `Measure`, and `Reset` remain explicit nodes.

They cannot be hidden inside a unitary call or erased by an equivalence pass.

Measurement nodes record typed classical result schemas and ownership transitions. Reset records its target capability and known-state result. Neither node has an adjoint.

### Hybrid boundaries

A `TargetBoundary` separates semantic region construction from target execution. A `ClassicalContinuation` records the typed resume point and live classical values under WIP-0004.

The graph may represent a bounded target-resident hybrid subgraph when the target advertises the required measurement, reset, and classical-kernel capabilities.

### Data and ownership edges

Edges carry semantic information:

```text
value flow
owner move
shared borrow
exclusive borrow
quantum resource origin
control dependency
measurement result
classical parameter
proof or evidence dependency
```

A graph is invalid when it permits use after move, overlapping mutable access, dirty ancilla release, observation inside a unitary node, or an effect order not represented by an edge.

### Canonical graph identity

Canonical graph encoding orders tables and node definitions by stable identity. Source traversal, map order, thread completion, and allocation addresses cannot change the graph hash.

Graph identity includes semantic node structure and references. Optional display names, layout coordinates, folded state, colors, and tool preferences are nonsemantic attachments.

### Large-program representation

The graph may contain symbolic repeat and call nodes whose flattened expansion would exceed artifact or memory limits.

Every symbolic node still carries a finite bound. Wheeler rejects an unbounded routine graph.

Tools and target backends operate through bounded iterators, streaming expansion, or resource formulas. They are not required to materialize the complete flat circuit in memory.

### Canonical and derived graphs

The canonical `.wbc` graph reflects accepted source semantics after mandatory type checking, specialization, and semantic normalization.

Transformations such as optimization, target decomposition, routing, and physical scheduling create derived graphs or executables.

A derived graph references its parent. It does not mutate the parent identity.

### Transformation classes

The first transformation classes are:

```text
Analysis
ExactRewrite
ApproximateRewrite
Lowering
Scheduling
ExecutionMaterialization
```

An analysis produces reports and cannot change the graph.

An exact rewrite produces a graph under one accepted exact relation.

An approximate rewrite requires an explicit error budget and relation.

A lowering changes operation vocabulary or target qualification while preserving the declared relation.

Scheduling orders or groups operations under dependencies and target rules.

Execution materialization creates provider or runtime payloads. It has no semantic authority beyond its receipt and validation.

### Transformation evidence

A transformation may carry:

- kernel-checkable proof;
- compiler-checked local rewrite witness;
- admitted intrinsic rule;
- finite exhaustive validation under a declared bound;
- test evidence;
- no evidence beyond provenance.

Only the first three may satisfy a requirement for verified exact rewriting in the initial profile. Finite exhaustive validation may be admitted for a specific bounded rule if WIP-0011 defines that certificate form.

Test evidence and provider success do not become proof.

### Source mapping

Every semantic node retains one or more source spans or generated-source reasons.

A generated node states why it exists:

```text
generated inverse
generated adjoint
oracle embedding
controlled synthesis
ancilla initialization
cleanup
bounds check
target decomposition
routing insertion
```

Tools can navigate from a target operation through each derived receipt to the source routine.

### Resource attribution

Each node references a WIP-0036 resource profile.

Reports may aggregate by:

- source declaration;
- routine identity;
- call site;
- node kind;
- target transformation;
- proof or assumption status.

A report must distinguish inclusive resource cost from exclusive local cost.

### Implementation families

The graph records the exact implementation selected before unitary or coherent lowering.

Alternative implementations remain ordinary explicit strategy values or design candidates. They do not coexist as runtime dispatch inside one executable routine graph.

A planning tool may construct several derived graphs and compare their resource vectors. The selected graph and policy enter the target executable identity.

### Design-only graphs

A tool may create a design graph with routine specifications and assumed resource expressions.

Design nodes carry an execution status:

```text
Unbound
BoundToImplementation
Certified
Assumed
```

Only `BoundToImplementation` or `Certified` nodes with all required semantics may enter an executable Wheeler graph. An assumed resource box remains suitable for planning, not execution or theorem proof.

### Interoperability

A tool may externally export a routine graph to QREF or another hierarchical format.

Exported data is derived and may omit Wheeler ownership, effect, proof, and package details that the outside format cannot express.

Import creates a design-only graph unless a trusted importer and binding process establish every required Wheeler semantic fact.

## Reversibility and history

Routine graph construction and transformation are deterministic compiler activities. They do not use WIP-0001 machine rewind as semantic proof.

The graph preserves each operation’s true relation:

- language inverse;
- logged rewind class;
- barrier;
- coherent permutation;
- unitary adjoint;
- measurement;
- reset;
- target or workflow edge.

A transformation cannot replace one relation with another merely because the final output appears similar in a sample.

Transformation receipts are immutable provenance values. Rewinding program execution does not erase that a compiler produced or rejected a plan.

Replay uses recorded observations under WIP-0004. It does not replay a graph transformation as though it were physical inverse execution.

## Concurrency and determinism

Canonical routine graph construction is deterministic.

Independent compiler analyses and transformations may run concurrently. Published results reduce by canonical input graph, transformation, policy, and output identity.

A graph may expose disjoint operation groups. Target scheduling may exploit them, but semantic dependency edges remain authoritative.

Target job completion order never changes graph or transformation identity.

Nondeterministic optimization heuristics must use explicit seeds or record their nondeterministic inputs. Their output is a derived plan, not canonical source IR.

This proposal adds no shared-memory source concurrency.

## Quantum and proof implications

The graph gives proof terms a stable hierarchy.

A routine proof may establish:

```text
body implements declared semantic relation
adjoint composes to identity
controlled specialization matches controlled semantics
compute–use ancillas return clean
resource profile satisfies bound
transformation output relates to input under relation R
```

A transformation requiring exact equivalence cannot use a certificate that proves only measurement-distribution equivalence.

Global-phase equivalence is adequate for some uncontrolled unitary uses. It may be inadequate under control. The receipt names the exact relation so later composition can decide.

Approximate rewrites carry an explicit error expression and composition rule. Error accumulation becomes part of the derived plan and proof or model profile.

Target calibration and hardware experiments remain empirical evidence attached to an execution. They do not change the ideal routine graph theorem.

## Bytecode, persistence, and compatibility

Canonical `.wbc` uses the existing quantum-region and callable extension points to store a required hierarchical routine-graph feature.

The first encoding adds bounded tables equivalent to:

```text
RoutineDescriptorTable
RoutineInstanceTable
RoutineNodeTable
RoutineEdgeTable
RoutineGraphRootTable
TransformationRelationTable
SourceGenerationReasonTable
```

WIP-0036 resource expressions remain in their own canonical tables and are referenced by node ID.

The manifest lists the hierarchical graph feature as required when selected entry points depend on it. A loader that does not recognize the feature rejects the artifact before execution.

Existing `.wbc` artifacts without the feature remain valid. A compatible newer loader may construct a trivial routine graph around an older flat quantum body for tooling, but that graph is derived compatibility data and cannot invent missing hierarchy or proof facts.

Derived graphs, lowering reports, target executables, visual layouts, and provider payloads live in separate versioned artifacts. They identify:

- parent semantic graph;
- transformation chain;
- policy;
- assumptions;
- target descriptor;
- tool versions;
- source mapping;
- proof and resource evidence.

Persisted hybrid runs reference semantic region and executable identities. They do not persist live routine-local quantum resources.

## Safety, limits, and failures

Limits cover:

- routines;
- call sites;
- graph nodes and edges;
- node nesting;
- repeat expression size;
- source maps;
- generic and evidence references;
- transformation chain length;
- proof and assumption references;
- resource attachments;
- derived graph bytes;
- streaming expansion work;
- compiler and verifier time and memory;
- diagnostics.

The first stable diagnostic families should include:

```text
WRGR001 routine graph contains unresolved generic or evidence
WRGR002 dynamic callable dispatch in coherent or unitary graph
WRGR003 invalid ownership or effect edge
WRGR004 unbounded repeat or recursive expansion
WRGR005 node relation conflicts with callable kind
WRGR006 source mapping or generated-reason identity is malformed
WRGR007 graph or hierarchy limit exceeded

WTRN001 transformation input identity mismatch
WTRN002 transformation claims unsupported semantic relation
WTRN003 required proof or validation evidence is missing
WTRN004 weaker relation cannot satisfy caller requirement
WTRN005 approximation exceeds declared error budget
WTRN006 resource delta does not match output graph
WTRN007 target plan derived from stale or different semantic graph
WTRN008 transformation or derived-artifact limit exceeded
```

A malformed semantic graph fails before target planning. A failed transformation leaves the parent graph valid and publishes no accepted child plan.

## Migration and deletion

1. Define routine and graph identities over closed callable descriptors.
2. Emit call and sequence nodes for current quantum and coherent bodies.
3. Add repeat, adjoint, and controlled nodes.
4. Add compute–use and ancilla-scope nodes.
5. Add preparation, measurement, reset, target, and continuation boundaries.
6. Add canonical graph encoding and verification in `.wbc` feature metadata.
7. Add source mapping and generated-reason records.
8. Add resource-profile attachment and source attribution.
9. Add transformation receipts and exact local rewrite evidence.
10. Add target lowering chains and derived graph identities.
11. Add hierarchy, circuit, resource, and transformation inspection tools.
12. Add QREF export and design-only import after canonical graph conformance passes.
13. Delete flat-circuit-as-authority paths, string-named pass identities, duplicate call-tree reconstruction, and target payloads treated as canonical program meaning.

## Progress

- [ ] Routine and routine-instance identity is accepted.
- [ ] Current coherent and unitary calls emit hierarchy.
- [ ] Repeat, adjoint, and controlled nodes emit.
- [ ] Compute–use and ancilla scopes emit.
- [ ] Measurement and hybrid boundaries remain explicit.
- [ ] Canonical graph encoding and verification pass.
- [ ] Resource profiles attach to source nodes.
- [ ] Exact transformation receipts check.
- [ ] Target executables carry complete derivation chains.
- [ ] Source-linked hierarchy and resource tools work.
- [ ] Flat semantic authority and stringly pass identity are deleted.

## Testing and acceptance

- [ ] Two clean builds of the same closed program produce byte-identical routine graphs.
- [ ] Generic and type-class specialization changes routine identity when semantics change.
- [ ] Repeated operations remain symbolic and bounded without forced flattening.
- [ ] Adjoint, controlled, compute–use, and ancilla nodes preserve their structural identity.
- [ ] Measurement, reset, and target boundaries cannot be hidden inside a unitary node.
- [ ] Ownership and effect edges reject use after move, aliasing, and illegal observation.
- [ ] A flat simulator execution of the graph matches the existing semantic simulator on acceptance fixtures.
- [ ] An exact rewrite receipt verifies and links input to output.
- [ ] A rewrite with missing, stale, or weaker evidence is rejected.
- [ ] Approximate rewrites retain explicit error bounds and cannot satisfy exact callers.
- [ ] Resource reports attribute inclusive and exclusive costs to stable source routines.
- [ ] A target operation can be traced through lowering receipts to its source node.
- [ ] Existing artifacts without hierarchy remain loadable under their original contract.
- [ ] QREF export does not become a semantic round-trip guarantee.
- [ ] Current reference docs describe routine graphs only after implementation.

## Alternatives

### Flatten immediately and reconstruct hierarchy later

Rejected. Reconstruction cannot reliably recover source calls, generic identity, compute lifetimes, custom controlled implementations, or proof relationships.

### Add a separate routine DSL

Rejected. Wheeler callables already carry the required semantics. A second language would duplicate types, ownership, effects, proofs, and packages.

### Make the target circuit canonical

Rejected. Provider gate sets, routing, calibration, and SDKs change independently of Wheeler semantics.

### Store only a call tree

Rejected. Control, data, ownership, measurement, and ancilla dependencies require a graph.

### Trust every compiler pass

Rejected. Some passes may remain trusted or provenance-only, but the artifact must state the relation and evidence instead of presenting all rewrites as proved.

### Put visual layout in semantic identity

Rejected. Diagram coordinates and folded state do not affect execution.

### Require full flattening before execution

Rejected. Fault-tolerant-scale programs may be too large. Bounded symbolic repeat and streaming lowering are part of the design.

### Use QREF as Wheeler IR

Rejected. QREF is useful interchange, but it does not own Wheeler’s complete type, ownership, effect, proof, and package contracts.

## Open questions

- Which structural node kinds are mandatory for the first executable slice? **Owner:** compiler, verifier, and quantum IR maintainers. **Decide by:** before Review.
- Does the canonical graph store source lexical grouping beyond semantic sequence and structural nodes? **Owner:** compiler, debugger, and tooling maintainers. **Decide by:** before encoding freeze.
- Which local rewrite rules may use verifier-checked witnesses without a full WIP-0011 proof term? **Owner:** verifier and proof maintainers. **Decide by:** before transformation acceptance.
- Should design-only graphs live in `.wbc` optional sections or a separate canonical design artifact? **Owner:** bytecode, package, and tooling maintainers. **Decide by:** before design import implementation.
- Which exact relation vocabulary belongs in the first transformation profile? **Owner:** quantum, proof, and target maintainers. **Decide by:** before certificate schema freeze.
- May a newer loader synthesize a trivial hierarchy for an older flat artifact in normal tooling, or only under an explicit compatibility flag? **Owner:** bytecode and tooling maintainers. **Decide by:** before migration implementation.

## References

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0002](WIP-0002-unified-classical-quantum-semantics.md)
- [WIP-0003](WIP-0003-quantum-target-and-qiskit-backend.md)
- [WIP-0005](WIP-0005-wheeler-source-language.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0029](WIP-0029-parametric-polymorphism-and-bounded-specialization.md)
- [WIP-0031](WIP-0031-reversible-quantum-and-effect-polymorphism.md)
- [WIP-0034](WIP-0034-structured-uncomputation-and-clean-ancilla-scopes.md)
- [WIP-0035](WIP-0035-reversible-and-coherent-control-flow.md)
- [WIP-0036](WIP-0036-symbolic-resource-contracts-and-compositional-cost-evidence.md)
