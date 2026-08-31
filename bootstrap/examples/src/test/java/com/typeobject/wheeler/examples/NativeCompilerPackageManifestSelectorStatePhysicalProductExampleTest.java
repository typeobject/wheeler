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

/** Native evidence for package-manifest selector scalar state. */
final class NativeCompilerPackageManifestSelectorStatePhysicalProductExampleTest {
  private static final String MODULE = "wheeler.compiler.packages.manifest_selector_state";

  @Tag("closure-evidence")
  @Test
  void compilesManifestSelectorStateByteForByte() throws Exception {
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
  void executesLengthEqualityAndCompletionStates() throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(MODULE));
    sources.put("PackageManifestSelectorStateExample.w", """
        module example.package_manifest_selector_state;

        import wheeler.compiler.packages.manifest_selector_state;

        classical class PackageManifestSelectorStateExample {
          entry void main() {
            assert(manifestSelectorLengthKind(3, 2) == -1);
            assert(manifestSelectorLengthKind(2, 3) == 0);
            assert(manifestSelectorLengthKind(3, 3) == 1);
            assert(manifestSelectorSame(true, 97, 97));
            assert(manifestSelectorSame(true, 96, 97) == false);
            assert(manifestSelectorSame(true, 98, 97) == false);
            assert(manifestSelectorSame(false, 97, 97) == false);
            assert(manifestSelectorComplete(1, 0));
            assert(manifestSelectorComplete(0, 47));
            assert(manifestSelectorComplete(0, 48) == false);
          }
        }
        """);
    var program = new WheelerCompiler().compileModuleFiles(
        sources, "example.package_manifest_selector_state");

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
