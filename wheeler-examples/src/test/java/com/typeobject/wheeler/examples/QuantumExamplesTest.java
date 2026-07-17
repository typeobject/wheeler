package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.runtime.ExecutionResult;
import com.typeobject.wheeler.runtime.WheelerRuntime;
import com.typeobject.wheeler.runtime.quantum.StateVectorSimulator;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.stream.Stream;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

class QuantumExamplesTest {
  @ParameterizedTest
  @MethodSource("examples")
  void checkedInQuantumExamplesRoundTripAndRun(String file, String global, long expected)
      throws Exception {
    WheelerCompiler compiler = new WheelerCompiler();
    byte[] first = compiler.compileToBytecode(Files.readString(Path.of("src/main/wheeler", file)));
    Program decoded = new BytecodeReader().read(first);
    byte[] second = new BytecodeWriter().write(decoded);

    ExecutionResult result = new WheelerRuntime().execute(decoded, new StateVectorSimulator(7));

    assertArrayEquals(first, second);
    assertEquals(expected, result.globals().get(global));
  }

  static Stream<Arguments> examples() {
    return Stream.of(
        Arguments.of("QFT.w", "measured", 5L),
        Arguments.of("CoherentOracle.w", "measured", 1L));
  }
}
