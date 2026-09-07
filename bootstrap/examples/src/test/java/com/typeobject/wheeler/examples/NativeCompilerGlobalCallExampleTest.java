package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.CompilerException;
import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.runtime.SemanticCoverage;
import com.typeobject.wheeler.runtime.WheelerRuntime;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.StringJoiner;
import org.junit.jupiter.api.Test;

/** Call assignments keep global destinations distinct from prior local columns. */
final class NativeCompilerGlobalCallExampleTest {
  private record Example(String parameters, String helper, String entry) {}

  @Test
  void emitsCompleteGlobalAndLocalCallArtifactsAndRewindsTheirExecution() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    for (Example example : List.of(
        new Example("", "return 7;", "observed = helper();"),
        new Example("long value", "return value;", "long seed = 7; observed = helper(seed);"),
        new Example("long left, long right", "return left + right;",
            "long first = 3; long second = 4; observed = helper(first, second);"),
        new Example("", "return 7;",
            "long copy = helper(); copy = helper(); observed = helper(); assert(copy == 7);"))) {
      assertArtifactAndExecution(compiler, source(example.parameters(), example.helper(), example.entry()));
    }
    assertArtifactAndExecution(compiler, source("", "return 7;", "observed = helper();")
        .replace("helper", "observed"));
  }

  @Test
  void selectsTheNamedHelperInEitherDeclarationOrder() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    String source = source("", "return 7;", "observed = helper();");
    String selected = "long helper() { return 7; }";
    String decoy = "long decoy() { return 3; }";
    for (String declarations : List.of(selected + decoy, decoy + selected)) {
      for (String global : List.of("aardvark", "observed", "zzzz")) {
        assertArtifactAndExecution(compiler,
            source.replace(selected, declarations).replace("observed", global));
      }
    }
  }

  @Test
  void boundsTheGlobalHelperLibraryWithoutLosingItsStateName() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    String source = source("", "return 7;", "observed = helper22();");
    StringJoiner helpers = new StringJoiner("\n");
    for (int helper = 0; helper < 23; helper++) {
      helpers.add("long helper" + helper + "() { return 7; }");
    }
    String accepted = source.replace("long helper() { return 7; }", helpers.toString());
    assertArtifactAndExecution(compiler, accepted);
    String excess = accepted.replace("entry void main()",
        "long helper23() { return 7; } entry void main()");
    String extraGlobal = accepted.replace("state long observed",
        "state long spare = 1; state long observed");
    for (String rejected : List.of(excess, extraGlobal)) {
      new WheelerCompiler().compileModuleFiles(Map.of("Test.w", rejected), "example.globals");
      NativeCompilerSelfSourceExampleTest.assertNoPublication(compiler, rejected);
    }
  }

  @Test
  void emitsEveryWideGlobalSourceCallAndRejectsTheEighthArgument() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    for (int arity = 3; arity <= 8; arity++) {
      var parameters = new StringJoiner(", ");
      var arguments = new StringJoiner(", ");
      var declarations = new StringBuilder();
      for (int argument = 0; argument < arity; argument++) {
        String name = "arg" + argument;
        parameters.add("long " + name);
        arguments.add(name);
        declarations.append("long ").append(name).append(" = ").append(8 - arity + argument).append("; ");
      }
      String source = source(parameters.toString(), "return arg" + (arity - 1) + ";",
          declarations + "observed = helper(" + arguments + ");");
      if (arity == 8) {
        new WheelerCompiler().compileModuleFiles(Map.of("Test.w", source), "example.globals");
        NativeCompilerSelfSourceExampleTest.assertNoPublication(compiler, source);
      } else {
        assertArtifactAndExecution(compiler, source);
      }
    }
  }

  @Test
  void rejectsUnknownWrongTypeAndAmbiguousTargetsWithoutArtifactPublication() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    String valid = source("", "return 7;", "observed = helper();");
    for (String source : List.of(
        valid.replace("state long observed = 9;", ""),
        valid.replace("observed = helper();", "observez = helper();"),
        valid.replace("observed = helper();", "observed = absent(); observed = helper();"),
        valid.replace("observed = helper();", "long ignored = absent(); observed = helper();"),
        valid.replace("long helper() { return 7; }", "boolean helper() { return false; }"),
        valid.replace("observed = helper();", "boolean observed = false; observed = helper();"),
        valid.replace("observed = helper();", "long observed = 0; observed = helper();"),
        valid.replace("observed = helper();",
            "long observed = 0; boolean observed = false; observed = helper();"),
        source("long observed", "return observed;", "long seed = 7; observed = helper(seed);"),
        source("", "long observed = 7; return observed;", "observed = helper();"),
        source("long value", "return value;", "boolean seed = true; observed = helper(seed);"),
        source("long value", "return value;", "observed = helper();"))) {
      assertThrows(CompilerException.class, () -> new WheelerCompiler().compileModuleFiles(
          Map.of("Test.w", source), "example.globals"), source);
      NativeCompilerSelfSourceExampleTest.assertNoPublication(compiler, source);
    }
  }

  @Test
  void preservesTheNativeHelperConstantShadowExclusion() throws Exception {
    String source = source("", "long BASE = 7; return BASE;", "observed = helper();")
        .replace("state long observed = 9;", "state long observed = 9; const long BASE = 5;");
    new WheelerCompiler().compileModuleFiles(Map.of("Test.w", source), "example.globals");
    NativeCompilerSelfSourceExampleTest.assertNoPublication(CompilerSources.minimalCompilerProgram(), source);
  }

  @Test
  void comparesCompleteNativeCoverageForGlobalCallsLoadsAndStores() throws Exception {
    String literal = source("", "return 7;", "observed = helper();");
    String constant = literal.replace("state long observed = 9;",
        "state long observed = 9; const long BASE = 7;")
        .replace("assert(observed == 7)", "assert(observed == BASE)");
    Program compiler = CompilerSources.minimalCompilerProgram();
    Program runner = NativeCoverageRunExampleTest.runner();
    for (String source : List.of(literal, constant)) {
      Program expected = new WheelerCompiler().compileModuleFiles(Map.of("Test.w", source), "example.globals");
      var coverage = new SemanticCoverage();
      new WheelerRuntime().executeObserved(expected, coverage);
      var writer = NativeCompilerSelfSourceExampleTest.nativeWriter(compiler, source);
      CompilerMachineRunner.runWithoutRewindHistory(writer);
      var machine = VirtualMachine.withBinaryInput(runner, writer.hostOutput(), 32768);
      CompilerMachineRunner.runWithoutRewindHistory(machine);
      assertArrayEquals(coverage.canonicalReport().getBytes(StandardCharsets.UTF_8), machine.hostOutput());
      assertEquals(7, machine.global("finalGlobal"));
    }
  }

  @Test
  void rewindsCompilerPublicationAndARejectedMissingDestination() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    String valid = source("", "return 7;", "observed = helper();");
    for (boolean accepted : List.of(true, false)) {
      String source = accepted ? valid : valid.replace("state long observed = 9;", "");
      var writer = NativeCompilerSelfSourceExampleTest.nativeWriter(compiler, source);
      var initial = writer.snapshot();
      if (accepted) {
        writer.run();
      } else {
        assertThrows(VmTrap.class, writer::run);
        assertArrayEquals(new byte[writer.hostOutput().length], writer.hostOutput());
      }
      while (writer.historySize() > 0) { writer.rewindOne(); }
      assertEquals(initial, writer.snapshot());
    }
  }

  private static void assertArtifactAndExecution(Program compiler, String source) throws Exception {
    Program expected = new WheelerCompiler().compileModuleFiles(Map.of("Test.w", source), "example.globals");
    var writer = NativeCompilerSelfSourceExampleTest.nativeWriter(compiler, source);
    CompilerMachineRunner.runWithoutRewindHistory(writer);
    assertArrayEquals(new BytecodeWriter().write(expected), writer.hostOutput(), source);
    Program artifact = new BytecodeReader().read(writer.hostOutput());
    var machine = new VirtualMachine(artifact);
    var initial = machine.snapshot();
    machine.run();
    assertEquals(7, machine.global(expected.globals().getFirst().name()));
    while (machine.historySize() > 0) { machine.rewindOne(); }
    assertEquals(initial, machine.snapshot());
  }

  private static String source(String parameters, String helper, String entry) {
    return """
        // café 𝄞
        module example.globals;
        classical class Globals {
          state long observed = 9;
          long helper(%s) { %s }
          entry void main() { %s assert(observed == 7); }
        }
        """.formatted(parameters, helper, entry);
  }
}
