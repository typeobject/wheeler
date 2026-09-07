package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Arrays;
import java.util.List;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/** One archive pass compares complete Boolean assertion and signed ordering owners. */
final class NativeCompilerResolvedAssertionRangesPhysicalProductExampleTest {
  @Tag("closure-evidence")
  @Test
  void compilesResolvedAssertionRangesByteForByte() throws Exception {
    var modules = List.of(
        NativeCompilerPhysicalSelection.comparable("wheeler.compiler.resolved_boolean_literal_assertions"),
        NativeCompilerPhysicalSelection.comparable("wheeler.compiler.resolved_boolean_literal_comparisons"),
        NativeCompilerPhysicalSelection.comparable("wheeler.compiler.signed_ordering_kinds"));
    var expected = new ByteArrayOutputStream();
    for (var module : modules) {
      byte[] artifact = new BytecodeWriter().write(new WheelerCompiler().compileLibraryModuleFiles(
          CompilerSources.moduleClosure(module.name()), module.name()));
      assertTrue(artifact.length <= 32_768, module.name());
      expected.writeBytes(artifact);
    }
    var program = NativeCompilerArchiveClosureProgram.program(true, modules, List.of());
    byte[] archive = CompilerSources.packageArchive();
    byte[] manifest = CompilerSources.bootstrapModuleManifest().canonicalBytes();
    byte[] input = ByteBuffer.allocate(4 + archive.length + manifest.length).order(ByteOrder.LITTLE_ENDIAN)
        .putInt(archive.length).put(archive).put(manifest).array();
    var machine = VirtualMachine.withBinaryInput(program, input, expected.size() + 1_048_576);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    assertEquals(1, machine.global("published"));
    assertEquals(3, machine.global("physicalModuleProductCount"));
    assertEquals(0, machine.global("physicalCallableProductCount"));
    assertEquals(expected.size(), machine.global("physicalModuleProductLength"));
    assertArrayEquals(expected.toByteArray(), Arrays.copyOf(machine.hostOutput(), expected.size()));
  }
}
