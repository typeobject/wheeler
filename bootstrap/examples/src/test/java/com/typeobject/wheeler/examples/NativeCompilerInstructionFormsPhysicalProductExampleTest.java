package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Arrays;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/** Native evidence for direct instruction-form products. */
final class NativeCompilerInstructionFormsPhysicalProductExampleTest {
  @Tag("closure-evidence")
  @Test
  void compilesInstructionFormsByteForByte() throws Exception {
    var module = NativeCompilerPhysicalSelection.comparable(
        "wheeler.compiler.instruction_forms");
    var expectedProgram = new WheelerCompiler().compileLibraryModuleFiles(
        CompilerSources.moduleClosure(module.name()), module.name());
    byte[] expected = new BytecodeWriter().write(expectedProgram);
    var operandCount = expectedProgram.functions().getFirst();
    assertEquals(Opcode.CALL_VALUE, operandCount.forward().get(261).opcode());
    assertEquals(3, operandCount.forward().get(263).operands().get(1));

    var productProgram = NativeCompilerArchiveClosureProgram.physicalProductProgram(module);
    var manifest = CompilerSources.bootstrapModuleManifest();
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        productProgram,
        framed(CompilerSources.packageArchive(), manifest.canonicalBytes()),
        expected.length + 1_048_576);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("published"));
    assertArrayEquals(expected, Arrays.copyOf(machine.hostOutput(), expected.length));
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
