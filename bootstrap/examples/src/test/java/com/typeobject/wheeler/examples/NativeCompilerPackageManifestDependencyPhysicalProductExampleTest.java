package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Map;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/** Native physical evidence for dependency admission and publication. */
final class NativeCompilerPackageManifestDependencyPhysicalProductExampleTest {
  private static final String MODULE = "wheeler.compiler.packages.manifest_dependency";

  @Tag("closure-evidence")
  @Test
  void retainsDependencyAdmissionAndRelocatesFieldAndOrderingPolicy() throws Exception {
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
    var manifest = CompilerSources.bootstrapModuleManifest();
    var machine = VirtualMachine.withBinaryInput(
        NativeCompilerPhysicalPrograms.callable(module),
        framed(
            CompilerSources.packageArchive(),
            manifest.canonicalBytes()),
        1_048_576);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(expectedFunctions, machine.global("physicalRetainedFunctionCount"));
    assertEquals(expectedInstructions, machine.global("physicalRetainedInstructionCount"));
    assertEquals(9, machine.global("physicalCallableRelocationCount"));
    assertEquals(9, machine.global("physicalResolvedCallableTargetCount"));
    byte[] transport = machine.hostOutput();
    var references = Map.of(MODULE, expected);
    NativeCompilerPhysicalProductAssertions.assertCallables(manifest, references, transport);

    byte[] misbound = transport.clone();
    int lastTarget = misbound.length - 9;
    assertTrue(0 < Byte.toUnsignedInt(misbound[lastTarget]));
    misbound[lastTarget] -= 1;
    assertThrows(AssertionError.class,
        () -> NativeCompilerPhysicalProductAssertions.assertCallables(manifest, references, misbound));
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
