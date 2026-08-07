package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
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
    assertTrue(source.contains("private const long MAX_SOURCE_BYTES = 32768;"));
    assertTrue(source.contains("private const long SOURCE_BYTE_LIMIT = 32769;"));
    String copyLoops = CompilerSources.read("compiler/syntax/loops/OwnedUtf8CopyLoops.w");
    assertTrue(copyLoops.contains("public const long COPY_LOOP_LIMIT_SCALE = 65536;"));

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

  @Test
  void copiesTheCompletePhysicalSourceWindow() throws Exception {
    String sources = CompilerSources.read("compiler/graphs/Sources.w");
    String root = """
        module example.graph_source_boundary;

        import wheeler.compiler.graphs.sources;

        classical class GraphSourceBoundary {
          entry void main(borrow utf8 source, borrow mut bytes output) {
            region arena = new region(/* bytes= */ 32768, /* allocations= */ 1);
            utf8 copied = copySelectedSource(
              0,
              2,
              source,
              source,
              source,
              source,
              source,
              source,
              source,
              arena
            );
            assert(bufferLength(copied) == 32768);
            setByte(output, 0, 1);
            drop(copied);
            drop(arena);
          }
        }
        """;
    Program copier = new WheelerCompiler().compileModuleFiles(
        Map.of("Sources.w", sources, "GraphSourceBoundary.w", root),
        "example.graph_source_boundary");

    byte[] accepted = "a".repeat(32_768).getBytes(StandardCharsets.UTF_8);
    VirtualMachine machine = new VirtualMachine(copier, accepted, 1);
    machine.run();
    assertArrayEquals(new byte[] {1}, machine.hostOutput());

    byte[] rejected = "a".repeat(32_769).getBytes(StandardCharsets.UTF_8);
    VirtualMachine oversized = new VirtualMachine(copier, rejected, 1);
    assertThrows(VmTrap.class, oversized::run);
    assertArrayEquals(new byte[1], oversized.hostOutput());
  }

  private static void assertRejected(String source) throws Exception {
    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(), List.of(), source);
  }
}
