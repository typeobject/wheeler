package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/** One archive pass compares exact words, scalar decoding, keys, and layout consumers. */
final class NativeCompilerPackageManifestWordsPhysicalProductExampleTest {
  @Tag("closure-evidence")
  @Test
  void retainsExactWordsWithCompleteBodiesAndCallTargets() throws Exception {
    var comparable = List.of(
        NativeCompilerPhysicalSelection.comparable("wheeler.compiler.packages.manifest_words"));
    var prefix = new ByteArrayOutputStream();
    for (var module : comparable) {
      byte[] artifact = new BytecodeWriter().write(new WheelerCompiler().compileLibraryModuleFiles(
          CompilerSources.moduleClosure(module.name()), module.name()));
      assertTrue(artifact.length <= 32768, module.name() + " exceeds the retained module buffer");
      prefix.writeBytes(artifact);
    }
    var callable = List.of(
        NativeCompilerPhysicalSelection.callable("wheeler.compiler.packages.canonical_indent"),
        NativeCompilerPhysicalSelection.callable("wheeler.compiler.packages.manifest_header_state"),
        NativeCompilerPhysicalSelection.callable("wheeler.compiler.packages.manifest_keys"),
        NativeCompilerPhysicalSelection.callable("wheeler.compiler.packages.manifest_kinds"),
        NativeCompilerPhysicalSelection.callable("wheeler.compiler.packages.manifest_tokens"));
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
    var program = NativeCompilerArchiveClosureProgram.program(true, comparable, callable);
    var machine = VirtualMachine.withBinaryInput(program, input, prefix.size() + 1_048_576);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    byte[] transport = machine.hostOutput();
    assertEquals(1, machine.global("published"));
    assertEquals(1, machine.global("physicalModuleProductCount"));
    assertEquals(5, machine.global("physicalCallableProductCount"));
    assertEquals(prefix.size(), machine.global("physicalModuleProductLength"));
    assertArrayEquals(prefix.toByteArray(), Arrays.copyOf(transport, prefix.size()));
    assertEquals(9, machine.global("physicalCallableRelocationCount"));
    assertEquals(9, machine.global("physicalResolvedCallableTargetCount"));
    NativeCompilerPhysicalProductAssertions.assertCallables(manifest, references, transport);
  }
}
