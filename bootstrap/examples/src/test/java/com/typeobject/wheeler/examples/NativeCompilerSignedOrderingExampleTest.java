package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
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

/** Signed ordering retains operand origin instead of assuming two prior local names. */
final class NativeCompilerSignedOrderingExampleTest {
  @Test
  void compilesTheOriginalMinimumAndMinusOneControlsWithoutRemovingTheirAssertions() throws Exception {
    String source = """
        //! Exercises the native signed-state literal minimum without any imports.

        module consumer.globals;

        classical class Minimum {
          state long observed = -9223372036854775808;

          entry void main() {
            assert(observed < 0);
            observed = 7;
          }
        }
        """;
    Program compiler = CompilerSources.minimalCompilerProgram();
    for (String input : List.of(source, source.replace("-9223372036854775808", "-1"))) {
      assertArtifact(compiler, input, true);
    }
  }

  @Test
  void comparesEveryOrderedOperandOriginIncludingTheFalseStatePairAndRewinds() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    for (String left : List.of("FLOOR", "left", "observed")) {
      for (String right : List.of("CEILING", "right", "observed")) {
        String source = "module consumer.globals; classical class Ordering { "
            + "state long observed = 0; const long FLOOR = -9223372036854775808; "
            + "const long CEILING = 9223372036854775807; entry void main() { "
            + "long left = FLOOR; long right = CEILING; assert(" + left + " < " + right + "); "
            + "observed = 7; } }";
        assertArtifact(compiler, source, !(left.equals("observed") && right.equals("observed")));
      }
    }
    assertArtifact(compiler, "module consumer.globals; classical class Literals { "
        + "state long observed = 0; entry void main() { "
        + "assert(-9223372036854775808 < 9223372036854775807); observed = 7; } }", true);
  }

  @Test
  void compilesEveryFalseOriginPairBeforeTheFollowingStateMutation() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    for (String left : List.of("FLOOR", "left", "observed")) {
      for (String right : List.of("CEILING", "right", "observed")) {
        String source = source("const long FLOOR = 1; const long CEILING = -1;", "",
            "long left = FLOOR; long right = CEILING; assert(" + left + " < " + right + "); observed = 7;");
        assertArtifact(compiler, source, false);
      }
    }
  }

  @Test
  void retainsForwardConstantsVocabularyNamesAndSignedParameters() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    assertArtifact(compiler, source("const long CEILING = FLOOR + 2; const long FLOOR = -1;", "",
        "assert(FLOOR < observed); assert(observed < CEILING); observed = 7;"), true);
    for (String name : List.of("public", "reverse", "vojE")) {
      assertArtifact(compiler, source("const long " + name + " = -1;", "",
          "assert(" + name + " < observed); observed = 7;"), true);
      assertArtifact(compiler, source("", "", "long " + name + " = -1; assert(" + name
          + " < observed); observed = 7;"), true);
    }
    assertArtifact(compiler, source("const long FLOOR = -9223372036854775808; "
        + "const long CEILING = 9223372036854775807;", """
        long checked(long value) {
          assert(FLOOR < value);
          assert(value < CEILING);
          assert(value < observed);
          return value;
        }
        """, "long value = -1; observed = checked(value); observed = 7;"), true);
    for (String assertion : List.of("-0x8000_0000_0000_0000 < -0x7fff_ffff_ffff_ffff",
        "-0b10 < -0b1", "-9_223_372_036_854_775_808 < 9_223_372_036_854_775_807")) {
      assertArtifact(compiler, source("", "", "assert(" + assertion + "); observed = 7;"), true);
    }
  }

  @Test
  void rejectsMalformedTypesMissingNamesAndOverflowWithoutCompilerPublication() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    for (String expression : List.of("true < 0", "0 < false", "missing < 0", "0 < missing",
        "right < 0", "0 < right", "9223372036854775808 < 0", "0 < 9223372036854775808",
        "-9223372036854775809 < 0", "0 < -9223372036854775809", "-name < 0",
        "0 < -name", "< 0", "0 <", "0 < 1 < 2", "0 <= 1")) {
      String source = source("", "", "boolean right = false; assert(" + expression + "); observed = 7;");
      assertThrows(CompilerException.class, () -> reference(source), source);
      assertRejected(compiler, source, 32_768, false);
    }
    for (String body : List.of("assert(0 < 1)", "assert(0 < 1];",
        "long value = -1; boolean value = false; assert(value < 0);")) {
      String source = source("", "", body);
      assertThrows(CompilerException.class, () -> reference(source), source);
      assertRejected(compiler, source, 32_768, false);
    }
    // These expressions remain legal source, but outside this direct-operand lowering stage.
    for (String expression : List.of("(0) < 1", "0 < (1)", "0 + 1 < 2", "0 < 1 + 2")) {
      String source = source("", "", "assert(" + expression + "); observed = 7;");
      reference(source);
      assertRejected(compiler, source, 32_768, false);
    }
  }

  @Test
  void bindsBothQualifiedOperandSidesWithImportedHelpersAndState() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    String bounds = """
        module example.bounds;
        classical class Bounds {
          public const long LOW = -9223372036854775808;
          public const long HIGH = 9223372036854775807;
          public long checked(long value) {
            assert(LOW < value);
            assert(value < HIGH);
            return value;
          }
        }
        """;
    String extra = "module example.extra; classical class Extra { public const long ZERO = 0; }";
    String root = """
        module consumer.globals;
        import example.bounds;
        import example.extra;
        classical class Ordering {
          state long observed = example.extra::ZERO;
          entry void main() {
            assert(example.bounds::LOW < observed);
            assert(observed < example.bounds::HIGH);
            long value = 1;
            observed = example.bounds::checked(value);
            observed = 7;
          }
        }
        """;
    Program expected = new WheelerCompiler().compileModuleFiles(
        Map.of("Bounds.w", bounds, "Extra.w", extra, "Root.w", root), "consumer.globals");
    for (var imports : List.of(List.of(bounds, extra), List.of(extra, bounds))) {
      byte[] actual = NativeModuleCompilerHarness.compile(compiler, imports, root);
      assertArrayEquals(new BytecodeWriter().write(expected), actual);
      var execution = new VirtualMachine(new BytecodeReader().read(actual));
      var initial = execution.snapshot();
      execution.run();
      assertEquals(MachineStatus.HALTED, execution.status());
      assertEquals(7, execution.global("observed"));
      while (execution.historySize() > 0) { execution.rewindOne(); }
      assertEquals(initial, execution.snapshot());
    }
  }

  @Test
  void admitsSignedOrderingInVoidAndBooleanHelpers() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    assertArtifact(compiler, source("", "void checked(long value) { assert(observed < value); }",
        "long value = 1; checked(value); observed = 7;"), true);
    assertArtifact(compiler, source("", "boolean checked(long value) { assert(observed < value); return true; }",
        "boolean ready = checked(1); assert(ready); observed = 7;"), true);
  }

  @Test
  void rejectsLoanParametersOnEitherSideBeforeArtifactPublication() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    for (String type : List.of("borrow utf8", "borrow byteview", "borrow mut words", "borrow mut bytes",
        "borrow mut region", "borrow mut longmap")) {
      String head = "long checked(" + type + " value) { ";
      assertArtifact(compiler, source("", head + "return 0; }", "observed = 7;"), true);
      for (String expression : List.of("value < 0", "0 < value")) {
        String input = source("", head + "assert(" + expression + "); return 0; }", "observed = 7;");
        assertThrows(CompilerException.class, () -> reference(input), input);
        assertRejected(compiler, input, 32_768, false);
      }
    }
  }

  @Test
  void keepsBooleanLiteralsAndConstructorSyntaxOutOfSignedNameBinding() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    for (String word : List.of("true", "false", "new")) {
      assertArtifact(compiler, source("const long " + word + " = -1;", "", "observed = 7;"), true);
      assertArtifact(compiler, source("", "", "long " + word + " = -1; observed = 7;"), true);
      String state = "module consumer.globals; classical class Literal { state long " + word
          + " = -1; entry void main() { } }";
      var writer = new VirtualMachine(compiler, state.getBytes(StandardCharsets.UTF_8), 32_768);
      CompilerMachineRunner.runWithoutRewindHistory(writer);
      assertArrayEquals(new BytecodeWriter().write(reference(state)), writer.hostOutput());
      var execution = new VirtualMachine(new BytecodeReader().read(writer.hostOutput()));
      var initial = execution.snapshot();
      execution.run();
      assertEquals(-1, execution.global(word));
      while (execution.historySize() > 0) { execution.rewindOne(); }
      assertEquals(initial, execution.snapshot());
      for (String expression : List.of(word + " < 0", "0 < " + word)) {
        for (String input : List.of(source("const long " + word + " = -1;", "", "assert(" + expression + ");"),
            source("", "", "long " + word + " = -1; assert(" + expression + ");"),
            "module consumer.globals; classical class Literal { state long " + word
                + " = -1; entry void main() { assert(" + expression + "); } }")) {
          assertThrows(CompilerException.class, () -> reference(input), input);
          assertRejected(compiler, input, 32_768, false);
        }
      }
    }
  }

  @Test
  void rewindsSuccessfulPublicationAndRightOperandRejection() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    String source = source("", "", "assert(-9223372036854775808 < observed); observed = 7;");
    byte[] expected = new BytecodeWriter().write(reference(source));
    var writer = new VirtualMachine(compiler, source.getBytes(StandardCharsets.UTF_8), expected.length);
    var initial = writer.snapshot();
    writer.run();
    assertArrayEquals(expected, writer.hostOutput());
    assertEquals(1, writer.global("verification"));
    while (writer.historySize() > 0) { writer.rewindOne(); }
    assertEquals(initial, writer.snapshot());
    assertRejected(compiler, source, expected.length - 1, true);
    assertRejected(compiler, source("", "", "boolean right = false; assert(0 < right); observed = 7;"),
        32_768, true);
  }

  static String source(String constants, String members, String body) {
    return "module consumer.globals; classical class Ordering { state long observed = 0; "
        + constants + " " + members + " entry void main() { " + body + " } }";
  }

  static void assertRejected(Program compiler, String source, int capacity, boolean history) {
    var writer = new VirtualMachine(compiler, source.getBytes(StandardCharsets.UTF_8), capacity);
    var initial = writer.snapshot();
    if (history) { assertThrows(VmTrap.class, writer::run, source); }
    else { assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(writer), source); }
    assertArrayEquals(new byte[capacity], writer.hostOutput(), source);
    assertEquals(0, writer.global("verification"));
    assertEquals(0, writer.global("finalCursor"));
    assertEquals(0, writer.global("codeStart"));
    if (history) {
      while (writer.historySize() > 0) { writer.rewindOne(); }
      assertEquals(initial, writer.snapshot());
    }
  }

  static Program reference(String source) {
    return new WheelerCompiler().compileModuleFiles(Map.of("Input.w", source), "consumer.globals");
  }

  static void assertArtifact(Program compiler, String source, boolean passes) {
    Program expected = reference(source);
    VirtualMachine writer = new VirtualMachine(compiler, source.getBytes(StandardCharsets.UTF_8), 32_768);
    assertDoesNotThrow(() -> CompilerMachineRunner.runWithoutRewindHistory(writer), source);
    assertEquals(MachineStatus.HALTED, writer.status());
    assertArrayEquals(new BytecodeWriter().write(expected), writer.hostOutput());
    var emitted = new BytecodeReader().read(writer.hostOutput());
    var machine = new VirtualMachine(emitted);
    var initial = machine.snapshot();
    if (passes) {
      machine.run();
      assertEquals(MachineStatus.HALTED, machine.status());
      assertEquals(7, machine.global("observed"));
    } else {
      var reference = new VirtualMachine(expected);
      VmTrap expectedTrap = assertThrows(VmTrap.class, reference::run);
      VmTrap actualTrap = assertThrows(VmTrap.class, machine::run);
      assertEquals(expectedTrap.getMessage(), actualTrap.getMessage());
      assertEquals(reference.status(), machine.status());
      assertEquals(0, machine.global("observed"));
    }
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }
}
