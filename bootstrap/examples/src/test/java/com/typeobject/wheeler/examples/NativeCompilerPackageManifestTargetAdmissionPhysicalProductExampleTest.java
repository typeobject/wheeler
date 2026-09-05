package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/** One archive pass compares complete target admission and its head, source, and tail owners. */
final class NativeCompilerPackageManifestTargetAdmissionPhysicalProductExampleTest {
  @Tag("closure-evidence")
  @Test
  void retainsTargetAdmissionWithExactCallTargets() throws Exception {
    var coordinates = NativeCompilerPhysicalSelection.comparable(
        "wheeler.compiler.packages.manifest_target_coordinates");
    byte[] prefix = new BytecodeWriter().write(new WheelerCompiler().compileLibraryModuleFiles(
        CompilerSources.moduleClosure(coordinates.name()), coordinates.name()));
    var callable = List.of(
        NativeCompilerPhysicalSelection.callable("wheeler.compiler.packages.manifest_target_admission"),
        NativeCompilerPhysicalSelection.callable("wheeler.compiler.packages.manifest_target_head"),
        NativeCompilerPhysicalSelection.callable("wheeler.compiler.packages.manifest_target_module_head"),
        NativeCompilerPhysicalSelection.callable(
            "wheeler.compiler.packages.manifest_target_source_collection"),
        NativeCompilerPhysicalSelection.callable("wheeler.compiler.packages.manifest_target_tail"));
    Map<String, Program> references = new LinkedHashMap<>();
    for (var module : callable) {
      references.put(module.name(), new WheelerCompiler().compileLibraryModuleFiles(
          CompilerSources.moduleClosure(module.name()), module.name()));
    }
    var manifest = CompilerSources.bootstrapModuleManifest();
    byte[] archive = CompilerSources.packageArchive();
    byte[] input = ByteBuffer.allocate(4 + archive.length + manifest.canonicalBytes().length)
        .order(ByteOrder.LITTLE_ENDIAN)
        .putInt(archive.length).put(archive).put(manifest.canonicalBytes()).array();
    var program = NativeCompilerArchiveClosureProgram.program(true, List.of(coordinates), callable);
    var machine = VirtualMachine.withBinaryInput(program, input, prefix.length + 1_048_576);
    try {
      CompilerMachineRunner.runWithoutRewindHistory(machine);
    } catch (VmTrap failure) {
      int owner = Math.toIntExact(machine.global("physicalModuleOwner"));
      throw new AssertionError("physical module " + manifest.modules().get(owner).name(), failure);
    }

    byte[] transport = machine.hostOutput();
    assertEquals(1, machine.global("published"));
    assertEquals(1, machine.global("physicalModuleProductCount"));
    assertEquals(5, machine.global("physicalCallableProductCount"));
    assertEquals(prefix.length, machine.global("physicalModuleProductLength"));
    assertArrayEquals(prefix, Arrays.copyOf(transport, prefix.length));
    assertEquals(35, machine.global("physicalCallableRelocationCount"));
    assertEquals(35, machine.global("physicalResolvedCallableTargetCount"));
    NativeCompilerPhysicalProductAssertions.assertCallables(manifest, references, transport);
  }
}
