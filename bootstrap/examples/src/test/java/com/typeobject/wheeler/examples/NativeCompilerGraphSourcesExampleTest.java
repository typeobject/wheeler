package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Opcode;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential evidence for bounded canonical graph-source copying. */
final class NativeCompilerGraphSourcesExampleTest {
  @Test
  void compilesThePhysicalGraphSourceOwnerByteForByte() throws Exception {
    String source = CompilerSources.read("compiler/graphs/Sources.w");
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            Map.of("Sources.w", source),
            "wheeler.compiler.graphs.sources"));
    byte[] actual = NativeModuleCompilerHarness.compile(
        NativeModuleCompilerHarness.program(), List.of(), source);
    assertArrayEquals(expected, actual);

    var program = new BytecodeReader().read(actual);
    assertEquals(3, program.functions().size());
    var copy = program.functions().getFirst();
    assertEquals(1, copy.forward().stream()
        .filter(instruction -> instruction.opcode() == Opcode.LOCAL_LOOP_CHECK)
        .count());
    assertEquals(1, copy.forward().stream()
        .filter(instruction -> instruction.opcode() == Opcode.BYTES_SET)
        .count());
    assertEquals(1, copy.forward().stream()
        .filter(instruction -> instruction.opcode() == Opcode.UTF8_FREEZE)
        .count());
    var selection = program.functions().get(1);
    assertEquals(8, selection.forward().stream()
        .filter(instruction -> instruction.opcode() == Opcode.CALL_VALUE)
        .count());

    assertRejected(source.replace("cursor += 1;", "cursor += 2;"));
    assertRejected(source.replace(
        "utf8Scalar(source, cursor)",
        "bufferLength(source)"));
    assertRejected(source.replace(
        "copySource(firstSource, arena)",
        "copySource(index, arena)"));
  }

  private static void assertRejected(String source) throws Exception {
    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(), List.of(), source);
  }
}
