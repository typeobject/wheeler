package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/** Native evidence for direct imported helper-result kind products. */
final class NativeCompilerHelperResultKindsPhysicalProductExampleTest {
  @Tag("closure-evidence")
  @Test
  void retainsHelperResultKindsAndRelocatesClassifiers() throws Exception {
    var module = NativeCompilerPhysicalSelection.callable(
        "wheeler.compiler.helper_result_kinds");
    var expectedProgram = new WheelerCompiler().compileLibraryModuleFiles(
        CompilerSources.moduleClosure(module.name()), module.name());
    var localFunctions = expectedProgram.functions().stream()
        .filter(function -> function.name().startsWith(module.name() + "::"))
        .toList();
    long expectedInstructions = localFunctions.stream()
        .mapToLong(function -> function.forward().size() + function.inverse().size())
        .sum();
    assertEquals(3, localFunctions.size());

    var productProgram = NativeCompilerPhysicalPrograms.callable(module);
    var manifest = CompilerSources.bootstrapModuleManifest();
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        productProgram,
        framed(CompilerSources.packageArchive(), manifest.canonicalBytes()),
        1_048_576);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("published"));
    assertEquals(localFunctions.size(), machine.global("physicalRetainedFunctionCount"));
    assertEquals(expectedInstructions, machine.global("physicalRetainedInstructionCount"));
    assertEquals(1, machine.global("physicalCallableProductCount"));
    assertEquals(9, machine.global("physicalCallableRelocationCount"));
    assertEquals(9, machine.global("physicalResolvedCallableTargetCount"));
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
