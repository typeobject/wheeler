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

/** Native evidence for canonical package-manifest section and indent policy. */
final class NativeCompilerPackageCanonicalIndentPhysicalProductExampleTest {
  private static final String MODULE = "wheeler.compiler.packages.canonical_indent";

  @Tag("closure-evidence")
  @Test
  void compilesCanonicalIndentPolicyByteForByte() throws Exception {
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
  void executesClosedSectionAndIndentPolicy() throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(MODULE));
    sources.put("PackageCanonicalIndentExample.w", """
        module example.package_canonical_indent;

        import wheeler.compiler.packages.canonical_indent;

        classical class PackageCanonicalIndentExample {
          entry void main() {
            long dependencies = 2626680644436426025;
            long development = 2597989917310390198;
            assert(canonicalManifestSection(0, 0, 0) == 0);
            assert(canonicalManifestSection(5, 0, 0) == 1);
            assert(canonicalManifestSection(6, dependencies, 1) == 2);
            assert(canonicalManifestSection(7, development, 2) == 3);
            assert(canonicalManifestSection(8, 0, 2) == 2);
            assert(canonicalManifestIndent(0, 0, 0, 0) == 0);
            assert(canonicalManifestIndent(2, 0, 0, 0) == 2);
            assert(canonicalManifestIndent(5, 0, 0, 0) == 0);
            assert(canonicalManifestIndent(6, dependencies, 0, 0) == 0);
            assert(canonicalManifestIndent(7, development, 0, 0) == 0);
            assert(canonicalManifestIndent(8, 0, 3, 2) == 6);
            assert(canonicalManifestIndent(8, 0, 3, 4) == 2);
            assert(canonicalManifestIndent(8, 0, 1, 2) == 4);
          }
        }
        """);
    var program = new WheelerCompiler().compileModuleFiles(
        sources, "example.package_canonical_indent");

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
