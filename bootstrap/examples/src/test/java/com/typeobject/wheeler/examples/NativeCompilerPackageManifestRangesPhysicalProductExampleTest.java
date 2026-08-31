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

/** Native evidence for quoted package-manifest ranges. */
final class NativeCompilerPackageManifestRangesPhysicalProductExampleTest {
  private static final String MODULE = "wheeler.compiler.packages.manifest_ranges";

  @Tag("closure-evidence")
  @Test
  void compilesManifestRangesByteForByte() throws Exception {
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
  void executesInteriorStartAndLengthProjections() throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(MODULE));
    sources.put("PackageManifestRangesExample.w", """
        module example.package_manifest_ranges;

        import wheeler.compiler.packages.manifest_ranges;

        classical class PackageManifestRangesExample {
          entry void main() {
            region tokens = new region(/* bytes= */ 96, /* allocations= */ 2);
            words starts = allocate(tokens, /* length= */ 2);
            words lengths = allocate(tokens, /* length= */ 2);
            set(starts, 0, 4);
            set(starts, 1, 20);
            set(lengths, 0, 6);
            set(lengths, 1, 10);
            assert(manifestQuotedStart(starts, 0) == 5);
            assert(manifestQuotedStart(starts, 1) == 21);
            assert(manifestQuotedLength(lengths, 0) == 4);
            assert(manifestQuotedLength(lengths, 1) == 8);
            drop(lengths);
            drop(starts);
            drop(tokens);
          }
        }
        """);
    var program = new WheelerCompiler().compileModuleFiles(
        sources, "example.package_manifest_ranges");

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
