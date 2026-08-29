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

/** Native evidence for canonical package-manifest coordinates. */
final class NativeCompilerPackageCanonicalCoordinatesPhysicalProductExampleTest {
  private static final String MODULE = "wheeler.compiler.packages.canonical_coordinates";

  @Tag("closure-evidence")
  @Test
  void compilesCanonicalCoordinatesByteForByte() throws Exception {
    var module = NativeCompilerPhysicalSelection.comparable(MODULE);
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
  void executesLineAndIndentCoordinates() throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(MODULE));
    sources.put("PackageCanonicalCoordinatesExample.w", """
        module example.package_canonical_coordinates;

        import wheeler.compiler.packages.canonical_coordinates;

        classical class PackageCanonicalCoordinatesExample {
          entry void main(borrow utf8 source) {
            assert(canonicalLineEnd(source, 0) == 4);
            assert(canonicalLineEnd(source, 5) == 12);
            assert(canonicalLineEnd(source, 13) == 19);
            assert(canonicalExactIndent(source, 0, 0, 0));
            assert(canonicalExactIndent(source, 5, 7, 2));
            assert(canonicalExactIndent(source, 5, 7, 1) == false);
            assert(canonicalExactIndent(source, 13, 14, 1) == false);
          }
        }
        """);
    var program = new WheelerCompiler().compileModuleFiles(
        sources, "example.package_canonical_coordinates");
    var machine = new VirtualMachine(
        program, "name\n  child\nxchild".getBytes(StandardCharsets.US_ASCII));

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
