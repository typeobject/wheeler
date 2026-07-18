package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
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
    String ir = Files.readString(Path.of("src/main/wheeler/compiler/Ir.w"));
    String parser = Files.readString(Path.of("src/main/wheeler/compiler/Parser.w"));
    String tokens = Files.readString(Path.of("src/main/wheeler/compiler/Tokens.w"));
    String scanner = Files.readString(Path.of("src/main/wheeler/lexer/Scanner.w"));
    var writerProgram = new WheelerCompiler().compileModuleFiles(
        Map.of(
            "MinimalCompiler.w", root,
            "Encoding.w", encoding,
            "Ir.w", ir,
            "Parser.w", parser,
            "Scanner.w", scanner,
            "Tokens.w", tokens),
        "examples.compiler.seed");
    String source =
        "classical class LongClass { state long value = 7; "
            + "entry void main() { value += 5; } }";
    VirtualMachine writer = new VirtualMachine(
        writerProgram, source.getBytes(StandardCharsets.UTF_8), 512);
    var initial = writer.snapshot();

    writer.run();

    byte[] emitted = writer.hostOutput();
    byte[] stageZero = new WheelerCompiler().compileToBytecode(source);
    assertEquals(392, writer.global("codeStart"));
    assertEquals(504, writer.global("finalCursor"));
    assertEquals(504, emitted.length);
    assertArrayEquals(stageZero, emitted);

    var decoded = new BytecodeReader().read(emitted);
    assertArrayEquals(emitted, new BytecodeWriter().write(decoded));
    VirtualMachine seed = new VirtualMachine(decoded);
    seed.run();
    assertEquals(MachineStatus.HALTED, seed.status());
    assertEquals(12, seed.global("value"));

    while (writer.historySize() > 0) {
      writer.rewindOne();
    }
    assertEquals(initial, writer.snapshot());

    assertDifferentialHalt(
        writerProgram,
        "classical class Bare { entry void main() { } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class Local { entry void main() { long x = 2; } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class Local { entry void main() { long x = -2; } }");
    assertDifferentialExecution(
        writerProgram,
        "classical class Empty { state long idle = 7; "
            + "entry void main() { } }",
        "idle",
        7);
    assertDifferentialExecution(
        writerProgram,
        "classical class Set { state long result = 4; "
            + "entry void main() { result = 99; } }",
        "result",
        99);
    assertDifferentialExecution(
        writerProgram,
        "classical class zebra { state long alpha = 0; "
            + "entry void main() { alpha += 0; } }",
        "alpha",
        0);
    assertDifferentialExecution(
        writerProgram,
        "classical class zebra { state long alpha = 10; "
            + "entry void main() { alpha -= 3; } }",
        "alpha",
        7);
    assertDifferentialExecution(
        writerProgram,
        "classical class Omega { state long mask = 6; "
            + "entry void main() { mask ^= 9; } }",
        "mask",
        15);
    assertDifferentialExecution(
        writerProgram,
        "classical class Negative { state long value = -10; "
            + "entry void main() { value += -3; } }",
        "value",
        -13);
    assertDifferentialExecution(
        writerProgram,
        "classical class Mixed { state long total = 10; "
            + "entry void main() { total = 4; total ^= 7; } }",
        "total",
        3);
    assertDifferentialExecution(
        writerProgram,
        "classical class WithLocal { state long total = 1; "
            + "entry void main() { long scratch = -2; total += 4; } }",
        "total",
        5);
    assertDifferentialExecution(
        writerProgram,
        "classical class Asserted { state long value = 1; "
            + "entry void main() { value += 2; assert value == 3; } }",
        "value",
        3);
    assertDifferentialExecution(
        writerProgram,
        "classical class Series { state long value = 1; "
            + "entry void main() { value += 2; value ^= 7; } }",
        "value",
        4);

    VirtualMachine duplicate = new VirtualMachine(
        writerProgram,
        ("classical class main { state long alpha = 0; "
            + "entry void main() { alpha += 0; } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, duplicate::run);
    assertArrayEquals(new byte[512], duplicate.hostOutput());

    VirtualMachine signedOverflow = new VirtualMachine(
        writerProgram,
        ("classical class Overflow { "
            + "state long value = -9223372036854775808; "
            + "entry void main() { } }")
            .getBytes(StandardCharsets.UTF_8),
        1024);
    assertThrows(VmTrap.class, signedOverflow::run);
    assertArrayEquals(new byte[1024], signedOverflow.hostOutput());

    VirtualMachine invalid = new VirtualMachine(
        writerProgram,
        ("classical class Caf\u00e9 { state long value = 7; "
            + "entry void main() { value += 5; } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, invalid::run);
    assertArrayEquals(new byte[512], invalid.hostOutput());
  }

  private void assertDifferentialHalt(
      Program writerProgram,
      String source) {
    VirtualMachine writer = new VirtualMachine(
        writerProgram, source.getBytes(StandardCharsets.UTF_8), 1024);
    writer.run();
    assertArrayEquals(
        new WheelerCompiler().compileToBytecode(source),
        writer.hostOutput());
    VirtualMachine artifact = new VirtualMachine(
        new BytecodeReader().read(writer.hostOutput()));
    artifact.run();
    assertEquals(MachineStatus.HALTED, artifact.status());
  }

  private void assertDifferentialExecution(
      Program writerProgram,
      String source,
      String global,
      long expected) {
    VirtualMachine writer = new VirtualMachine(
        writerProgram, source.getBytes(StandardCharsets.UTF_8), 1024);
    writer.run();
    assertArrayEquals(
        new WheelerCompiler().compileToBytecode(source),
        writer.hostOutput());
    VirtualMachine artifact = new VirtualMachine(
        new BytecodeReader().read(writer.hostOutput()));
    artifact.run();
    assertEquals(expected, artifact.global(global));
  }
}
