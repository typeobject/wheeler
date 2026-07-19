package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.proof.ProofRule;
import com.typeobject.wheeler.runtime.ExecutionResult;
import com.typeobject.wheeler.runtime.WheelerRuntime;
import com.typeobject.wheeler.runtime.hybrid.HybridRun;
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
    byte[] first = compiler.compileToBytecode(Files.readString(Path.of("src/main/wheeler", file)));
    Program decoded = new BytecodeReader().read(first);
    byte[] second = new BytecodeWriter().write(decoded);

    ExecutionResult result = new WheelerRuntime().execute(decoded, new StateVectorTarget());

    assertArrayEquals(first, second);
    if (file.equals("QFT.w")) {
      assertEquals(ProofRule.GENERATED_ADJOINT, decoded.proofCertificates().getFirst().rule());
    } else if (file.equals("QuantumCompiler.w")) {
      assertEquals(ProofRule.CIRCUIT_EQUIVALENCE, decoded.proofCertificates().getFirst().rule());
    }
    expected.forEach((global, value) -> assertEquals(value, result.globals().get(global), global));
  }

  @Test
  void optimizerObservationsReplayWithoutAnotherTargetSubmission() throws Exception {
    Program program = new WheelerCompiler().compile(
        Path.of("src/main/wheeler/QuantumOptimizer.w"));
    StateVectorTarget target = new StateVectorTarget();
    HybridRun run = HybridRun.start(program, target);
    ExecutionResult recorded = run.runToCompletion(Duration.ofSeconds(1));

    ExecutionResult replayed = HybridRun.replay(program, run.snapshot());

    assertEquals(recorded.globals(), replayed.globals());
    assertEquals(recorded.measurements(), replayed.measurements());
  }

  static Stream<Arguments> examples() {
    return Stream.of(
        Arguments.of("QFT.w", Map.of("measured", 5L)),
        Arguments.of("QFTProof.w", Map.of("measured", 2L)),
        Arguments.of("CoherentOracle.w", Map.of("measured", 1L)),
        Arguments.of("QuantumOptimizer.w", Map.of("sample", 1L, "bestCost", 1L, "accepted", 1L)),
        Arguments.of("QuantumNeuralNetwork.w", Map.of("activation", 1L, "measured", 0L)),
        Arguments.of("QuantumCompiler.w", Map.of("sourceResult", 1L, "normalizedResult", 1L)),
        Arguments.of("SurfaceCode.w", Map.of("measured", 0L)));
  }
}
