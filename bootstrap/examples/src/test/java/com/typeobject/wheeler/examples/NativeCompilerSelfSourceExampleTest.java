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
  void compilesTheCanonicalTypeCodeOwnerByteForByte() throws Exception {
    assertConstantOnlyCompilerLibrary(
        "compiler/ir/TypeCodes.w",
        "wheeler.compiler.type_codes");
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
  void rejectsMultipleHelpersBeforePublication() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    String source = """
        module examples.two_helpers;
        classical class TwoHelpers {
          public long first(long value) {
            return value;
          }

          public long second(long value) {
            return value;
          }
        }
        """;
    VirtualMachine writer = nativeWriter(compiler, source);

    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(writer));
    assertArrayEquals(new byte[OUTPUT_CAPACITY], writer.hostOutput());
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
