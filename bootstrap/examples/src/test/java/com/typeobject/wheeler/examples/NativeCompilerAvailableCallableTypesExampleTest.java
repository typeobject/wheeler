package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for partial primitive callable-type materialization. */
final class NativeCompilerAvailableCallableTypesExampleTest {
  @Test
  void freezesPrimitiveSignaturesBesideNominalSignatures() throws Exception {
    byte[] source = "longPairlongMystery".getBytes(StandardCharsets.US_ASCII);
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(false), source, 1);

    machine.run();

    assertEquals(3, machine.global("callableCount"));
    assertEquals(1, machine.global("validCount"));
    assertEquals(1, machine.global("firstResultType"));
    assertEquals(1, machine.global("firstParameterType"));
    assertEquals(1, machine.global("firstPrimitive"));
    assertEquals(0, machine.global("secondPrimitive"));
    assertEquals(0, machine.global("thirdPrimitive"));
  }

  @Test
  void rejectsInvalidRangesBeforeTypeProductPublication() throws Exception {
    byte[] source = "longPairlongMystery".getBytes(StandardCharsets.US_ASCII);
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(true), source, 1);

    assertThrows(VmTrap.class, machine::run);

    assertEquals(-1, machine.global("firstResultType"));
    assertEquals(0, machine.global("firstPrimitive"));
  }

  private static Program program(boolean invalid) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.callable_type_products"));
    sources.put("AvailableCallableTypesExample.w", """
        module example.available_callable_types;

        import wheeler.compiler.closure.callable_type_products;

        classical class AvailableCallableTypesExample {
          state long callableCount = 0;
          state long validCount = 0;
          state long firstResultType = -1;
          state long firstParameterType = -1;
          state long firstPrimitive = 0;
          state long secondPrimitive = 0;
          state long thirdPrimitive = 0;

          entry void main(borrow byteview source, borrow mut bytes output) {
            region rows = new region(/* bytes= */ 720896, /* allocations= */ 10);
            words resultStarts = allocate(rows, /* length= */ 4096);
            words resultLengths = allocate(rows, /* length= */ 4096);
            words firstParameters = allocate(rows, /* length= */ 4096);
            words parameterCounts = allocate(rows, /* length= */ 4096);
            words parameterStarts = allocate(rows, /* length= */ 16384);
            words parameterLengths = allocate(rows, /* length= */ 16384);
            words parameterModes = allocate(rows, /* length= */ 16384);
            words resultTypes = allocate(rows, /* length= */ 4096);
            words parameterTypes = allocate(rows, /* length= */ 16384);
            words primitiveCallables = allocate(rows, /* length= */ 4096);
            set(resultStarts, 0, 0);
            set(resultLengths, 0, 4);
            set(firstParameters, 0, 0);
            set(parameterCounts, 0, 1);
            set(resultStarts, 1, 4);
            set(resultLengths, 1, 4);
            set(firstParameters, 1, 1);
            set(parameterCounts, 1, 0);
            set(resultStarts, 2, 8);
            set(resultLengths, 2, THIRD_RESULT_LENGTH);
            set(firstParameters, 2, 1);
            set(parameterCounts, 2, 1);
            set(parameterStarts, 0, 8);
            set(parameterLengths, 0, 4);
            set(parameterStarts, 1, 12);
            set(parameterLengths, 1, 7);
            AvailablePrimitiveCallableTypePlan types =
              materializeAvailablePrimitiveCallableTypes(
                source,
                /* callableCount= */ 3,
                /* parameterCount= */ 2,
                resultStarts,
                resultLengths,
                firstParameters,
                parameterCounts,
                parameterStarts,
                parameterLengths,
                parameterModes,
                resultTypes,
                parameterTypes,
                primitiveCallables
              );
            callableCount = types.callableCount;
            validCount = types.validCount;
            firstResultType = resultTypes[0];
            firstParameterType = parameterTypes[0];
            firstPrimitive = primitiveCallables[0];
            secondPrimitive = primitiveCallables[1];
            thirdPrimitive = primitiveCallables[2];
            setOutputLength(output, 0);
            drop(primitiveCallables);
            drop(parameterTypes);
            drop(resultTypes);
            drop(parameterModes);
            drop(parameterLengths);
            drop(parameterStarts);
            drop(parameterCounts);
            drop(firstParameters);
            drop(resultLengths);
            drop(resultStarts);
            drop(rows);
          }
        }
        """.replace("THIRD_RESULT_LENGTH", invalid ? "100" : "4"));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.available_callable_types");
  }
}
