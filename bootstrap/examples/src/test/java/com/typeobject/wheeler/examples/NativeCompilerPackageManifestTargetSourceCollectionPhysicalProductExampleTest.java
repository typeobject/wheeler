package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/** Native physical evidence for target source-collection entry admission. */
final class NativeCompilerPackageManifestTargetSourceCollectionPhysicalProductExampleTest {
  private static final String MODULE = "wheeler.compiler.packages.manifest_target_source_collection";

  @Tag("closure-evidence")
  @Test
  void retainsManifestTargetSourceCollectionAndClosesItsImports() throws Exception {
    var module = NativeCompilerPhysicalSelection.callable(MODULE);
    var expected = new WheelerCompiler().compileLibraryModuleFiles(
        CompilerSources.moduleClosure(module.name()), module.name());
    long expectedFunctions = 0;
    long expectedInstructions = 0;
    for (var function : expected.functions()) {
      if (function.name().startsWith(module.name() + "::")) {
        expectedFunctions += 1;
        expectedInstructions += function.forward().size();
        expectedInstructions += function.inverse().size();
      }
    }
    var machine = VirtualMachine.withBinaryInput(
        NativeCompilerPhysicalPrograms.callable(module),
        framed(
            CompilerSources.packageArchive(),
            CompilerSources.bootstrapModuleManifest().canonicalBytes()),
        1_048_576);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(expectedFunctions, machine.global("physicalRetainedFunctionCount"));
    assertEquals(expectedInstructions, machine.global("physicalRetainedInstructionCount"));
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
