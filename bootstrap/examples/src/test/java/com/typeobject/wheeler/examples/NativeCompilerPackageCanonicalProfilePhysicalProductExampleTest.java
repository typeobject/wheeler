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

/** Native evidence for canonical package-manifest bounds and completion. */
final class NativeCompilerPackageCanonicalProfilePhysicalProductExampleTest {
  private static final String MODULE = "wheeler.compiler.packages.canonical_profile";

  @Tag("closure-evidence")
  @Test
  void compilesCanonicalProfileByteForByte() throws Exception {
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
  void executesBoundsAndCompletion() throws Exception {
    executeBounds("name\n", true);
    executeBounds("name", false);
    executeBounds("", false);
  }

  private static void executeBounds(String input, boolean expected) throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(MODULE));
    sources.put("PackageCanonicalProfileExample.w", """
        module example.package_canonical_profile;

        import wheeler.compiler.packages.canonical_profile;

        classical class PackageCanonicalProfileExample {
          entry void main(borrow utf8 source) {
            assert(canonicalManifestBounds(source) == %s);
            assert(canonicalManifestComplete(4, 4, 3));
            assert(canonicalManifestComplete(3, 4, 3) == false);
            assert(canonicalManifestComplete(4, 4, 2) == false);
          }
        }
        """.formatted(expected));
    var program = new WheelerCompiler().compileModuleFiles(
        sources, "example.package_canonical_profile");

    new VirtualMachine(program, input.getBytes(StandardCharsets.US_ASCII)).run();
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
