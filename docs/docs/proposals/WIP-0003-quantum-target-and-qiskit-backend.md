# WIP-0003: Quantum target contract and Qiskit-compatible backend

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler runtime and quantum backend maintainers |
| Created | 2026-07-17 |
| Updated | 2026-07-17 |
| Area | Quantum targets, Qiskit, simulators, hardware capabilities |
| Depends on | WIP-0002 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler executes WIP-0002 quantum regions through a capability-based `QuantumTarget` contract. Targets describe semantic operations, topology, qubit kind, dynamic control, reset, parameter binding, sampling, expectation estimation, limits, timing, and result guarantees without exposing provider objects to Wheeler programs. Lowering produces a target-qualified derived executable; asynchronous submission produces versioned results and provenance.

The first implementations are a deterministic semantic simulator and a Qiskit-compatible adapter. The adapter translates supported region IR into Qiskit circuits or lossless interchange accepted by Qiskit, delegates physical mapping and provider-native lowering through an explicit policy, and supports local simulators and provider backends. The core contract also accommodates future fault-tolerant logical targets, target-resident classical kernels, and tightly coupled processors without making today's coupling maps or cloud queues permanent language concepts.

## Motivation

Running on a simulator is not enough, but compiling Wheeler directly against one Qiskit API would age poorly. Today's devices differ in native gates, topology, qubit count, reset, mid-circuit measurement, conditional control, shot limits, parameter handling, queueing, calibration, and result products. Future systems may expose logical qubits, lattice-surgery operations, distributed entanglement, long-lived sessions, or coherent reversible coprocessors rather than today's physical circuit interface.

The examples exercise several target shapes:

- `QFT` needs static unitary circuit execution.
- `QuantumOptimizer` needs parameterized repeated sampling.
- `QuantumNeuralNetwork` needs repeated circuits and gradient-related observations.
- `SurfaceCode` needs dynamic measurement, reset, decoding latency, and feed-forward.
- `QuantumCompiler` needs topology and calibration metadata but should not make those provider values part of source semantics.

A durable boundary must make capability differences explicit, preserve the ideal Wheeler program, and reject unsupported plans before expensive submission.

## Use cases

### Local development

A developer runs QFT and hybrid optimizer fixtures against a semantic simulator with explicit seeds, no credentials, and full traceability. The same `.wbc` region later targets Qiskit without source changes.

### Qiskit simulator or hardware

The runtime discovers a Qiskit target, obtains its capability snapshot, lowers a Wheeler region, binds parameters, submits shots or an expectation request, and maps results back to typed WIP-0002 observations.

### Unsupported dynamic circuit

A surface-code region requires mid-circuit measurement, reset, bounded classical decoding, and conditional correction. A static target rejects the plan with a structured list of missing capabilities before submission.

### Future logical machine

A fault-tolerant target advertises logical qubits and operations, code distance or logical error goals, and resource estimates without pretending to have a physical coupling graph identical to a NISQ device. Existing source and region IR remain meaningful.

### Reproducible derived executable

A cached target executable identifies the semantic region hash, target descriptor fingerprint, lowering pipeline and versions, mapping, native operations, calibration epoch when applicable, and optimization policy. A changed target snapshot causes deliberate relowering rather than accidental reuse.

## Goals

- Define a provider-neutral target descriptor, lowering contract, job API, and result model.
- Run a useful WIP-0002 subset through current Qiskit simulators and compatible hardware.
- Keep credentials, queues, provider objects, and Python dependencies outside language semantics and `.wbc` canonical quantum bodies.
- Negotiate capabilities before submission and preserve actionable diagnostics.
- Support static circuits, parameterized sampling, expectation estimation, and optional dynamic circuits.
- Make local simulation and remote hardware share lifecycle semantics even when one completes immediately.
- Model future logical and tightly coupled targets through capabilities rather than a fixed NISQ hierarchy.
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

A **target descriptor** is an immutable, bounded capability snapshot used for one planning decision. It has a stable fingerprint and expiry or freshness policy where provider data changes.

A **lowering plan** maps one semantic region to target operations while preserving its declared ideal semantics and recording policy choices.

A **target executable** is derived, target-qualified content. It is not canonical Wheeler bytecode and cannot be moved to a different target descriptor without validation.

A **submission** combines a target executable, parameter bindings, result request, execution options, and provenance identity.

A **job** has an asynchronous lifecycle and may outlive the process that submitted it. A **result** is an immutable typed observation product, never a surviving provider qubit reference.

## Ownership and boundaries

`wheeler-compiler` owns semantic-region validation, target-independent simplification, inverse preservation, and requirement inference.

