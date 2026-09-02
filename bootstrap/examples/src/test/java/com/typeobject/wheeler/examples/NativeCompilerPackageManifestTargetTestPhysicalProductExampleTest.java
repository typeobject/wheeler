package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.LinkedHashMap;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/** Native evidence for package-manifest target test policy. */
final class NativeCompilerPackageManifestTargetTestPhysicalProductExampleTest {
  private static final String MODULE = "wheeler.compiler.packages.manifest_target_test";

  @Tag("closure-evidence")
  @Test
  void retainsManifestTargetTestAndRelocatesKey() throws Exception {
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
    assertEquals(1, machine.global("physicalCallableRelocationCount"));
    assertEquals(1, machine.global("physicalResolvedCallableTargetCount"));
  }

  @Test
  void executesManifestTargetTestPolicy() throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(MODULE));
    sources.put("PackageManifestTargetTestExample.w", """
        module example.package_manifest_target_test;

        import wheeler.compiler.packages.manifest_target_test;

        classical class PackageManifestTargetTestExample {
          entry void main() {
            assert(manifestTargetTestAllowed(1, 0));
            assert(manifestTargetTestAllowed(1, 1));
            assert(manifestTargetTestAllowed(2, 0));
            assert(manifestTargetTestAllowed(2, 1) == false);
            assert(manifestTargetTestAllowed(3, 0));
            assert(manifestTargetTestAllowed(3, 1));
          }
        }
        """);
    var program = new WheelerCompiler().compileModuleFiles(
        sources, "example.package_manifest_target_test");

    new VirtualMachine(program).run();
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
