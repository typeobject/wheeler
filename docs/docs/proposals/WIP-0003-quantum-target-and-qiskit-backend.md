# WIP-0003: Quantum target contract and OpenQASM interoperability

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler runtime and quantum backend maintainers |
| Created | 2026-07-17 |
| Updated | 2026-07-17 |
| Area | Quantum targets, OpenQASM, simulators, hardware capabilities |
| Depends on | WIP-0002 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler runs WIP-0002 quantum regions through a capability-based `QuantumTarget` contract. A target describes supported operations, topology, qubit kind, dynamic control, reset, parameter binding, sampling, expectation estimates, limits, timing, and result guarantees. Wheeler programs never receive provider objects.

The Wheeler region remains authoritative during planning. Lowering creates a target-specific executable, and asynchronous submission returns versioned results with provenance. OpenQASM, provider circuits, pulse plans, and job payloads are derived data. They do not replace the source region's ownership, effects, adjoint, inverse, or proof identity.

The first targets are a deterministic semantic simulator and an OpenQASM 3 boundary. Wheeler lowers supported static regions to portable OpenQASM. An application-supplied executor may then use a REST API, appliance SDK, queue, local engine, or external tool. Qiskit is one possible OpenQASM consumer, not a Wheeler runtime dependency.

The same contract can later support logical fault-tolerant targets, target-side classical kernels, and tightly coupled processors. It does not make today's coupling maps or cloud queues part of the language.

## Motivation

A simulator is useful, but direct dependence on one Qiskit API would age badly. Current devices differ in native gates, topology, qubit count, reset, mid-circuit measurement, conditional control, shot limits, parameters, queues, calibration, and result formats. Future systems may expose logical qubits, lattice-surgery operations, distributed entanglement, long sessions, or coherent coprocessors.

The examples also need different target shapes:

- `QFT` needs static unitary execution.
- `QuantumOptimizer` needs repeated parameterized sampling.
- `QuantumNeuralNetwork` needs repeated circuits and gradient-related observations.
- `SurfaceCode` needs measurement, reset, low-latency decoding, and feed-forward.
- `QuantumCompiler` needs topology and calibration data without making provider values part of source meaning.

A stable target boundary must expose these differences, preserve the ideal Wheeler program, and reject unsupported plans before submission begins.

## Use cases

### Local development

A developer runs QFT and hybrid optimizer fixtures against a semantic simulator with explicit seeds, no credentials, and full traceability. The same `.wbc` region later lowers to OpenQASM for a conforming consumer without source changes.

### OpenQASM consumer or hardware

The runtime obtains a target capability snapshot, lowers a Wheeler region to OpenQASM when lossless, submits shots through the host executor, and maps validated results back to typed WIP-0002 observations. Qiskit may be that consumer, but it is not embedded in Wheeler.

### Unsupported dynamic circuit

A surface-code region requires mid-circuit measurement, reset, bounded classical decoding, and conditional correction. A static target rejects the plan with a structured list of missing capabilities before submission.

### Future logical machine

A fault-tolerant target advertises logical qubits and operations, code distance or logical error goals, and resource estimates without pretending to have a physical coupling graph identical to a NISQ device. Existing source and region IR remain meaningful.

### Reproducible derived executable

A cached target executable identifies the semantic region hash, target descriptor fingerprint, lowering pipeline and versions, mapping, native operations, calibration epoch when applicable, and optimization policy. A changed target snapshot causes deliberate relowering instead of accidental reuse.

## Goals

- Define a provider-neutral target descriptor, lowering contract, job API, and result model.
- Run a useful WIP-0002 subset through current OpenQASM consumers and compatible hardware.
- Keep credentials, queues, provider objects, and provider SDK dependencies outside language semantics and `.wbc` canonical quantum bodies.
- Negotiate capabilities before submission and preserve actionable diagnostics.
- Support static circuits, parameterized sampling, expectation estimation, and optional dynamic circuits.
- Make local simulation and remote hardware share lifecycle semantics even when one completes immediately.
- Model future logical and tightly coupled targets through capabilities instead of a fixed NISQ hierarchy.
- Record enough provenance for WIP-0004 replay and scientific comparison.

## Non-goals

- Guarantee that every valid Wheeler quantum region runs on every target.
- Standardize one provider, transpiler, error-mitigation package, or account system.
- Expose raw Qiskit `QuantumCircuit`, backend, primitive, pass-manager, or job objects to Wheeler source.
- Promise deterministic hardware outcomes or identical noise across targets.
- Make remote quantum jobs synchronous.
- Standardize pulse schedules in the first target contract.
- Define workflow rollback, retries, or history retention; WIP-0004 does that.

## Terms and semantic model

A **semantic region** is WIP-0002 backend-neutral quantum IR with ideal operations and declared requirements.

