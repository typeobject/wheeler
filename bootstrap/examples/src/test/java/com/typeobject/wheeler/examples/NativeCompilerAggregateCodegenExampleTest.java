package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for canonical aggregate instruction code generation. */
final class NativeCompilerAggregateCodegenExampleTest {
  @Test
  void emitsEveryAggregateConstructionAndProjectionFormCanonically() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false), new byte[0], 344);

    machine.run();

    byte[] code = machine.hostOutput();
    assertEquals(344, code.length);
    List<DecodedInstruction> decoded = decode(code);
    assertEquals(List.of(
        new DecodedInstruction(0x0500, List.of(3L, 0L, 2L, 1L)),
        new DecodedInstruction(0x0501, List.of(6L, 5L, 0L)),
        new DecodedInstruction(0x0510, List.of(3L, 0L, 1L, 2L, 1L)),
        new DecodedInstruction(0x0511, List.of(6L, 5L, 1L)),
        new DecodedInstruction(0x0512, List.of(6L, 5L, 1L, 0L)),
        new DecodedInstruction(0x0520, List.of(3L, 0L, 2L, 1L)),
        new DecodedInstruction(0x0521, List.of(6L, 5L, 0L)),
        new DecodedInstruction(0x0530, List.of(3L, 0L, 5L, 1L, 2L)),
        new DecodedInstruction(0x0531, List.of(6L, 5L, 0L))), decoded);

    Program stageZero = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("Record.w", """
            module example.record;
            classical class Record {
              record Pair(long value) {}
              private long use(long value) {
                Pair pair = new Pair(value);
                return pair.value;
              }
            }
            """),
        "example.record");
    var aggregateInstructions = stageZero.functions().getFirst().forward().stream()
        .filter(instruction -> instruction.opcode() == Opcode.RECORD_NEW
            || instruction.opcode() == Opcode.RECORD_GET)
        .toList();
    assertEquals(aggregateInstructions.get(0).opcode().code(), decoded.get(0).opcode());
    assertEquals(aggregateInstructions.get(0).operands(), decoded.get(0).operands());
    assertEquals(aggregateInstructions.get(1).opcode().code(), decoded.get(1).opcode());
    assertEquals(aggregateInstructions.get(1).operands(), decoded.get(1).operands());
  }

  @Test
  void rejectsInvalidOperandsBeforeWritingAHeader() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true), new byte[0], 40);

    assertThrows(VmTrap.class, machine::run);
    assertArrayEquals(new byte[40], machine.hostOutput());
  }

  private static Program program(boolean invalid) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.aggregate_codegen"));
    sources.put("AggregateCodegenExample.w", """
        module example.aggregate_codegen;

        import wheeler.compiler.aggregate_codegen;

        classical class AggregateCodegenExample {
          entry void main(borrow utf8 input, borrow mut bytes output) {
            long cursor = 0;
            if (%s) {
              cursor = writeRecordConstruction(output, cursor, 3, 0, 2, -1);
            } else {
              cursor = writeRecordConstruction(output, cursor, 3, 0, 2, 1);
              cursor = writeRecordProjection(output, cursor, 6, 5, 0);
              cursor = writeVariantConstruction(output, cursor, 3, 0, 1, 2, 1);
              cursor = writeVariantCaseTest(output, cursor, 6, 5, 1);
              cursor = writeVariantProjection(output, cursor, 6, 5, 1, 0);
              cursor = writeArrayConstruction(output, cursor, 3, 0, 2, 1);
              cursor = writeArrayProjection(output, cursor, 6, 5, 0);
              cursor = writeSliceConstruction(output, cursor, 3, 0, 5, 1, 2);
              cursor = writeSliceProjection(output, cursor, 6, 5, 0);
              setOutputLength(output, cursor);
            }
          }
        }
        """.formatted(invalid));
    return new WheelerCompiler().compileModuleFiles(sources, "example.aggregate_codegen");
  }

  private static List<DecodedInstruction> decode(byte[] code) {
    ByteBuffer input = ByteBuffer.wrap(code).order(ByteOrder.LITTLE_ENDIAN);
    java.util.ArrayList<DecodedInstruction> instructions = new java.util.ArrayList<>();
    while (input.hasRemaining()) {
      int opcode = Short.toUnsignedInt(input.getShort());
      int operandCount = Short.toUnsignedInt(input.getShort());
      assertEquals(8 + operandCount * 8, input.getInt());
      java.util.ArrayList<Long> operands = new java.util.ArrayList<>();
      for (int operand = 0; operand < operandCount; operand++) {
        operands.add(input.getLong());
      }
      instructions.add(new DecodedInstruction(opcode, operands));
    }
    return List.copyOf(instructions);
  }

  private record DecodedInstruction(int opcode, List<Long> operands) {}
}
