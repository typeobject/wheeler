package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/** Native evidence for the complete direct assignment-call syntax product. */
final class NativeCompilerAssignmentCallSyntaxPhysicalProductExampleTest {
  @Tag("closure-evidence")
  @Test
  void retainsEveryHelperAndRelocatesTheRecursiveCallGraph() throws Exception {
    var module = NativeCompilerPhysicalSelection.callable(
        "wheeler.compiler.assignment_call_syntax");
    Program expectedProgram = new WheelerCompiler().compileLibraryModuleFiles(
        CompilerSources.moduleClosure(module.name()), module.name());
    var classifier = expectedProgram.functions().stream()
        .filter(function -> function.name().equals(module.name() + "::classifyArguments"))
        .findFirst()
        .orElseThrow();
    assertEquals(75, classifier.forward().size());

    Program productProgram = NativeCompilerPhysicalPrograms.callable(module);
    var manifest = CompilerSources.bootstrapModuleManifest();
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        productProgram,
        framed(CompilerSources.packageArchive(), manifest.canonicalBytes()),
        1_048_576);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    long expectedInstructions = expectedProgram.functions().stream()
        .filter(function -> function.name().startsWith(module.name() + "::"))
        .mapToLong(function -> function.forward().size() + function.inverse().size())
        .sum();
    assertEquals(12, machine.global("physicalRetainedFunctionCount"));
    assertEquals(expectedInstructions, machine.global("physicalRetainedInstructionCount"));
    assertEquals(1, machine.global("physicalCallableProductCount"));
    assertEquals(5, machine.global("physicalCallableRelocationCount"));
    assertEquals(5, machine.global("physicalResolvedCallableTargetCount"));
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
