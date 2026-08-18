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

/** Native evidence for direct early-return classifiers. */
final class NativeCompilerEarlyReturnKindsPhysicalProductExampleTest {
  @Tag("closure-evidence")
  @Test
  void compilesEarlyReturnKindsByteForByte() throws Exception {
    var module = NativeCompilerArchiveClosureProgram.physicalModule(
        "wheeler.compiler.early_return_kinds");
    var expectedProgram = new WheelerCompiler().compileLibraryModuleFiles(
        CompilerSources.moduleClosure(module.name()), module.name());
    byte[] expected = new BytecodeWriter().write(expectedProgram);
    var localCount = expectedProgram.functions().get(1);
    assertEquals("wheeler.compiler.early_return_kinds::sourceEarlyReturnLocalCount",
        localCount.name());
    assertEquals(Opcode.CALL_VALUE, localCount.forward().get(37).opcode());
    assertEquals(4, localCount.forward().get(39).operands().get(1));

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