`wheeler-runtime` owns target discovery, descriptor snapshots, lowering orchestration, submission lifecycle, bounds, result validation, and conversion to WIP-0002 values.

Target adapters own provider translation, native decomposition assigned to them, provider job handles, polling, cancellation requests, and provider metadata normalization.

The Qiskit adapter owns Qiskit version compatibility and Python integration. Qiskit types do not cross the adapter boundary.

Hosts own target selection, credentials, network policy, account configuration, and authorization. Credentials never enter `.wbc`, job results, debug dumps, or replay logs.

## Design

### Target descriptor

A descriptor identifies adapter, provider, backend, snapshot version, and qubit model. It advertises bounded capability records rather than one linear “generation” number. Initial records cover:

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

The reference simulator implements ideal semantics for the accepted gate and control subset. It prioritizes conformance, source traces, inverse checks, and explicit limits over large-scale performance. Statevector, stabilizer, tensor-network, density-matrix, or noisy simulators may implement the same target contract with distinct capability descriptors.

Seeded simulation records algorithm, seed, and version. Exact amplitudes are a simulator-only diagnostic capability and are never portable hardware program output.

### Qiskit-compatible adapter

The initial adapter translates Wheeler resources, parameters, gates, controls, measurements, and supported dynamic control into Qiskit circuit constructs or a lossless interchange path supported by the selected Qiskit version. It supports:

- local ideal simulation for parity tests;
- provider/backend descriptor discovery;
- static circuit submission;
- parameterized batches used by optimizers and parameter-shift workflows;
- sampling and expectation-style result requests when the provider supports them;
- dynamic circuits only when descriptor inspection confirms every required construct;
- explicit pass-manager or provider-transpilation policy;
- provider job recovery by durable external job ID.

The adapter may run in a separate Python worker so Wheeler's Java runtime does not embed Python. Transport is adapter-private but begins with a version handshake, bounded messages, structured errors, timeouts, and redacted logs. A future in-process or service adapter must pass the same conformance suite and cannot alter program semantics.

OpenQASM 3 or QIR may be used as interchange when they preserve the complete selected region and metadata. Neither format is assumed to represent every future target capability, and neither replaces the canonical Wheeler region IR.

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

Planning preserves ideal inverse relationships, but submitting an inverse circuit is not machine rewind. On hardware it is another physical execution subject to noise, queueing, and state-lifetime constraints.

A target may apply a unitary and its adjoint within one live region. Once measurement, reset, job termination, or loss of session state occurs, Wheeler does not claim to restore the prior physical state. WIP-0004 may replay observations or prepare and retry.

Target executables and results are immutable provenance objects. They do not enter WIP-0001 undo payloads as if external execution were local memory mutation.

## Concurrency and determinism

Planning is deterministic for the same semantic region, descriptor snapshot, named policy, and deterministic adapter version unless the policy explicitly permits provider heuristics. Nondeterministic planning inputs are recorded.

Independent jobs may run concurrently. Result delivery is correlated by submission identity, never arrival order. Target batch ordering and bit ordering are normalized.

Hardware samples are nondeterministic. Simulator determinism is declared as a capability with seed semantics. No comparison assumes byte-identical distributions from different physical targets.

## Quantum and proof implications

A lowering report may carry checkable equivalence witnesses for gate decomposition, routing, adjoint preservation, and approximation bounds. Those witnesses are not trusted merely because an adapter emits them; a later proof WIP will define accepted certificate forms and trusted checkers.

Calibration and empirical fidelity are evidence about a target run, not proofs of source-level unitarity or correctness. `QuantumCompiler.w` must distinguish semantic verification, classical compilation, and calibration experiments.

## Bytecode, persistence, and compatibility

WIP-0003 activates WIP-0001 target-requirement sections. Canonical `.wbc` records requirement predicates and semantic region identities, not credentials or provider job IDs.

Derived executables, descriptor snapshots, lowering reports, submissions, handles, and results use separate versioned runtime schemas. Cached executables are invalid when any identity input or required freshness condition changes.

Adapters declare the runtime API versions and semantic operation versions they implement. Provider SDK upgrades require adapter parity tests before becoming the default; they do not force a Wheeler bytecode major version unless Wheeler semantics change.

## Safety, limits, and failures

Host policy bounds descriptor size, compile time, executable size, submissions, batches, shots, result bytes, polling rate, retries, and total cost where a provider exposes cost information. Submission may require explicit user approval above policy thresholds.

Adapter processes are untrusted capability holders with least-privilege credentials. Messages are validated on both sides. Logs and errors redact secrets and bounded provider payloads.

