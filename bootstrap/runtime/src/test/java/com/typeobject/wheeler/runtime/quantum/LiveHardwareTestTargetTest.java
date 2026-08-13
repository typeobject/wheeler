package com.typeobject.wheeler.runtime.quantum;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.quantum.Gate;
import com.typeobject.wheeler.core.quantum.GateOperation;
import com.typeobject.wheeler.core.quantum.QuantumCircuit;
import com.typeobject.wheeler.core.quantum.QuantumRegister;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.Test;

/** Admission evidence for explicit, bounded, nondeterministic hardware tests. */
final class LiveHardwareTestTargetTest {
  @Test
  void disabledPolicyRejectsBeforeProviderSubmission() {
    AtomicInteger submissions = new AtomicInteger();
    QuantumTarget provider = provider(submissions);
    LiveHardwareTestTarget target = new LiveHardwareTestTarget(
        provider, LiveHardwareTestPolicy.disabled());

    assertThrows(QuantumExecutionException.class, () -> target.submit(submission(1)));
    assertEquals(0, submissions.get());
  }

  @Test
  void enabledPolicyChargesSubmissionsAndShotsBeforeProviderWork() {
    AtomicInteger submissions = new AtomicInteger();
    LiveHardwareTestTarget target = new LiveHardwareTestTarget(
        provider(submissions), LiveHardwareTestPolicy.enabled(2, 3));

    target.submit(submission(1)).await(Duration.ofSeconds(1));
    target.submit(submission(2)).await(Duration.ofSeconds(1));
    assertThrows(QuantumExecutionException.class, () -> target.submit(submission(1)));

    assertEquals(2, submissions.get());
    assertEquals(2, target.budget().admittedSubmissions());
    assertEquals(3, target.budget().admittedShots());
  }

  private static QuantumTarget provider(AtomicInteger submissions) {
    return new OpenQasmTarget("hardware-fixture", 4, 16, (qasm, shots, seed) -> {
      submissions.incrementAndGet();
      return java.util.Collections.nCopies(shots, 0L);
    });
  }

  private static QuantumSubmission submission(int shots) {
    QuantumRegister register = new QuantumRegister(0, "q", 1);
    QuantumCircuit circuit = new QuantumCircuit(
        0, "identity", 0, List.of(GateOperation.of(Gate.X, 0)));
    Program program = StateVectorTargetTest.program(register, circuit, List.of());
    return new QuantumSubmission(
        program, 0, 0, List.of(new CircuitApplication(0, false)), Map.of(), shots, 7);
  }
}
