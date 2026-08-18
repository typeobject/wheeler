package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/** Native evidence for the direct imported early-comparison form product. */
final class NativeCompilerEarlyComparisonFormsPhysicalProductExampleTest {
  @Tag("closure-evidence")
  @Test
  void retainsTheComparisonFormAndRelocatesBothClassifiers() throws Exception {
    var module = NativeCompilerPhysicalSelection.callable(
        "wheeler.compiler.early_comparison_forms");
    Program expectedProgram = new WheelerCompiler().compileLibraryModuleFiles(
        CompilerSources.moduleClosure(module.name()), module.name());
    var expectedFunction = expectedProgram.functions().stream()
        .filter(function -> function.name().startsWith(module.name() + "::"))
        .findFirst()
        .orElseThrow();
    assertEquals(11, expectedFunction.forward().size());

    Program productProgram = NativeCompilerPhysicalPrograms.callable(module);
    var manifest = CompilerSources.bootstrapModuleManifest();
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        productProgram,
        framed(CompilerSources.packageArchive(), manifest.canonicalBytes()),
        1_048_576);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("physicalRetainedFunctionCount"));
    assertEquals(11, machine.global("physicalRetainedInstructionCount"));
    assertEquals(1, machine.global("physicalCallableProductCount"));
    assertEquals(2, machine.global("physicalCallableRelocationCount"));
    assertEquals(2, machine.global("physicalResolvedCallableTargetCount"));
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
