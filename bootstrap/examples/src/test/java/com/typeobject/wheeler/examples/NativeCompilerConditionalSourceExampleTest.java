package com.typeobject.wheeler.examples;

import static com.typeobject.wheeler.examples.NativeCompilerSelfSourceExampleTest.assertImportedConstantCompilerLibrary;
import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential self-source tests for bounded conditional classification modules. */
class NativeCompilerConditionalSourceExampleTest {
  @Test
  void compilesLocalLiteralAssignmentsByteForByte() throws Exception {
    String source = """
        module examples.local_conditional_assignments;
        classical class LocalConditionalAssignments {
          public boolean equal(boolean input) {
            boolean valid = false;
            if (input == true) { valid = true; }
            return valid;
          }

          public boolean below(long input) {
            boolean valid = true;
            if (input < 10) { valid = false; }
            return valid;
          }

          public boolean above(long input) {
            boolean valid = false;
            if (10 < input) { valid = true; }
            return valid;
          }
        }
        """;
    Program compiler = CompilerSources.minimalCompilerProgram();
    VirtualMachine writer = NativeCompilerSelfSourceExampleTest.nativeWriter(compiler, source);

    CompilerMachineRunner.runWithoutRewindHistory(writer);

    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("LocalConditionalAssignments.w", source),
        "examples.local_conditional_assignments");
    assertArrayEquals(new BytecodeWriter().write(expected), writer.hostOutput());
  }

  @Test
  void rejectsInvalidLocalLiteralAssignmentsBeforePublication() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    List<String> invalidBodies = List.of(
        "long target = 0; if (input == true) { target = true; } return true;",
        "boolean target = false; if (input < true) { target = true; } return target;",
        "boolean target = false; if (input == true) { target = 1; } return target;");
    for (String body : invalidBodies) {
      String source = "module examples.invalid_conditional; classical class InvalidConditional { "
          + "public boolean invalid(boolean input) { " + body + " } }";
      NativeCompilerSelfSourceExampleTest.assertNoPublication(compiler, source);
    }
  }

  @Test
  void compilesBooleanLocalEqualityReturnsByteForByte() throws Exception {
    String source = """
        module examples.boolean_local_guard_return;
        classical class BooleanLocalGuardReturn {
          public boolean profileByte(
            long scalar,
            boolean allowPunctuation,
            boolean valid
          ) {
            if (scalar == 45) { return allowPunctuation; }
            if (scalar == 46) { return allowPunctuation; }
            if (scalar == 95) { return allowPunctuation; }
            if (scalar < 48) { return false; }
            if (scalar < 58) { return true; }
            if (scalar < 65) { return false; }
            if (scalar < 91) { return true; }
            if (scalar < 97) { return false; }
            if (scalar < 123) { return true; }
            return valid;
          }
        }
        """;
    Program compiler = CompilerSources.minimalCompilerProgram();
    VirtualMachine writer = NativeCompilerSelfSourceExampleTest.nativeWriter(compiler, source);

    CompilerMachineRunner.runWithoutRewindHistory(writer);

    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("BooleanLocalGuardReturn.w", source),
        "examples.boolean_local_guard_return");
    assertArrayEquals(new BytecodeWriter().write(expected), writer.hostOutput());
    NativeCompilerSelfSourceExampleTest.assertNoPublication(
        compiler,
        source.replace("return allowPunctuation;", "return scalar;"));
  }

  @Test
  void compilesEarlyLocalAdditionByteForByte() throws Exception {
    String source = """
        module examples.early_local_addition;
        classical class EarlyLocalAddition {
          public long boundedAdd(long base, long target) {
            if (target < 0) { return -1; }
            if (target < 256) { return target + base; }
            return -1;
          }
        }
        """;
    Program compiler = CompilerSources.minimalCompilerProgram();
    VirtualMachine writer = NativeCompilerSelfSourceExampleTest.nativeWriter(compiler, source);

    CompilerMachineRunner.runWithoutRewindHistory(writer);

    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("EarlyLocalAddition.w", source), "examples.early_local_addition");
    assertArrayEquals(new BytecodeWriter().write(expected), writer.hostOutput());
  }

  @Test
  void compilesCanonicalNamedLocalConditionalKindsByteForByte() throws Exception {
    Program decoded = assertImportedConstantCompilerLibrary(
        "compiler/syntax/conditionals/NamedLocalConditionalKinds.w",
        "wheeler.compiler.named_local_conditional_kinds",
        "compiler/ir/StatementKinds.w");
    assertEquals(
        "wheeler.compiler.named_local_conditional_kinds::namedLocalConditional",
        decoded.functions().getFirst().name());
    assertEquals(5, decoded.functions().size());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalNamedLocalConditionalValuesByteForByte() throws Exception {
    Program decoded = assertImportedConstantCompilerLibrary(
        "compiler/syntax/conditionals/NamedLocalConditionalValues.w",
        "wheeler.compiler.named_local_conditional_values",
        "compiler/ir/StatementKinds.w");
    assertEquals(
        "wheeler.compiler.named_local_conditional_values::namedLocalConditionalValue",
        decoded.functions().getFirst().name());
    assertEquals(2, decoded.functions().size());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalLiteralComparisonOperationsByteForByte() throws Exception {
    Program decoded = assertImportedConstantCompilerLibrary(
        "compiler/syntax/conditionals/LiteralComparisonOperations.w",
        "wheeler.compiler.literal_comparison_operations",
        "compiler/ir/ResolvedStatements.w",
        "compiler/ir/StatementKinds.w");
    assertEquals(
        "wheeler.compiler.literal_comparison_operations::literalComparisonConditionalLessThan",
        decoded.functions().getFirst().name());
    assertEquals(
        "wheeler.compiler.literal_comparison_operations::literalComparisonConditionalAssignment",
        decoded.functions().get(3).name());
    assertEquals(5, decoded.functions().size());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalNamedConditionalBasesByteForByte() throws Exception {
    Program decoded = assertImportedConstantCompilerLibrary(
        "compiler/syntax/conditionals/NamedConditionalBases.w",
        "wheeler.compiler.named_conditional_bases",
        "compiler/ir/ResolvedStatements.w",
        "compiler/ir/StatementKinds.w");
    assertEquals(
        "wheeler.compiler.named_conditional_bases::namedLiteralComparisonConditionalBase",
        decoded.functions().getFirst().name());
    assertEquals(
        "wheeler.compiler.named_conditional_bases::namedLocalConditionalBase",
        decoded.functions().get(1).name());
    assertEquals(3, decoded.functions().size());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalNamedLiteralComparisonKindsByteForByte() throws Exception {
    Program decoded = assertImportedConstantCompilerLibrary(
        "compiler/syntax/conditionals/NamedLiteralComparisonKinds.w",
        "wheeler.compiler.named_literal_comparison_kinds",
        "compiler/ir/StatementKinds.w");
    assertEquals(
        "wheeler.compiler.named_literal_comparison_kinds::namedLiteralComparisonConditional",
        decoded.functions().getFirst().name());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalResolvedLocalConditionalKindsByteForByte() throws Exception {
    Program decoded = assertImportedConstantCompilerLibrary(
        "compiler/syntax/conditionals/ResolvedLocalConditionalKinds.w",
        "wheeler.compiler.resolved_local_conditional_kinds");
    assertEquals(
        "wheeler.compiler.resolved_local_conditional_kinds::resolvedLocalConditional",
        decoded.functions().getFirst().name());
    assertEquals(5, decoded.functions().size());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalResolvedLocalConditionalOperandsByteForByte() throws Exception {
    Program decoded = assertImportedConstantCompilerLibrary(
        "compiler/syntax/conditionals/ResolvedLocalConditionalOperands.w",
        "wheeler.compiler.resolved_local_conditional_operands");
    assertEquals(
        "wheeler.compiler.resolved_local_conditional_operands::resolvedLocalConditionalSource",
        decoded.functions().getFirst().name());
    assertEquals(28, decoded.functions().getFirst().localCount());
    assertEquals(40, decoded.functions().getFirst().forward().size());
    assertEquals(2, decoded.functions().size());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalResolvedLocalConditionalSourcesByteForByte() throws Exception {
    Program decoded = assertImportedConstantCompilerLibrary(
        "compiler/syntax/conditionals/ResolvedLocalConditionalSources.w",
        "wheeler.compiler.resolved_local_conditional_sources");
    assertEquals(
        "wheeler.compiler.resolved_local_conditional_sources::resolvedLocalConditionalValue",
        decoded.functions().getFirst().name());
    assertEquals(
        "wheeler.compiler.resolved_local_conditional_sources::resolvedLocalConditionalXor",
        decoded.functions().get(2).name());
    assertEquals(4, decoded.functions().size());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalResolvedLiteralComparisonKindsByteForByte() throws Exception {
    Program decoded = assertImportedConstantCompilerLibrary(
        "compiler/syntax/conditionals/ResolvedLiteralComparisonKinds.w",
        "wheeler.compiler.resolved_literal_comparison_kinds");
    assertEquals(
        "wheeler.compiler.resolved_literal_comparison_kinds::resolvedLiteralComparisonConditional",
        decoded.functions().getFirst().name());
    assertEquals(
        "wheeler.compiler.resolved_literal_comparison_kinds::resolvedLiteralComparisonConditionalSource",
        decoded.functions().get(1).name());
    assertEquals(3, decoded.functions().size());
    assertEquals("$library", decoded.functions().getLast().name());
  }
}
