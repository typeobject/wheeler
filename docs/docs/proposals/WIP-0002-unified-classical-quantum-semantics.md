# WIP-0002: Unified classical and quantum semantics

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler language, compiler, and quantum maintainers |
| Created | 2026-07-17 |
| Updated | 2026-07-17 |
| Area | Language, hybrid execution, quantum IR, reversibility |
| Depends on | WIP-0001 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler uses one typed effect and region model across classical reversible execution, coherent quantum execution, measurement, and host effects. A verified classical `rev` function that satisfies the coherent subset can run as ordinary WIP-0001 bytecode on a CPU or be lifted automatically to a unitary operation when called with coherent operands. Quantum regions lower to backend-neutral region IR inside the same `.wbc` artifact; they are not foreign-language strings or opaque provider circuits.

Transitions are seamless in source but explicit in semantics. Known classical data may parameterize or prepare quantum state. Measurement consumes coherent state and produces classical observations. Quantum data is affine, cannot be cloned or inspected, and must be uncomputed, measured, reset, or returned according to its resource contract. Measurement and remote submission are not described as physically reversible; Wheeler records observations and can replay or restart a workflow according to WIP-0004.

## Motivation

The examples already describe the intended language as more than a classical VM with a quantum library:

- `Counter` and `BinaryTree` require ordinary reversible classical state.
- `QFT` is a closed unitary circuit with a natural inverse.
- `QuantumOptimizer` and `QuantumNeuralNetwork` alternate parameterized quantum execution and classical optimization.
- `SurfaceCode` requires mid-circuit measurement, classical decoding, and target-resident feedback.
- `QuantumCompiler` mixes classical circuit transformation with quantum calibration work.
- `QFTProof` wants unitary, inverse, and resource properties tied to the same program.

The current sketches blur several boundaries. Measurement appears inside reversible transactions, arbitrary quantum state is treated as copyable through CNOT, `clean` appears able to erase an unknown register, and a `quantum pure` function measures a qubit. Those operations cannot share one undifferentiated notion of “reverse.”

Wheeler needs a model that remains valid for today's noisy gate devices, simulators, future fault-tolerant logical machines, and possible tightly coupled classical/quantum processors. Provider APIs will change over decades; linear quantum information, unitary evolution, measurement, and classical observations remain the durable boundary.

## Use cases

### One reversible function, two execution domains

A finite-width `rev` permutation is called with ordinary integers and executes as classical bytecode. The same function is called with coherently encoded basis values inside a quantum region and lowers to a unitary oracle without source duplication or a provider API.

### QFT and inverse QFT

`applyQFT` lowers to a parameterized unitary region. `uncall applyQFT` or `reverse applyQFT` uses compiler-validated inverse order and inverse gates. The circuit runs identically under the semantic simulator or a compatible hardware target after decomposition.

### Variational loop

A classical optimizer binds parameters into a quantum circuit template, submits repeated executions, receives measured classical results, and updates parameters. Source remains one hybrid workflow even when a remote target makes each quantum materialization asynchronous.

### Dynamic error correction

A surface-code cycle contains coherent gates, syndrome measurement, bounded classical decoding, reset, and conditional corrections. It can execute as one region only on a target advertising the required dynamic-circuit and latency capabilities; otherwise the compiler reports a capability error or uses an explicitly selected host-split plan.

### Ancilla cleanup

A lifted reversible computation borrows ancillas initialized to zero, computes a result, copies only allowed classical-basis output, and applies its inverse so every borrowed ancilla returns to zero. The compiler rejects `clean` on an entangled or unknown register.

## Goals

- Give `classical`, `quantum`, `hybrid`, `rev`, and `pure` precise, orthogonal meanings.
- Let coherently eligible reversible source run on either a classical VM or quantum target.
- Represent quantum code as typed, backend-neutral region IR in `.wbc`.
- Make preparation, coherent lifting, measurement, reset, and host submission explicit transitions.
- Enforce no-cloning, affine ownership, ancilla cleanup, and use-after-measure rules.
- Separate inverse execution, machine rewind, measurement replay, and workflow retry.
- Partition hybrid programs according to target capabilities without changing source-level results.
- Keep current and future target details behind WIP-0003.

