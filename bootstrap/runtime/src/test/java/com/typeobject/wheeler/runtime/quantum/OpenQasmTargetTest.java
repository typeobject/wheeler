package com.typeobject.wheeler.runtime.quantum;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.quantum.Gate;
import com.typeobject.wheeler.core.quantum.GateOperation;
import com.typeobject.wheeler.core.quantum.ParameterizedGateOperation;
import com.typeobject.wheeler.core.quantum.QuantumCircuit;
import com.typeobject.wheeler.core.quantum.QuantumRegister;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.Test;

/** Conformance tests for deterministic OpenQASM target lowering and execution boundaries. */
class OpenQasmTargetTest {
  @Test
  void portableExecutorReceivesQasmAndReturnsValidatedOutcomes() {
    AtomicReference<String> submitted = new AtomicReference<>();
    OpenQasmTarget target = new OpenQasmTarget(
        "test-provider",
        8,
        100,
        (qasm, shots, seed) -> {
          submitted.set(qasm);
          return java.util.Collections.nCopies(shots, 1L);
        });
    QuantumSubmission submission = submission(3);

    QuantumJob job = target.submit(submission);
    QuantumResult result = job.await(Duration.ofSeconds(2));

    assertTrue(submitted.get().startsWith("OPENQASM 3.0;"));
    assertEquals(List.of(1L, 1L, 1L), result.outcomes());
    assertEquals("test-provider", result.target());
    assertEquals(JobState.SUCCEEDED, job.state());
  }

  @Test
  void idealAndOpenQasmTargetsAgreeOnBasisAndSeededSamples() {
    QuantumRegister register = new QuantumRegister(0, "q", 1);
    QuantumCircuit circuit = new QuantumCircuit(
        0, "coin", 0, List.of(GateOperation.of(Gate.H, 0)));
    Program program = StateVectorTargetTest.program(register, circuit, List.of());
    QuantumSubmission submission = new QuantumSubmission(
        program,
        0,
        0,
        List.of(new CircuitApplication(0, false)),
        Map.of(),
        32,
        17);
    List<Long> oracle = new StateVectorTarget()
        .submit(submission)
        .await(Duration.ofSeconds(1))
        .outcomes();
    OpenQasmTarget target = new OpenQasmTarget(
        "conforming-executor", 8, 100, (qasm, shots, seed) -> {
          assertTrue(qasm.contains("h q[0];"));
          assertEquals(32, shots);
          assertEquals(17, seed);
          return oracle;
        });

    QuantumResult result = target.submit(submission).await(Duration.ofSeconds(1));

    assertEquals(oracle, result.outcomes());
    assertEquals(
        oracle.stream().filter(value -> value == 0).count(),
        result.counts().getOrDefault(0L, 0L));
    assertEquals(
        oracle.stream().filter(value -> value == 1).count(),
        result.counts().getOrDefault(1L, 0L));
  }

  @Test
  void targetExecutableIdentityBindsDescriptorPolicySchemaAndRegion() {
    QuantumSubmission base = submission(3);
    TargetDescriptor descriptor = new TargetDescriptor(
        "adapter", "target", java.util.Set.of(TargetCapability.STATIC_CIRCUIT), 8, 100);
    String identity = TargetExecutableIdentity.of(descriptor, "policy-1", base);
    TargetDescriptor changedDescriptor = new TargetDescriptor(
        "adapter-2", "target", java.util.Set.of(TargetCapability.STATIC_CIRCUIT), 8, 100);
    QuantumRegister register = new QuantumRegister(0, "q", 1);
    QuantumCircuit phase = new QuantumCircuit(
        0,
        "phase",
        0,
        List.of(new ParameterizedGateOperation(Gate.PHASE, List.of(0), "theta", 1)));
    QuantumSubmission changedSchema = new QuantumSubmission(
        StateVectorTargetTest.program(register, phase, List.of()),
        0,
        0,
        List.of(new CircuitApplication(0, false)),
        Map.of("theta", 0.25),
        3,
        4);
    QuantumCircuit changedRegion = new QuantumCircuit(
        0, "flip-z", 0, List.of(GateOperation.of(Gate.Z, 0)));
    QuantumSubmission changedSemanticRegion = new QuantumSubmission(
        StateVectorTargetTest.program(register, changedRegion, List.of()),
        0,
        0,
        List.of(new CircuitApplication(0, false)),
        Map.of(),
        3,
        4);

    assertEquals(identity, TargetExecutableIdentity.of(descriptor, "policy-1", base));
    assertTrue(!identity.equals(TargetExecutableIdentity.of(
        changedDescriptor, "policy-1", base)));
    assertTrue(!identity.equals(TargetExecutableIdentity.of(descriptor, "policy-2", base)));
    assertTrue(!identity.equals(TargetExecutableIdentity.of(descriptor, "policy-1", changedSchema)));
    assertTrue(!identity.equals(TargetExecutableIdentity.of(
        descriptor, "policy-1", changedSemanticRegion)));
  }

