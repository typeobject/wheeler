package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

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

/** Differential evidence for compiler modules accepted by the Wheeler-native compiler. */
final class NativeCompilerSelfSourceExampleTest {
  private static final int OUTPUT_CAPACITY = 32_768;

  @Test
  void compilesTheCanonicalProofRuleOwnerByteForByte() throws Exception {
    assertConstantOnlyCompilerLibrary(
        "compiler/ir/ProofRules.w",
        "wheeler.compiler.proof_rules");
  }

  @Test
  void compilesCanonicalStatementKindsByteForByte() throws Exception {
    assertConstantOnlyCompilerLibrary(
        "compiler/ir/StatementKinds.w",
        "wheeler.compiler.statement_kinds");
  }

  @Test
  void compilesCanonicalLoopKindsByteForByte() throws Exception {
    assertConstantOnlyCompilerLibrary(
        "compiler/syntax/LoopKinds.w",
        "wheeler.compiler.loop_kinds");
  }

  @Test
  void compilesCanonicalResolvedStatementsByteForByte() throws Exception {
    assertConstantOnlyCompilerLibrary(
        "compiler/ir/ResolvedStatements.w",
        "wheeler.compiler.resolved_statements");
  }

  @Test
  void compilesTheCanonicalTypeCodeOwnerByteForByte() throws Exception {
    assertConstantOnlyCompilerLibrary(
        "compiler/ir/TypeCodes.w",
        "wheeler.compiler.type_codes");
  }

  @Test
  void compilesTheCanonicalCoreOpcodeOwnerByteForByte() throws Exception {
    assertConstantOnlyCompilerLibrary(
        "compiler/ir/Opcodes.w",
        "wheeler.compiler.opcodes");
  }

  @Test
  void compilesTheCanonicalStorageOpcodeOwnerByteForByte() throws Exception {
    assertConstantOnlyCompilerLibrary(
        "compiler/ir/StorageOpcodes.w",
        "wheeler.compiler.storage_opcodes");
  }

  @Test
  void hashesTheCompleteBoundedIdentifier() throws Exception {
    String acceptedName = "A".repeat(256);
    String source = "module examples.long_name; classical class LongName { "
        + "public const long " + acceptedName + " = 40; "
        + "public const long VALUE = " + acceptedName + " + 2; }";
    Program compiler = CompilerSources.minimalCompilerProgram();
    VirtualMachine writer = nativeWriter(compiler, source);
    CompilerMachineRunner.runWithoutRewindHistory(writer);

    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("LongName.w", source),
        "examples.long_name");
    assertArrayEquals(new BytecodeWriter().write(expected), writer.hostOutput());

