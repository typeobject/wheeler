package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for borrowed-word loop body products. */
final class NativeCompilerLoopBufferProductsExampleTest {
  private static final String SOURCE = """
      classical class Example {
        entry void main() {
          region arena = new region(/* bytes= */ 8, /* allocations= */ 1);
          words values = allocate(arena, /* length= */ 1);
          long cursor = 0;
          while (cursor < 1) limit 1 {
            long value = values[cursor];
            set(values, cursor, value);
            cursor += 1;
          }
          drop(values);
          drop(arena);
        }
      }
      """.strip();

  @Test
  void matchesStageZeroBufferReadAndWriteRows() throws Exception {
    Program expectedProgram = new WheelerCompiler().compile(SOURCE);
    List<Instruction> expected = expectedProgram.functions().getFirst().forward();
    int firstLoopInstruction = 7;
    int loopInstructionCount = 16;
    int expectedLength = expected.subList(
        firstLoopInstruction, firstLoopInstruction + loopInstructionCount).stream()
        .mapToInt(Instruction::encodedLength)
        .sum();
    VirtualMachine machine = new VirtualMachine(
        program(SOURCE), SOURCE.getBytes(StandardCharsets.UTF_8), 262_144);

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(3, machine.global("bodyCount"));
    assertEquals(34_048, machine.global("firstOpcode"));
    assertEquals(1_030, machine.global("firstOperand"));
    assertEquals(34_049, machine.global("secondOpcode"));
    assertEquals(263_694, machine.global("secondOperand"));
    assertEquals(loopInstructionCount, machine.global("instructionCount"));
    assertEquals(expectedLength, machine.global("length"));
    byte[] actual = machine.hostOutput();
    int cursor = 0;
    for (int offset = 0; offset < loopInstructionCount; offset++) {
      int index = firstLoopInstruction + offset;
      Instruction instruction = expected.get(index);
      long actualOpcode = unsigned(actual, cursor, 2);
      assertEquals(
          instruction.opcode().code(),
          actualOpcode,
          "instruction=" + index + " expected=" + instruction + " cursor=" + cursor);
      boolean exactOperands = offset < 5;
      if (offset == 6) {
        exactOperands = true;
      }
      if (exactOperands) {
        for (int operand = 0; operand < instruction.operands().size(); operand++) {
          assertEquals(
              instruction.operands().get(operand).longValue(),
              unsigned(actual, cursor + 8 + operand * 8, 8),
              "instruction=" + index + " operand=" + operand);
        }
      }
      cursor += instruction.encodedLength();
    }
    assertEquals(1, machine.global("firstBodyType"));
    assertEquals(1, machine.global("fourthBodyType"));
  }

  @Test
  void rejectsMalformedOrMistypedBufferRowsWithoutPublishing() throws Exception {
    for (String source : List.of(
        SOURCE.replace("words values", "long values"),
        SOURCE.replace("values[cursor]", "cursor[cursor]"),
        SOURCE.replace("values[cursor]", "values[values]"),
        SOURCE.replace("set(values, cursor, value)", "set(cursor, cursor, value)"),
        SOURCE.replace("set(values, cursor, value)", "set(values, values, value)"),
        SOURCE.replace("set(values, cursor, value)", "set(values, cursor, values)"))) {
      VirtualMachine machine = new VirtualMachine(
          program(source), source.getBytes(StandardCharsets.UTF_8), 262_144);

      machine.run();

      assertEquals(0, machine.global("valid"), source);
      assertEquals(0, machine.global("bodyCount"), source);
      assertEquals(91, machine.global("firstOpcode"), source);
    }
  }

