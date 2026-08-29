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

/** Native evidence for semantic-version prerelease-sequence precedence. */
final class NativeCompilerSemverPrereleaseComparisonPhysicalProductExampleTest {
  private static final String MODULE =
      "wheeler.compiler.packages.semver_prerelease_comparison";

  @Tag("closure-evidence")
  @Test
  void retainsPrereleaseComparisonAndRelocatesDependencies() throws Exception {
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
    assertEquals(4, machine.global("physicalCallableRelocationCount"));
    assertEquals(
        machine.global("physicalCallableRelocationCount"),
        machine.global("physicalResolvedCallableTargetCount"));
  }

  @Test
  void executesCanonicalPrereleasePrecedence() throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(MODULE));
    sources.put("SemverPrereleaseComparisonExample.w", """
        module example.semver_prerelease_comparison;

        import wheeler.compiler.packages.semver_prerelease_comparison;

        classical class SemverPrereleaseComparisonExample {
          entry void main(borrow utf8 source) {
            assert(semverComparePrerelease(source, 0, 11, 12, 13) == -1);
            assert(semverComparePrerelease(source, 12, 13, 26, 16) == -1);
            assert(semverComparePrerelease(source, 26, 16, 43, 10) == -1);
            assert(semverComparePrerelease(source, 43, 10, 54, 12) == -1);
            assert(semverComparePrerelease(source, 54, 12, 67, 13) == -1);
            assert(semverComparePrerelease(source, 67, 13, 81, 10) == -1);
            assert(semverComparePrerelease(source, 81, 10, 92, 5) == -1);
            assert(semverComparePrerelease(source, 92, 5, 0, 11) == 1);
            assert(semverComparePrerelease(source, 0, 11, 0, 11) == 0);
          }
        }
        """);
    var program = new WheelerCompiler().compileModuleFiles(
        sources, "example.semver_prerelease_comparison");
    var machine = new VirtualMachine(program, (
        "1.0.0-alpha/1.0.0-alpha.1/1.0.0-alpha.beta/1.0.0-beta/"
            + "1.0.0-beta.2/1.0.0-beta.11/1.0.0-rc.1/1.0.0").getBytes(
                StandardCharsets.US_ASCII));

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
