package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for source-local nominal callable type products. */
final class NativeCompilerSourceCallableTypeProductsExampleTest {
  @Test
  void resolvesPrimitiveRecordAndVariantSignatureTypes() throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        program(/* duplicate= */ false), "PairChoicevoid".getBytes(StandardCharsets.US_ASCII), 1);

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(0x1000_0000L, machine.global("firstResult"));
    assertEquals(0, machine.global("secondResult"));
    assertEquals(0x2000_0000L, machine.global("firstParameter"));
  }

  @Test
  void rejectsDuplicateNominalNamesBeforeTypePublication() throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        program(/* duplicate= */ true), "PairChoicevoid".getBytes(StandardCharsets.US_ASCII), 1);

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(91, machine.global("firstResult"));
    assertEquals(91, machine.global("firstParameter"));
  }

  private static Program program(boolean duplicate) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_callable_type_products"));
    sources.put("SourceCallableTypeProductsExample.w", """
        module example.source_callable_type_products;

        import wheeler.compiler.closure.source_callable_type_products;

        classical class SourceCallableTypeProductsExample {
          state long valid = 0;
          state long firstResult = 0;
          state long secondResult = 0;
          state long firstParameter = 0;

          entry void main(borrow byteview input, borrow mut bytes output) {
            region products = new region(/* bytes= */ 694784, /* allocations= */ 10);
            words aggregates = allocate(products, /* length= */ 832);
            words resultStarts = allocate(products, /* length= */ 4096);
            words resultLengths = allocate(products, /* length= */ 4096);
            words firstParameters = allocate(products, /* length= */ 4096);
            words parameterCounts = allocate(products, /* length= */ 4096);
            words parameterStarts = allocate(products, /* length= */ 16384);
            words parameterLengths = allocate(products, /* length= */ 16384);
            words parameterModes = allocate(products, /* length= */ 16384);
            words resultTypes = allocate(products, /* length= */ 4096);
            words parameterTypes = allocate(products, /* length= */ 16384);
            set(aggregates, 0, 1);
            set(aggregates, 64, 0);
            set(aggregates, 128, 4);
            set(aggregates, 1, %d);
            set(aggregates, 65, %d);
            set(aggregates, 129, %d);
            set(resultStarts, 0, 0);
            set(resultLengths, 0, 4);
            set(resultStarts, 1, 10);
            set(resultLengths, 1, 4);
            set(firstParameters, 0, 0);
            set(parameterCounts, 0, 1);
            set(firstParameters, 1, 1);
            set(parameterCounts, 1, 0);
            set(parameterStarts, 0, 4);
            set(parameterLengths, 0, 6);
            set(resultTypes, 0, 91);
            set(parameterTypes, 0, 91);
            SourceCallableTypeProductPlan plan = materializeSourceCallableTypes(
              input,
              /* aggregateCount= */ %d,
              aggregates,
              /* callableCount= */ 2,
              /* parameterCount= */ 1,
              resultStarts,
              resultLengths,
              firstParameters,
              parameterCounts,
              parameterStarts,
              parameterLengths,
              parameterModes,
              resultTypes,
              parameterTypes
            );
            if (plan.valid) {
              valid = 1;
            }
            firstResult = resultTypes[0];
            secondResult = resultTypes[1];
            firstParameter = parameterTypes[0];
            setOutputLength(output, 0);
            drop(parameterTypes);
            drop(resultTypes);
            drop(parameterModes);
            drop(parameterLengths);
            drop(parameterStarts);
            drop(parameterCounts);
            drop(firstParameters);
            drop(resultLengths);
            drop(resultStarts);
            drop(aggregates);
            drop(products);
          }
        }
        """.formatted(
            duplicate ? 1 : 4,
            duplicate ? 0 : 4,
            duplicate ? 4 : 6,
            2));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.source_callable_type_products");
  }
}
