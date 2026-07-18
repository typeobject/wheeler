package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.Map;
import org.junit.jupiter.api.Test;

class BytecodeHeaderExampleTest {
  @Test
  void wheelerEmitsCanonicalHeaderAndSectionDirectory() throws Exception {
    String root = Files.readString(Path.of("src/main/wheeler/BytecodeHeader.w"));
    String encoding = Files.readString(Path.of("src/main/wheeler/compiler/Encoding.w"));
    var program = new WheelerCompiler().compileModuleFiles(
        Map.of("BytecodeHeader.w", root, "Encoding.w", encoding),
        "examples.compiler.header");
    VirtualMachine machine = new VirtualMachine(program, null, 232);
    var initial = machine.snapshot();

    machine.run();

    assertEquals(232, machine.global("finalCursor"));
    byte[] stageZeroArtifact = new BytecodeWriter().write(program);
    assertEquals(9_096, stageZeroArtifact.length);
    assertArrayEquals(
        Arrays.copyOf(stageZeroArtifact, 232), machine.hostOutput());
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }
}
