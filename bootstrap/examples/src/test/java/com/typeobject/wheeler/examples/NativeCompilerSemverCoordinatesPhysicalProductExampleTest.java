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

/** Native evidence for direct semantic-version coordinate products. */
final class NativeCompilerSemverCoordinatesPhysicalProductExampleTest {
  @Tag("closure-evidence")
  @Test
  void compilesSemverCoordinatesByteForByte() throws Exception {
    var module = NativeCompilerPhysicalSelection.comparable(
        "wheeler.compiler.packages.semver_coordinates");
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            CompilerSources.moduleClosure(module.name()), module.name()));
    var productProgram = NativeCompilerPhysicalPrograms.comparable(module);
    byte[] archive = CompilerSources.packageArchive();
    byte[] manifest = CompilerSources.bootstrapModuleManifest().canonicalBytes();
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        productProgram,
        framed(archive, manifest),
        expected.length + 1_048_576);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("published"));
    assertArrayEquals(expected, Arrays.copyOf(machine.hostOutput(), expected.length));
    assertEquals(expected.length, machine.global("physicalModuleProductLength"));
  }

  @Test
  void executesBoundedSemverCoordinates() throws Exception {
    String coordinates = CompilerSources.read("compiler/packages/semver/SemverCoordinates.w");
    String root = """
        module example.semver_coordinates;

        import wheeler.compiler.packages.semver_coordinates;

        classical class SemverCoordinateExample {
          entry void main(borrow utf8 source) {
            assert(semverCoreComponent(source, 0, 16, 0) == 10);
            assert(semverCoreComponent(source, 0, 16, 1) == 20);
            assert(semverCoreComponent(source, 0, 16, 2) == 30);
            long prerelease = semverPrereleaseStart(source, 0, 16);
            assert(prerelease == 9);
            long firstEnd = semverIdentifierEnd(source, prerelease, 16);
            assert(firstEnd == 14);
            assert(semverIdentifierEnd(source, firstEnd + 1, 16) == 16);
          }
        }
        """;
    var sources = new LinkedHashMap<String, String>();
    sources.put("SemverCoordinates.w", coordinates);
    sources.put("SemverCoordinateExample.w", root);
    var program = new WheelerCompiler().compileModuleFiles(
        sources, "example.semver_coordinates");
    var machine = new VirtualMachine(
        program, "10.20.30-alpha.7".getBytes(StandardCharsets.US_ASCII));

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