A **target descriptor** is an immutable, bounded capability snapshot used for one planning decision; it has a stable fingerprint and expiry or freshness policy where provider data changes.

A **lowering plan** maps one semantic region to target operations while preserving its declared ideal semantics and recording policy choices.

A **target executable** is derived, target-qualified content. It is not canonical Wheeler bytecode and cannot be moved to a different target descriptor without validation.

A **submission** combines a target executable, parameter bindings, result request, execution options, and provenance identity.

A **job** has an asynchronous lifecycle and may outlive the process that submitted it; a **result** is an immutable typed observation product, never a surviving provider qubit reference.

## Ownership and boundaries

`wheeler-compiler` owns semantic-region validation, target-independent simplification, inverse preservation, and requirement inference.

`wheeler-runtime` owns target discovery, descriptor snapshots, lowering orchestration, submission lifecycle, bounds, result validation, and conversion to WIP-0002 values.

Target adapters own provider translation, native decomposition assigned to them, provider job handles, polling, cancellation requests, and provider metadata normalization.

The OpenQASM executor owner handles provider compatibility and transport. Provider SDK types don't cross the target boundary.

Hosts own target selection, credentials, network policy, account configuration, and authorization; credentials never enter `.wbc`, job results, debug dumps, or replay logs.

## Design

### Target descriptor

A descriptor identifies adapter, provider, backend, snapshot version, and qubit model; it advertises bounded capability records instead of one linear "generation" number. Initial records cover:

- physical, simulated, or logical qubit kind and available count;
- semantic operations accepted directly or through certified decomposition;
- native operation names and parameter domains;
- directed connectivity or a declaration that topology is abstract/managed;
- measurement bases, simultaneous measurement, and per-shot memory availability;
- reset, mid-circuit measurement, conditionals, bounded loops, switches, and target-resident classical computation;
- maximum circuit count, operations, depth where known, parameters, shots, result bytes, and wall duration;
- parameter binding and batch submission;
- sampling and expectation-value result modes;
- session or long-lived resource support;
- timing, scheduling, barriers, and concurrency where exposed;
- calibration/noise metadata availability and freshness, without making it ideal semantics;
- logical resource estimation and error goals for future fault-tolerant targets.

Capabilities are individually versioned and may carry constraints. An adapter cannot advertise a broad capability and then silently accept only a provider-specific subset.

### Planning and lowering

Planning has explicit stages:

1. validate semantic region and resource bounds;
2. compare inferred requirements to the target descriptor;
3. choose allowed target-independent decompositions;
4. choose placement, routing, scheduling, and target-native lowering according to named policy;
5. validate the derived executable against the same descriptor snapshot;
6. emit a lowering report and derived-executable identity.

The report maps source and semantic operations to derived operations, records inserted swaps/resets, preserves measurement identities, gives depth and resource estimates, and identifies approximations. Approximate synthesis requires an explicit error budget and cannot be selected silently.

Unitary adjoints and coherently lifted functions retain equivalence obligations through decomposition. A provider transpiler may perform additional rewrites only under the selected policy; its version and relevant options become provenance.

### Target API

The conceptual API is asynchronous even for local simulation:

```text
inspect() -> TargetDescriptor
plan(SemanticRegion, TargetDescriptor, LoweringPolicy) -> LoweringPlan
materialize(LoweringPlan) -> TargetExecutable
submit(TargetExecutable, Bindings, ResultRequest, ExecutionOptions) -> JobHandle
poll(JobHandle) -> JobState
cancel(JobHandle) -> CancellationState
result(JobHandle) -> QuantumResult
```

Implementations may combine calls for efficiency but preserve their validation and identity boundaries. Job states include `queued`, `running`, `succeeded`, `failed`, `cancel-requested`, `cancelled`, and `unknown`; provider state is retained as bounded metadata.

Cancellation is a request, not proof that hardware stopped. A late valid result remains identifiable so WIP-0004 policy can discard or archive it.

### Result model

A result identifies submission, executable, semantic region, target descriptor, bindings, and request. Result products include:

- sampled counts over declared classical registers;
- optional bounded per-shot memory;
- expectation values with uncertainty and observable identity;
- target or simulator diagnostics;
- mapping and execution metadata;
- timing and provider job identity after credential scrubbing.

Counts use canonical bit/register ordering independent of provider display conventions. Missing shots, malformed keys, nonfinite estimates, oversized metadata, and identity mismatches are rejected.

### Semantic simulator

The reference simulator implements ideal semantics for the accepted gate and control subset; it prioritizes conformance, source traces, inverse checks, and explicit limits over large-scale performance. Statevector, stabilizer, tensor-network, density-matrix, or noisy simulators may implement the same target contract with distinct capability descriptors.

Seeded simulation records algorithm, seed, and version. Exact amplitudes are a simulator-only diagnostic capability and are never portable hardware program output.

