package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/** Native evidence for the direct imported assignment-call kind product. */
final class NativeCompilerAssignmentCallKindsPhysicalProductExampleTest {
  @Tag("closure-evidence")
  @Test
  void retainsKindFunctionsAndRelocatesArityAndBaseCalls() throws Exception {
    var module = NativeCompilerPhysicalSelection.callable(
        "wheeler.compiler.assignment_call_kinds");
    Program expectedProgram = new WheelerCompiler().compileLibraryModuleFiles(
        CompilerSources.moduleClosure(module.name()), module.name());
    var localFunctions = expectedProgram.functions().stream()
        .filter(function -> function.name().startsWith(module.name() + "::"))
        .toList();
    long expectedInstructions = localFunctions.stream()
        .mapToLong(function -> function.forward().size() + function.inverse().size())
        .sum();
    assertEquals(4, localFunctions.size());
    assertEquals(63, expectedInstructions);

    Program productProgram = NativeCompilerPhysicalPrograms.callable(module);
    var manifest = CompilerSources.bootstrapModuleManifest();
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        productProgram,
        framed(CompilerSources.packageArchive(), manifest.canonicalBytes()),
        1_048_576);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(4, machine.global("physicalRetainedFunctionCount"));
    assertEquals(63, machine.global("physicalRetainedInstructionCount"));
    assertEquals(1, machine.global("physicalCallableProductCount"));
    assertEquals(3, machine.global("physicalCallableRelocationCount"));
    assertEquals(3, machine.global("physicalResolvedCallableTargetCount"));
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