## Non-goals

- Promise that every classical Wheeler function can execute coherently.
- Make floating-point optimization, I/O, arbitrary allocation, exceptions, or logged history unitary.
- Hide measurement or pretend a hardware measurement can be undone.
- Define provider queues, credentials, jobs, or Qiskit transport; WIP-0003 does that.
- Define durable workflow history and retry; WIP-0004 does that.
- Accept the existing proof syntax as a sound theorem system.
- Standardize pulse-level control or one physical error-correction architecture.

## Terms and semantic model

### Data domains

- A **classical value** is ordinary copyable data represented in WIP-0001 slots or regions.
- A **coherent value** is a finite logical value encoded in quantum basis state and possibly superposition. It is affine and cannot be copied, compared, printed, or branched on classically without measurement.
- A **quantum resource** is a `qubit`, `qureg`, logical qubit group, or target-defined affine handle owned by one lexical or execution region.
- A **classical parameter** is immutable classical data used to construct gates or choose compile-time region structure without becoming quantum state.
- A **measurement result** is a classical observation with basis, shot, region, and target provenance.

### Effects

Computation domains and effects are separate. Wheeler tracks at least these effects:

| Effect | Meaning |
| --- | --- |
| `pure` | No mutation, resource transition, measurement, submission, or host observation. |
| `rev` | Classical state transition with a verified inverse or bounded WIP-0001 undo contract. |
| `unitary` | Coherent state transition with a validated adjoint and no observation. |
| `prepare` | Initialize a quantum resource from a declared known state or encoding. |
| `measure` | Consume or transform coherent state and create a classical observation. |
| `reset` | Discard prior coherent state through a target operation and establish a known state. |
| `submit` | Materialize a quantum region on a simulator or target. |
| `io` | External classical effect governed by WIP-0001 effect policy. |

`classical`, `quantum`, and `hybrid` describe allowed data and lowering regions. They do not by themselves imply purity or reversibility. A quantum function that measures has a `measure` effect and is not `pure`. A closed gate circuit normally has `unitary`. A hybrid function may sequence several effect domains.

### Transition boundaries

The core transitions are:

```text
classical known data --prepare/encode--> coherent data
coherent data --unitary/rev lift--> coherent data
coherent data --measure--> classical observation
coherent data --reset--> known coherent data
classical workflow --submit--> target job/continuation
```

There is no implicit coherent-to-classical conversion. Passing classical gate angles does not encode them into qubits. Measurement is explicit even when a simulator can expose amplitudes internally.

### Reversibility meanings

Wheeler uses distinct terms:

- **inverse/adjoint:** execute the mathematical inverse of a classical permutation or unitary region;
- **uncompute:** apply inverses to return temporary coherent or reversible state to its required clean value;
- **machine rewind:** consume WIP-0001 step records for classical execution;
- **replay:** reuse recorded nondeterministic observations without claiming to restore physical state;
- **retry:** prepare a new target state and execute a region again.

Source documentation and diagnostics must name the applicable operation instead of calling all five “reverse.”

## Ownership and boundaries

The language owns data domains, affine use, effects, inverse declarations, preparation, measurement, reset, and source-level region composition.

The compiler owns coherent-eligibility checking, region partitioning, inverse generation, ancilla accounting, backend-neutral quantum IR, source mapping, and target requirement inference.

WIP-0001 owns classical execution, artifacts, effect barriers, and machine rewind. WIP-0003 owns target capabilities, lowering, submission, and results. WIP-0004 owns hybrid continuations, replay, retry, and committed history.

Targets own physical or simulated quantum state. Wheeler code never receives raw provider qubit objects. Hosts own credentials and target selection but do not weaken type or effect checking.

## Design

### Coherent lifting

A `rev` callable receives an inferred `coherent` capability when the compiler proves all of the following:

