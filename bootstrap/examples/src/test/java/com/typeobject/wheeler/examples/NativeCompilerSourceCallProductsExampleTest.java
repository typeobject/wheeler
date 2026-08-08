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

/** Native evidence for pre-link source call products. */
final class NativeCompilerSourceCallProductsExampleTest {
  private static final byte[] SOURCE = "identity identity(7)".getBytes(StandardCharsets.UTF_8);

  @Test
  void resolvesOneUnqualifiedImportedNameAndArity() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false, false), SOURCE);

    machine.run();

    assertEquals(1, machine.global("callCount"));
    assertEquals(0, machine.global("firstTarget"));
    assertEquals(1, machine.global("firstArity"));
    assertEquals(1, machine.global("published"));
  }

  @Test
  void localCallableShadowsTheImportedProduct() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true, false), SOURCE);

    machine.run();

    assertEquals(0, machine.global("callCount"));
    assertEquals(1, machine.global("published"));
  }

  @Test
  void equalImportedNamesAndAritiesRemainAmbiguous() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false, true), SOURCE);

    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
  }

  private static Program program(boolean localShadow, boolean ambiguous) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_call_products"));
    sources.put("SourceCallProductsExample.w", """
        module example.source_call_products;

        import wheeler.compiler.closure.source_call_products;

        classical class SourceCallProductsExample {
          state long callCount = 0;
          state long firstTarget = -1;
          state long firstArity = -1;
          state long published = 0;

          entry void main(borrow utf8 source) {
            region rows = new region(/* bytes= */ 106496, /* allocations= */ 4);
            words nameStarts = allocate(rows, /* length= */ 4096);
            words nameLengths = allocate(rows, /* length= */ 4096);
            words parameterCounts = allocate(rows, /* length= */ 4096);
            words calls = allocate(rows, /* length= */ 1024);
            set(nameStarts, 0, 0);
            set(nameLengths, 0, 8);
            set(parameterCounts, 0, 1);
            set(nameStarts, 1, 0);
            set(nameLengths, 1, 8);
            set(parameterCounts, 1, 1);
            callCount = resolveSourceCallProducts(
              source,
              source,
              0,
              LOCAL_COUNT,
              IMPORTED_FIRST,
              IMPORTED_COUNT,
              nameStarts,
              nameLengths,
              parameterCounts,
              calls
            );
            if (0 < callCount) {
              firstTarget = calls[768];
              firstArity = calls[512];
            }
            published = 1;
            drop(calls);
            drop(parameterCounts);
            drop(nameLengths);
            drop(nameStarts);
            drop(rows);
          }
        }
        """.replace("LOCAL_COUNT", localShadow ? "1" : "0")
            .replace("IMPORTED_FIRST", localShadow ? "1" : "0")
            .replace("IMPORTED_COUNT", ambiguous ? "2" : "1"));
    return new WheelerCompiler().compileModuleFiles(sources, "example.source_call_products");
  }
}
