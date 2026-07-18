package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import org.junit.jupiter.api.Test;

class BytecodeHeaderExampleTest {
  @Test
  void wheelerEmitsTheCanonicalFixedBytecodeHeaderPrefix() throws Exception {
    String root = Files.readString(Path.of("src/main/wheeler/BytecodeHeader.w"));
    String encoding = Files.readString(Path.of("src/main/wheeler/compiler/Encoding.w"));
    var program = new WheelerCompiler().compileModuleFiles(
        Map.of("BytecodeHeader.w", root, "Encoding.w", encoding),
        "examples.compiler.header");
    VirtualMachine machine = new VirtualMachine(program, null, 24);
    var initial = machine.snapshot();

    machine.run();

    assertEquals(24, machine.global("finalCursor"));
    assertArrayEquals(new byte[] {
        87, 72, 69, 69, 76, 66, 67, 0,
        1, 0, 0, 0, 0, 0, 0, 0,
        40, 0, 0, 0, 0, 0, 0, 0
    }, machine.hostOutput());
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }
}
