# Quantum targets

Wheeler programs contain semantic quantum regions. A target plans and runs those regions. It is a runtime adapter, not a source-language dependency.

## Submission contract

A target publishes an immutable `TargetDescriptor` with:

- adapter and target identity;
- independently negotiated capabilities;
- a maximum logical-qubit count;
- a maximum shot count.

The first capability set includes static circuits, parameter binding, batches, mid-circuit measurement, reset, classical conditions, state-vector diagnostics, and logical qubits. A target advertises only the records it can execute.

The runtime submits an immutable `QuantumTask`. It contains the verified artifact, logical register, basis preparation, ordered circuit or adjoint applications, shot count, and simulator seed policy.

`QuantumJob` is asynchronous even when a local simulator finishes at once. It reports identity and lifecycle, accepts a cancellation request, and returns a bounded `QuantumResult`.

Results use canonical little-endian integer outcomes and carry target identity. The runtime checks job and target identities before it changes classical state.

`QuantumTarget.recover(jobId, task)` reconciles an acknowledged job without submitting it again. Local targets can recover jobs kept by the same target instance. A remote adapter must map the durable external identity and reject unknown or mismatched tasks. Recovery never grants permission to resubmit.

[WIP-0032](../proposals/WIP-0032-unified-io-fabric-and-durability-receipts.md) will move this lifecycle under `IoScope` while keeping target-specific request and result types plus WIP-0004 identities. That proposal is still a Draft, so the current `QuantumJob` API doesn't implement the general fabric.

In either model, submission moves classical descriptions and observations; coherent quantum state never becomes an I/O buffer.

## Ideal state-vector target

`StateVectorTarget` is the semantic reference for the current static gate set. It supports up to 20 qubits and reruns the complete prepare, unitary, and measure task for each shot.

Explicit seeds make simulator samples repeatable. They do not make real hardware deterministic.

The engine supports H, X, Z, phase, controlled phase, CNOT, CZ, swap, generated adjoints, and coherently lifted XOR permutations.

## Batches and sampled expectations

`QuantumBatch` is an ordered, content-identified list of complete tasks; its identity includes each task identity in semantic order.

`QuantumBatchJob` keeps that order even when tasks finish out of order. It uses one overall timeout, supports cancellation requests across member jobs, and rejects any job or task identity drift.

The ideal target advertises `BATCH_SUBMISSION`. Its provider-neutral implementation uses normal asynchronous member jobs, so each job keeps its own recovery and result provenance. A target without the capability rejects the whole batch before the first submission.

`ParameterizedGateOperation` stores a stable parameter name and finite scale in semantic region IR. A task provides the exact finite binding map. Missing or extra names fail before submission, and the map becomes part of task identity.

Generated adjoints negate the symbolic scale. The ideal target evaluates bindings directly, while OpenQASM lowering writes the bound numeric angle. Both paths advertise `PARAMETER_BINDING`.

`QuantumResult.zExpectation(...)` estimates a tensor product of Pauli-Z observables from canonical little-endian samples. It reports the value, standard error, and shot count.

Provider-native expectation requests may be used as a lowering optimization; Wheeler can still keep the sampled result and its provenance.

## OpenQASM 3

`OpenQasm3Emitter` lowers a supported static task into a complete program:

```qasm
OPENQASM 3.0;
include "stdgates.inc";
bit[2] c;
qubit[2] q;
h q[0];
cx q[0], q[1];
c = measure q;
```

OpenQASM is a derived target format. Wheeler region IR remains the source of truth because one interchange format cannot describe every future logical or target-resident feature.

`wheeler qasm` emits this form from a `.wbc` artifact that contains one static submission. Qiskit and other OpenQASM 3 tools may import the result without becoming Wheeler runtime dependencies.

## OpenQASM target SPI

`OpenQasmTarget` accepts an application-provided `OpenQasmExecutor`:

```java
OpenQasmTarget target = new OpenQasmTarget(
  "provider-name",
  127,
  10_000,
  (qasm, shots, seed) -> provider.submit(qasm, shots));
```

The executor may call a provider REST API, appliance SDK, local engine, or queue service. Wheeler passes canonical QASM and checks that the executor returns one in-range full-register outcome for every shot. Execution still uses asynchronous `QuantumJob` state.

This boundary avoids an embedded Python runtime. A Qiskit application can consume emitted OpenQASM outside Wheeler, and a Java host can implement a provider REST adapter directly.

Credentials and provider objects stay with the host. They never enter `.wbc`, QASM, result records, or logs.

## Physical limits

Running a generated adjoint is another physical computation. It is not VM rewind.

After measurement or target-session loss, Wheeler can replay a recorded observation or prepare new state and retry. It cannot rebuild an unknown earlier hardware state.

Dynamic-circuit and fault-tolerant features remain explicit target requirements. A static target fails before submission instead of silently moving a latency-sensitive region to the host.