- inputs, outputs, and mutable state have finite exact encodings;
- every reachable operation is intrinsic or checked reversible and has a unitary lowering;
- no operation uses logged undo, measurement, reset, submission, host I/O, randomness, wall time, or exceptions;
- loops are statically bounded or lower to a verified reversible control structure;
- temporary allocation has a static bound and every ancilla is returned to its declared clean state;
- arithmetic semantics have a finite reversible representation, such as explicit modular width;
- all callees are coherently eligible.

An optional source annotation may require coherent eligibility and turn loss of eligibility into a declaration-site error. Eligibility is recorded in the function descriptor and can be independently checked from quantum-body metadata.

Calling an eligible function with classical operands uses its WIP-0001 body. Calling it with coherent encodings inside a quantum region uses its lifted unitary body. Dispatch follows static operand domains; there is no runtime provider-name overload.

A reversible in-place function lowers as a permutation of basis states. A non-bijective pure function may only become an oracle through an explicit reversible embedding such as `(x, y) -> (x, y xor f(x))`; that broader oracle synthesis is not implied by `pure`.

### Affine quantum ownership

`qubit` and `qureg` values are affine. Assignment transfers ownership unless the operation explicitly borrows. Aliases may identify disjoint slices only when the compiler proves disjointness. A measured or reset-consuming handle cannot be used under its old state identity.

CNOT does not copy an arbitrary quantum state. It may copy a computational-basis bit into a clean target, or entangle a superposed control and target. The type and proof systems must not label the latter as an independent saved state.

### Ancillas, `uncompute`, and `clean`

An ancilla declares its initial and required final state, normally `|0>` or a logical clean state. `uncompute` applies the validated inverse of a recorded coherent computation. It does not delete a value.

`clean resource` is accepted only when static analysis or a checked target operation establishes the resource's required final state. Unknown or entangled state must be uncomputed, measured, or reset according to explicit effects. History cleanup in classical code remains a WIP-0001 `COMMIT`, not quantum erasure.

### Quantum region IR

The `.wbc` region graph describes dependencies among classical bodies, quantum bodies, preparation, measurement, and host materialization points. A quantum body contains typed operations for:

- logical resource declaration and disjoint slicing;
- a small semantic gate set and parameter expressions;
- calls to unitary bodies and coherently lifted reversible functions;
- adjoint and controlled application;
- barriers that constrain optimization but do not imply host synchronization;
- measurement with explicit destination and basis;
- reset and known-state preparation;
- bounded static control and target-capability-dependent dynamic control;
- source locations, inverse relationships, and resource estimates.

The IR names semantic operations, not Qiskit classes or one hardware native gate set. WIP-0003 lowering decomposes those operations for a target.

### Region partitioning

The compiler partitions a hybrid function into maximal regions allowed by data dependencies and target capabilities:

- compile-time classical loops around gates may be unrolled or represented symbolically;
- coherent conditions become controlled unitary operations;
- measurement-conditioned control remains target-resident only with dynamic-circuit support;
- host classical computation after measurement ends the current remote quantum region unless the target supports an uploaded bounded classical kernel;
- a later quantum region starts from explicit newly prepared or target-session state, never an assumed surviving cloud qubit handle.

Partitioning is observable in cost and latency but not in typed program results. The compiler can emit a plan explaining every split and capability requirement.

### Transactions

Before measurement, a transaction consisting only of classical reversible and unitary operations may abort by applying inverses while resources remain live.

After measurement, reset, submission, or external effect, abort cannot restore an unknown physical pre-measurement state. It may restore classical state, discard observations, reset/reprepare resources, and retry according to WIP-0004. Source `rollback` must therefore carry an effect-sensitive type and cannot promise physical time reversal.

### Example interpretation

| Example | Intended interpretation or required correction |
| --- | --- |
| `Counter` | Classical `rev`; printing is an effect, while inverse calls remain valid. |
| `BinaryTree` | Reversible API using bounded logged mutation; history cleanup creates a commit horizon. |
| `QFT` | Closed unitary region; inverse should be generated or validated rather than maintained independently without checking. |
| `QFTProof` | Supplies future proof goals; measurements cannot be theorem variables for an unknown preserved pre-measurement state. |
| `QuantumOptimizer` | Parameterized circuit template plus repeated measurement and classical updates. |
| `QuantumNeuralNetwork` | Hybrid job loop; CNOT recording creates entanglement, not a clone, and ancillas must be uncomputed before destructive boundaries. |
| `SurfaceCode` | Dynamic target region with measurement, reset, decoding, and feed-forward capability requirements. |
| `QuantumCompiler` | Circuit transformation and mapping are classical; calibration and fidelity estimation are submitted quantum experiments. |

