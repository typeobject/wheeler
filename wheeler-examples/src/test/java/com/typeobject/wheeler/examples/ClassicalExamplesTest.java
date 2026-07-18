package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import java.util.stream.Stream;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

class ClassicalExamplesTest {
  @ParameterizedTest
  @MethodSource("examples")
  void checkedInClassicalExamplesCompileEncodeAndRun(String file, Map<String, Long> expected)
      throws Exception {
    Path source = Path.of("src/main/wheeler", file);
    byte[] artifact = new WheelerCompiler().compileToBytecode(Files.readString(source));
    VirtualMachine machine = new VirtualMachine(new BytecodeReader().read(artifact));

    machine.run();

    assertEquals(MachineStatus.HALTED, machine.status());
    expected.forEach((global, value) -> assertEquals(value, machine.global(global), global));
  }

  static Stream<Arguments> examples() {
    return Stream.of(
        Arguments.of("Counter.w", Map.of("count", 0L)),
        Arguments.of("BinaryTree.w", Map.of("root", 0L, "left", 0L, "right", 0L)),
        Arguments.of("BootstrapControl.w", Map.of("sum", 10L, "branch", 1L)),
        Arguments.of("FixedArrays.w", Map.of("selected", 6L, "sum", 20L, "equal", 1L)),
        Arguments.of("FunctionValues.w", Map.of("result", 10L)),
        Arguments.of("LoopControl.w", Map.of("sum", 12L, "selected", 7L)),
        Arguments.of("Records.w", Map.of("width", 5L, "equal", 1L)),
        Arguments.of("RecursiveValue.w", Map.of("result", 6L)),
        Arguments.of("Variants.w", Map.of("selected", 9L, "equal", 1L)));
  }
}
