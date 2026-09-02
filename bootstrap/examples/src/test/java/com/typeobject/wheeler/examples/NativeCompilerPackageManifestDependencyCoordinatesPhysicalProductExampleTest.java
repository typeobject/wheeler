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

/** Native evidence for package-manifest dependency coordinates. */
final class NativeCompilerPackageManifestDependencyCoordinatesPhysicalProductExampleTest {
  private static final String MODULE =
      "wheeler.compiler.packages.manifest_dependency_coordinates";

  @Tag("closure-evidence")
  @Test
  void compilesManifestDependencyCoordinatesByteForByte() throws Exception {
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
  void executesManifestDependencyCoordinates() throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(MODULE));
    sources.put("PackageManifestDependencyCoordinatesExample.w", """
        module example.package_manifest_dependency_coordinates;

        import wheeler.compiler.packages.manifest_dependency_coordinates;

        classical class PackageManifestDependencyCoordinatesExample {
          entry void main() {
            region arena = new region(16, 2);
            words starts = allocate(arena, 1);
            words lengths = allocate(arena, 1);
            set(starts, 0, 41);
            set(lengths, 0, 13);
            assert(manifestDependencyNameToken(4) == 10);
            assert(manifestDependencyVersionToken(4) == 13);
            assert(manifestDependencyNextToken(4) == 14);
            assert(manifestDependencyValueStart(starts, 0) == 42);
            assert(manifestDependencyValueLength(lengths, 0) == 11);
            drop(lengths);
            drop(starts);
            drop(arena);
          }
        }
        """);
    var program = new WheelerCompiler().compileModuleFiles(
        sources, "example.package_manifest_dependency_coordinates");

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