## Reversibility and history

Classical execution follows WIP-0001. Coherent bodies carry an adjoint mapping for every operation and a reversed dependency order. Gate decomposition must preserve that mapping.

Measurements emit observations, not undo records capable of recreating unknown physical amplitudes. A simulator may checkpoint its internal state for debugging, but that is an implementation feature and cannot strengthen portable language semantics.

A lifted `rev` body must not depend on WIP-0001 dynamic history. Information needed for inversion remains in coherent output or clean ancillas under a unitary mapping.

## Concurrency and determinism

Within one quantum body, operation dependency order is deterministic. Operations on disjoint resources may be scheduled in parallel by a target when commutation and declared barriers permit it.

Measurement outcomes are nondeterministic observations. Simulators accept explicit seeds where the model supports seeded sampling; hardware does not promise seeded outcomes. WIP-0004 records result provenance for replay.

This proposal does not define shared-memory VM threads. A later concurrency design must preserve affine quantum ownership and cannot concurrently mutate one quantum resource through aliases.

## Quantum and proof implications

This proposal establishes the semantic facts a later proof system may trust: operation signatures, effect sets, affine resource flow, inverse/adjoint relationships, region boundaries, and target requirements. It does not trust textual `because` clauses or make a compiler test equivalent to a mathematical proof.

A future proof certificate may establish unitary equivalence, ancilla cleanup, bounds, decomposition equivalence, or properties such as QFT correctness. Runtime execution remains safe without such certificates; unsupported optimization or theorem claims are rejected rather than assumed.

## Bytecode, persistence, and compatibility

WIP-0002 activates WIP-0001 section types 7 and 8. Region and quantum records are length-delimited and versioned. Function descriptors gain explicit effect sets, coherent eligibility, and quantum-body references.

Provider-compiled circuits, physical layouts, calibration snapshots, and credentials are not canonical semantic bytecode. They may be cached as target-qualified derived artifacts keyed by semantic region hash and target fingerprint.

Changing the meaning of a semantic gate, measurement, ownership rule, or coherent-eligibility condition requires a major semantic version. Adding an optional operation requires a declared capability and canonical rejection by older runtimes.

## Safety, limits, and failures

Compilation and runtime enforce bounds on logical qubits, ancillas, gates, depth estimates, parameters, controls, loop iterations, measurements, result bits, shots, and region splits. Target limits may be stricter.

The compiler rejects cloning, overlapping mutable slices, use after consume, dirty ancillas, implicit measurements, unsupported coherent lifts, unbounded dynamic control, and a `pure` declaration containing measurement or submission.

A target capability failure occurs before submission whenever possible. No fallback silently changes ideal semantics, noise policy, shot count, measurement basis, or error-mitigation method.

## Migration and deletion

1. Define effect and affine ownership models independent of the current AST hierarchy.
2. Add coherent-eligibility checking over a small WIP-0001 reversible function subset.
3. Define canonical region graph and quantum-body records in `.wbc`.
4. Implement a semantic simulator for the initial gate, preparation, measurement, and lifted-function subset.
5. Compile `Counter` classically and one finite reversible oracle both classically and coherently.
6. Compile `QFT` with generated adjoint and compare it against the hand-written inverse fixture.
7. Rewrite `QuantumOptimizer` as the first measured hybrid fixture.
8. Correct no-cloning, cleanup, purity, transaction, and remote-lifetime violations in the larger examples.
9. Delete AST and grammar constructs that cannot be assigned accepted semantics rather than retaining nonfunctional syntax.

## Progress

