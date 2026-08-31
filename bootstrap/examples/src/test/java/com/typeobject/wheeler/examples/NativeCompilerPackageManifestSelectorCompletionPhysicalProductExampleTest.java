package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.LinkedHashMap;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/** Native evidence for package-manifest selector completion. */
final class NativeCompilerPackageManifestSelectorCompletionPhysicalProductExampleTest {
  private static final String MODULE =
      "wheeler.compiler.packages.manifest_selector_completion";

  @Tag("closure-evidence")
  @Test
  void compilesManifestSelectorCompletionByteForByte() throws Exception {
    var module = NativeCompilerPhysicalSelection.comparable(MODULE);
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            CompilerSources.moduleClosure(module.name()), module.name()));
    var machine = VirtualMachine.withBinaryInput(
        NativeCompilerPhysicalPrograms.comparable(module),
        framed(
            CompilerSources.packageArchive(),
            CompilerSources.bootstrapModuleManifest().canonicalBytes()),
        expected.length + 1_048_576);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("published"));
    assertArrayEquals(expected, Arrays.copyOf(machine.hostOutput(), expected.length));
    assertEquals(expected.length, machine.global("physicalModuleProductLength"));
  }

  @Test
  void executesEqualPrefixAndNonseparatorCompletion() throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(MODULE));
    sources.put("PackageManifestSelectorCompletionExample.w", """
        module example.package_manifest_selector_completion;

        import wheeler.compiler.packages.manifest_selector_completion;

        classical class PackageManifestSelectorCompletionExample {
          entry void main(borrow utf8 source) {
            assert(manifestSelectorRangeComplete(source, 1, 0, 3));
            assert(manifestSelectorRangeComplete(source, 0, 4, 3));
            assert(manifestSelectorRangeComplete(source, 0, 13, 3) == false);
          }
        }
        """);
    var program = new WheelerCompiler().compileModuleFiles(
        sources, "example.package_manifest_selector_completion");

    new VirtualMachine(
        program,
        "src src/Main srcx".getBytes(StandardCharsets.US_ASCII)).run();
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
