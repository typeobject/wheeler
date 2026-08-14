package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.proof.ProofRule;
import com.typeobject.wheeler.runtime.ExecutionResult;
import com.typeobject.wheeler.runtime.WheelerRuntime;
import com.typeobject.wheeler.runtime.hybrid.HybridRun;
import com.typeobject.wheeler.runtime.hybrid.HybridRunException;
import com.typeobject.wheeler.runtime.hybrid.HybridRunStore;
import com.typeobject.wheeler.runtime.hybrid.RunStatus;
import com.typeobject.wheeler.runtime.hybrid.TransactionPhase;
import com.typeobject.wheeler.runtime.quantum.DynamicCircuitResult;
import com.typeobject.wheeler.runtime.quantum.DynamicStateVectorSimulator;
import com.typeobject.wheeler.runtime.quantum.DynamicStateVectorTarget;
import com.typeobject.wheeler.runtime.quantum.StateVectorTarget;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.Map;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

/** Conformance tests for the executable quantum and hybrid Wheeler examples. */
class QuantumExamplesTest {
  @ParameterizedTest
  @MethodSource("examples")
  void checkedInQuantumExamplesRoundTripAndRun(String file, Map<String, Long> expected)
      throws Exception {
    WheelerCompiler compiler = new WheelerCompiler();
    byte[] first = compiler.compileToBytecode(
        Files.readString(Path.of("src/main/wheeler/quantum", file)));
    Program decoded = new BytecodeReader().read(first);
    byte[] second = new BytecodeWriter().write(decoded);

    ExecutionResult result = new WheelerRuntime().execute(decoded, new StateVectorTarget());

    assertArrayEquals(first, second);
    if (file.equals("QFT.w") || file.equals("GroverSearch.w")
        || file.equals("QuantumWalk.w") || file.equals("algorithms/StaticPhaseEstimation.w")
        || file.equals("algorithms/AmplitudeEstimation.w")) {
      assertEquals(ProofRule.GENERATED_ADJOINT, decoded.proofCertificates().getFirst().rule());
    }
    if (file.equals("algorithms/AmplitudeEstimation.w")) {
      assertEquals(2, decoded.proofCertificates().size());
    } else if (file.equals("QuantumCompiler.w")) {
      assertEquals(ProofRule.CIRCUIT_EQUIVALENCE, decoded.proofCertificates().getFirst().rule());
    }
    expected.forEach((global, value) -> assertEquals(value, result.globals().get(global), global));
  }

  @Test
  void checkedInDynamicTeleportationRoundTripsAndRunsWithoutHostSplit() throws Exception {
    byte[] artifact = new WheelerCompiler().compileToBytecode(
        Path.of("src/main/wheeler/quantum/DynamicTeleportation.w"));
    Program program = new BytecodeReader().read(artifact);
    assertArrayEquals(artifact, new BytecodeWriter().write(program));

    var circuit = program.quantumCircuits().getFirst();
    DynamicCircuitResult result = new DynamicStateVectorSimulator()
        .execute(program, circuit, 0);

    assertEquals(1, (result.basisState() >> 2) & 1);
    assertEquals(2, result.resultSlots().size());

    ExecutionResult executed = new WheelerRuntime().execute(
        program, new DynamicStateVectorTarget());
    assertEquals(1, (executed.globals().get("measured") >> 2) & 1);
    assertEquals(1, executed.quantumJobs().size());
  }

  @Test
  void adaptivePhaseEstimateCorrectsAndResetsInsideTheTarget() throws Exception {
    byte[] artifact = new WheelerCompiler().compileToBytecode(
        Path.of("src/main/wheeler/quantum/algorithms/AdaptivePhaseEstimation.w"));
    Program program = new BytecodeReader().read(artifact);
    assertArrayEquals(artifact, new BytecodeWriter().write(program));

    DynamicCircuitResult result = new DynamicStateVectorSimulator()
        .execute(program, program.quantumCircuits().getFirst(), 0);
    assertEquals(2, result.resultSlots().size());
    assertTrue(result.resultSlots().get(0));
    assertFalse(result.resultSlots().get(1));
    assertEquals(0, result.basisState());

    ExecutionResult executed = new WheelerRuntime().execute(
        program, new DynamicStateVectorTarget());
    assertEquals(0, executed.globals().get("measured"));
    assertEquals(1, executed.quantumJobs().size());
  }

  @Test
  void optimizerLifecycleCoversRecoveryReplayRetryCancellationAndCommit() throws Exception {
    Program program = new WheelerCompiler().compile(
        Path.of("src/main/wheeler/quantum/QuantumOptimizer.w"));
    StateVectorTarget target = new StateVectorTarget();
    HybridRun original = HybridRun.start(program, target);
    original.beginTransaction();
    assertEquals(RunStatus.WAITING, original.advance());
    byte[] encoded = new HybridRunStore().encode(original.snapshot());
    HybridRun restored = HybridRun.restore(
        program, target, new HybridRunStore().decode(encoded));

    ExecutionResult recorded = restored.runToCompletion(Duration.ofSeconds(1));
    assertEquals(TransactionPhase.COMMITTED, restored.transactionPhase());
    assertThrows(HybridRunException.class, restored::abortTransaction);
    ExecutionResult replayed = HybridRun.replay(program, restored.snapshot());
    assertEquals(recorded.globals(), replayed.globals());
    assertEquals(recorded.measurements(), replayed.measurements());

    HybridRun retried = HybridRun.start(program, new StateVectorTarget());
    assertEquals(RunStatus.WAITING, retried.advance());
    String firstBranch = retried.activeBranch();
    retried.retry();
    assertNotEquals(firstBranch, retried.activeBranch());
    retried.runToCompletion(Duration.ofSeconds(1));
    assertEquals(RunStatus.COMPLETED, retried.status());

    HybridRun cancelled = HybridRun.start(program, new StateVectorTarget());
    assertEquals(RunStatus.WAITING, cancelled.advance());
    assertFalse(cancelled.cancel());
    assertEquals(RunStatus.CANCELLED, cancelled.status());
    assertThrows(
        HybridRunException.class,
        () -> cancelled.resume(Duration.ofSeconds(1)));
  }

  static Stream<Arguments> examples() {
    return Stream.of(
        Arguments.of("QFT.w", Map.of("measured", 5L)),
        Arguments.of("QFTProof.w", Map.of("measured", 2L)),
        Arguments.of("CoherentOracle.w", Map.of("value", 0L, "measured", 0L)),
        Arguments.of("GroverSearch.w", Map.of("measured", 3L)),
        Arguments.of("QuantumOptimizer.w", Map.of("sample", 1L, "bestCost", 1L, "accepted", 1L)),
        Arguments.of("QuantumNeuralNetwork.w", Map.of("activation", 1L, "measured", 0L)),
        Arguments.of("QuantumCompiler.w", Map.of("sourceResult", 1L, "normalizedResult", 1L)),
        Arguments.of("QuantumWalk.w", Map.of("measured", 0L)),
        Arguments.of("SurfaceCode.w", Map.of("measured", 0L)),
        Arguments.of("algorithms/StaticPhaseEstimation.w", Map.of("measured", 7L)),
        Arguments.of(
            "algorithms/AmplitudeEstimation.w",
            Map.of("measured", 3L, "circuitApplications", 4L, "plannedShots", 4_096L)));
  }
}
