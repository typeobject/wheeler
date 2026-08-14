package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for source-ordered callable instruction prefixes. */
final class NativeCompilerCallableInstructionPrefixesExampleTest {
  @Test
  void ignoresLoopStatementAndDirectProductStorageOrder() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false), new byte[0]);

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(2, machine.global("loopCount"));
    assertEquals(5, machine.global("secondRootPrefix"));
    assertEquals(3, machine.global("firstRootPrefix"));
  }

  @Test
  void rejectsDuplicateLoopStatementsAtomically() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true), new byte[0]);

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(0, machine.global("loopCount"));
    assertEquals(77, machine.global("secondRootPrefix"));
    assertEquals(88, machine.global("firstRootPrefix"));
  }

  private static Program program(boolean duplicate) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.callable_instruction_prefixes"));
    sources.put("CallableInstructionPrefixesExample.w", """
        module example.callable_instruction_prefixes;

        import wheeler.compiler.closure.callable_instruction_prefixes;

        classical class CallableInstructionPrefixesExample {
          state long valid = 0;
          state long loopCount = 0;
          state long secondRootPrefix = 0;
          state long firstRootPrefix = 0;

          entry void main(borrow utf8 input) {
            assert(bufferLength(input) == 0);
            region products = new region(/* bytes= */ 483328, /* allocations= */ 4);
            words loops = allocate(products, /* length= */ 2304);
            words statements = allocate(products, /* length= */ 28672);
            words directs = allocate(products, /* length= */ 28672);
            words starts = allocate(products, /* length= */ 256);
            set(loops, 0, 0);
            set(loops, 512, 4);
            set(loops, 1, 0);
            set(loops, 513, 1);
            set(statements, 0, 0);
            set(statements, 8192, 3);
            set(statements, 12288, 300);
            set(statements, 16384, 20);
            set(statements, 1, 0);
            set(statements, 8193, 4);
            set(statements, 12289, 400);
            set(statements, 16385, 100);
            set(statements, 2, 0);
            set(statements, 8194, 0);
            set(statements, 12290, 100);
            set(statements, 16386, 20);
            set(statements, 3, 0);
            set(statements, 8195, 1);
            set(statements, 12291, 200);
            set(statements, 16387, 100);
            set(statements, 4, 0);
            set(statements, 8196, 2);
            set(statements, 12292, 250);
            set(statements, 16388, 20);
            if (DUPLICATE) {
              set(statements, 8192, 4);
            }
            set(directs, 0, 0);
            set(directs, 8192, 2);
            set(directs, 1, 4);
            set(directs, 8193, 4);
            set(directs, 2, 2);
            set(directs, 8194, 3);
            set(starts, 0, 77);
            set(starts, 1, 88);
            CallableInstructionPrefixPlan plan = materializeCallableInstructionPrefixes(
              /* loopCount= */ 2,
              loops,
              /* statementCount= */ 5,
              statements,
              /* directCount= */ 3,
              directs,
              starts
            );
            if (plan.valid) {
              valid = 1;
            }
            loopCount = plan.loopCount;
            secondRootPrefix = starts[0];
            firstRootPrefix = starts[1];
            drop(starts);
            drop(directs);
            drop(statements);
            drop(loops);
            drop(products);
          }
        }
        """.replace("DUPLICATE", duplicate ? "true" : "false"));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.callable_instruction_prefixes");
  }
}
