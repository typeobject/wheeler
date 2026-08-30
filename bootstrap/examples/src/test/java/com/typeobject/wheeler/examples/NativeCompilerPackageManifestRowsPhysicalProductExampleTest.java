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

/** Native evidence for package-manifest fixed-width row capacity. */
final class NativeCompilerPackageManifestRowsPhysicalProductExampleTest {
  private static final String MODULE = "wheeler.compiler.packages.manifest_rows";

  @Tag("closure-evidence")
  @Test
  void compilesManifestRowsByteForByte() throws Exception {
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
  void executesFirstFinalAndOverflowingRows() throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(MODULE));
    sources.put("PackageManifestRowsExample.w", """
        module example.package_manifest_rows;

        import wheeler.compiler.packages.manifest_rows;

        classical class PackageManifestRowsExample {
          entry void main() {
            region output = new region(/* bytes= */ 448, /* allocations= */ 4);
            words targetRows = allocate(output, /* length= */ 20);
            words sourceRows = allocate(output, /* length= */ 4);
            words dependencyRows = allocate(output, /* length= */ 10);
            words capabilityRows = allocate(output, /* length= */ 8);
            assert(manifestTargetRowCapacity(targetRows, 0));
            assert(manifestTargetRowCapacity(targetRows, 1));
            assert(manifestTargetRowCapacity(targetRows, 2) == false);
            assert(manifestSourceRowCapacity(sourceRows, 0));
            assert(manifestSourceRowCapacity(sourceRows, 1));
            assert(manifestSourceRowCapacity(sourceRows, 2) == false);
            assert(manifestDependencyRowCapacity(dependencyRows, 0));
            assert(manifestDependencyRowCapacity(dependencyRows, 1));
            assert(manifestDependencyRowCapacity(dependencyRows, 2) == false);
            assert(manifestCapabilityRowCapacity(capabilityRows, 0));
            assert(manifestCapabilityRowCapacity(capabilityRows, 1));
            assert(manifestCapabilityRowCapacity(capabilityRows, 2) == false);
            drop(capabilityRows);
            drop(dependencyRows);
            drop(sourceRows);
            drop(targetRows);
            drop(output);
          }
        }
        """);
    var program = new WheelerCompiler().compileModuleFiles(
        sources, "example.package_manifest_rows");

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
