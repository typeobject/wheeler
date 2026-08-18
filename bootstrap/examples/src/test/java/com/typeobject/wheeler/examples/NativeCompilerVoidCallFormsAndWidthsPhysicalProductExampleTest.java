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

/** Native evidence for direct imported void-call form and width products. */
final class NativeCompilerVoidCallFormsAndWidthsPhysicalProductExampleTest {
  @Tag("closure-evidence")
  @Test
  void retainsFormsAndWidthsAndRelocatesTheirClassifierCalls() throws Exception {
    var modules = modules();
    long expectedFunctions = 0;
    long expectedInstructions = 0;
    for (var module : modules) {
      Program expectedProgram = new WheelerCompiler().compileLibraryModuleFiles(
          CompilerSources.moduleClosure(module.name()), module.name());
      var localFunctions = expectedProgram.functions().stream()
          .filter(function -> function.name().startsWith(module.name() + "::"))
          .toList();
      expectedFunctions += localFunctions.size();
      expectedInstructions += localFunctions.stream()
          .mapToLong(function -> function.forward().size() + function.inverse().size())
          .sum();
    }
    assertEquals(6, expectedFunctions);
    assertEquals(343, expectedInstructions);

    Program productProgram = NativeCompilerPhysicalPrograms.callable(modules);
    var manifest = CompilerSources.bootstrapModuleManifest();
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        productProgram,
        framed(CompilerSources.packageArchive(), manifest.canonicalBytes()),
        1_048_576);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(expectedFunctions, machine.global("physicalRetainedFunctionCount"));
    assertEquals(expectedInstructions, machine.global("physicalRetainedInstructionCount"));
    assertEquals(3, machine.global("physicalCallableProductCount"));
    assertEquals(4, machine.global("physicalCallableRelocationCount"));
    assertEquals(4, machine.global("physicalResolvedCallableTargetCount"));
  }

  private static List<NativeCompilerArchiveClosureProgram.PhysicalModule> modules() {
    return List.of(
        NativeCompilerPhysicalSelection.callable("wheeler.compiler.void_call_source_forms"),
        NativeCompilerPhysicalSelection.callable("wheeler.compiler.void_call_source_widths"),
        NativeCompilerPhysicalSelection.callable("wheeler.compiler.void_call_widths"));
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
