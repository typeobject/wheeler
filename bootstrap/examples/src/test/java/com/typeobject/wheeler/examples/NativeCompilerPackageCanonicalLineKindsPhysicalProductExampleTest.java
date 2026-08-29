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

/** Native evidence for canonical package-manifest line kinds. */
final class NativeCompilerPackageCanonicalLineKindsPhysicalProductExampleTest {
  private static final String MODULE = "wheeler.compiler.packages.canonical_line_kinds";

  @Tag("closure-evidence")
  @Test
  void compilesCanonicalLineKindsByteForByte() throws Exception {
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
  void executesClosedLineKinds() throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(MODULE));
    sources.put("PackageCanonicalLineKindsExample.w", """
        module example.package_canonical_line_kinds;

        import wheeler.compiler.packages.canonical_line_kinds;

        classical class PackageCanonicalLineKindsExample {
          entry void main() {
            assert(canonicalPlainLineTokenCount(2));
            assert(canonicalPlainLineTokenCount(3));
            assert(canonicalPlainLineTokenCount(4));
            assert(canonicalPlainLineTokenCount(1) == false);
            assert(canonicalPlainLineTokenCount(5) == false);
            assert(canonicalDashedLineTokenCount(2));
            assert(canonicalDashedLineTokenCount(4));
            assert(canonicalDashedLineTokenCount(3) == false);
            assert(canonicalFinalLineToken(10, 4) == 13);
          }
        }
        """);
    var program = new WheelerCompiler().compileModuleFiles(
        sources, "example.package_canonical_line_kinds");

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