### OpenQASM interoperability

The initial portable adapter translates Wheeler resources, gates, coherent calls, generated adjoints, preparation, and full-register measurement to OpenQASM 3. `OpenQasmTarget` accepts an application-owned executor and retains Wheeler's asynchronous job and result validation around it.

An executor may submit through a provider REST API, appliance SDK, queue service, local engine, or external application. It receives canonical QASM, shot count, and seed policy and returns one bounded little-endian outcome per shot. Wheeler validates count and width before accepting the result.

Qiskit can import emitted OpenQASM, but Wheeler does not embed Python or Qiskit. `wheeler qasm` emits a static submission for external tools. Future Java or native provider adapters implement the same executor contract without changing source or bytecode.

OpenQASM 3 does not replace canonical Wheeler region IR. Regions requiring dynamic feedback, future logical operations, or semantics not represented losslessly require another capability-specific lowering instead of provider text hidden in source.

### Future target evolution

The contract avoids assumptions that all useful machines expose physical qubit indices, per-gate cloud circuits, or a host round trip after every measurement. Future adapters may advertise:

- logical qubits and logical operations;
- bounded uploaded reversible classical kernels;
- target-resident loops and low-latency decoding;
- networked entanglement resources;
- persistent sessions or memories;
- analog or non-gate operations through versioned semantic extensions;
- compiled coherent calls from WIP-0002 without decomposition to today's elementary gates.

New capabilities do not weaken affine ownership, explicit measurement, result provenance, or resource bounds.

## Reversibility and history

Planning preserves ideal inverse relationships, but submitting an inverse circuit is not machine rewind. On hardware it's another physical execution subject to noise, queueing, and state-lifetime constraints.

A target may apply a unitary and its adjoint within one live region. Once measurement, reset, job termination, or loss of session state occurs, Wheeler does not claim to restore the prior physical state. WIP-0004 may replay observations or prepare and retry.

Target executables and results are immutable provenance objects. They do not enter WIP-0001 undo payloads as if external execution were local memory mutation.

## Concurrency and determinism

Planning is deterministic for the same semantic region, descriptor snapshot, named policy, and deterministic adapter version unless the policy explicitly permits provider heuristics. Nondeterministic planning inputs are recorded.

Independent jobs may run concurrently. Result delivery is correlated by submission identity, never arrival order. Target batch ordering and bit ordering are normalized.

Hardware samples are nondeterministic. Simulator determinism is declared as a capability with seed semantics. No comparison assumes byte-identical distributions from different physical targets.

## Quantum and proof implications

A lowering report may carry checkable equivalence witnesses for gate decomposition, routing, adjoint preservation, and approximation bounds. Those witnesses are not trusted only because an adapter emits them; a later proof WIP will define accepted certificate forms and trusted checkers.

Calibration and empirical fidelity are evidence about a target run, not proofs of source-level unitarity or correctness. `QuantumCompiler.w` must distinguish semantic verification, classical compilation, and calibration experiments.

## Bytecode, persistence, and compatibility

WIP-0003 activates WIP-0001 target-requirement sections. Canonical `.wbc` records requirement predicates and semantic region identities, not credentials or provider job IDs.

Derived executables, descriptor snapshots, lowering reports, submissions, handles, and results use separate versioned runtime schemas. Cached executables are invalid when any identity input or required freshness condition changes.

Adapters declare the runtime API versions and semantic operation versions they implement. Provider SDK upgrades require adapter parity tests before becoming the default; they do not force a Wheeler bytecode major version unless Wheeler semantics change.

## Safety, limits, and failures

Host policy bounds descriptor size, compile time, executable size, submissions, batches, shots, result bytes, polling rate, retries, and total cost where a provider exposes cost information. Submission may require explicit user approval above policy thresholds.

Adapter processes are untrusted capability holders with least-privilege credentials. Messages are validated on both sides. Logs and errors redact secrets and bounded provider payloads.

Structured failures distinguish invalid Wheeler IR, missing target capability, lowering failure, provider rejection, queue timeout, execution failure, cancellation state, malformed result, stale descriptor, and adapter incompatibility. No failure silently switches backend, increases shots, enables approximation, or changes mitigation.

## Unified target-operation lifecycle

WIP-0032 supplies the common future lifecycle for target submission, observation, cancellation, result delivery, and recoverable sessions. Target requests and results remain quantum-domain types carrying WIP-0004 identities; they are not generic file writes with provider credentials attached.

The current `QuantumJob` API is an executable stage-0 slice of that lifecycle. Migration preserves its submit/acknowledge/validate/recover behavior while moving ownership, queue credit, completion, and cancellation races under `IoScope`. Coherent state never enters the fabric as bytes.

## Migration and deletion

