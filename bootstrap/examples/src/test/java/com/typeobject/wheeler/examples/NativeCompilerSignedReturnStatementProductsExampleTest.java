package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Arrays;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/** Native evidence for focused signed-return statement products. */
final class NativeCompilerSignedReturnStatementProductsExampleTest {
  @Tag("closure-evidence")
  @Test
  void compilesSignedReturnStatementsByteForByte() throws Exception {
    assertPhysicalProduct("wheeler.compiler.signed_return_statements");
  }

  @Tag("closure-evidence")
  @Test
  void compilesResolvedLocalReturnStatementsByteForByte() throws Exception {
    assertPhysicalProduct("wheeler.compiler.resolved_local_return_statements");
  }

  @Tag("closure-evidence")
  @Test
  void compilesResolvedLocalResultKindsByteForByte() throws Exception {
    assertPhysicalProduct("wheeler.compiler.resolved_local_result_kinds");
  }

  private static void assertPhysicalProduct(String moduleName) throws Exception {
    var module = NativeCompilerPhysicalSelection.comparable(moduleName);
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            CompilerSources.moduleClosure(module.name()), module.name()));
    var productProgram = NativeCompilerPhysicalPrograms.comparable(module);
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
