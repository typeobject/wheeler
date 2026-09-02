package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Arrays;
import java.util.LinkedHashMap;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/** Native evidence for package-manifest target coordinates. */
final class NativeCompilerPackageManifestTargetCoordinatesPhysicalProductExampleTest {
  private static final String MODULE = "wheeler.compiler.packages.manifest_target_coordinates";

  @Tag("closure-evidence")
  @Test
  void compilesManifestTargetCoordinatesByteForByte() throws Exception {
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
  void executesTargetCoordinates() throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(MODULE));
    sources.put("PackageManifestTargetCoordinatesExample.w", """
        module example.package_manifest_target_coordinates;

        import wheeler.compiler.packages.manifest_target_coordinates;

        classical class PackageManifestTargetCoordinatesExample {
          entry void main() {
            assert(manifestTargetNameToken(4) == 10);
            assert(manifestTargetRootToken(4) == 13);
            assert(manifestTargetModuleKeyToken(4) == 14);
            assert(manifestTargetModuleToken(4) == 16);
            assert(manifestTargetSourcesKeyToken(4) == 17);
            assert(manifestTargetFirstSourceRowToken(4) == 19);
            assert(manifestTargetSelectorToken(19) == 20);
            assert(manifestTargetNextSourceRowToken(19) == 21);
            assert(manifestTargetTestToken(21) == 23);
            assert(manifestTargetNextToken(21) == 24);
          }
        }
        """);
    var program = new WheelerCompiler().compileModuleFiles(
        sources, "example.package_manifest_target_coordinates");

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
