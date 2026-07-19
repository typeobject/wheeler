# Quantum targets

Wheeler programs contain semantic quantum regions. A target plans and executes those regions; it is a runtime adapter, not a source-language dependency.

## Submission contract

A target publishes an immutable `TargetDescriptor`:

- adapter and target identity;
- independently negotiated capabilities;
- maximum logical qubits;
- maximum shots.

The initial capability vocabulary includes static circuits, parameter binding, batches, mid-circuit measurement, reset, classical conditions, state-vector diagnostics, and logical qubits. A target advertises only the records it implements.

The runtime submits an immutable `QuantumTask` containing the verified artifact, logical register, basis preparation, ordered circuit or adjoint applications, shot count, and simulator seed policy.

`QuantumJob` is asynchronous even when a local simulator completes immediately. It reports identity and lifecycle, accepts a cancellation request, and returns a bounded `QuantumResult`. Results use canonical little-endian integer outcomes and carry target identity. The runtime rejects job or target identity mismatches before updating classical state.

`QuantumTarget.recover(jobId, task)` reconciles an acknowledged job without submitting it again. The local targets recover jobs retained by the target instance. A remote adapter must map the durable external identity and reject unknown or mismatched tasks; it must not interpret recovery as permission to resubmit.

[WIP-0032](../proposals/WIP-0032-unified-io-fabric-and-durability-receipts.md) will move this lifecycle under `IoScope` while retaining target-specific request/result types and WIP-0004 identities. That proposal is Draft: the current `QuantumJob` API does not yet implement the general fabric. In either model, target submission moves classical descriptions and observations; coherent quantum state never becomes an I/O buffer.

## Ideal state-vector target

`StateVectorTarget` is the semantic reference for the current static gate subset. It supports up to 20 qubits and reruns a complete prepare-unitary-measure task for every shot. Explicit seeds make its samples repeatable; those seeds do not imply deterministic hardware.

The engine implements H, X, Z, phase, controlled phase, CNOT, CZ, swap, generated adjoints, and coherently lifted XOR permutations.

## Batches and sampled expectations

`QuantumBatch` is an ordered content-identified list of complete tasks. Batch identity includes each task identity in semantic order. `QuantumBatchJob` preserves that order regardless of completion timing, applies one overall timeout, supports cancellation requests across member jobs, and rejects job or task identity drift.

The ideal target advertises `BATCH_SUBMISSION`. Its provider-neutral batch implementation uses ordinary asynchronous member jobs, so batching does not weaken individual recovery or result provenance. Targets without the capability reject a batch before the first submission.

`ParameterizedGateOperation` carries a stable parameter name and finite scale in semantic region IR. A task supplies the exact finite binding map; missing and extra names fail before submission, and the binding map participates in task identity. Generated adjoints negate the symbolic scale. The ideal target evaluates bindings directly, while OpenQASM lowering emits the bound numeric angle. Both advertise `PARAMETER_BINDING`.

`QuantumResult.zExpectation(...)` estimates a tensor product of Pauli-Z observables directly from canonical little-endian samples and reports value, standard error, and shots. Provider-native expectation requests remain a separate lowering optimization; Wheeler can always retain the sampled result and its provenance.

## OpenQASM 3

`OpenQasm3Emitter` lowers the supported static task to a complete program:

```qasm
OPENQASM 3.0;
include "stdgates.inc";
bit[2] c;
qubit[2] q;
h q[0];
cx q[0], q[1];
c = measure q;
```

OpenQASM is a derived target format. Wheeler region IR remains authoritative because one interchange format cannot describe every future logical or target-resident capability.

`wheeler qasm` emits this form from a `.wbc` artifact containing one static submission. Qiskit and other OpenQASM 3 consumers can import the result without becoming Wheeler runtime dependencies.

## OpenQASM target SPI

`OpenQasmTarget` accepts an application-supplied `OpenQasmExecutor`:

```java
OpenQasmTarget target = new OpenQasmTarget(
  "provider-name",
  127,
  10_000,
  (qasm, shots, seed) -> provider.submit(qasm, shots));
```

The executor may call a provider REST API, appliance SDK, local engine, or queue service. Wheeler passes canonical QASM and validates that the executor returns exactly one in-range full-register outcome per shot. Execution remains asynchronous through `QuantumJob`.

This boundary avoids an embedded Python runtime. A Qiskit application can consume emitted OpenQASM externally; a Java host can implement a provider REST executor directly. Credentials and provider objects remain host-owned and never enter `.wbc`, QASM, result records, or logs.

## Physical limits

Applying a generated adjoint is another physical computation. It is not VM rewind. After measurement or target-session loss, Wheeler can replay a recorded observation or prepare and retry, but it cannot reconstruct an unknown prior hardware state.

Dynamic-circuit and fault-tolerant capabilities remain explicit target requirements. A static target fails before submission rather than splitting a latency-sensitive region silently.
