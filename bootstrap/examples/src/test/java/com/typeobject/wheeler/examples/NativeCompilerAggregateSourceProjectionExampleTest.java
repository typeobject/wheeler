package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for offset-stable aggregate declaration projection. */
final class NativeCompilerAggregateSourceProjectionExampleTest {
  private static final String SOURCE = """
      module example.aggregate_projection;

      public record Pair(long left, long right) {}
      public variant Maybe { None, Some(long value) }

      classical class Example { public long value() { return 1; } }
      """.strip();

  @Test
  void blanksDeclarationsWithoutMovingNewlinesOrFollowingSource() throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        program(false), SOURCE.getBytes(StandardCharsets.UTF_8), 32_768);

    machine.run();

    assertEquals(1, machine.global("valid"));
    byte[] output = machine.hostOutput();
    int recordStart = SOURCE.indexOf("public record");
    int recordEnd = SOURCE.indexOf('\n', recordStart);
    int variantStart = SOURCE.indexOf("public variant");
    int variantEnd = SOURCE.indexOf('\n', variantStart);
    for (int index = 0; index < SOURCE.length(); index++) {
      int expected = SOURCE.charAt(index);
      if ((recordStart <= index && index < recordEnd)
          || (variantStart <= index && index < variantEnd)) {
        expected = ' ';
      }
      assertEquals(expected, Byte.toUnsignedInt(output[index]), "offset=" + index);
    }
  }

  @Test
  void rejectsOverlappingDeclarationRangesBeforeMutation() throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        program(true), SOURCE.getBytes(StandardCharsets.UTF_8), 32_768);

    assertThrows(VmTrap.class, machine::run);

    assertEquals(0xee, machine.hostOutput()[0] & 0xff);
  }

  private static Program program(boolean overlap) throws Exception {
    int recordStart = SOURCE.indexOf("public record");
    int recordEnd = SOURCE.indexOf('\n', recordStart);
    int variantStart = SOURCE.indexOf("public variant");
    int variantEnd = SOURCE.indexOf('\n', variantStart);
    if (overlap) {
      variantStart = recordStart;
    }
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.aggregate_source_projection"));
    sources.put("AggregateSourceProjectionExample.w", """
        module example.aggregate_source_projection;

        import wheeler.compiler.closure.aggregate_source_projection;

        classical class AggregateSourceProjectionExample {
          state long valid = 0;
          state long firstOutputByte = 0;

          entry void main(borrow byteview input, borrow mut bytes output) {
            region products = new region(/* bytes= */ 6656, /* allocations= */ 1);
            words aggregates = allocate(products, /* length= */ 832);
            set(aggregates, 0, 1);
            set(aggregates, 512, %d);
            set(aggregates, 768, %d);
            set(aggregates, 1, 4);
            set(aggregates, 513, %d);
            set(aggregates, 769, %d);
            setByte(output, 0, 0xee);
            long length = writeSourceWithoutAggregateDeclarations(
              input,
              /* sourceStart= */ 0,
              bufferLength(input),
              /* aggregateCount= */ 2,
              aggregates,
              output
            );
            if (length == bufferLength(input)) {
              valid = 1;
            }
            firstOutputByte = output[0];
            drop(aggregates);
            drop(products);
          }
        }
        """.formatted(recordStart, recordEnd, variantStart, variantEnd));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.aggregate_source_projection");
  }
}
