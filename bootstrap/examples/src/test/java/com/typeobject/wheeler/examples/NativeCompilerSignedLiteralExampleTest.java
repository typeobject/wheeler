package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.CompilerException;
import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Complete native artifacts preserve signed literal endpoints in every admitted scalar owner. */
final class NativeCompilerSignedLiteralExampleTest {
  private record Literal(String text, long value) {}

  @Test
  void preservesSignedStateLocalAndReturnLiteralsWithCompleteArtifactsAndRewind() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    for (Literal literal : literals()) {
      String text = literal.text();
      assertArtifact(compiler, "state long observed = " + text + ";", "",
          "assert(observed == " + text + ");", literal.value());
      assertArtifact(compiler, "state long observed = 0;", "",
          "long value = " + text + "; observed = value; assert(value == " + text + ");",
          literal.value());
      assertArtifact(compiler, "state long observed = 0;",
          "long value() { return " + text + "; }", "observed = value();", literal.value());
      assertArtifact(compiler, "state long observed = 0;",
          "long identity(long value) { return value; }",
          "long result = identity(" + text + "); observed = result;", literal.value());
    }
  }

  @Test
  void foldsBothEndpointsAndKeepsConstantArithmeticChecked() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    for (Literal literal : literals()) {
      assertArtifact(compiler, "const long BOUND = " + literal.text() + "; "
          + "const boolean READY = BOUND == " + literal.text() + "; "
          + "state long observed = BOUND;", "",
          "boolean ready = READY; assert(ready);", literal.value());
    }
    for (String expression : List.of(
        "-9223372036854775808 + 1", "9223372036854775807 - 9223372036854775807",
        "-9223372036854775808 - -9223372036854775808")) {
      long expected = expression.endsWith("+ 1") ? Long.MIN_VALUE + 1 : 0;
      assertArtifact(compiler, "const long VALUE = " + expression + "; "
          + "state long observed = VALUE;", "", "", expected);
    }
    for (String expression : List.of("-9223372036854775808 - 1", "9223372036854775807 + 1",
        "-9223372036854775808 / -1", "-9223372036854775808 * -1")) {
      String source = source("const long VALUE = " + expression + "; "
          + "state long observed = VALUE;", "", "");
      assertThrows(CompilerException.class, () -> new WheelerCompiler().compileToBytecode(source), source);
      NativeCompilerSelfSourceExampleTest.assertNoPublication(compiler, source);
    }
  }

  @Test
  void rejectsFirstExcessLiteralsBeforeArtifactPublicationAndRewindsTheCompiler() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    for (String text : List.of("9223372036854775808", "-9223372036854775809",
        "9_223_372_036_854_775_808", "-9_223_372_036_854_775_809",
        "0x8000000000000000", "-0x8000000000000001",
        "0b1" + "0".repeat(63), "-0b1" + "0".repeat(62) + "1")) {
      for (String source : List.of(source("state long observed = " + text + ";", "", ""),
          source("state long observed = 0;", "", "long value = " + text + "; observed = value;"),
          source("const long VALUE = " + text + "; state long observed = VALUE;", "", ""))) {
        assertThrows(CompilerException.class, () -> new WheelerCompiler().compileToBytecode(source), source);
        NativeCompilerSelfSourceExampleTest.assertNoPublication(compiler, source);
      }
    }
    var rejected = NativeCompilerSelfSourceExampleTest.nativeWriter(compiler,
        source("state long observed = -9223372036854775809;", "", ""));
    var initial = rejected.snapshot();
    assertThrows(VmTrap.class, rejected::run);
    assertArrayEquals(new byte[rejected.hostOutput().length], rejected.hostOutput());
    rewind(rejected);
    assertEquals(initial, rejected.snapshot());
  }

  @Test
  void keepsResolvedLocalNamesOutOfTheLiteralDecoder() throws Exception {
    assertArtifact(CompilerSources.minimalCompilerProgram(), "state long observed = 0;", "",
        "long first = 7; long second = first; boolean flag = false; boolean copy = flag; "
            + "boolean inverse = !copy; observed = second; assert(inverse);", 7);
  }

  @Test
  void bindsImportedSignedMinimaBeforeQualifiedStateInitializers() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    String imported = "module example.numbers; classical class Numbers { "
        + "public const long BOUND = -9223372036854775808; }";
    for (String reference : List.of("BOUND", "example.numbers::BOUND")) {
      String root = "module example.root; import example.numbers; classical class Root { "
          + "state long observed = " + reference + "; "
          + "entry void main() { assert(observed == -9223372036854775808); } }";
      Program expected = new WheelerCompiler().compileModuleFiles(
          Map.of("Numbers.w", imported, "Root.w", root), "example.root");
      byte[] actual = NativeModuleCompilerHarness.compile(compiler, imported, root);
      assertArrayEquals(new BytecodeWriter().write(expected), actual);
      assertExecution(new BytecodeReader().read(actual), "observed", Long.MIN_VALUE);
    }
  }

  @Test
  void acceptsTheFormerMinimumRejectionWithCompleteArtifactAndRewind() throws Exception {
    String source = "classical class Overflow { state long value = -9223372036854775808; "
        + "entry void main() { } }";
    byte[] expected = new WheelerCompiler().compileToBytecode(source);
    var writer = new VirtualMachine(CompilerSources.minimalCompilerProgram(),
        source.getBytes(StandardCharsets.UTF_8), 1024);
    CompilerMachineRunner.runWithoutRewindHistory(writer);
    assertEquals(MachineStatus.HALTED, writer.status());
    assertArrayEquals(expected, writer.hostOutput());
    assertExecution(new BytecodeReader().read(writer.hostOutput()), "value", Long.MIN_VALUE);
  }

  @Test
  void rewindsSuccessfulCompilerPublicationOfTheSignedMinimum() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    String source = source("state long observed = -9223372036854775808;", "", "");
    byte[] expected = new WheelerCompiler().compileToBytecode(source);
    var writer = NativeCompilerSelfSourceExampleTest.nativeWriter(compiler, source);
    var initial = writer.snapshot();
    writer.run();
    assertEquals(MachineStatus.HALTED, writer.status());
    assertArrayEquals(expected, writer.hostOutput());
    rewind(writer);
    assertEquals(initial, writer.snapshot());
  }

  private static List<Literal> literals() {
    return List.of(new Literal("9223372036854775807", Long.MAX_VALUE),
        new Literal("-9223372036854775808", Long.MIN_VALUE),
        new Literal("-9_223_372_036_854_775_808", Long.MIN_VALUE),
        new Literal("-0x8000_0000_0000_0000", Long.MIN_VALUE),
        new Literal("-0b1" + "0".repeat(63), Long.MIN_VALUE));
  }

  private static void assertArtifact(Program compiler, String prefix, String helper,
      String body, long result) {
    String source = source(prefix, helper, body);
    byte[] expected = new WheelerCompiler().compileToBytecode(source);
    var writer = NativeCompilerSelfSourceExampleTest.nativeWriter(compiler, source);
    CompilerMachineRunner.runWithoutRewindHistory(writer);
    assertEquals(MachineStatus.HALTED, writer.status());
    assertArrayEquals(expected, writer.hostOutput(), source);
    assertExecution(new BytecodeReader().read(writer.hostOutput()), "observed", result);
  }

  private static void assertExecution(Program program, String global, long result) {
    assertEquals(1, program.globals().size());
    var machine = new VirtualMachine(program);
    var initial = machine.snapshot();
    machine.run();
    assertEquals(MachineStatus.HALTED, machine.status());
    assertEquals(result, machine.global(global));
    rewind(machine);
    assertEquals(initial, machine.snapshot());
  }

  private static String source(String prefix, String helper, String body) {
    return "// café 𝄞\nclassical class Integers { " + prefix + " " + helper
        + " entry void main() { " + body + " } }";
  }

  private static void rewind(VirtualMachine machine) {
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
  }
}
