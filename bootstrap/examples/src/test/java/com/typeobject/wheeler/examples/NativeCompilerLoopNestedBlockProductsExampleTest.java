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

/** Native evidence for resolved one-arm blocks inside loop bodies. */
final class NativeCompilerLoopNestedBlockProductsExampleTest {
  private static final String SOURCE = """
      classical class Example {
        entry void main() {
          long cursor = 0;
          while (cursor < 2) limit 2 {
            if (cursor == 0) {
              cursor += 1;
            }
            cursor += 1;
          }
        }
      }
      """.strip();

  @Test
  void matchesTheStageZeroNestedGuardWindowByteForByte() throws Exception {
    List<Instruction> expected = new WheelerCompiler().compile(SOURCE)
        .functions().getFirst().forward().subList(9, 16);
    VirtualMachine machine = new VirtualMachine(
        program(
            false,
            false,
            /* conditionKind= */ 1,
            /* conditionLiteral= */ 0),
        new byte[0],
        262_144);

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(7, machine.global("instructionCount"));
    assertEquals(176, machine.global("length"));
    assertEquals(1, machine.global("childBodyCount"));
    int cursor = 0;
    for (Instruction instruction : expected) {
      assertEquals(instruction.opcode().code(), unsigned(machine.hostOutput(), cursor, 2));
      for (int operand = 0; operand < instruction.operands().size(); operand++) {
        assertEquals(
            instruction.operands().get(operand).longValue(),
            unsigned(machine.hostOutput(), cursor + 8 + operand * 8, 8));
      }
      cursor += instruction.encodedLength();
    }
  }

  @Test
  void matchesTheStageZeroLessThanGuardWindowByteForByte() throws Exception {
    String source = SOURCE.replace("cursor == 0", "cursor < 1");
    List<Instruction> expected = new WheelerCompiler().compile(source)
        .functions().getFirst().forward().subList(9, 16);
    VirtualMachine machine = new VirtualMachine(
        program(
            false,
            false,
            /* conditionKind= */ 2,
            /* conditionLiteral= */ 1),
        new byte[0],
        262_144);

    machine.run();

    assertEquals(1, machine.global("valid"));
    int cursor = 0;
    for (Instruction instruction : expected) {
      assertEquals(instruction.opcode().code(), unsigned(machine.hostOutput(), cursor, 2));
      for (int operand = 0; operand < instruction.operands().size(); operand++) {
        assertEquals(
            instruction.operands().get(operand).longValue(),
            unsigned(machine.hostOutput(), cursor + 8 + operand * 8, 8));
      }
      cursor += instruction.encodedLength();
    }
  }

  @Test
  void rejectsDetachedOrRecursiveChildrenBeforePublishingBytes() throws Exception {
    for (boolean[] relation : List.of(
        new boolean[] {true, false},
        new boolean[] {false, true})) {
      VirtualMachine machine = new VirtualMachine(
          program(
              relation[0],
              relation[1],
              /* conditionKind= */ 1,
              /* conditionLiteral= */ 0),
          new byte[0],
          262_144);

      machine.run();

      assertEquals(0, machine.global("valid"));
      assertEquals(0, machine.global("instructionCount"));
      assertEquals(0, machine.global("childBodyCount"));
      assertEquals(0xff, machine.global("firstOutputByte"));
    }
  }

  private static Program program(
      boolean detached,
      boolean recursive,
      long conditionKind,
      long conditionLiteral) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.loop_nested_block_products"));
    sources.put("LoopNestedBlockProductsExample.w", """
        module example.loop_nested_block_products;

        import wheeler.compiler.closure.loop_nested_block_products;

        classical class LoopNestedBlockProductsExample {
          state long valid = 0;
          state long instructionCount = 0;
          state long length = 0;
          state long childBodyCount = 0;
          state long firstOutputByte = 0;

          entry void main(borrow utf8 input, borrow mut bytes output) {
            assert(bufferLength(input) == 0);
            region products = new region(/* bytes= */ 483328, /* allocations= */ 4);
            words statements = allocate(products, /* length= */ 28672);
            words blocks = allocate(products, /* length= */ 6144);
            words bodies = allocate(products, /* length= */ 20480);
            words unused = allocate(products, /* length= */ 5120);
            set(statements, 4096, 1);
            set(statements, 20480, 2);
            set(statements, 24576, 1);
            set(statements, 4097, 2);
            set(statements, 24577, CHILD_COUNT);
            set(blocks, 1026, PARENT);
            set(bodies, 0, 1);
            set(bodies, 4096, 10);
            set(bodies, 8192, 1025);
            set(bodies, 12288, 0);
            set(bodies, 16384, 1);
            setByte(output, 0, 0xff);
            LoopNestedBlockPlan plan = writeLoopNestedBlockProducts(
              /* parentStatement= */ 0,
              /* statementCount= */ 2,
              statements,
              /* blockCount= */ 3,
              blocks,
              /* bodyCount= */ 1,
              bodies,
              /* conditionKind= */ CONDITION_KIND,
              /* conditionLocal= */ 1,
              /* conditionLiteral= */ CONDITION_LITERAL,
              /* conditionLocalBase= */ 7,
              /* instructionBase= */ 9,
              output
            );
            if (plan.valid) {
              valid = 1;
            }
            instructionCount = plan.instructionCount;
            length = plan.length;
            childBodyCount = plan.childBodyCount;
            firstOutputByte = output[0];
            drop(unused);
            drop(bodies);
            drop(blocks);
            drop(statements);
            drop(products);
          }
        }
        """
        .replace("PARENT", detached ? "0" : "1")
        .replace("CHILD_COUNT", recursive ? "1" : "0")
        .replace("CONDITION_KIND", Long.toString(conditionKind))
        .replace("CONDITION_LITERAL", Long.toString(conditionLiteral)));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.loop_nested_block_products");
  }

  private static long unsigned(byte[] bytes, int offset, int width) {
    long value = 0;
    for (int index = width - 1; index >= 0; index--) {
      value = (value << 8) | Byte.toUnsignedInt(bytes[offset + index]);
    }
    return value;
  }
}
