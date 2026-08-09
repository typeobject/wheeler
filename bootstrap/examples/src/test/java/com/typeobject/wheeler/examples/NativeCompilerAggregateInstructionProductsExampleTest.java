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
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for counted aggregate instruction products. */
final class NativeCompilerAggregateInstructionProductsExampleTest {
  @Test
  void lowersACountedOperationWindowIntoCanonicalBytes() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false), new byte[0], 344);

    machine.run();

    assertEquals(9, machine.global("instructionCount"));
    assertEquals(344, machine.global("length"));
    assertEquals(
        List.of(0x0500, 0x0501, 0x0510, 0x0511, 0x0512,
            0x0520, 0x0521, 0x0530, 0x0531),
        opcodes(machine.hostOutput()));
  }

  @Test
  void rejectsTheCompleteWindowBeforeOutputMutation() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true), new byte[0], 344);

    assertThrows(VmTrap.class, machine::run);
    assertArrayEquals(new byte[344], machine.hostOutput());
  }

  private static Program program(boolean invalid) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.aggregate_instruction_products"));
    sources.put("AggregateInstructionProductsExample.w", """
        module example.aggregate_instruction_products;

        import wheeler.compiler.closure.aggregate_instruction_products;

        classical class AggregateInstructionProductsExample {
          state long instructionCount = 0;
          state long length = 0;

          entry void main(borrow utf8 input, borrow mut bytes output) {
            region rows = new region(/* bytes= */ 196608, /* allocations= */ 1);
            words operations = allocate(rows, /* length= */ 24576);
            set(operations, 0, 0x0500);
            set(operations, 1, 0x0501);
            set(operations, 2, 0x0510);
            set(operations, 3, 0x0511);
            set(operations, 4, 0x0512);
            set(operations, 5, 0x0520);
            set(operations, 6, 0x0521);
            set(operations, 7, 0x0530);
            set(operations, 8, 0x0531);
            set(operations, 4096, 3);
            set(operations, 4097, 6);
            set(operations, 4098, 3);
            set(operations, 4099, 6);
            set(operations, 4100, 6);
            set(operations, 4101, 3);
            set(operations, 4102, 6);
            set(operations, 4103, 3);
            set(operations, 4104, 6);
            set(operations, 8192, 0);
            set(operations, 8193, 5);
            set(operations, 8194, 0);
            set(operations, 8195, 5);
            set(operations, 8196, 5);
            set(operations, 8197, 0);
            set(operations, 8198, 5);
            set(operations, 8199, 0);
            set(operations, 8200, 5);
            set(operations, 12288, 2);
            set(operations, 12289, 0);
            set(operations, 12290, 1);
            set(operations, 12291, 1);
            set(operations, 12292, 1);
            set(operations, 12293, 2);
            set(operations, 12294, 0);
            set(operations, 12295, 5);
            set(operations, 12296, 0);
            set(operations, 16384, 1);
            set(operations, 16386, 2);
            set(operations, 16389, 1);
            set(operations, 16391, 1);
            set(operations, 20482, 1);
            set(operations, 20487, 2);
            if (%s) {
              set(operations, 8, 0x0999);
            }
            AggregateInstructionProductPlan product = writeAggregateInstructionProduct(
              /* operationCount= */ 9,
              operations,
              output
            );
            instructionCount = product.instructionCount;
            length = product.length;
            setOutputLength(output, product.length);
            drop(operations);
            drop(rows);
          }
        }
        """.formatted(invalid));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.aggregate_instruction_products");
  }

  private static List<Integer> opcodes(byte[] code) {
    ByteBuffer input = ByteBuffer.wrap(code).order(ByteOrder.LITTLE_ENDIAN);
    List<Integer> result = new ArrayList<>();
    while (input.hasRemaining()) {
      result.add(Short.toUnsignedInt(input.getShort()));
      int operands = Short.toUnsignedInt(input.getShort());
      int length = input.getInt();
      assertEquals(8 + operands * 8, length);
      input.position(input.position() + operands * 8);
    }
    return List.copyOf(result);
  }
}
