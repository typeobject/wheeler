package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import org.junit.jupiter.api.Test;

class SeedArtifactExampleTest {
  @Test
  void wheelerEmitsACompleteCanonicalExecutableArtifact() throws Exception {
    String root = Files.readString(Path.of("src/main/wheeler/SeedArtifact.w"));
    String encoding = Files.readString(Path.of("src/main/wheeler/compiler/Encoding.w"));
    var writerProgram = new WheelerCompiler().compileModuleFiles(
        Map.of("SeedArtifact.w", root, "Encoding.w", encoding),
        "examples.compiler.seed");
    VirtualMachine writer = new VirtualMachine(writerProgram, null, 360);
    var initial = writer.snapshot();

    writer.run();

    byte[] emitted = writer.hostOutput();
    byte[] stageZero = new WheelerCompiler().compileToBytecode(
        "classical class Seed { entry void main() { } }");
    assertEquals(360, emitted.length);
    assertEquals(360, writer.global("finalCursor"));
    assertArrayEquals(stageZero, emitted);

    var decoded = new BytecodeReader().read(emitted);
    assertArrayEquals(emitted, new BytecodeWriter().write(decoded));
    VirtualMachine seed = new VirtualMachine(decoded);
    seed.run();
    assertEquals(MachineStatus.HALTED, seed.status());

    while (writer.historySize() > 0) {
      writer.rewindOne();
    }
    assertEquals(initial, writer.snapshot());
  }
}
