package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for source-ordered callable coordinate products. */
final class NativeCompilerCallableCoordinateProductsExampleTest {
  @Test
  void plansSequentialRootsAndANestedFirstLoopIndependentOfStorageOrder() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false, false));

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(10, machine.global("productCount"));
    assertEquals(30, machine.global("localTypeCount"));
    assertEquals(31, machine.global("instructionCount"));
    assertEquals(736, machine.global("codeLength"));
    assertEquals(30, machine.global("localCount"));
    assertEquals(2, machine.global("outerLocal"));
    assertEquals(10, machine.global("nestedLocal"));
    assertEquals(20, machine.global("secondLocal"));
    assertEquals(26, machine.global("assertionLocal"));
    assertEquals(29, machine.global("returnLocal"));
    assertEquals(19, machine.global("secondInstruction"));
    assertEquals(456, machine.global("secondCode"));
  }

  @Test
  void logicalGapPublishesNoCoordinateOrCallableRows() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true, false));

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(0, machine.global("productCount"));
    assertEquals(91, machine.global("localCount"));
    assertEquals(92, machine.global("outerLocal"));
  }

  @Test
  void overlappingRootProductsPublishNothing() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false, true));

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(0, machine.global("productCount"));
    assertEquals(91, machine.global("localCount"));
    assertEquals(92, machine.global("outerLocal"));
  }

  private static Program program(boolean logicalGap, boolean overlappingRoot) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.callable_coordinate_products"));
    sources.put("CallableCoordinateProductsExample.w", """
        module example.callable_coordinate_products;

        import wheeler.compiler.closure.callable_coordinate_products;

        classical class CallableCoordinateProductsExample {
          state long valid = 0;
          state long productCount = 0;
          state long localTypeCount = 0;
          state long instructionCount = 0;
          state long codeLength = 0;
          state long localCount = 0;
          state long outerLocal = 0;
          state long nestedLocal = 0;
          state long secondLocal = 0;
          state long assertionLocal = 0;
          state long returnLocal = 0;
          state long secondInstruction = 0;
          state long secondCode = 0;

          private void putProduct(
            borrow mut words rows,
            long product,
            long start,
            long end,
            long parent,
            long logicalStart,
            long logicalWidth,
            long physicalWidth,
            long instructions,
            long bytes,
            long kind
          ) {
            set(rows, product, 0);
            set(rows, 4096 + product, start);
            set(rows, 8192 + product, end);
            set(rows, 12288 + product, parent);
            set(rows, 16384 + product, logicalStart);
            set(rows, 20480 + product, logicalWidth);
            set(rows, 24576 + product, physicalWidth);
            set(rows, 28672 + product, instructions);
            set(rows, 32768 + product, bytes);
            set(rows, 36864 + product, kind);
          }

          entry void main() {
            region products = new region(/* bytes= */ 625664, /* allocations= */ 4);
            words signatures = allocate(products, /* length= */ 64);
            words rows = allocate(products, /* length= */ 40960);
            words callables = allocate(products, /* length= */ 320);
            words coordinates = allocate(products, /* length= */ 36864);
            set(signatures, 0, 2);
            putProduct(rows, 0, 550, 570, 6, 13, 1, 1, 1, 24, 2);
            putProduct(rows, 1, 100, 400, -1, 2, 1, 5, 5, 120, 1);
            putProduct(rows, 2, 650, 670, -1, 17, 1, 1, 2, 40, 8);
            putProduct(rows, 3, 250, 270, 7, 7, 2, 2, 2, 48, 2);
            putProduct(
              rows,
              4,
              BETWEEN_SOURCE,
              470,
              -1,
              BETWEEN_LOGICAL,
              2,
              2,
              2,
              48,
              2
            );
            putProduct(rows, 5, 600, 620, -1, 14, 3, 3, 4, 96, 2);
            putProduct(rows, 6, 500, 590, -1, 12, 1, 5, 5, 120, 1);
            putProduct(rows, 7, 200, 300, 1, 6, 1, 5, 5, 120, 1);
            putProduct(rows, 8, 150, 180, 1, 3, 3, 3, 4, 96, 2);
            putProduct(rows, 9, 350, 370, 1, 9, 1, 1, 1, 24, 2);
            set(callables, 0, 91);
            set(coordinates, 1, 92);
            CallableCoordinatePlan plan = materializeCallableCoordinateProducts(
              /* callableCount= */ 1,
              signatures,
              /* productCount= */ 10,
              rows,
              callables,
              coordinates
            );
            if (plan.valid) {
              valid = 1;
            }
            productCount = plan.productCount;
            localTypeCount = plan.localTypeCount;
            instructionCount = plan.instructionCount;
            codeLength = plan.codeLength;
            localCount = callables[0];
            outerLocal = coordinates[1];
            nestedLocal = coordinates[7];
            secondLocal = coordinates[6];
            assertionLocal = coordinates[5];
            returnLocal = coordinates[2];
            secondInstruction = coordinates[12288 + 6];
            secondCode = coordinates[20480 + 6];
            drop(coordinates);
            drop(callables);
            drop(rows);
            drop(signatures);
            drop(products);
          }
        }
        """
        .replace("BETWEEN_SOURCE", overlappingRoot ? "390" : "450")
        .replace("BETWEEN_LOGICAL", logicalGap ? "11" : "10"));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.callable_coordinate_products");
  }
}
