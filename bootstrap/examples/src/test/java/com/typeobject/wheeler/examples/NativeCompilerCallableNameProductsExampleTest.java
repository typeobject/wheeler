package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
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

/** Native evidence for source-independent callable-name products. */
final class NativeCompilerCallableNameProductsExampleTest {
  private static final byte[] NAMES = "alphabeta".getBytes(StandardCharsets.US_ASCII);

  @Test
  void copiesValidatedCallableNamesBeforeSourceRelease() throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(false), NAMES, NAMES.length);

    machine.run();

    assertEquals(NAMES.length, machine.global("nameBytes"));
    assertEquals(0, machine.global("firstStart"));
    assertEquals(5, machine.global("secondStart"));
    assertEquals(1, machine.global("published"));
    assertArrayEquals(NAMES, machine.hostOutput());
  }

  @Test
  void rejectsEveryInvalidRangeBeforeProductMutation() throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(true), NAMES, NAMES.length);

    assertThrows(VmTrap.class, machine::run);

    assertEquals(0, machine.global("published"));
    assertArrayEquals(new byte[NAMES.length], machine.hostOutput());
  }

  private static Program program(boolean invalid) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.module_callables"));
    sources.put("CallableNameProductsExample.w", """
        module example.callable_name_products;

        import wheeler.compiler.closure.module_callables;

        classical class CallableNameProductsExample {
          state long nameBytes = 0;
          state long firstStart = -1;
          state long secondStart = -1;
          state long published = 0;

          entry void main(borrow byteview input, borrow mut bytes output) {
            region rows = new region(/* bytes= */ 1146880, /* allocations= */ 4);
            words sourceStarts = allocate(rows, /* length= */ 4096);
            words lengths = allocate(rows, /* length= */ 4096);
            words productStarts = allocate(rows, /* length= */ 4096);
            bytes productNames = allocateBytes(rows, /* length= */ 1048576);
            set(sourceStarts, 0, 0);
            set(lengths, 0, 5);
            set(sourceStarts, 1, 5);
            set(lengths, 1, SECOND_LENGTH);
            nameBytes = copyCallableNameProducts(
              input,
              /* callableCount= */ 2,
              sourceStarts,
              lengths,
              productStarts,
              productNames
            );
            firstStart = productStarts[0];
            secondStart = productStarts[1];
            long nameByte = 0;
            while (nameByte < nameBytes) limit 1048576 {
              setByte(output, nameByte, productNames[nameByte]);
              nameByte += 1;
            }
            setOutputLength(output, nameBytes);
            published = 1;
            drop(productNames);
            drop(productStarts);
            drop(lengths);
            drop(sourceStarts);
            drop(rows);
          }
        }
        """.replace("SECOND_LENGTH", invalid ? "257" : "4"));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.callable_name_products");
  }
}
