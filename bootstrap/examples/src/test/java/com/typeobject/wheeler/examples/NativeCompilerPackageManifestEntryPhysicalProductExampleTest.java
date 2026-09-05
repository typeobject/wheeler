package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/** Physical evidence for complete dependency and capability entry publication. */
final class NativeCompilerPackageManifestEntryPhysicalProductExampleTest {
  @Tag("closure-evidence")
  @Test
  void retainsEntriesCapacitiesAndCoordinatesWithExactCallTargets() throws Exception {
    var comparable = List.of(
        NativeCompilerPhysicalSelection.comparable("wheeler.compiler.packages.manifest_rows"),
        NativeCompilerPhysicalSelection.comparable(
            "wheeler.compiler.packages.manifest_dependency_coordinates"),
        NativeCompilerPhysicalSelection.comparable(
            "wheeler.compiler.packages.manifest_capability_coordinates"));
    var callable = List.of(
        NativeCompilerPhysicalSelection.callable("wheeler.compiler.packages.manifest_dependency"),
        NativeCompilerPhysicalSelection.callable("wheeler.compiler.packages.manifest_capability"));
    ByteArrayOutputStream prefix = new ByteArrayOutputStream();
    for (var module : comparable) {
      prefix.writeBytes(new BytecodeWriter().write(
          new WheelerCompiler().compileLibraryModuleFiles(
              CompilerSources.moduleClosure(module.name()), module.name())));
    }
    Map<String, Program> references = new LinkedHashMap<>();
    for (var module : callable) {
      references.put(module.name(), new WheelerCompiler().compileLibraryModuleFiles(
          CompilerSources.moduleClosure(module.name()), module.name()));
    }
    var manifest = CompilerSources.bootstrapModuleManifest();
    var machine = VirtualMachine.withBinaryInput(
        NativeCompilerArchiveClosureProgram.program(true, comparable, callable),
        framed(CompilerSources.packageArchive(), manifest.canonicalBytes()),
        prefix.size() + 1_048_576);
    try {
      CompilerMachineRunner.runWithoutRewindHistory(machine);
    } catch (VmTrap failure) {
      int owner = Math.toIntExact(machine.global("physicalModuleOwner"));
      throw new AssertionError("physical module " + manifest.modules().get(owner).name(), failure);
    }

    byte[] transport = machine.hostOutput();
    assertEquals(1, machine.global("published"));
    assertEquals(comparable.size(), machine.global("physicalModuleProductCount"));
    assertEquals(callable.size(), machine.global("physicalCallableProductCount"));
    assertEquals(prefix.size(), machine.global("physicalModuleProductLength"));
    assertArrayEquals(prefix.toByteArray(), Arrays.copyOf(transport, prefix.size()));
    assertEquals(29, machine.global("physicalCallableRelocationCount"));
    assertEquals(29, machine.global("physicalResolvedCallableTargetCount"));
    NativeCompilerPhysicalProductAssertions.assertCallables(manifest, references, transport);

    byte[] misbound = transport.clone();
    int lastTarget = misbound.length - 9;
    assertTrue(0 < Byte.toUnsignedInt(misbound[lastTarget]));
    misbound[lastTarget] -= 1;
    assertThrows(AssertionError.class,
        () -> NativeCompilerPhysicalProductAssertions.assertCallables(manifest, references, misbound));
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
