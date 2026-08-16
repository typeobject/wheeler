---
title: Quantum Targets
description: Submission identity, ideal simulation, dynamic control, batches, OpenQASM, and physical limits.
---

# Quantum Targets

Wheeler artifacts carry semantic quantum regions. A target plans and performs
those regions using a particular simulator, chamber, or provider. The adapter does
not define source-language meaning.

## Descriptor and submission

A `TargetDescriptor` publishes adapter and target identity, independently
negotiated capabilities, maximum logical qubits, and maximum shots.

Capabilities include static circuits, parameter binding, batches, mid-circuit
measurement, reset, classical conditions, state-vector diagnostics, logical
qubits, and network entanglement. A target advertises only work it can execute.

`QuantumSubmission` binds the verified artifact, logical register, basis
preparation, ordered circuit or adjoint applications, shot count, and seed policy.

Every `QuantumJob` is asynchronous, including a local job that finishes
immediately. It carries identity and lifecycle, accepts a cancellation request,
and returns a `QuantumResult`. Results use canonical little-endian outcome
integers and name their target.

Before classical state changes, the runtime verifies job, target, and complete
task identity. `recover(jobId, task)` reconciles acknowledged work without another
submission. An unknown or mismatched provider identity stops recovery.

Submission moves classical circuit descriptions and measured observations.
Coherent quantum state never becomes an I/O buffer.

## Ideal state-vector target

`StateVectorTarget` is the semantic reference for static gates. It supports at
most 20 qubits and repeats preparation, unitary work, and measurement for every
shot.

One explicit seed supplies one pseudorandom stream in shot order. The target does
not reseed between shots. A seed makes the simulator sample repeatable. It carries
no promise about hardware.

The ideal engine supports H, X, Z, phase, controlled phase, CNOT, CZ, swap,
generated adjoints, coherently lifted XOR, and width-modular constant addition or
subtraction.

The simulator may disclose its numerical state vector. That disclosure belongs to
the ideal model and is unavailable from ordinary hardware measurement.

## Target-resident dynamic work

`DynamicStateVectorTarget` separately advertises mid-circuit measurement, reset,
and classical conditions. Its semantic regions may:

1. prepare a register.
2. apply fixed gates.
3. measure one qubit into a target-resident Boolean slot.
4. reset the measured qubit.
5. apply X or Z when an earlier slot matches.

A measured qubit cannot enter another gate or measurement before reset. The
complete region executes in one target call. Host code receives an observation
only through an explicit final full-register measurement.

The maintained teleportation fixture uses two measured slots with conditional X
and Z corrections for either basis input. The syndrome fixture performs at most
1,024 parity-measurement rounds in one call. Their results retain final basis,
slots, syndrome, reset, and correction evidence. These cases establish semantic
conformance, rather than a hardware noise model.

A static target rejects a dynamic region before submission. Wheeler never moves a
latency-sensitive branch to the host in silence.

## Batches and parameter bindings

A `QuantumBatch` is an ordered content-identified list of complete tasks. Member
jobs may finish in any order. The batch result preserves semantic task order. One
overall timeout applies. Job and task identity drift causes rejection.

A target without `BATCH_SUBMISSION` rejects the complete batch before the first
submission.

A symbolic gate stores a stable parameter name and finite scale in `.wbc`. The
task supplies one exact finite binding map. Missing and extra names fail before
submission and the map enters task identity.

Generated adjoints negate symbolic scale. The ideal target evaluates the binding
directly. OpenQASM lowering emits the corresponding numeric angle.

`QuantumResult.zExpectation(...)` estimates a tensor product of Pauli-Z
observables from little-endian samples and returns estimate, standard error, and
shot count.

## Maintained planning protocols

Several higher-level protocols use the same target identity rules:

- `RecoverableOptimizerCampaign` executes 1 through 64 iterations, each containing
  1 through 64 bound submissions. It persists acknowledged member identities and
  never applies one submission identity to the objective twice.
- `CalibrationAwareCompiler` requests calibration for 1 through 64 direct gates.
  Its plan binds target descriptor, request, result, epoch policy, duration, and
  additive parts-per-trillion error ceiling. The plan is evidence of selection,
  rather than pulse lowering or fidelity.
- `DelegatedComputationSession` maintains one masked-NOT transcript under the
  named honest-but-curious single-provider model. It makes no malicious-provider,
  collusion, side-channel, transport, or general privacy theorem.
- `DistributedEntanglementSession` requires `NETWORK_ENTANGLEMENT`, binds two
  endpoints and a deadline, and persists no provider or qubit handles. Restoration
  sends no second request. A local discard makes no statement about remote
  physical destruction.
- `LogicalResourcePlan` keeps Clifford gates, T gates, measurements, T-depth,
  magic states, factory batches, logical qubits, target cycles, code distance, and
  modeled error as separate dimensions. It provides planning evidence, rather
  than a proof of decoder throughput or physical performance.

These protocols never promote target metadata into a stronger physical statement.

## Provider-neutral quantum instructions

`.wbc` carries stable semantic gate descriptors and regular quantum instruction
records. Gate forms name controls, targets, and angle parameters in a fixed order.
Targets may decompose them into a native basis and advertise stricter limits.

No physical gate basis belongs to every provider. Wheeler standardizes semantic
operations instead of appliance opcodes. Preparation, measurement, reset, and
conditional gates have distinct instruction families. Provider payloads cannot
extend canonical semantics at runtime.

## OpenQASM 3

`OpenQasm3Emitter` lowers one supported static task into a complete program:

```qasm
OPENQASM 3.0;
include "stdgates.inc";
bit[2] c;
qubit[2] q;
h q[0];
cx q[0], q[1];
c = measure q;
```

OpenQASM is a derived target format. `wheeler qasm` emits it from an artifact that
contains one static submission.

`OpenQasmTarget` accepts an application-provided executor:

```java
OpenQasmTarget target = new OpenQasmTarget(
  "provider-name",
  127,
  10_000,
  (qasm, shots, seed) -> provider.submit(qasm, shots));
```

The executor may call a provider API, appliance SDK, local engine, or queue. It
must return one in-range full-register outcome for every shot. Credentials and
provider objects stay with the host and never enter `.wbc`, QASM, result records,
or logs.

## Live hardware authority

Live tests require an invocation-local `LiveHardwareTestPolicy`. The default is
disabled. An enabled policy names hard submission and aggregate-shot ceilings,
and the wrapper charges both before contacting a provider.

Ordinary acceptance work creates no enabled policy. A separately authorized smoke
run may supply credentials and budget through its host environment. Its result is
sampled hardware evidence, rather than a deterministic acceptance result or
proof.

## Physical limits

A generated adjoint is another physical computation. It cannot consume VM history.
After measurement or loss of a target session, Wheeler may replay an accepted
observation or prepare fresh state and retry. It cannot reconstruct an unknown
earlier hardware state.

Dynamic and fault-tolerant features remain explicit target requirements. Target
planning rejects missing capabilities before queue submission.

The [hybrid-run appendix](hybrid-runs.md) follows acknowledged jobs and accepted
observations. [Weather](../tutorials/12-weather.md) preserves one chamber account
in which those distinctions became operational.
