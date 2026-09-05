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

/** Native evidence for canonical code emitted from loop products. */
final class NativeCompilerLoopInstructionProductsExampleTest {
  private static final String SOURCE = """
      classical class Example {
        entry void main() {
          long cursor = 0;
          while (cursor < 2) limit 2 {
            long delta = 1;
            boolean ready = true;
            ready = false;
            ready = ready;
            ready = true;
            assert(ready);
            assert(cursor < 3);
            assert(cursor == 0);
            cursor = 0;
            cursor = delta;
            if (ready) {
              cursor += delta;
            }
          }
        }
      }
      """.strip();

  @Test
  void matchesTheStageZeroLoopWindowByteForByte() throws Exception {
    assertMatches(SOURCE);
  }

  @Test
  void matchesNestedEqualityGuardsByteForByte() throws Exception {
    assertMatches(SOURCE.replace("if (ready)", "if (cursor == 0)"));
  }

  private static void assertMatches(String source) throws Exception {
    Program expectedProgram = new WheelerCompiler().compile(source);
    List<Instruction> expected = expectedProgram.functions().getFirst().forward();
    int firstLoopInstruction = 2;
    int loopInstructionCount = expected.size() - firstLoopInstruction - 1;
    int expectedLength = expected.subList(firstLoopInstruction, expected.size() - 1).stream()
        .mapToInt(Instruction::encodedLength)
        .sum();
    VirtualMachine machine = new VirtualMachine(
        program(source), source.getBytes(StandardCharsets.UTF_8), 262_144);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("valid"));
    assertEquals(loopInstructionCount, machine.global("instructionCount"));
    assertEquals(expectedLength, machine.global("length"));
    byte[] actual = machine.hostOutput();
    int cursor = 0;
    for (int index = firstLoopInstruction; index < expected.size() - 1; index++) {
      Instruction instruction = expected.get(index);
      assertEquals(instruction.opcode().code(), unsigned(actual, cursor, 2));
      assertEquals(instruction.operands().size(), unsigned(actual, cursor + 2, 2));
      assertEquals(instruction.encodedLength(), unsigned(actual, cursor + 4, 4));
      for (int operand = 0; operand < instruction.operands().size(); operand++) {
        assertEquals(
            instruction.operands().get(operand).longValue(),
            signed(actual, cursor + 8 + operand * 8),
            "instruction=" + index + " operand=" + operand);
      }
      cursor += instruction.encodedLength();
    }
    assertEquals(expectedLength, cursor);
  }

  private static Program program(String source) throws Exception {
    int bodyStart = source.indexOf("{", source.indexOf("main("));
    int bodyEnd = matchingClose(source, bodyStart) + 1;
    int cursorStart = source.indexOf("cursor = 0");
    int deltaStart = source.indexOf("delta = 1");
    int readyStart = source.indexOf("ready = true");
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.loop_instruction_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.resolved_loop_body_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.resolved_loop_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_loop_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_statement_products"));
    sources.put("LoopInstructionProductsExample.w", """
        module example.loop_instruction_products;

        import wheeler.compiler.closure.loop_instruction_products;
        import wheeler.compiler.closure.resolved_loop_body_products;
        import wheeler.compiler.closure.resolved_loop_products;
        import wheeler.compiler.closure.source_loop_products;
        import wheeler.compiler.closure.source_statement_products;

        classical class LoopInstructionProductsExample {
          state long valid = 0;
          state long instructionCount = 0;
          state long length = 0;

          entry void main(borrow utf8 input, borrow mut bytes output) {
            region products = new region(/* bytes= */ 1925143, /* allocations= */ 28);
            words bodyStarts = allocate(products, /* length= */ 4096);
            words bodyLengths = allocate(products, /* length= */ 4096);
            words blocks = allocate(products, /* length= */ 6144);
            words statements = allocate(products, /* length= */ 28672);
            words sourceConditions = allocate(products, /* length= */ 1536);
            words sourceLoops = allocate(products, /* length= */ 2304);
            words values = allocate(products, /* length= */ 7168);
            words bodyRows = allocate(products, /* length= */ 20480);
            words nestedRows = allocate(products, /* length= */ 20480);
            words statementPhysicalWidths = allocate(products, /* length= */ 4096);
            words resolvedConditions = allocate(products, /* length= */ 1536);
            words resolvedLoops = allocate(products, /* length= */ 2304);
            words symbolOwners = allocate(products, /* length= */ 16384);
            words symbolStarts = allocate(products, /* length= */ 16384);
            words symbolLengths = allocate(products, /* length= */ 16384);
            words symbolTypes = allocate(products, /* length= */ 16384);
            words symbolValues = allocate(products, /* length= */ 16384);
            words symbolResolved = allocate(products, /* length= */ 16384);
            words loopLocalBases = allocate(products, /* length= */ 256);
            words loopInstructionStarts = allocate(products, /* length= */ 256);
            words statementPhysicalStarts = allocate(products, /* length= */ 4096);
            words loopWindowRows = allocate(products, /* length= */ 768);
            words callStatements = allocate(products, /* length= */ 256);
            words callWindowRows = allocate(products, /* length= */ 768);
            words callInstructionStarts = allocate(products, /* length= */ 256);
            bytes callCode = allocateBytes(products, /* length= */ 262144);
            words unused4 = allocate(products, /* length= */ 1);
            words unused5 = allocate(products, /* length= */ 1);
            set(bodyStarts, 0, %d);
            set(bodyLengths, 0, %d);
            set(values, 0, 0);
            set(values, 1024, %d);
            set(values, 2048, 6);
            set(values, 3072, 1);
            set(values, 4096, 1);
            set(values, 1, 0);
            set(values, 1025, %d);
            set(values, 2049, 5);
            set(values, 3073, 3);
            set(values, 4097, 3);
            set(values, 2, 0);
            set(values, 1026, %d);
            set(values, 2050, 5);
            set(values, 3074, 5);
            set(values, 4098, 4);
            set(loopLocalBases, 0, 2);
            set(loopInstructionStarts, 0, 2);
            SourceBlockProductPlan blockPlan = materializeSourceBlockProducts(
              input,
              /* archiveSourceStart= */ 0,
              /* firstCallable= */ 0,
              /* callableCount= */ 1,
              bodyStarts,
              bodyLengths,
              blocks
            );
            assert(blockPlan.valid);
            SourceLoopProductPlan loopPlan = materializeSourceLoopProducts(
              input,
              blockPlan.blockCount,
              blocks,
              statements,
              sourceConditions,
              sourceLoops
            );
            assert(loopPlan.valid);
            ResolvedLoopBodyPlan bodyPlan = materializeResolvedLoopBodyProducts(
              input,
              loopPlan.statementCount,
              statements,
              /* valueCount= */ 3,
              values,
              /* callCount= */ 0,
              callStatements,
              bodyRows,
              nestedRows,
              statementPhysicalWidths
            );
            assert(bodyPlan.valid);
            ResolvedLoopProductPlan resolvedPlan = materializeResolvedLoopProducts(
              input,
              /* symbolNames= */ callCode,
              /* moduleOwner= */ 0,
              loopPlan.loopCount,
              sourceConditions,
              sourceLoops,
              /* valueCount= */ 3,
              values,
              /* symbolCount= */ 0,
              symbolOwners,
              symbolStarts,
              symbolLengths,
              symbolTypes,
              symbolValues,
              symbolResolved,
              resolvedConditions,
              resolvedLoops
            );
            assert(resolvedPlan.valid);
            LoopInstructionProductPlan code = writeLoopInstructionProducts(
              false,
              resolvedPlan.loopCount,
              resolvedConditions,
              resolvedLoops,
              loopPlan.statementCount,
              statements,
              blockPlan.blockCount,
              blocks,
              bodyPlan.bodyCount,
              bodyRows,
              /* callCount= */ 0,
              callStatements,
              callWindowRows,
              callInstructionStarts,
              callCode,
              bodyPlan.nestedCount,
              nestedRows,
              loopLocalBases,
              loopInstructionStarts,
              loopWindowRows,
              output
            );
            if (code.valid) {
              valid = 1;
            }
            instructionCount = code.instructionCount;
            length = code.length;
            setOutputLength(output, code.length);
            drop(unused5);
            drop(unused4);
            drop(callCode);
            drop(callInstructionStarts);
            drop(callWindowRows);
            drop(callStatements);
            drop(loopWindowRows);
            drop(statementPhysicalStarts);
            drop(loopInstructionStarts);
            drop(loopLocalBases);
            drop(symbolResolved);
            drop(symbolValues);
            drop(symbolTypes);
            drop(symbolLengths);
            drop(symbolStarts);
            drop(symbolOwners);
            drop(resolvedLoops);
            drop(resolvedConditions);
            drop(statementPhysicalWidths);
            drop(nestedRows);
            drop(bodyRows);
            drop(values);
            drop(sourceLoops);
            drop(sourceConditions);
            drop(statements);
            drop(blocks);
            drop(bodyLengths);
            drop(bodyStarts);
            drop(products);
          }
        }
        """.formatted(bodyStart, bodyEnd - bodyStart, cursorStart, deltaStart, readyStart));
    return new WheelerCompiler().compileModuleFiles(sources, "example.loop_instruction_products");
  }

  private static long unsigned(byte[] bytes, int start, int width) {
    long value = 0;
    for (int index = width - 1; index >= 0; index--) {
      value = value * 256 + Byte.toUnsignedInt(bytes[start + index]);
    }
    return value;
  }

  private static long signed(byte[] bytes, int start) {
    return unsigned(bytes, start, 8);
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
