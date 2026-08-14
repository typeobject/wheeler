package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for source-ordered callable instruction composition. */
final class NativeCompilerCallableInstructionPlansExampleTest {
  @Test
  void composesDirectAndLoopWindowsInCallableSourceOrder() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false));

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(4, machine.global("productCount"));
    assertEquals(21, machine.global("instructionCount"));
    assertEquals(72, machine.global("directLength"));
    assertEquals(448, machine.global("loopLength"));
    assertEquals(0, machine.global("firstInstructionBase"));
    assertEquals(2, machine.global("secondInstructionBase"));
    assertEquals(0, machine.global("thirdInstructionBase"));
    assertEquals(8, machine.global("fourthInstructionBase"));
    assertEquals(2, machine.global("firstCallableCount"));
    assertEquals(2, machine.global("secondCallableCount"));
  }

  @Test
  void rejectsDuplicateWindowsWithoutChangingCallerRows() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true));

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(91, machine.global("firstStatement"));
    assertEquals(92, machine.global("firstInstructionBase"));
  }

  private static Program program(boolean duplicateWindow) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.callable_instruction_plans"));
    sources.put("CallableInstructionPlansExample.w", """
        module example.callable_instruction_plans;

        import wheeler.compiler.closure.callable_instruction_plans;

        classical class CallableInstructionPlansExample {
          state long valid = 0;
          state long productCount = 0;
          state long instructionCount = 0;
          state long directLength = 0;
          state long loopLength = 0;
          state long firstStatement = 0;
          state long firstInstructionBase = 0;
          state long secondInstructionBase = 0;
          state long thirdInstructionBase = 0;
          state long fourthInstructionBase = 0;
          state long firstCallableCount = 0;
          state long secondCallableCount = 0;

          entry void main() {
            region products = new region(/* bytes= */ 660000, /* allocations= */ 4);
            words callablePlans = allocate(products, /* length= */ 256);
            words statements = allocate(products, /* length= */ 28672);
            words windows = allocate(products, /* length= */ 20480);
            words composition = allocate(products, /* length= */ 33024);
            set(callablePlans, 0, 0);
            set(callablePlans, 64, 2);
            set(callablePlans, 128, 0);
            set(callablePlans, 192, 4);
            set(callablePlans, 1, 2);
            set(callablePlans, 65, 1);
            set(callablePlans, 129, 4);
            set(callablePlans, 193, 2);
            set(statements, 0, 0);
            set(statements, 1, 0);
            set(statements, 2, 0);
            set(statements, 3, 0);
            set(statements, 4, 1);
            set(statements, 5, 1);
            set(statements, 4096, 0);
            set(statements, 4097, 0);
            set(statements, 4098, 1);
            set(statements, 4099, 1);
            set(statements, 4100, 2);
            set(statements, 4101, 2);
            set(statements, 8192, 0);
            set(statements, 8193, 1);
            set(statements, 8194, 2);
            set(statements, 8195, 3);
            set(statements, 8196, 0);
            set(statements, 8197, 1);
            set(windows, 0, 0);
            set(windows, 1, 1);
            set(windows, 2, 4);
            set(windows, 3, %d);
            set(windows, 4096, 0);
            set(windows, 4097, 1);
            set(windows, 4098, 1);
            set(windows, 4099, 0);
            set(windows, 8192, 2);
            set(windows, 8193, 10);
            set(windows, 8194, 8);
            set(windows, 8195, 1);
            set(windows, 12288, 0);
            set(windows, 12289, 0);
            set(windows, 12290, 248);
            set(windows, 12291, 48);
            set(windows, 16384, 48);
            set(windows, 16385, 248);
            set(windows, 16386, 200);
            set(windows, 16387, 24);
            set(composition, 4096, 91);
            set(composition, 16384, 92);
            CallableInstructionPlan plan = materializeCallableInstructionPlans(
              /* callableCount= */ 2,
              callablePlans,
              /* statementCount= */ 6,
              statements,
              /* windowCount= */ 4,
              windows,
              composition
            );
            if (plan.valid) {
              valid = 1;
            }
            productCount = plan.productCount;
            instructionCount = plan.instructionCount;
            directLength = plan.directLength;
            loopLength = plan.loopLength;
            firstStatement = composition[4096];
            firstInstructionBase = composition[16384];
            secondInstructionBase = composition[16385];
            thirdInstructionBase = composition[16386];
            fourthInstructionBase = composition[16387];
            firstCallableCount = composition[32832];
            secondCallableCount = composition[32833];
            drop(composition);
            drop(windows);
            drop(statements);
            drop(callablePlans);
            drop(products);
          }
        }
        """.formatted(duplicateWindow ? 4 : 5));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.callable_instruction_plans");
  }
}
