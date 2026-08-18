package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.List;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/** Native evidence for direct imported assignment-call width products. */
final class NativeCompilerAssignmentCallWidthsPhysicalProductExampleTest {
  @Tag("closure-evidence")
  @Test
  void retainsWidthFunctionsAndRelocatesTheirArityCalls() throws Exception {
    var modules = modules();
    for (var module : modules) {
      Program expectedProgram = new WheelerCompiler().compileLibraryModuleFiles(
          CompilerSources.moduleClosure(module.name()), module.name());
      var expectedFunction = expectedProgram.functions().stream()
          .filter(function -> function.name().startsWith(module.name() + "::"))
          .findFirst()
          .orElseThrow();
      assertEquals(19, expectedFunction.forward().size());
    }

    Program productProgram = NativeCompilerPhysicalPrograms.callable(
        modules);
    var manifest = CompilerSources.bootstrapModuleManifest();
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        productProgram,
        framed(CompilerSources.packageArchive(), manifest.canonicalBytes()),
        1_048_576);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(3, machine.global("physicalRetainedFunctionCount"));
    assertEquals(57, machine.global("physicalRetainedInstructionCount"));
    assertEquals(3, machine.global("physicalCallableProductCount"));
    assertEquals(3, machine.global("physicalCallableRelocationCount"));
    assertEquals(3, machine.global("physicalResolvedCallableTargetCount"));
  }

  private static List<NativeCompilerArchiveClosureProgram.PhysicalModule> modules() {
    return List.of(
        NativeCompilerPhysicalSelection.callable(
            "wheeler.compiler.assignment_call_code_widths"),
        NativeCompilerPhysicalSelection.callable(
            "wheeler.compiler.assignment_call_instruction_widths"),
        NativeCompilerPhysicalSelection.callable(
            "wheeler.compiler.assignment_call_local_widths"));
  }

  private static byte[] framed(byte[] archive, byte[] manifest) {
    return ByteBuffer.allocate(Integer.BYTES + archive.length + manifest.length)
        .order(ByteOrder.LITTLE_ENDIAN)
        .putInt(archive.length)
        .put(archive)
        .put(manifest)
        .array();
  }
}