    String rejected = source.replace(acceptedName, acceptedName + "A");
    VirtualMachine rejectedWriter = nativeWriter(compiler, rejected);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(rejectedWriter));
    assertArrayEquals(new byte[OUTPUT_CAPACITY], rejectedWriter.hostOutput());
  }

  @Test
  void compilesEarlyBooleanReturnsByteForByte() throws Exception {
    String source = """
        module examples.early_return;
        classical class EarlyReturn {
          public boolean known(long opcode) {
            if (opcode == 1) {
              return true;
            }

            if (opcode == 2) {
              return false;
            }

            return opcode == 3;
          }
        }
        """;
    Program compiler = CompilerSources.minimalCompilerProgram();
    VirtualMachine writer = nativeWriter(compiler, source);
    CompilerMachineRunner.runWithoutRewindHistory(writer);

    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("EarlyReturn.w", source),
        "examples.early_return");
    assertArrayEquals(new BytecodeWriter().write(expected), writer.hostOutput());
  }

  @Test
  void compilesEarlyOrderingReturnsByteForByte() throws Exception {
    String source = """
        module examples.early_ordering;
        classical class EarlyOrdering {
          public const long LIMIT = 3;

          public boolean below(long opcode) {
            if (opcode < LIMIT) {
              return true;
            }

            return opcode < 9;
          }

          public long classify(long opcode) {
            if (opcode < -1) {
              return opcode - LIMIT;
            }

            return 9;
          }
        }
        """;
    Program compiler = CompilerSources.minimalCompilerProgram();
    VirtualMachine writer = nativeWriter(compiler, source);
    CompilerMachineRunner.runWithoutRewindHistory(writer);

    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("EarlyOrdering.w", source),
        "examples.early_ordering");
    assertArrayEquals(new BytecodeWriter().write(expected), writer.hostOutput());
    assertNoPublication(compiler, source.replace("return true;", "return 1;"));
    assertNoPublication(
        compiler,
        source.replace("return opcode - LIMIT;", "return false;"));
    assertNoPublication(
        compiler,
        source.replace("return opcode - LIMIT;", "return LIMIT - opcode;"));
  }

  @Test
  void compilesAnEarlySameModuleCallByteForByte() throws Exception {
    String source = """
        module examples.early_call;
        classical class EarlyCall {
          public boolean base(long opcode) {
            return opcode == 1;
          }

          public boolean combined(long opcode) {
            if (base(opcode)) {
              return true;
            }

            return opcode == 2;
          }
        }
        """;
    Program compiler = CompilerSources.minimalCompilerProgram();
    VirtualMachine writer = nativeWriter(compiler, source);
    CompilerMachineRunner.runWithoutRewindHistory(writer);

    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("EarlyCall.w", source),
        "examples.early_call");
    assertArrayEquals(new BytecodeWriter().write(expected), writer.hostOutput());
  }

  @Test
  void compilesEarlySignedReturnsByteForByte() throws Exception {
    String source = """
        module examples.early_signed;
        classical class EarlySigned {
          public const long THREE = 3;

          public long direct(long opcode) {
            if (opcode == 1) {
              return THREE;
            }

            return -1;
          }

          private boolean known(long opcode) {
            return opcode == 2;
          }

          public long combined(long opcode) {
            if (known(opcode)) {
              return -3;
            }

            return -1;
          }
        }
        """;
    Program compiler = CompilerSources.minimalCompilerProgram();
    VirtualMachine writer = nativeWriter(compiler, source);
    CompilerMachineRunner.runWithoutRewindHistory(writer);

    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("EarlySigned.w", source),
        "examples.early_signed");
    byte[] artifact = writer.hostOutput();
    assertArrayEquals(new BytecodeWriter().write(expected), artifact);
    Program decoded = new BytecodeReader().read(artifact);
    assertEquals("examples.early_signed::direct", decoded.functions().getFirst().name());
    assertEquals("examples.early_signed::known", decoded.functions().get(1).name());
    assertEquals("examples.early_signed::combined", decoded.functions().get(2).name());

    String wrongBoolean = source.replace("private boolean known(long opcode) {\n    return opcode == 2;\n  }",
        "private boolean known(long opcode) {\n"
            + "    if (opcode == 2) { return 1; }\n"
            + "    return false;\n  }");
    assertNoPublication(compiler, wrongBoolean);
    String wrongSigned = source.replace("return THREE;", "return true;");
    assertNoPublication(compiler, wrongSigned);
    assertNoPublication(compiler, source.replace("opcode == 1", "opcode > 1"));
  }

  @Test
  void compilesOneEntrylessHelperByteForByte() throws Exception {
    String source = """
        module examples.native_helper;
        classical class NativeHelper {
          public long identity(long value) {
            return value;
          }
        }
        """;
    Program compiler = CompilerSources.minimalCompilerProgram();
    VirtualMachine writer = nativeWriter(compiler, source);
    CompilerMachineRunner.runWithoutRewindHistory(writer);

    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("NativeHelper.w", source),
        "examples.native_helper");
    assertArrayEquals(new BytecodeWriter().write(expected), writer.hostOutput());
  }

  @Test
  void compilesTheCanonicalOpcodeClassifiersByteForByte() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    String dependency = CompilerSources.read("compiler/ir/Opcodes.w");
    String root = CompilerSources.read("compiler/ir/OpcodeKinds.w");

    byte[] artifact = NativeModuleCompilerHarness.compile(compiler, dependency, root);
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of(
            "compiler/ir/Opcodes.w", dependency,
            "compiler/ir/OpcodeKinds.w", root),
        "wheeler.compiler.opcode_kinds");
    assertArrayEquals(new BytecodeWriter().write(expected), artifact);
    Program decoded = new BytecodeReader().read(artifact);
    assertEquals(5, decoded.functions().size());
    assertEquals("wheeler.compiler.opcode_kinds::isLocalMathOpcode",
        decoded.functions().get(3).name());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalBooleanDeclarationKindsByteForByte() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    String dependency = CompilerSources.read("compiler/ir/StatementKinds.w");
    String root = CompilerSources.read("compiler/syntax/BooleanDeclarationKinds.w");

    byte[] artifact = NativeModuleCompilerHarness.compile(compiler, dependency, root);
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of(
            "compiler/ir/StatementKinds.w", dependency,
            "compiler/syntax/BooleanDeclarationKinds.w", root),
        "wheeler.compiler.boolean_declaration_kinds");
    assertArrayEquals(new BytecodeWriter().write(expected), artifact);
    Program decoded = new BytecodeReader().read(artifact);
    assertEquals(
        "wheeler.compiler.boolean_declaration_kinds::booleanDeclarationStatement",
        decoded.functions().getFirst().name());
    assertEquals(32, decoded.functions().getFirst().localCount());
    assertEquals(53, decoded.functions().getFirst().forward().size());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesAWideLinkedHelperTableByteForByte() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    String dependency = CompilerSources.read("compiler/ir/StatementKinds.w");
    String root = "module examples.wide_link;\n"
        + "import wheeler.compiler.statement_kinds;\n"
        + "classical class WideLink {\n"
        + wideBooleanHelper("alpha")
        + wideBooleanHelper("beta")
        + wideBooleanHelper("gamma")
        + wideBooleanHelper("omega")
        + "}\n";
    assertTrue(dependency.length() + root.length() > 16_384);

    byte[] artifact = NativeModuleCompilerHarness.compile(compiler, dependency, root);
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("StatementKinds.w", dependency, "WideLink.w", root),
        "examples.wide_link");
    assertArrayEquals(new BytecodeWriter().write(expected), artifact);
    Program decoded = new BytecodeReader().read(artifact);
    assertEquals("examples.wide_link::alpha", decoded.functions().getFirst().name());
    assertEquals("examples.wide_link::omega", decoded.functions().get(3).name());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalOneArgumentCallKindsByteForByte() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    String dependency = CompilerSources.read("compiler/ir/StatementKinds.w");
    String root = CompilerSources.read("compiler/syntax/calls/OneArgumentCalls.w");

    byte[] artifact = NativeModuleCompilerHarness.compile(compiler, dependency, root);
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of(
            "compiler/ir/StatementKinds.w", dependency,
            "compiler/syntax/calls/OneArgumentCalls.w", root),
        "wheeler.compiler.one_argument_calls");
    assertArrayEquals(new BytecodeWriter().write(expected), artifact);
    Program decoded = new BytecodeReader().read(artifact);
    assertEquals(
        "wheeler.compiler.one_argument_calls::oneArgumentCallStatement",
        decoded.functions().getFirst().name());
    assertEquals(24, decoded.functions().getFirst().localCount());
    assertEquals(39, decoded.functions().getFirst().forward().size());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalTwoArgumentCallKindsByteForByte() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    String dependency = CompilerSources.read("compiler/ir/StatementKinds.w");
    String root = CompilerSources.read("compiler/syntax/calls/TwoArgumentCallKinds.w");

    byte[] artifact = NativeModuleCompilerHarness.compile(compiler, dependency, root);
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of(
            "compiler/ir/StatementKinds.w", dependency,
            "compiler/syntax/calls/TwoArgumentCallKinds.w", root),
        "wheeler.compiler.two_argument_call_kinds");
    assertArrayEquals(new BytecodeWriter().write(expected), artifact);
    Program decoded = new BytecodeReader().read(artifact);
    assertEquals(
        "wheeler.compiler.two_argument_call_kinds::twoArgumentCallStatement",
        decoded.functions().getFirst().name());
    assertEquals(48, decoded.functions().getFirst().localCount());
    assertEquals(81, decoded.functions().getFirst().forward().size());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalCallArgumentSourcesByteForByte() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    String dependency = CompilerSources.read("compiler/ir/StatementKinds.w");
    String root = CompilerSources.read("compiler/syntax/calls/CallArgumentSources.w");

    byte[] artifact = NativeModuleCompilerHarness.compile(compiler, dependency, root);
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of(
            "compiler/ir/StatementKinds.w", dependency,
            "compiler/syntax/calls/CallArgumentSources.w", root),
        "wheeler.compiler.call_argument_sources");
    assertArrayEquals(new BytecodeWriter().write(expected), artifact);
    Program decoded = new BytecodeReader().read(artifact);
    assertEquals(
        "wheeler.compiler.call_argument_sources::twoArgumentCallFirstNamed",
        decoded.functions().getFirst().name());
    assertEquals(24, decoded.functions().getFirst().localCount());
    assertEquals(39, decoded.functions().getFirst().forward().size());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalEarlyReturnKindsByteForByte() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    String dependency = CompilerSources.read("compiler/ir/StatementKinds.w");
    String root = CompilerSources.read("compiler/syntax/EarlyReturnKinds.w");

    byte[] artifact = NativeModuleCompilerHarness.compile(compiler, dependency, root);
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of(
            "compiler/ir/StatementKinds.w", dependency,
            "compiler/syntax/EarlyReturnKinds.w", root),
        "wheeler.compiler.early_return_kinds");
    assertArrayEquals(new BytecodeWriter().write(expected), artifact);
    Program decoded = new BytecodeReader().read(artifact);
    assertEquals(
        "wheeler.compiler.early_return_kinds::earlyReturnStatement",
        decoded.functions().getFirst().name());
    assertEquals(40, decoded.functions().getFirst().localCount());
    assertEquals(67, decoded.functions().getFirst().forward().size());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalEarlyReturnSourcesByteForByte() throws Exception {
    Program decoded = assertImportedConstantCompilerLibrary(
        "compiler/syntax/returns/EarlyReturnSources.w",
        "wheeler.compiler.early_return_sources");
    assertEquals(
        "wheeler.compiler.early_return_sources::earlyHelperReturnSource",
        decoded.functions().getFirst().name());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalResolvedEarlyComparisonKindsByteForByte() throws Exception {
    Program decoded = assertImportedConstantCompilerLibrary(
        "compiler/syntax/returns/ResolvedEarlyComparisonKinds.w",
        "wheeler.compiler.resolved_early_comparison_kinds");
    assertEquals(
        "wheeler.compiler.resolved_early_comparison_kinds::resolvedEarlyEqualityReturn",
        decoded.functions().getFirst().name());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalResolvedEarlyResultKindsByteForByte() throws Exception {
    Program decoded = assertImportedConstantCompilerLibrary(
        "compiler/syntax/returns/ResolvedEarlyResultKinds.w",
        "wheeler.compiler.resolved_early_result_kinds");
    assertEquals(
        "wheeler.compiler.resolved_early_result_kinds::resolvedEarlyHelperReturn",
        decoded.functions().getFirst().name());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesCanonicalInstructionFormsByteForByte() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    String opcodes = CompilerSources.read("compiler/ir/Opcodes.w");
    String storageOpcodes = CompilerSources.read("compiler/ir/StorageOpcodes.w");
    String root = CompilerSources.read("compiler/ir/InstructionForms.w");

    byte[] artifact = NativeModuleCompilerHarness.compile(
        compiler,
        List.of(opcodes, storageOpcodes),
        root);
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of(
            "compiler/ir/InstructionForms.w", root,
            "compiler/ir/Opcodes.w", opcodes,
            "compiler/ir/StorageOpcodes.w", storageOpcodes),
        "wheeler.compiler.instruction_forms");
    assertArrayEquals(new BytecodeWriter().write(expected), artifact);
    Program decoded = new BytecodeReader().read(artifact);
    assertEquals(
        "wheeler.compiler.instruction_forms::expectedOperandCount",
        decoded.functions().getFirst().name());
    assertEquals(214, decoded.functions().getFirst().localCount());
    assertEquals(373, decoded.functions().getFirst().forward().size());
    assertEquals(
        "wheeler.compiler.instruction_forms::threeOperandStorageOpcode",
        decoded.functions().get(1).name());
    assertEquals(68, decoded.functions().get(1).localCount());
    assertEquals(116, decoded.functions().get(1).forward().size());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void compilesTheCanonicalTypeKindHelperByteForByte() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    String dependency = CompilerSources.read("compiler/ir/TypeCodes.w");
    String root = CompilerSources.read("compiler/ir/TypeKinds.w");

    byte[] artifact = NativeModuleCompilerHarness.compile(compiler, dependency, root);
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of(
            "compiler/ir/TypeCodes.w", dependency,
            "compiler/ir/TypeKinds.w", root),
        "wheeler.compiler.type_kinds");
    assertArrayEquals(new BytecodeWriter().write(expected), artifact);
    Program decoded = new BytecodeReader().read(artifact);
    assertEquals(
        "wheeler.compiler.type_kinds::typeDescriptor",
        decoded.functions().getFirst().name());
    assertEquals("$library", decoded.functions().getLast().name());
    VirtualMachine library = new VirtualMachine(decoded);
    library.run();
    assertEquals(MachineStatus.HALTED, library.status());
  }

  @Test
  void compilesTwoEntrylessHelpersByteForByte() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    String source = twoHelperSource("""
          public long first(long value) {
            return value;
          }

          public long second(long value) {
            return value;
          }
        """);
    VirtualMachine writer = nativeWriter(compiler, source);
    CompilerMachineRunner.runWithoutRewindHistory(writer);

    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("TwoHelpers.w", source),
        "examples.two_helpers");
    byte[] artifact = writer.hostOutput();
    assertArrayEquals(new BytecodeWriter().write(expected), artifact);
    Program decoded = new BytecodeReader().read(artifact);
    assertEquals("examples.two_helpers::first", decoded.functions().get(0).name());
    assertEquals("examples.two_helpers::second", decoded.functions().get(1).name());
    assertEquals("$library", decoded.functions().get(2).name());
  }

  @Test
  void compilesFourEntrylessHelpersByteForByte() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    String source = twoHelperSource("""
          public long alpha(long value) {
            return value;
          }

          public long beta(long value) {
            return value;
          }

          public long gamma(long value) {
            return value;
          }

          public long omega(long value) {
            return value;
          }
        """);
    VirtualMachine writer = nativeWriter(compiler, source);
    CompilerMachineRunner.runWithoutRewindHistory(writer);

    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("FourHelpers.w", source),
        "examples.two_helpers");
    byte[] artifact = writer.hostOutput();
    assertArrayEquals(new BytecodeWriter().write(expected), artifact);
    Program decoded = new BytecodeReader().read(artifact);
    assertEquals("examples.two_helpers::alpha", decoded.functions().get(0).name());
    assertEquals("examples.two_helpers::omega", decoded.functions().get(3).name());
    assertEquals("$library", decoded.functions().get(4).name());

    String reordered = twoHelperSource("""
          public long omega(long value) {
            return value;
          }

          public long alpha(long value) {
            return value;
          }

          public long gamma(long value) {
            return value;
          }

          public long beta(long value) {
            return value;
          }
        """);
    VirtualMachine reorderedWriter = nativeWriter(compiler, reordered);
    CompilerMachineRunner.runWithoutRewindHistory(reorderedWriter);
    Program reorderedExpected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("FourHelpers.w", reordered),
        "examples.two_helpers");
    Program reorderedDecoded = new BytecodeReader().read(reorderedWriter.hostOutput());
    assertEquals("examples.two_helpers::omega", reorderedDecoded.functions().get(0).name());
    assertEquals("examples.two_helpers::alpha", reorderedDecoded.functions().get(1).name());
    assertEquals("examples.two_helpers::gamma", reorderedDecoded.functions().get(2).name());
    assertEquals("examples.two_helpers::beta", reorderedDecoded.functions().get(3).name());
    assertArrayEquals(
        new BytecodeWriter().write(reorderedExpected),
        reorderedWriter.hostOutput());
  }

  @Test
  void rejectsExcessEntrylessHelpersBeforePublication() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    String source = twoHelperSource("""
          public long alpha(long value) {
            return value;
          }

          public long beta(long value) {
            return value;
          }

          public long gamma(long value) {
            return value;
          }

          public long omega(long value) {
            return value;
          }

          public long zeta(long value) {
            return value;
          }
        """);
    assertNoPublication(compiler, source);
  }

  private static void assertNoPublication(Program compiler, String source) {
    VirtualMachine writer = nativeWriter(compiler, source);
    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(writer));
    assertArrayEquals(new byte[OUTPUT_CAPACITY], writer.hostOutput());
  }

  private static String wideBooleanHelper(String name) {
    return """
          public boolean %s(long kind) {
            if (kind == STATEMENT_ASSIGN) { return true; }
            if (kind == STATEMENT_ASSERT_EQ) { return false; }
            if (kind == STATEMENT_LOCAL_LONG) { return true; }
            if (kind == STATEMENT_LOCAL_BOOLEAN) { return false; }
            if (kind == STATEMENT_LOCAL_BOOLEAN_NOT) { return true; }
            if (kind == STATEMENT_ASSERT_BOOLEAN) { return false; }
            if (kind == STATEMENT_ASSERT_BOOLEAN_NOT) { return true; }
            return kind == STATEMENT_ASSERT_LOCAL_BOOLEAN;
          }

        """.formatted(name);
  }

  private static String twoHelperSource(String members) {
    return "module examples.two_helpers;\nclassical class TwoHelpers {\n"
        + members + "}\n";
  }

  private static Program assertImportedConstantCompilerLibrary(
      String logicalPath,
      String moduleName) throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    String dependency = CompilerSources.read("compiler/ir/ResolvedStatements.w");
    String root = CompilerSources.read(logicalPath);

    byte[] artifact = NativeModuleCompilerHarness.compile(compiler, dependency, root);
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of(
            "compiler/ir/ResolvedStatements.w", dependency,
            logicalPath, root),
        moduleName);
    assertArrayEquals(new BytecodeWriter().write(expected), artifact);
    return new BytecodeReader().read(artifact);
  }

  private static void assertConstantOnlyCompilerLibrary(
      String logicalPath,
      String moduleName) throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    String source = CompilerSources.read(logicalPath);
    VirtualMachine writer = nativeWriter(compiler, source);
    CompilerMachineRunner.runWithoutRewindHistory(writer);

    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of(logicalPath, source),
        moduleName);
    byte[] artifact = writer.hostOutput();
    assertArrayEquals(new BytecodeWriter().write(expected), artifact);
    Program decoded = new BytecodeReader().read(artifact);
    assertEquals("$library", decoded.functions().getFirst().name());
    VirtualMachine library = new VirtualMachine(decoded);
    library.run();
    assertEquals(MachineStatus.HALTED, library.status());
  }

  private static VirtualMachine nativeWriter(Program compiler, String source) {
    return new VirtualMachine(
        compiler,
        source.getBytes(StandardCharsets.UTF_8),
        OUTPUT_CAPACITY);
  }
}
