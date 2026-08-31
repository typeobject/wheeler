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

/** Native evidence for package-manifest source selectors. */
final class NativeCompilerPackageManifestSelectorsPhysicalProductExampleTest {
  private static final String MODULE = "wheeler.compiler.packages.manifest_selectors";
  private static final String SELECTORS =
      "\"src\" \"src/Main.w\" \"src/Main.w\" \"src\" \"lib\" \"srcx/Main.w\"";

  @Tag("closure-evidence")
  @Test
  void retainsManifestSelectorsAndRelocatesPolicy() throws Exception {
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
    assertEquals(
        machine.global("physicalCallableRelocationCount"),
        machine.global("physicalResolvedCallableTargetCount"));
  }

  @Test
  void executesEqualDirectoryLongerMismatchAndDelimiterChecks() throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(MODULE));
    sources.put("PackageManifestSelectorsExample.w", """
        module example.package_manifest_selectors;

        import wheeler.compiler.packages.manifest_selectors;

        classical class PackageManifestSelectorsExample {
          entry void main(borrow utf8 source) {
            assert(manifestSelectorRangeCoversRoot(source, 1, 3, 7, 10));
            assert(manifestSelectorRangeCoversRoot(source, 20, 10, 33, 3) == false);
            assert(manifestSelectorRangeCoversRoot(source, 33, 3, 1, 3));
            assert(manifestSelectorRangeCoversRoot(source, 39, 3, 7, 10) == false);
            assert(manifestSelectorRangeCoversRoot(source, 1, 3, 45, 11) == false);
          }
        }
        """);
    var program = new WheelerCompiler().compileModuleFiles(
        sources, "example.package_manifest_selectors");

    new VirtualMachine(program, SELECTORS.getBytes(StandardCharsets.US_ASCII)).run();
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
