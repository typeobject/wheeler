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

/** Native evidence for exact imported callable signatures. */
final class NativeCompilerTypedCallProductsExampleTest {
  private static final byte[] NAMES = "identity identity".getBytes(StandardCharsets.UTF_8);

  @Test
  void resolvesExactParameterLoanResultAndEffectProducts() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false, false, false), NAMES);

    machine.run();

    assertEquals(1, machine.global("target"));
    assertEquals(1, machine.global("rankedTarget"));
    assertEquals(1, machine.global("published"));
  }

  @Test
  void rejectsARequestWithTheWrongLoanMode() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true, false, false), NAMES);

    machine.run();

    assertEquals(-1, machine.global("target"));
    assertEquals(1, machine.global("published"));
  }

  @Test
  void writtenDependencyRankCannotResolveAnotherDependency() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false, false, true), NAMES);

    machine.run();

    assertEquals(1, machine.global("target"));
    assertEquals(-1, machine.global("rankedTarget"));
    assertEquals(1, machine.global("published"));
  }

  @Test
  void equalExactSignaturesRemainAmbiguous() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false, true, false), NAMES);

    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
  }

  private static Program program(boolean wrongLoan, boolean ambiguous, boolean wrongRank)
      throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_call_products"));
    sources.put("TypedCallProductsExample.w", """
        module example.typed_call_products;

        import wheeler.compiler.closure.source_call_products;

        classical class TypedCallProductsExample {
          state long target = -2;
          state long rankedTarget = -2;
          state long published = 0;

          entry void main(borrow utf8 names) {
            region rows = new region(/* bytes= */ 492584, /* allocations= */ 4);
            words request = allocate(rows, /* length= */ 133);
            words callables = allocate(rows, /* length= */ 24576);
            words parameters = allocate(rows, /* length= */ 32768);
            words dependencyRanks = allocate(rows, /* length= */ 4096);
            set(request, 0, 0);
            set(request, 1, 8);
            set(request, 2, 1);
            set(request, 3, 3);
            set(request, 4, 1);
            set(request, 5, 8);
            set(request, 69, REQUEST_LOAN);
            set(callables, 0, 0);
            set(callables, 4096, 8);
            set(callables, 8192, 1);
            set(callables, 12288, 3);
            set(callables, 16384, 1);
            set(callables, 20480, 0);
            set(callables, 1, 9);
            set(callables, 4097, 8);
            set(callables, 8193, 1);
            set(callables, 12289, 3);
            set(callables, 16385, 1);
            set(callables, 20481, 1);
            set(parameters, 0, AMBIGUOUS_TYPE);
            set(parameters, 1, 8);
            set(parameters, 16384, 0);
            set(parameters, 16385, 0);
            set(dependencyRanks, 0, 0);
            set(dependencyRanks, 1, 1);
            target = resolveTypedCallableProduct(names, request, 0, 2, callables, parameters);
            rankedTarget = resolveRankedTypedCallableProduct(
              names,
              request,
              DEPENDENCY_RANK,
              0,
              2,
              callables,
              parameters,
              dependencyRanks
            );
            published = 1;
            drop(dependencyRanks);
            drop(parameters);
            drop(callables);
            drop(request);
            drop(rows);
          }
        }
        """.replace("REQUEST_LOAN", wrongLoan ? "1" : "0")
            .replace("AMBIGUOUS_TYPE", ambiguous ? "8" : "7")
            .replace("DEPENDENCY_RANK", wrongRank ? "0" : "1"));
    return new WheelerCompiler().compileModuleFiles(sources, "example.typed_call_products");
  }
}
