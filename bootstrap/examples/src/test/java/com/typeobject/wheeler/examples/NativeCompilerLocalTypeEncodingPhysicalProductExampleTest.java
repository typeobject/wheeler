package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Arrays;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/** Native evidence for direct root byte-mutation products. */
final class NativeCompilerLocalTypeEncodingPhysicalProductExampleTest {
  @Tag("closure-evidence")
  @Test
  void compilesRootByteMutationsByteForByte() throws Exception {
    var module = NativeCompilerArchiveClosureProgram.PHYSICAL_LOCAL_TYPE_ENCODING_MODULE;
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            CompilerSources.moduleClosure(module.name()), module.name()));
    var productProgram = NativeCompilerArchiveClosureProgram.physicalProductProgram(module);
    var manifest = CompilerSources.bootstrapModuleManifest();
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        productProgram,
        framed(CompilerSources.packageArchive(), manifest.canonicalBytes()),
        expected.length + 1_048_576);

    try {
      CompilerMachineRunner.runWithoutRewindHistory(machine);
    } catch (RuntimeException exception) {
      var frames = machine.snapshot().selectedFrames().stream()
          .map(frame -> {
            var function = productProgram.function(frame.functionId());
            var instruction = function.forward().get(frame.programCounter());
            int center = instruction.operands().isEmpty()
                ? 0
                : Math.toIntExact(instruction.operands().getFirst().longValue());
            int first = Math.max(0, Math.min(center - 4, frame.localCount()));
            int end = Math.max(first, Math.min(center + 1, frame.localCount()));
            return function.name() + "@" + frame.programCounter()
                + " locals=" + frame.locals().subList(first, end);
          })
          .toList();
      throw new AssertionError(frames.toString(), exception);
    }

    assertEquals(1, machine.global("published"));
    assertArrayEquals(expected, Arrays.copyOf(machine.hostOutput(), expected.length));
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
