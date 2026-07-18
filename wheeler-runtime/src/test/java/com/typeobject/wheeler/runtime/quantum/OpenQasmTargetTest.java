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
    QuantumTask task = task(3);

    QuantumJob job = target.submit(task);
    QuantumResult result = job.await(Duration.ofSeconds(2));

    assertTrue(submitted.get().startsWith("OPENQASM 3.0;"));
    assertEquals(List.of(1L, 1L, 1L), result.outcomes());
    assertEquals("test-provider", result.target());
    assertEquals(JobState.SUCCEEDED, job.state());
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
    QuantumTask task = new QuantumTask(
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

    target.submit(task).await(Duration.ofSeconds(2));

    assertTrue(submitted.get().contains("p(-0.5) q[0];"));
  }

  @Test
  void malformedProviderResultFailsClosed() {
    OpenQasmTarget target = new OpenQasmTarget(
        "broken-provider", 8, 100, (qasm, shots, seed) -> List.of(4L));

    QuantumJob job = target.submit(task(2));

    assertThrows(QuantumExecutionException.class, () -> job.await(Duration.ofSeconds(2)));
    assertEquals(JobState.FAILED, job.state());
  }

  private static QuantumTask task(int shots) {
    QuantumRegister register = new QuantumRegister(0, "q", 1);
    QuantumCircuit circuit = new QuantumCircuit(
        0, "flip", 0, List.of(GateOperation.of(Gate.X, 0)));
    Program program = StateVectorTargetTest.program(register, circuit, List.of());
    return new QuantumTask(
        program, 0, 0, List.of(new CircuitApplication(0, false)), Map.of(), shots, 4);
  }
}
