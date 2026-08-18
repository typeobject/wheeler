package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/** Native evidence for the imported-call void-syntax product. */
final class NativeCompilerVoidCallSyntaxPhysicalProductExampleTest {
  @Tag("closure-evidence")
  @Test
  void retainsVoidCallSyntaxAndRelocatesItsClassifierCalls() throws Exception {
    var module = NativeCompilerPhysicalSelection.callable(
        "wheeler.compiler.void_call_syntax");
    Program expectedProgram = new WheelerCompiler().compileLibraryModuleFiles(
        CompilerSources.moduleClosure(module.name()), module.name());
    var expectedFunction = expectedProgram.functions().stream()
        .filter(function -> function.name().equals(module.name() + "::voidCallStatementWidth"))
        .findFirst()
        .orElseThrow();
    assertEquals(134, expectedFunction.forward().size());

    Program productProgram = NativeCompilerArchiveClosureProgram.physicalCallableProductProgram(
        module);
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
    assertEquals(5, machine.global("physicalRetainedFunctionCount"));
    assertEquals(expectedInstructions, machine.global("physicalRetainedInstructionCount"));
    assertEquals(1, machine.global("physicalCallableProductCount"));
    assertEquals(1, machine.global("physicalCallableRelocationCount"));
    assertEquals(1, machine.global("physicalResolvedCallableTargetCount"));
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
