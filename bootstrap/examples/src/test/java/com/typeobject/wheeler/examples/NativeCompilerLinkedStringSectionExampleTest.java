package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for canonical linked bootstrap string sections. */
final class NativeCompilerLinkedStringSectionExampleTest {
  @Test
  void sortsDeduplicatesAndMapsCountedNames() throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        program(), "betaalphabeta".getBytes(StandardCharsets.US_ASCII), 1_048_576);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("firstId"));
    assertEquals(0, machine.global("secondId"));
    assertEquals(1, machine.global("thirdId"));
    assertEquals(1, machine.global("published"));
    assertArrayEquals(expected(), machine.hostOutput());
  }

  @Test
  void rejectsNoncanonicalBootstrapNameBytesBeforePublication() throws Exception {
    byte[] input = "betaalphabeta".getBytes(StandardCharsets.US_ASCII);
    input[0] = 0;
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(), input, 1_048_576);

    assertThrows(
        VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("published"));
  }

  private static byte[] expected() {
    ByteBuffer output = ByteBuffer.allocate(21).order(ByteOrder.LITTLE_ENDIAN);
    output.putInt(2);
    output.putInt(5).put("alpha".getBytes(StandardCharsets.US_ASCII));
    output.putInt(4).put("beta".getBytes(StandardCharsets.US_ASCII));
    return output.array();
  }

  private static Program program() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.linked_string_section"));
    sources.put("LinkedStringSectionExample.w", """
        module example.linked_string_section;

        import wheeler.compiler.closure.linked_string_section;

        classical class LinkedStringSectionExample {
          state long firstId = -1;
          state long secondId = -1;
          state long thirdId = -1;
          state long published = 0;

          entry void main(borrow byteview source, borrow mut bytes output) {
            region rows = new region(/* bytes= */ 393216, /* allocations= */ 3);
            words starts = allocate(rows, /* length= */ 16384);
            words lengths = allocate(rows, /* length= */ 16384);
            words finalRows = allocate(rows, /* length= */ 16384);
            set(starts, 0, 0);
            set(lengths, 0, 4);
            set(starts, 1, 4);
            set(lengths, 1, 5);
            set(starts, 2, 9);
            set(lengths, 2, 4);
            long sectionBytes = emitLinkedStringSection(
              source,
              bufferLength(source),
              /* stringCount= */ 3,
              starts,
              lengths,
              finalRows,
              output
            );
            firstId = finalRows[0];
            secondId = finalRows[1];
            thirdId = finalRows[2];
            published = 1;
            setOutputLength(output, sectionBytes);
            drop(finalRows);
            drop(lengths);
            drop(starts);
            drop(rows);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(sources, "example.linked_string_section");
  }
}
