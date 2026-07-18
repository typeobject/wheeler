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
    String helperParser = Files.readString(
        Path.of("src/main/wheeler/compiler/HelperParser.w"));
    String ir = Files.readString(Path.of("src/main/wheeler/compiler/Ir.w"));
    String parser = Files.readString(Path.of("src/main/wheeler/compiler/Parser.w"));
    String statements = Files.readString(
        Path.of("src/main/wheeler/compiler/Statements.w"));
    String structure = Files.readString(
        Path.of("src/main/wheeler/compiler/Structure.w"));
    String tokens = Files.readString(Path.of("src/main/wheeler/compiler/Tokens.w"));
    String verifier = Files.readString(Path.of("src/main/wheeler/compiler/Verifier.w"));
    String scanner = Files.readString(Path.of("src/main/wheeler/lexer/Scanner.w"));
    var writerProgram = new WheelerCompiler().compileModuleFiles(
        Map.of(
            "MinimalCompiler.w", root,
            "Encoding.w", encoding,
            "HelperParser.w", helperParser,
            "Ir.w", ir,
            "Parser.w", parser,
            "Scanner.w", scanner,
            "Statements.w", statements,
            "Structure.w", structure,
            "Tokens.w", tokens,
            "Verifier.w", verifier),
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
    assertEquals(1, writer.global("verification"));
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
        "classical class Calls { state long value = 1; "
            + "void bump() { value += 2; } "
            + "entry void main() { bump(); } }",
        "value",
        3);
    assertDifferentialExecution(
        writerProgram,
        "classical class CheckedCalls { state long value = 1; "
            + "void bump() { value += 2; } "
            + "entry void main() { bump(); assert value == 3; } }",
        "value",
        3);
    assertDifferentialExecution(
        writerProgram,
        "classical class LocalCalls { state long value = 1; "
            + "void bump() { value += 2; } "
            + "entry void main() { bump(); long scratch = -4; } }",
        "value",
        3);
    assertDifferentialExecution(
        writerProgram,
        "classical class ReversibleCalls { state long value = 1; "
            + "rev void bump() { value += 2; } "
            + "entry void main() { bump(); reverse { bump(); } } }",
        "value",
        1);
    assertDifferentialExecution(
        writerProgram,
        "classical class CheckedReverse { state long value = 1; "
            + "rev void bump() { value += 2; } "
            + "entry void main() { bump(); reverse { bump(); } "
            + "assert value == 1; } }",
        "value",
        1);
    assertDifferentialExecution(
        writerProgram,
        "classical class SubtractiveReverse { state long value = 5; "
            + "rev void lower() { value -= 2; } "
            + "entry void main() { lower(); reverse { lower(); } "
            + "assert value == 5; } }",
        "value",
        5);
    assertDifferentialExecution(
        writerProgram,
        "classical class XorReverse { state long value = 5; "
            + "rev void flip() { value ^= 6; } "
            + "entry void main() { flip(); reverse { flip(); } "
            + "assert value == 5; } }",
        "value",
        5);
    assertDifferentialExecution(
        writerProgram,
        "classical class Certified { state long value = 1; "
            + "rev void bump() { value += 2; } "
            + "theorem bumpInverse proves inverse(bump); "
            + "entry void main() { bump(); reverse { bump(); } "
            + "assert value == 1; } }",
        "value",
        1);
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
    assertDifferentialExecution(
        writerProgram,
        "classical class Four { state long value = 1; "
            + "entry void main() { value += 2; value ^= 7; "
            + "value -= 1; assert value == 3; } }",
        "value",
        3);

    VirtualMachine duplicate = new VirtualMachine(
        writerProgram,
        ("classical class main { state long alpha = 0; "
            + "entry void main() { alpha += 0; } }")
            .getBytes(StandardCharsets.UTF_8),
        512);
    assertThrows(VmTrap.class, duplicate::run);
    assertArrayEquals(new byte[512], duplicate.hostOutput());

    VirtualMachine irreversibleHelper = new VirtualMachine(
        writerProgram,
        ("classical class BadReverse { state long value = 1; "
            + "rev void set() { value = 2; } "
            + "entry void main() { set(); reverse { set(); } } }")
            .getBytes(StandardCharsets.UTF_8),
        1024);
    assertThrows(VmTrap.class, irreversibleHelper::run);
    assertArrayEquals(new byte[1024], irreversibleHelper.hostOutput());

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

  @Test
  void wheelerVerifierRejectsMalformedArtifacts() throws Exception {
    String root = """
        module examples.compiler.verifiertest;
        import examples.compiler.verifier;
        classical class VerifierTest {
          state long result = 1;
          entry void main() {
            region arena = new region(320, 1);
            bytes artifact = allocateBytes(arena, 320);
            result = verifyArtifact(artifact, 320);
            drop(artifact);
            drop(arena);
            assert result == 0;
          }
        }
        """;
    String verifier = Files.readString(
        Path.of("src/main/wheeler/compiler/Verifier.w"));
    Program program = new WheelerCompiler().compileModuleFiles(
        Map.of("Verifier.w", verifier, "VerifierTest.w", root),
        "examples.compiler.verifiertest");
    VirtualMachine machine = new VirtualMachine(program);

    machine.run();

    assertEquals(0, machine.global("result"));
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
