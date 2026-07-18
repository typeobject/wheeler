package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
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
    VirtualMachine writer = new VirtualMachine(
        writerProgram, "LongClass".getBytes(StandardCharsets.UTF_8), 512);
    var initial = writer.snapshot();

    writer.run();

    byte[] emitted = writer.hostOutput();
    byte[] stageZero = new WheelerCompiler().compileToBytecode(
        "classical class LongClass { entry void main() { } }");
    assertEquals(368, emitted.length);
    assertEquals(368, writer.global("finalCursor"));
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

    VirtualMachine invalid = new VirtualMachine(
        writerProgram, "Caf\u00e9".getBytes(StandardCharsets.UTF_8), 512);
    assertThrows(VmTrap.class, invalid::run);
    assertArrayEquals(new byte[512], invalid.hostOutput());
  }
}