- [x] Classical, quantum, and hybrid program domains are represented and verified.
- [ ] Quantum resources have complete affine ownership and slice checking; the first profile prevents aliases by construction.
- [x] Coherent eligibility and lifted reversible calls work for the exact XOR subset.
- [x] Workflow and quantum body sections have canonical encoding and strict decoding.
- [x] The semantic state-vector simulator executes the initial gate and lifted-function subset.
- [x] Counter, coherent oracle, QFT, and the bounded measured optimizer pass end to end.

## Testing and acceptance

- [x] The same eligible `rev` XOR function produces matching classical basis results in the WIP-0001 VM and semantic quantum simulator.
- [x] Superposition tests show the lifted function acts as a unitary permutation, not a measurement-driven classical call.
- [x] A lifted function and unitary circuit followed by its generated adjoint restore the simulated register.
- [ ] Compiler-negative tests reject cloning, dirty ancillas, overlapping slices, use after measure, hidden logged history, I/O, and unbounded loops in coherent bodies.
- [x] QFT followed by its generated adjoint restores the checked basis-state fixture within numeric tolerance.
- [x] Full-register measurement produces a typed classical observation; broader consumed-identity checking remains.
- [ ] Static, host-split, and dynamic region plans preserve the same ideal result distributions where each is semantically valid.
- [ ] The optimizer fixture alternates parameter binding, quantum sampling, and classical updates without provider APIs in source.
- [ ] The surface-code fixture declares and checks dynamic measurement/reset/feed-forward requirements.
- [x] Every current example compiles, round-trips, parses with Tree-sitter, and executes in CI.
- [x] Current language and hybrid references distinguish inverse, uncompute, rewind, replay, and retry.

## Alternatives

### Separate classical and quantum languages

Rejected. It would duplicate types, modules, diagnostics, tooling, and algorithm structure, and it would prevent verified reversible functions from becoming reusable coherent operations.

### Treat quantum blocks as embedded Qiskit or OpenQASM strings

Rejected. Foreign strings lose Wheeler types, source maps, inverse relationships, affine ownership, proofs, and portability to future targets.

### Make transitions entirely implicit

Rejected. Automatic region partitioning is valuable, but preparation and measurement change information domains and must remain visible in semantics and diagnostics.

### Treat measurement as logged reversible mutation

Rejected. Recording an outcome supports deterministic workflow replay; it does not reconstruct an unknown pre-measurement physical state.

### Permit arbitrary classical calls from a quantum region

Rejected. Today's devices and unitary semantics require a bounded coherent subset or an explicit host split. Provider implementation convenience cannot define language meaning.

### Model CNOT as quantum copying

Rejected by no-cloning. It copies known basis information in a restricted case and entangles superposed inputs in general.

## Open questions

- What source annotation should require, rather than merely infer, coherent eligibility for a `rev` function? — **Owner:** language maintainers — **Decide by:** before this WIP enters Review
- Which small semantic gate set gives stable meaning while keeping decomposition practical for today's targets? — **Owner:** quantum compiler maintainers — **Decide by:** before quantum-body encoding is frozen
- Which finite classical data encodings are required in the first coherent-lifting slice beyond bits and fixed-width unsigned integers? — **Owner:** type-system maintainers — **Decide by:** before implementation begins

## References

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0003](WIP-0003-quantum-target-and-qiskit-backend.md)
- [WIP-0004](WIP-0004-hybrid-jobs-history-and-replay.md)
- [WIP-0010](WIP-0010-executable-application-portfolio.md)
- [WIP-0028](WIP-0028-constrained-generics-coherent-type-classes-and-region-ownership.md)
- [`Counter.w`](../../../wheeler-examples/src/main/wheeler/Counter.w)
- [`QFT.w`](../../../wheeler-examples/src/main/wheeler/QFT.w)
- [`QuantumOptimizer.w`](../../../wheeler-examples/src/main/wheeler/QuantumOptimizer.w)
- [`QuantumNeuralNetwork.w`](../../../wheeler-examples/src/main/wheeler/QuantumNeuralNetwork.w)
- [`SurfaceCode.w`](../../../wheeler-examples/src/main/wheeler/SurfaceCode.w)
- [`QuantumCompiler.w`](../../../wheeler-examples/src/main/wheeler/QuantumCompiler.w)
