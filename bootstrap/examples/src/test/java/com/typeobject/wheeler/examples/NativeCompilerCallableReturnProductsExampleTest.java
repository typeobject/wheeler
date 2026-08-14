package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for planned implicit void return coordinates. */
final class NativeCompilerCallableReturnProductsExampleTest {
  @Test
  void plansReturnsIndependentlyOfProductStorageOrder() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false), new byte[0]);

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(1, machine.global("returnCount"));
    assertEquals(1, machine.global("required"));
    assertEquals(8, machine.global("instructionStart"));
    assertEquals(64, machine.global("codeStart"));
    assertEquals(-1, machine.global("valueStart"));
  }

  @Test
  void rejectsDetachedDirectProductsAtomically() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true), new byte[0]);

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(0, machine.global("returnCount"));
    assertEquals(71, machine.global("required"));
    assertEquals(72, machine.global("instructionStart"));
    assertEquals(73, machine.global("codeStart"));
  }

  private static Program program(boolean malformed) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.callable_return_products"));
    sources.put("CallableReturnProductsExample.w", """
        module example.callable_return_products;

        import wheeler.compiler.closure.callable_return_products;

        classical class CallableReturnProductsExample {
          state long valid = 0;
          state long returnCount = 0;
          state long required = 0;
          state long instructionStart = 0;
          state long codeStart = 0;
          state long valueStart = 0;

          entry void main(borrow utf8 input) {
            assert(bufferLength(input) == 0);
            region products = new region(/* bytes= */ 487936, /* allocations= */ 6);
            words resultTypes = allocate(products, /* length= */ 64);
            words statements = allocate(products, /* length= */ 28672);
            words directs = allocate(products, /* length= */ 28672);
            words loops = allocate(products, /* length= */ 2304);
            words windows = allocate(products, /* length= */ 768);
            words returns = allocate(products, /* length= */ 192);
            set(resultTypes, 0, 0);
            set(resultTypes, 1, 3);
            set(statements, 0, 1);
            set(statements, 1, 0);
            set(directs, 0, MALFORMED_STATEMENT);
            set(directs, 8192, 2);
            set(directs, 16384, 16);
            set(directs, 1, 1);
            set(directs, 8193, 3);
            set(directs, 16385, 24);
            set(loops, 0, 0);
            set(loops, 2048, 2);
            set(loops, 1, 1);
            set(loops, 2049, 1);
            set(loops, 2, 0);
            set(loops, 2050, 1);
            set(windows, 256, 99);
            set(windows, 512, 792);
            set(windows, 257, 7);
            set(windows, 513, 56);
            set(windows, 258, 5);
            set(windows, 514, 40);
            set(returns, 0, 71);
            set(returns, 64, 72);
            set(returns, 128, 73);
            CallableReturnPlan plan = materializeCallableReturnProducts(
              /* callableCount= */ 2,
              resultTypes,
              /* statementCount= */ 2,
              statements,
              /* directCount= */ 2,
              directs,
              /* loopCount= */ 3,
              loops,
              windows,
              returns
            );
            if (plan.valid) {
              valid = 1;
            }
            returnCount = plan.returnCount;
            required = returns[0];
            instructionStart = returns[64];
            codeStart = returns[128];
            valueStart = returns[65];
            drop(returns);
            drop(windows);
            drop(loops);
            drop(directs);
            drop(statements);
            drop(resultTypes);
            drop(products);
          }
        }
        """.replace("MALFORMED_STATEMENT", malformed ? "2" : "0"));
    return new WheelerCompiler().compileModuleFiles(sources, "example.callable_return_products");
  }
}
