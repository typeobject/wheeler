package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/** Native evidence for semantic-version core precedence. */
final class NativeCompilerSemverPrecedenceCorePhysicalProductExampleTest {
  private static final String PHYSICAL_MODULE =
      "wheeler.compiler.packages.semver_core_comparison";
  private static final String RELEASE_MODULE =
      "wheeler.compiler.packages.semver_release_comparison";

  @Tag("closure-evidence")
  @Test
  void retainsCoreComparisonAndRelocatesCoordinates() throws Exception {
    var module = NativeCompilerPhysicalSelection.callable(PHYSICAL_MODULE);
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

    var productProgram = NativeCompilerPhysicalPrograms.callable(module);
    byte[] archive = CompilerSources.packageArchive();
    byte[] manifest = CompilerSources.bootstrapModuleManifest().canonicalBytes();
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        productProgram,
        framed(archive, manifest),
        1_048_576);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(expectedFunctions, machine.global("physicalRetainedFunctionCount"));
    assertEquals(expectedInstructions, machine.global("physicalRetainedInstructionCount"));
    assertEquals(1, machine.global("physicalCallableProductCount"));
    assertEquals(6, machine.global("physicalCallableRelocationCount"));
    assertEquals(
        machine.global("physicalCallableRelocationCount"),
        machine.global("physicalResolvedCallableTargetCount"));
  }

  @Test
  void executesCanonicalReleasePrecedence() throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(RELEASE_MODULE));
    sources.put("SemverReleaseComparisonExample.w", """
        module example.semver_release_comparison;

        import wheeler.compiler.packages.semver_release_comparison;

        classical class SemverReleaseComparisonExample {
          entry void main(borrow utf8 source) {
            assert(semverCompareReleases(source, 0, 5, 6, 5) == -1);
            assert(semverCompareReleases(source, 0, 5, 12, 5) == -1);
            assert(semverCompareReleases(source, 0, 5, 18, 5) == -1);
            assert(semverCompareReleases(source, 0, 5, 24, 11) == 1);
            assert(semverCompareReleases(source, 24, 11, 36, 13) == -1);
            assert(semverCompareReleases(source, 36, 13, 50, 16) == -1);
            assert(semverCompareReleases(source, 50, 16, 67, 10) == -1);
            assert(semverCompareReleases(source, 67, 10, 78, 12) == -1);
            assert(semverCompareReleases(source, 78, 12, 91, 13) == -1);
            assert(semverCompareReleases(source, 91, 13, 105, 10) == -1);
            assert(semverCompareReleases(source, 105, 10, 116, 5) == -1);
            assert(semverCompareReleases(source, 116, 5, 0, 5) == 0);
          }
        }
        """);
    var program = new WheelerCompiler().compileModuleFiles(
        sources, "example.semver_release_comparison");
    var machine = new VirtualMachine(program, (
        "1.0.0/2.0.0/1.1.0/1.0.1/1.0.0-alpha/1.0.0-alpha.1/"
            + "1.0.0-alpha.beta/1.0.0-beta/1.0.0-beta.2/1.0.0-beta.11/"
            + "1.0.0-rc.1/1.0.0").getBytes(StandardCharsets.US_ASCII));

    machine.run();
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
