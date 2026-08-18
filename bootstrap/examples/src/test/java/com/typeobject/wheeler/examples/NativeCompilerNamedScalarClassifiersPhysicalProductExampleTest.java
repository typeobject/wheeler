package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Arrays;
import java.util.List;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/** Native evidence for direct named scalar-classifier products. */
final class NativeCompilerNamedScalarClassifiersPhysicalProductExampleTest {
  private static final List<String> MODULES = List.of(
      "wheeler.compiler.named_local_update_kinds",
      "wheeler.compiler.named_long_operations");

  @Tag("closure-evidence")
  @Test
  void compilesNamedScalarClassifiersByteForByte() throws Exception {
    for (String name : MODULES) {
      assertPhysicalProduct(name);
    }
  }

  private static void assertPhysicalProduct(String name) throws Exception {
    var module = NativeCompilerPhysicalSelection.comparable(name);
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            CompilerSources.moduleClosure(module.name()), module.name()));
    var productProgram = NativeCompilerArchiveClosureProgram.physicalProductProgram(module);
    var manifest = CompilerSources.bootstrapModuleManifest();
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        productProgram,
        framed(CompilerSources.packageArchive(), manifest.canonicalBytes()),
        expected.length + 1_048_576);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("published"), name);
    assertArrayEquals(
        expected,
        Arrays.copyOf(machine.hostOutput(), expected.length),
        name);
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