  private static Program program(String source) throws Exception {
    int bodyStart = source.indexOf("{", source.indexOf("main("));
    int bodyEnd = matchingClose(source, bodyStart) + 1;
    int valuesStart = source.indexOf("values = allocate");
    int cursorStart = source.indexOf("cursor = ");
    int valueStart = source.indexOf("value = ");
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.loop_instruction_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.loop_local_type_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.resolved_loop_body_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_loop_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_statement_products"));
    sources.put("LoopBufferProductsExample.w", """
        module example.loop_buffer_products;

        import wheeler.compiler.closure.loop_instruction_products;
        import wheeler.compiler.closure.loop_local_type_products;
        import wheeler.compiler.closure.resolved_loop_body_products;
        import wheeler.compiler.closure.source_loop_products;
        import wheeler.compiler.closure.source_statement_products;

        classical class LoopBufferProductsExample {
          state long valid = 0;
          state long bodyCount = 0;
          state long firstOpcode = 0;
          state long firstOperand = 0;
          state long secondOpcode = 0;
          state long secondOperand = 0;
          state long instructionCount = 0;
          state long length = 0;
          state long firstBodyType = 0;
          state long fourthBodyType = 0;

          entry void main(borrow utf8 input, borrow mut bytes output) {
            region products = new region(/* bytes= */ 804864, /* allocations= */ 14);
            words bodyStarts = allocate(products, /* length= */ 4096);
            words bodyLengths = allocate(products, /* length= */ 4096);
            words blocks = allocate(products, /* length= */ 6144);
            words statements = allocate(products, /* length= */ 28672);
            words conditions = allocate(products, /* length= */ 1536);
            words loops = allocate(products, /* length= */ 2304);
            words values = allocate(products, /* length= */ 7168);
            words bodyRows = allocate(products, /* length= */ 20480);
            words loopLocalBases = allocate(products, /* length= */ 256);
            words loopInstructionStarts = allocate(products, /* length= */ 256);
            words typeRows = allocate(products, /* length= */ 12288);
            words unused0 = allocate(products, /* length= */ 1);
            words unused1 = allocate(products, /* length= */ 1);
            words unused2 = allocate(products, /* length= */ 1);
            set(bodyStarts, 0, %d);
            set(bodyLengths, 0, %d);
            set(values, 0, 0);
            set(values, 1024, %d);
            set(values, 2048, 6);
            set(values, 3072, 4);
            set(values, 4096, 2);
            set(values, 1, 0);
            set(values, 1025, %d);
            set(values, 2049, 6);
            set(values, 3073, 6);
            set(values, 4097, 3);
            set(values, 2, 0);
            set(values, 1026, %d);
            set(values, 2050, 5);
            set(values, 3074, 14);
            set(values, 4098, 5);
            set(loopLocalBases, 0, 7);
            set(loopInstructionStarts, 0, 6);
            set(bodyRows, 8192, 91);
            SourceBlockProductPlan blockPlan = materializeSourceBlockProducts(
              input, 0, 0, 1, bodyStarts, bodyLengths, blocks
            );
            SourceLoopProductPlan loopPlan = materializeSourceLoopProducts(
              input, blockPlan.blockCount, blocks, statements, conditions, loops
            );
            ResolvedLoopBodyPlan bodyPlan = materializeResolvedLoopBodyProducts(
              input, loopPlan.statementCount, statements, 3, values, bodyRows
            );
            set(conditions, 256, 1);
            set(conditions, 512, 6);
            set(conditions, 768, 0);
            set(conditions, 1024, 1);
            set(loops, 1024, 1);
            long admittedLoopCount = 0;
            if (bodyPlan.valid) {
              admittedLoopCount = loopPlan.loopCount;
            }
            long admittedBodyCount = 0;
            if (bodyPlan.valid) {
              admittedBodyCount = bodyPlan.bodyCount;
            }
            LoopInstructionProductPlan code = writeLoopInstructionProducts(
              admittedLoopCount,
              conditions,
              loops,
              admittedBodyCount,
              bodyRows,
              loopLocalBases,
              loopInstructionStarts,
              output
            );
            LoopLocalTypePlan types = materializeLoopLocalTypeProducts(
              admittedLoopCount,
              loops,
              admittedBodyCount,
              bodyRows,
              loopLocalBases,
              typeRows
            );
            if (blockPlan.valid) {
              if (loopPlan.valid) {
                if (bodyPlan.valid) {
                  if (code.valid) {
                    if (types.valid) {
                      valid = 1;
                    }
                  }
                }
              }
            }
            bodyCount = bodyPlan.bodyCount;
            firstOpcode = bodyRows[8192];
            firstOperand = bodyRows[16384];
            secondOpcode = bodyRows[8193];
            secondOperand = bodyRows[16385];
            instructionCount = code.instructionCount;
            length = code.length;
            firstBodyType = typeRows[8197];
            fourthBodyType = typeRows[8200];
            setOutputLength(output, code.length);
            drop(unused2);
            drop(unused1);
            drop(unused0);
            drop(typeRows);
            drop(loopInstructionStarts);
            drop(loopLocalBases);
            drop(bodyRows);
            drop(values);
            drop(loops);
            drop(conditions);
            drop(statements);
            drop(blocks);
            drop(bodyLengths);
            drop(bodyStarts);
            drop(products);
          }
        }
        """.formatted(
            bodyStart,
            bodyEnd - bodyStart,
            valuesStart,
            cursorStart,
            valueStart));
    return new WheelerCompiler().compileModuleFiles(sources, "example.loop_buffer_products");
  }

  private static long unsigned(byte[] bytes, int start, int width) {
    long value = 0;
    for (int index = width - 1; index >= 0; index--) {
      value = value * 256 + Byte.toUnsignedInt(bytes[start + index]);
    }
    return value;
  }

  private static int matchingClose(String source, int open) {
    int depth = 0;
    for (int cursor = open; cursor < source.length(); cursor++) {
      if (source.charAt(cursor) == '{') {
        depth += 1;
      }
      if (source.charAt(cursor) == '}') {
        depth -= 1;
        if (depth == 0) {
          return cursor;
        }
      }
    }
    throw new IllegalArgumentException("Unbalanced fixture");
  }
}