  @Test
  void symbolicBindingLowersToBoundOpenQasmAngle() {
    QuantumRegister register = new QuantumRegister(0, "q", 1);
    QuantumCircuit circuit = new QuantumCircuit(
        0,
        "phase",
        0,
        List.of(new ParameterizedGateOperation(Gate.PHASE, List.of(0), "theta", -2)));
    Program program = StateVectorTargetTest.program(register, circuit, List.of());
    QuantumSubmission submission = new QuantumSubmission(
        program,
        0,
        0,
        List.of(new CircuitApplication(0, false)),
        Map.of("theta", 0.25),
        1,
        0);
    AtomicReference<String> submitted = new AtomicReference<>();
    OpenQasmTarget target = new OpenQasmTarget(
        "bound-provider",
        8,
        100,
        (qasm, shots, seed) -> {
          submitted.set(qasm);
          return List.of(0L);
        });

    target.submit(submission).await(Duration.ofSeconds(2));

    assertTrue(submitted.get().contains("p(-0.5) q[0];"));
  }

  @Test
  void vqeReferencePointMatchesEquivalentOpenQasmExecution() {
    QuantumRegister register = new QuantumRegister(0, "hydrogen", 1);
    QuantumCircuit ansatz = new QuantumCircuit(
        0,
        "hydrogenAnsatz",
        0,
        List.of(
            GateOperation.of(Gate.H, 0),
            new ParameterizedGateOperation(Gate.PHASE, List.of(0), "theta", 1),
            GateOperation.of(Gate.H, 0)));
    Program program = StateVectorTargetTest.program(register, ansatz, List.of());
    QuantumSubmission submission = new QuantumSubmission(
        program,
        0,
        0,
        List.of(new CircuitApplication(0, false)),
        Map.of("theta", Math.PI),
        32,
        137);
    List<Long> oracle = new StateVectorTarget()
        .submit(submission)
        .await(Duration.ofSeconds(1))
        .outcomes();
    OpenQasmTarget target = new OpenQasmTarget(
        "vqe-qasm",
        8,
        100,
        (qasm, shots, seed) -> {
          assertTrue(qasm.contains("h q[0];"));
          assertTrue(qasm.contains("p(3.141592653589793) q[0];"));
          assertEquals(32, shots);
          assertEquals(137, seed);
          return oracle;
        });

    QuantumResult result = target.submit(submission).await(Duration.ofSeconds(1));

    assertEquals(oracle, result.outcomes());
    assertEquals(-1.0, result.zExpectation(0).value());
  }

  @Test
  void malformedProviderResultFailsClosed() {
    OpenQasmTarget target = new OpenQasmTarget(
        "broken-provider", 8, 100, (qasm, shots, seed) -> List.of(4L));

    QuantumJob job = target.submit(submission(2));

    assertThrows(QuantumExecutionException.class, () -> job.await(Duration.ofSeconds(2)));
    assertEquals(JobState.FAILED, job.state());
  }

  private static QuantumSubmission submission(int shots) {
    QuantumRegister register = new QuantumRegister(0, "q", 1);
    QuantumCircuit circuit = new QuantumCircuit(
        0, "flip", 0, List.of(GateOperation.of(Gate.X, 0)));
    Program program = StateVectorTargetTest.program(register, circuit, List.of());
    return new QuantumSubmission(
        program, 0, 0, List.of(new CircuitApplication(0, false)), Map.of(), shots, 4);
  }
}