1. Define immutable target, plan, executable, job, and result interfaces plus mock-target tests.
2. Implement the ideal semantic simulator as the reference target.
3. Add target-requirement inference and pre-submission capability diagnostics.
4. Implement OpenQASM 3 translation and an application-supplied executor for the initial static gate and measurement subset.
5. Add parameterized batch sampling and expectation result support.
6. Add descriptor-gated dynamic circuit support for capable targets.
7. Run QFT and optimizer fixtures against the semantic simulator and a conforming OpenQASM executor.
8. Keep live hardware smoke tests opt-in so ordinary CI remains deterministic.
9. Rewrite example code that reads topology or noise through undeclared globals to consume target descriptors or explicit compile inputs.

## Progress

- [x] Target descriptor, independent capabilities, limits, and requirement matching are implemented.
- [x] The ideal state-vector target passes the implemented region conformance suite.
- [x] Asynchronous jobs cover successful ideal and OpenQASM execution plus malformed results; cancellation and recovery remain.
- [x] Static OpenQASM 3 lowering, canonical symbolic parameter binding, ordered task batches, and sampled Pauli-Z expectations work.
- [ ] Static capability rejection works; dynamic capability discovery remains.
- [ ] QFT, inverse QFT, and the bounded optimizer run on the ideal target; OpenQASM executor parity and parameterized optimization remain.

## Testing and acceptance

- [x] Descriptor canonicalization and fingerprints are stable, bounded, and independent of set construction order.
- [x] Capability matching reports every missing required capability before submission.
- [ ] The semantic simulator and a conforming OpenQASM executor agree on basis-state results and representative sampled circuits.
- [x] QFT and inverse-QFT circuits preserve expected behavior on the ideal target.
- [x] Static parameter schema, binding values, register order, little-endian outcomes, shot counts, and result identity survive bytecode, ideal-target, and OpenQASM lowering round trips.
- [ ] Mock jobs cover queueing, success, provider failure, cancellation request races, late results, recovery, timeout, malformed result, and adapter restart.
- [ ] Cached target executables invalidate on descriptor, policy, adapter, parameter-schema, or semantic-region changes.
- [ ] A static target rejects the dynamic surface-code fixture with actionable missing capabilities.
- [ ] A dynamic simulator executes a bounded syndrome/conditional fixture without a host split.
- [x] The executor boundary and documentation keep credentials outside artifacts, QASM, results, and traces.
- [ ] Live hardware tests are opt-in, budget-capped, and do not make deterministic CI claims.
- [x] Current target documentation explains simulator, OpenQASM, hardware, and future logical capability boundaries.

## Alternatives

### Make Qiskit the Wheeler execution model

Rejected. Qiskit is an important OpenQASM consumer and ecosystem, but its APIs, providers, and circuit capabilities are not Wheeler's long-term language contract.

### Standardize only OpenQASM 3

Rejected as the sole boundary. It is useful interchange for many current circuits but does not by itself define jobs, target discovery, results, provenance, future logical operations, or every Wheeler resource contract.

### Standardize only QIR

Rejected for the same reason. QIR may be a useful lowering target, but it is not Wheeler's complete source, workflow, capability, or result model.

### Compile separately for each provider in source code

Rejected. Provider selection belongs to deployment and runtime policy. Source should state semantic operations and requirements.

### Hide unsupported features through decomposition or host splitting

Rejected. Decomposition must preserve semantics and error budgets; host splitting changes latency and may be impossible for live quantum state. Both require explicit plans and diagnostics.

## Open questions

- Which provider REST executor should be the first maintained live-hardware adapter (owner: target maintainers; decision point: before live hardware enters CI documentation)?
- Which expectation and observable model belongs in the first result contract instead of a later extension (owner: quantum API maintainers; decision point: before this WIP enters Review)?

## References

- [WIP-0002](WIP-0002-unified-classical-quantum-semantics.md)
- [WIP-0004](WIP-0004-hybrid-jobs-history-and-replay.md)
- [WIP-0010](WIP-0010-executable-application-portfolio.md)
- [WIP-0032](WIP-0032-unified-io-fabric-and-durability-receipts.md)
- [`QFT.w`](../../../wheeler-examples/src/main/wheeler/quantum/QFT.w)
- [`QuantumOptimizer.w`](../../../wheeler-examples/src/main/wheeler/quantum/QuantumOptimizer.w)
- [`SurfaceCode.w`](../../../wheeler-examples/src/main/wheeler/quantum/SurfaceCode.w)
- [`QuantumCompiler.w`](../../../wheeler-examples/src/main/wheeler/quantum/QuantumCompiler.w)
- [Qiskit documentation](https://docs.quantum.ibm.com/)
- [OpenQASM 3 specification](https://openqasm.com/)
- [QIR Alliance](https://www.qir-alliance.org/)