Structured failures distinguish invalid Wheeler IR, missing target capability, lowering failure, provider rejection, queue timeout, execution failure, cancellation state, malformed result, stale descriptor, and adapter incompatibility. No failure silently switches backend, increases shots, enables approximation, or changes mitigation.

## Migration and deletion

1. Define immutable target, plan, executable, job, and result interfaces plus mock-target tests.
2. Implement the ideal semantic simulator as the reference target.
3. Add target-requirement inference and pre-submission capability diagnostics.
4. Implement Qiskit translation for the initial static gate and measurement subset.
5. Add parameterized batch sampling and expectation result support.
6. Add descriptor-gated dynamic circuit support for available Qiskit targets.
7. Run QFT and optimizer fixtures against the semantic simulator and Qiskit local simulation.
8. Add opt-in live hardware smoke tests that never gate ordinary CI.
9. Rewrite example code that reads topology or noise through undeclared globals to consume target descriptors or explicit compile inputs.

## Progress

- [ ] Target descriptor and requirement matching are implemented.
- [ ] Semantic simulator passes the region conformance suite.
- [ ] Mock asynchronous jobs cover lifecycle and failure behavior.
- [ ] Qiskit static circuit and parameterized sampling adapters work.
- [ ] Dynamic capability discovery and rejection work.
- [ ] QFT and optimizer examples run on both local target implementations.

## Testing and acceptance

- [ ] Descriptor canonicalization and fingerprints are stable and bounded.
- [ ] Capability matching reports every missing requirement before submission.
- [ ] Semantic simulator and Qiskit local simulation agree on basis-state results and statistically agree on representative sampled circuits.
- [ ] QFT and inverse-QFT circuits preserve expected ideal behavior after target lowering.
- [ ] Parameter order, register order, endianness, shot counts, and result identity survive Qiskit round trips.
- [ ] Mock jobs cover queueing, success, provider failure, cancellation request races, late results, recovery, timeout, malformed result, and adapter restart.
- [ ] Cached target executables invalidate on descriptor, policy, adapter, parameter-schema, or semantic-region changes.
- [ ] A static target rejects the dynamic surface-code fixture with actionable missing capabilities.
- [ ] A dynamic simulator executes a bounded syndrome/conditional fixture without a host split.
- [ ] Credentials never appear in artifacts, snapshots, results, traces, or test golden files.
- [ ] Live hardware tests are opt-in, budget-capped, and do not make deterministic CI claims.
- [ ] Current target documentation explains simulator, Qiskit, hardware, and future logical capability boundaries.

## Alternatives

### Make Qiskit the Wheeler execution model

Rejected. Qiskit is an important adapter and ecosystem, but its APIs, providers, and circuit capabilities are not a 20–30 year language contract.

### Standardize only OpenQASM 3

Rejected as the sole boundary. It is useful interchange for many current circuits but does not by itself define jobs, target discovery, results, provenance, future logical operations, or every Wheeler resource contract.

### Standardize only QIR

Rejected for the same reason. QIR may be a valuable lowering target, but it is not Wheeler's complete source, workflow, capability, or result model.

### Compile separately for each provider in source code

Rejected. Provider selection belongs to deployment and runtime policy. Source should state semantic operations and requirements.

### Hide unsupported features through decomposition or host splitting

Rejected. Decomposition must preserve semantics and error budgets; host splitting changes latency and may be impossible for live quantum state. Both require explicit plans and diagnostics.

## Open questions

- Which Qiskit package/version range and simulator establish the first supported adapter baseline? — **Owner:** Qiskit adapter maintainers — **Decide by:** before adapter implementation
- Should the initial out-of-process adapter transport use generated protobuf, canonical CBOR, or another bounded schema? — **Owner:** runtime maintainers — **Decide by:** before the worker protocol is implemented
- Which expectation and observable model belongs in the first result contract rather than a later extension? — **Owner:** quantum API maintainers — **Decide by:** before this WIP enters Review

## References

- [WIP-0002](WIP-0002-unified-classical-quantum-semantics.md)
- [WIP-0004](WIP-0004-hybrid-jobs-history-and-replay.md)
- [`QFT.w`](../../../wheeler-examples/src/main/wheeler/QFT.w)
- [`QuantumOptimizer.w`](../../../wheeler-examples/src/main/wheeler/QuantumOptimizer.w)
- [`SurfaceCode.w`](../../../wheeler-examples/src/main/wheeler/SurfaceCode.w)
- [`QuantumCompiler.w`](../../../wheeler-examples/src/main/wheeler/QuantumCompiler.w)
- [Qiskit documentation](https://docs.quantum.ibm.com/)
- [OpenQASM 3 specification](https://openqasm.com/)
- [QIR Alliance](https://www.qir-alliance.org/)
