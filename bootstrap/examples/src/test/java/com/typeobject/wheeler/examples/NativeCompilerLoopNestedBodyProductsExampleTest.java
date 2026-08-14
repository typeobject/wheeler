package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for Boolean nested guards over heterogeneous direct products. */
final class NativeCompilerLoopNestedBodyProductsExampleTest {
  private static final String SOURCE = """
      classical class Example {
        public void apply(borrow mut words data, long index, long value, boolean emit) {
          if (emit) {
            emit = false;
            set(data, index, value);
          }
        }

        entry void main() {}
      }
      """.strip();

  @Test
  void matchesBorrowedIndexedBufferCopyByteForByte() throws Exception {
    String source = """
        classical class Example {
          public void apply(
            borrow mut words output,
            borrow mut words input,
            long writeIndex,
            long readIndex,
            boolean emit
          ) {
            if (emit) {
              set(output, writeIndex, input[readIndex]);
            }
          }

          entry void main() {}
        }
        """.strip();
    List<Instruction> expected = new WheelerCompiler().compile(source)
        .functions().getFirst().forward();
    VirtualMachine machine = new VirtualMachine(copyProgram(), new byte[0], 262_144);

    machine.run();

    assertEquals(1, machine.global("valid"));
    int instructionCount = Math.toIntExact(machine.global("instructionCount"));
    assertEquals(9, instructionCount);
    int cursor = 0;
    for (Instruction instruction : expected.subList(0, instructionCount)) {
      assertEquals(instruction.opcode().code(), unsigned(machine.hostOutput(), cursor, 2));
      for (int operand = 0; operand < instruction.operands().size(); operand++) {
        assertEquals(
            instruction.operands().get(operand).longValue(),
            unsigned(machine.hostOutput(), cursor + 8 + operand * 8, 8));
      }
      cursor += instruction.encodedLength();
    }
    assertEquals(cursor, machine.global("length"));
  }

  @Test
  void matchesBooleanAssignmentAndBufferWriteGuardByteForByte() throws Exception {
    List<Instruction> expected = new WheelerCompiler().compile(SOURCE)
        .functions().getFirst().forward();
    VirtualMachine machine = new VirtualMachine(program(), new byte[0], 262_144);

    machine.run();

    assertEquals(1, machine.global("valid"));
    int instructionCount = Math.toIntExact(machine.global("instructionCount"));
    assertEquals(9, instructionCount);
    int expectedLength = expected.subList(0, instructionCount).stream()
        .mapToInt(Instruction::encodedLength)
        .sum();
    assertEquals(expectedLength, machine.global("length"));
    int cursor = 0;
    for (Instruction instruction : expected.subList(0, instructionCount)) {
      assertEquals(instruction.opcode().code(), unsigned(machine.hostOutput(), cursor, 2));
      for (int operand = 0; operand < instruction.operands().size(); operand++) {
        assertEquals(
            instruction.operands().get(operand).longValue(),
            unsigned(machine.hostOutput(), cursor + 8 + operand * 8, 8));
      }
      cursor += instruction.encodedLength();
    }
    assertEquals(expectedLength, cursor);
  }

  private static Program copyProgram() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.loop_nested_block_products"));
    sources.put("LoopNestedCopyProductsExample.w", """
        module example.loop_nested_copy_products;

        import wheeler.compiler.closure.loop_nested_block_products;

        classical class LoopNestedCopyProductsExample {
          state long valid = 0;
          state long instructionCount = 0;
          state long length = 0;

          entry void main(borrow utf8 input, borrow mut bytes output) {
            assert(bufferLength(input) == 0);
            region products = new region(/* bytes= */ 442368, /* allocations= */ 3);
            words statements = allocate(products, /* length= */ 28672);
            words blocks = allocate(products, /* length= */ 6144);
            words bodies = allocate(products, /* length= */ 20480);
            set(statements, 4096, 1);
            set(statements, 20480, 2);
            set(statements, 24576, 1);
            set(statements, 4097, 2);
            set(blocks, 1026, 1);
            set(bodies, 0, 1);
            set(bodies, 4096, 6);
            set(bodies, 8192, 34050);
            set(bodies, 12288, 0);
            set(bodies, 16384, 12885033219);
            LoopNestedBlockPlan plan = writeLoopNestedBlockProducts(
              /* parentStatement= */ 0,
              /* statementCount= */ 2,
              statements,
              /* blockCount= */ 3,
              blocks,
              /* bodyCount= */ 1,
              bodies,
              /* conditionKind= */ 3,
              /* conditionLocal= */ 4,
              /* conditionLiteral= */ 0,
              /* conditionLocalBase= */ 5,
              /* instructionBase= */ 0,
              /* publish= */ true,
              /* outputStart= */ 0,
              output
            );
            if (plan.valid) {
              valid = 1;
            }
            instructionCount = plan.instructionCount;
            length = plan.length;
            setOutputLength(output, plan.length);
            drop(bodies);
            drop(blocks);
            drop(statements);
            drop(products);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.loop_nested_copy_products");
  }

  private static Program program() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.loop_nested_block_products"));
    sources.put("LoopNestedBodyProductsExample.w", """
        module example.loop_nested_body_products;

        import wheeler.compiler.closure.loop_nested_block_products;

        classical class LoopNestedBodyProductsExample {
          state long valid = 0;
          state long instructionCount = 0;
          state long length = 0;

          entry void main(borrow utf8 input, borrow mut bytes output) {
            assert(bufferLength(input) == 0);
            region products = new region(/* bytes= */ 442368, /* allocations= */ 3);
            words statements = allocate(products, /* length= */ 28672);
            words blocks = allocate(products, /* length= */ 6144);
            words bodies = allocate(products, /* length= */ 20480);
            set(statements, 4096, 1);
            set(statements, 20480, 2);
            set(statements, 24576, 1);
            set(statements, 4097, 2);
            set(statements, 4098, 2);
            set(blocks, 1026, 1);
            set(bodies, 0, 1);
            set(bodies, 4096, 5);
            set(bodies, 8192, 33539);
            set(bodies, 12288, 0);
            set(bodies, 16384, 0);
            set(bodies, 1, 2);
            set(bodies, 4097, 6);
            set(bodies, 8193, 34049);
            set(bodies, 12289, 0);
            set(bodies, 16385, 16777474);
            LoopNestedBlockPlan plan = writeLoopNestedBlockProducts(
              /* parentStatement= */ 0,
              /* statementCount= */ 3,
              statements,
              /* blockCount= */ 3,
              blocks,
              /* bodyCount= */ 2,
              bodies,
              /* conditionKind= */ 3,
              /* conditionLocal= */ 3,
              /* conditionLiteral= */ 0,
              /* conditionLocalBase= */ 4,
              /* instructionBase= */ 0,
              /* publish= */ true,
              /* outputStart= */ 0,
              output
            );
            if (plan.valid) {
              valid = 1;
            }
            instructionCount = plan.instructionCount;
            length = plan.length;
            setOutputLength(output, plan.length);
            drop(bodies);
            drop(blocks);
            drop(statements);
            drop(products);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.loop_nested_body_products");
  }

  private static long unsigned(byte[] bytes, int offset, int width) {
    long value = 0;
    for (int index = width - 1; index >= 0; index--) {
      value = (value << 8) | Byte.toUnsignedInt(bytes[offset + index]);
    }
    return value;
  }
}
