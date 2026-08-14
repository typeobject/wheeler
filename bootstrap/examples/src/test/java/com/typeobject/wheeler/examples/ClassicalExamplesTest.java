package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.proof.ProofRule;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import java.util.stream.Stream;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

/** Conformance tests for the executable classical Wheeler example portfolio. */
class ClassicalExamplesTest {
  @ParameterizedTest
  @MethodSource("examples")
  void checkedInClassicalExamplesCompileEncodeAndRun(String file, Map<String, Long> expected)
      throws Exception {
    Path source = Path.of("src/main/wheeler", file);
    String name = source.getFileName().toString();
    WheelerCompiler compiler = new WheelerCompiler();
    Program program;
    if (name.equals("FixedArrays.w")) {
      program = compileCoreExample(
          compiler,
          source,
          "CoreFixedLongs.w",
          "collections/FixedLongs.w",
          "examples.collections.fixed_arrays_main");
    } else if (name.equals("FrozenUtf8.w")) {
      program = compileCoreExample(
          compiler,
          source,
          "CoreUtf8.w",
          "text/Utf8.w",
          "examples.text.frozen_utf8_main");
    } else if (name.equals("LongMap.w")) {
      program = compileCoreExample(
          compiler,
          source,
          "CoreLongMap.w",
          "collections/LongMap.w",
          "examples.collections.long_map_main");
    } else {
      byte[] artifact = compiler.compileToBytecode(Files.readString(source));
      program = new BytecodeReader().read(artifact);
    }
    VirtualMachine machine = new VirtualMachine(program);
    var initial = machine.snapshot();

    machine.run();

    assertEquals(MachineStatus.HALTED, machine.status());
    if (name.equals("CertifiedInverseBounds.w") || name.equals("Counter.w")
        || name.equals("FixedPointSymplectic.w")
        || name.equals("IntegerWaveletTransform.w")
        || name.equals("ReversiblePacketCodec.w") || name.equals("ReversibleResult.w")) {
      assertEquals(ProofRule.GENERATED_INVERSE, program.proofCertificates().getFirst().rule());
    } else if (name.equals("FunctionValues.w")) {
      assertEquals(ProofRule.STATIC_STEP_BOUND, program.proofCertificates().getFirst().rule());
    }
    if (name.equals("CertifiedInverseBounds.w")) {
      assertEquals(2, program.proofCertificates().size());
      assertEquals(ProofRule.STATIC_STEP_BOUND, program.proofCertificates().get(1).rule());
    }
    expected.forEach((global, value) -> assertEquals(value, machine.global(global), global));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }

  private static Program compileCoreExample(
      WheelerCompiler compiler,
      Path example,
      String coreName,
      String corePath,
      String rootModule) throws Exception {
    return compiler.compileModuleFiles(
        Map.of(
            example.getFileName().toString(), Files.readString(example),
            coreName, Files.readString(CoreSources.path(corePath))),
        rootModule);
  }

  static Stream<Arguments> examples() {
    return Stream.of(
        Arguments.of(
            "proof/CertifiedInverseBounds.w",
            Map.of("value", 0L, "observed", 1L, "successor", 5L)),
        Arguments.of("classical/control/Counter.w", Map.of("count", 0L)),
        Arguments.of("classical/data/BinaryTree.w", Map.of("root", 0L, "left", 0L, "right", 0L)),
        Arguments.of(
            "classical/control/EventReducer.w",
            Map.of("lastEvent", 2L, "reduced", 12L, "duplicates", 1L)),
        Arguments.of("classical/control/BootstrapControl.w", Map.of("sum", 10L, "branch", 1L)),
        Arguments.of("classical/data/FiniteEnums.w", Map.of("selected", 7L)),
        Arguments.of(
            "classical/data/FixedArrays.w",
            Map.of(
                "selected", 6L,
                "sum", 20L,
                "middleSum", 10L,
                "equal", 1L,
                "recordSelected", 7L,
                "variantSelected", 13L)),
        Arguments.of(
            "classical/data/FixedPointSymplectic.w",
            Map.of(
                "position", 7_168L,
                "momentum", 5_120L,
                "observedPosition", 10_240L,
                "observedMomentum", 3_072L)),
        Arguments.of("text/FrozenUtf8.w", Map.of(
            "byteLength", 6L, "scalarCount", 3L, "middleScalar", 8364L, "valid", 1L)),
        Arguments.of("classical/control/FunctionValues.w", Map.of("result", 10L)),
        Arguments.of(
            "classical/control/IncrementalDependencyGraph.w",
            Map.of(
                "sourceVersion", 2L,
                "parseVersion", 2L,
                "codeVersion", 2L,
                "linkVersion", 2L,
                "rebuilds", 6L)),
        Arguments.of(
            "classical/data/IntegerWaveletTransform.w",
            Map.of("high", 10L, "low", 6L, "observedHigh", 4L, "observedLow", 10L)),
        Arguments.of("classical/control/LoopControl.w", Map.of("sum", 12L, "selected", 7L)),
        Arguments.of("classical/data/LongMap.w", Map.of(
            "selected", 17L, "zeroKey", 5L, "present", 1L, "missing", 1L)),
        Arguments.of("classical/ownership/OwnedReturns.w", Map.of(
            "wordValue", 17L, "byteValue", 65L, "scalarCount", 2L, "mapValue", 23L)),
        Arguments.of("classical/data/Records.w", Map.of("width", 5L, "equal", 1L)),
        Arguments.of("classical/control/RecursiveValue.w", Map.of("result", 6L)),
        Arguments.of(
            "classical/data/ReversiblePacketCodec.w",
            Map.of(
                "packet", 0L,
                "observed", 2_753_795L,
                "decodedVersion", 3L,
                "decodedKind", 5L,
                "decodedPayload", 42L,
                "malformedLength", 1L,
                "malformedChecksum", 2L)),
        Arguments.of("classical/control/ReversibleResult.w", Map.of("observed", 42L)),
        Arguments.of("classical/ownership/RegionStorage.w", Map.of("first", 7L, "byteValue", 65L, "utf8Scalars", 3L, "validUtf8", 1L, "byteLength", 6L,
            "decodedScalars", 3L, "scalarSum", 8591L, "scratchValue", 19L)),
        Arguments.of(
            "classical/data/Variants.w",
            Map.of("selected", 9L, "equal", 1L, "presence", 11L)),
        Arguments.of(
            "classical/oracles/WidthExplicitOracle.w",
            Map.of("rotated", 268_435_456L, "masked", 0L, "selected", 13L)));
  }
}
