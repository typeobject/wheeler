package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for root source-call instruction products. */
final class NativeCompilerSourceCallInstructionProductsExampleTest {
  @Test
  void plansCallsAcrossDirectAndLoopProductsInSourceOrder() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false), new byte[0]);

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(3, machine.global("instructionCount"));
    assertEquals(80, machine.global("length"));
    assertEquals(9, machine.global("lateInstruction"));
    assertEquals(2, machine.global("earlyInstruction"));
    assertEquals(64, machine.global("lateCodeStart"));
    assertEquals(0, machine.global("earlyCodeStart"));
    assertEquals(16, machine.global("lateLength"));
    assertEquals(64, machine.global("earlyLength"));
  }

  @Test
  void retainsNestedStartsForLoopCoordinatePublication() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true), new byte[0]);

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(7, machine.global("lateInstruction"));
    assertEquals(0, machine.global("earlyInstruction"));
    assertEquals(64, machine.global("lateCodeStart"));
    assertEquals(0, machine.global("earlyCodeStart"));
  }

  private static Program program(boolean nested) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_call_instruction_products"));
    sources.put("SourceCallInstructionProductsExample.w", """
        module example.source_call_instruction_products;

        import wheeler.compiler.closure.source_call_instruction_products;

        classical class SourceCallInstructionProductsExample {
          state long valid = 0;
          state long instructionCount = 0;
          state long length = 0;
          state long lateInstruction = 0;
          state long earlyInstruction = 0;
          state long lateCodeStart = 0;
          state long earlyCodeStart = 0;
          state long lateLength = 0;
          state long earlyLength = 0;

          entry void main(borrow utf8 input) {
            assert(bufferLength(input) == 0);
            region rows = new region(/* bytes= */ 509952, /* allocations= */ 11);
            words calls = allocate(rows, /* length= */ 1024);
            words callStatements = allocate(rows, /* length= */ 256);
            words callArgumentCounts = allocate(rows, /* length= */ 256);
            words statements = allocate(rows, /* length= */ 28672);
            words directs = allocate(rows, /* length= */ 28672);
            words loops = allocate(rows, /* length= */ 2304);
            words loopWindows = allocate(rows, /* length= */ 768);
            words instructionStarts = allocate(rows, /* length= */ 256);
            words callWindows = allocate(rows, /* length= */ 768);
            words unusedA = allocate(rows, /* length= */ 1);
            words unusedB = allocate(rows, /* length= */ 1);
            set(calls, 256, 0);
            set(calls, 257, 1);
            set(callStatements, 0, 3);
            set(callStatements, 1, 2);
            set(statements, 0, 0);
            set(statements, 4096, 0);
            set(statements, 8192, 0);
            set(statements, 12288, 100);
            set(statements, 1, 0);
            set(statements, 4097, 0);
            set(statements, 8193, 1);
            set(statements, 12289, 200);
            set(statements, 2, 0);
            set(statements, 4098, NESTED_BLOCK);
            set(statements, 8194, 2);
            set(statements, 12290, 150);
            set(statements, 3, 0);
            set(statements, 4099, 0);
            set(statements, 8195, 3);
            set(statements, 12291, 300);
            set(directs, 0, 0);
            set(directs, 8192, 2);
            set(loops, 0, 0);
            set(loops, 512, 1);
            set(loops, 2048, 1);
            set(loopWindows, 256, 5);
            set(instructionStarts, 0, 77);
            set(callWindows, 0, 88);
            SourceCallInstructionPlan plan = materializeSourceCallInstructionProducts(
              /* callCount= */ 2,
              calls,
              callStatements,
              callArgumentCounts,
              /* statementCount= */ 4,
              statements,
              /* directCount= */ 1,
              directs,
              /* loopCount= */ 1,
              loops,
              loopWindows,
              instructionStarts,
              callWindows
            );
            if (plan.valid) {
              valid = 1;
            }
            instructionCount = plan.instructionCount;
            length = plan.length;
            lateInstruction = instructionStarts[0];
            earlyInstruction = instructionStarts[1];
            lateCodeStart = callWindows[0];
            earlyCodeStart = callWindows[1];
            lateLength = callWindows[512];
            earlyLength = callWindows[513];
            drop(unusedB);
            drop(unusedA);
            drop(callWindows);
            drop(instructionStarts);
            drop(loopWindows);
            drop(loops);
            drop(directs);
            drop(statements);
            drop(callArgumentCounts);
            drop(callStatements);
            drop(calls);
            drop(rows);
          }
        }
        """.replace("NESTED_BLOCK", nested ? "1" : "0"));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.source_call_instruction_products");
  }
}
