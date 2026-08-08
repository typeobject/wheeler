package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence from canonical source-local strings through linked emission. */
final class NativeCompilerCompiledStringProductsExampleTest {
  @Test
  void decodesAndReemitsOneCanonicalStringSection() throws Exception {
    byte[] artifact = artifact();
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(), artifact, 1_048_576);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(stringCount(artifact), machine.global("stringCount"));
    assertEquals(1, machine.global("published"));
    assertArrayEquals(stringSection(artifact), machine.hostOutput());
  }

  @Test
  void rejectsMalformedStringLengthsBeforePublication() throws Exception {
    byte[] artifact = artifact();
    int start = sectionStart(artifact, 2);
    ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN).putInt(start + 4, 0);
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(), artifact, 1_048_576);

    assertThrows(
        VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("published"));
  }

  private static byte[] artifact() {
    String source = """
        module fixture.compiled_strings;

        classical class CompiledStrings {
          public record Pair(long left, boolean ready) {}

          public long identity(long value) {
            return value;
          }
        }
        """;
    return new BytecodeWriter().write(new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("CompiledStrings.w", source), "fixture.compiled_strings"));
  }

  private static int stringCount(byte[] artifact) {
    return ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN)
        .getInt(sectionStart(artifact, 2));
  }

  private static byte[] stringSection(byte[] artifact) {
    ByteBuffer bytes = ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN);
    int directory = sectionDirectory(artifact, 2);
    int start = Math.toIntExact(bytes.getLong(directory + 8));
    int length = Math.toIntExact(bytes.getLong(directory + 16));
    return Arrays.copyOfRange(artifact, start, start + length);
  }

  private static int sectionStart(byte[] artifact, int type) {
    int directory = sectionDirectory(artifact, type);
    return Math.toIntExact(ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN)
        .getLong(directory + 8));
  }

  private static int sectionDirectory(byte[] artifact, int type) {
    ByteBuffer bytes = ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN);
    int count = bytes.getInt(24);
    for (int index = 0; index < count; index++) {
      int directory = 40 + index * 32;
      if (bytes.getInt(directory) == type) {
        return directory;
      }
    }
    throw new AssertionError("missing section " + type);
  }

  private static Program program() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_string_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.linked_string_section"));
    sources.put("CompiledStringProductsExample.w", """
        module example.compiled_string_products;

        import wheeler.compiler.closure.compiled_string_products;
        import wheeler.compiler.closure.linked_string_section;

        classical class CompiledStringProductsExample {
          state long stringCount = 0;
          state long published = 0;

          entry void main(borrow byteview source, borrow mut bytes output) {
            region rows = new region(/* bytes= */ 524288, /* allocations= */ 4);
            words artifactRanks = allocate(rows, /* length= */ 16384);
            words starts = allocate(rows, /* length= */ 16384);
            words lengths = allocate(rows, /* length= */ 16384);
            words finalRows = allocate(rows, /* length= */ 16384);
            CompiledStringPlan plan = appendCompiledStringProducts(
              source,
              bufferLength(source),
              /* artifactBase= */ 0,
              /* artifactRank= */ 0,
              /* closureStringCount= */ 0,
              artifactRanks,
              starts,
              lengths
            );
            stringCount = plan.stringCount;
            long sectionBytes = emitLinkedStringSection(
              source,
              bufferLength(source),
              plan.closureStringCount,
              starts,
              lengths,
              finalRows,
              output
            );
            published = 1;
            setOutputLength(output, sectionBytes);
            drop(finalRows);
            drop(lengths);
            drop(starts);
            drop(artifactRanks);
            drop(rows);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(sources, "example.compiled_string_products");
  }
}
