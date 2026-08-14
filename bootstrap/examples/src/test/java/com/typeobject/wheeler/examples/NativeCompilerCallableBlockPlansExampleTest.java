package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for exact callable root-block and direct-statement windows. */
final class NativeCompilerCallableBlockPlansExampleTest {
  @Test
  void joinsEachCallableToOneRootAndContiguousStatementWindow() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false));

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(0, machine.global("firstBlock"));
    assertEquals(2, machine.global("firstBlockCount"));
    assertEquals(0, machine.global("firstStatement"));
    assertEquals(2, machine.global("firstStatementCount"));
    assertEquals(2, machine.global("secondBlock"));
    assertEquals(1, machine.global("secondBlockCount"));
    assertEquals(2, machine.global("secondStatement"));
    assertEquals(1, machine.global("secondStatementCount"));
  }

  @Test
  void rejectsForgedOrdinalsWithoutChangingCallerRows() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true));

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(91, machine.global("firstBlock"));
    assertEquals(92, machine.global("firstStatement"));
  }

  private static Program program(boolean forged) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.callable_block_plans"));
    sources.put("CallableBlockPlansExample.w", """
        module example.callable_block_plans;

        import wheeler.compiler.closure.callable_block_plans;

        classical class CallableBlockPlansExample {
          state long valid = 0;
          state long firstBlock = 0;
          state long firstBlockCount = 0;
          state long firstStatement = 0;
          state long firstStatementCount = 0;
          state long secondBlock = 0;
          state long secondBlockCount = 0;
          state long secondStatement = 0;
          state long secondStatementCount = 0;

          entry void main() {
            region products = new region(/* bytes= */ 250000, /* allocations= */ 3);
            words blocks = allocate(products, /* length= */ 6144);
            words statements = allocate(products, /* length= */ 24576);
            words plans = allocate(products, /* length= */ 256);
            set(blocks, 0, 0);
            set(blocks, 1024, -1);
            set(blocks, 2048, 0);
            set(blocks, 5120, 0);
            set(blocks, 1, 0);
            set(blocks, 1025, 0);
            set(blocks, 2049, 1);
            set(blocks, 5121, 1);
            set(blocks, 2, 1);
            set(blocks, 1026, -1);
            set(blocks, 2050, 0);
            set(blocks, 5122, 0);
            set(statements, 0, 0);
            set(statements, 4096, 0);
            set(statements, 8192, 1);
            set(statements, 12288, 0);
            set(statements, 1, 0);
            set(statements, 4097, 0);
            set(statements, 8193, %d);
            set(statements, 12289, 0);
            set(statements, 2, 1);
            set(statements, 4098, 0);
            set(statements, 8194, 1);
            set(statements, 12290, 0);
            set(plans, 0, 91);
            set(plans, 128, 92);
            CallableBlockPlan plan = materializeCallableBlockPlans(
              /* callableCount= */ 2,
              /* blockCount= */ 3,
              blocks,
              /* statementCount= */ 3,
              statements,
              plans
            );
            if (plan.valid) {
              valid = 1;
            }
            firstBlock = plans[0];
            firstBlockCount = plans[64];
            firstStatement = plans[128];
            firstStatementCount = plans[192];
            secondBlock = plans[1];
            secondBlockCount = plans[65];
            secondStatement = plans[129];
            secondStatementCount = plans[193];
            drop(plans);
            drop(statements);
            drop(blocks);
            drop(products);
          }
        }
        """.formatted(forged ? 7 : 2));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.callable_block_plans");
  }
}
