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

class MinimalCompilerExampleTest {
  @Test
  void wheelerCompilesMinimalSourceToACanonicalExecutableArtifact() throws Exception {
    String root = Files.readString(Path.of("src/main/wheeler/MinimalCompiler.w"));
    String encoding = Files.readString(Path.of("src/main/wheeler/compiler/Encoding.w"));
    String parser = Files.readString(Path.of("src/main/wheeler/lexer/Parser.w"));
    String scanner = Files.readString(Path.of("src/main/wheeler/lexer/Scanner.w"));
    var writerProgram = new WheelerCompiler().compileModuleFiles(
        Map.of(
            "MinimalCompiler.w", root,
            "Encoding.w", encoding,
            "Parser.w", parser,
            "Scanner.w", scanner),
        "examples.compiler.seed");
    String source =
        "classical class LongClass { state long value = 7; entry void main() { } }";
    VirtualMachine writer = new VirtualMachine(
        writerProgram, source.getBytes(StandardCharsets.UTF_8), 512);
    var initial = writer.snapshot();

    writer.run();

    byte[] emitted = writer.hostOutput();
    byte[] stageZero = new WheelerCompiler().compileToBytecode(source);
    assertEquals(392, emitted.length);
    assertEquals(392, writer.global("finalCursor"));
    assertArrayEquals(stageZero, emitted);

    var decoded = new BytecodeReader().read(emitted);
    assertArrayEquals(emitted, new BytecodeWriter().write(decoded));
    VirtualMachine seed = new VirtualMachine(decoded);
    seed.run();
    assertEquals(MachineStatus.HALTED, seed.status());
    assertEquals(7, seed.global("value"));

    while (writer.historySize() > 0) {
      writer.rewindOne();
    }
    assertEquals(initial, writer.snapshot());

    VirtualMachine invalid = new VirtualMachine(
        writerProgram,
        "classical class Caf\u00e9 { state long value = 7; entry void main() { } }"
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, invalid::run);
    assertArrayEquals(new byte[512], invalid.hostOutput());
  }
}
