package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for header-ranked public callable dependency products. */
final class NativeCompilerCallableDependencyProductsExampleTest {
  @Test
  void packsOnlyAvailablePublicLocalAndLockedExternalCallables() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false));

    machine.run();

    assertEquals(3, machine.global("productCount"));
    assertEquals(0, machine.global("firstRank"));
    assertEquals(0, machine.global("firstTarget"));
    assertEquals(0, machine.global("secondRank"));
    assertEquals(2, machine.global("secondTarget"));
    assertEquals(1, machine.global("thirdRank"));
    assertEquals(-1, machine.global("thirdTarget"));
    assertEquals(1, machine.global("published"));
  }

  @Test
  void rejectsAnUnpublishedExternalCallableTable() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true));

    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
  }

  private static Program program(boolean missingExternal) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.callable_dependency_products"));
    sources.put("CallableDependencyProductsExample.w", """
        module example.callable_dependency_products;

        import wheeler.compiler.closure.callable_dependency_products;

        classical class CallableDependencyProductsExample {
          state long productCount = 0;
          state long firstRank = -1;
          state long firstTarget = -2;
          state long secondRank = -1;
          state long secondTarget = -2;
          state long thirdRank = -1;
          state long thirdTarget = -2;
          state long published = 0;

          entry void main() {
            region rows = new region(/* bytes= */ 238592, /* allocations= */ 14);
            words firstImports = allocate(rows, /* length= */ 512);
            words directImportCounts = allocate(rows, /* length= */ 512);
            words edgeTargets = allocate(rows, /* length= */ 3072);
            words moduleFirstCallables = allocate(rows, /* length= */ 512);
            words moduleCallableCounts = allocate(rows, /* length= */ 512);
            words localVisibilities = allocate(rows, /* length= */ 4096);
            words localAvailableCallables = allocate(rows, /* length= */ 4096);
            words externalFirstCallables = allocate(rows, /* length= */ 64);
            words externalCallableCounts = allocate(rows, /* length= */ 64);
            words externalVisibilities = allocate(rows, /* length= */ 4096);
            words externalAvailableCallables = allocate(rows, /* length= */ 4096);
            words dependencyRows = allocate(rows, /* length= */ 8192);
            set(firstImports, 0, 0);
            set(directImportCounts, 0, 2);
            set(edgeTargets, 0, 1);
            set(edgeTargets, 1, -1);
            set(moduleFirstCallables, 1, 0);
            set(moduleCallableCounts, 1, 3);
            set(localVisibilities, 0, 1);
            set(localVisibilities, 1, 1);
            set(localVisibilities, 2, 1);
            set(localAvailableCallables, 0, 1);
            set(localAvailableCallables, 2, 1);
            set(externalFirstCallables, 0, 0);
            set(externalCallableCounts, 0, 2);
            set(externalVisibilities, 0, 1);
            set(externalVisibilities, 1, 0);
            set(externalAvailableCallables, 0, 1);
            productCount = packCallableDependencyProducts(
              /* moduleCount= */ 3,
              /* externalCount= */ EXTERNAL_COUNT,
              /* module= */ 0,
              firstImports,
              directImportCounts,
              edgeTargets,
              moduleFirstCallables,
              moduleCallableCounts,
              localVisibilities,
              localAvailableCallables,
              externalFirstCallables,
              externalCallableCounts,
              externalVisibilities,
              externalAvailableCallables,
              dependencyRows
            );
            firstRank = dependencyRows[0];
            firstTarget = dependencyRows[4096];
            secondRank = dependencyRows[1];
            secondTarget = dependencyRows[4097];
            thirdRank = dependencyRows[2];
            thirdTarget = dependencyRows[4098];
            published = 1;
            drop(dependencyRows);
            drop(externalAvailableCallables);
            drop(externalVisibilities);
            drop(externalCallableCounts);
            drop(externalFirstCallables);
            drop(localAvailableCallables);
            drop(localVisibilities);
            drop(moduleCallableCounts);
            drop(moduleFirstCallables);
            drop(edgeTargets);
            drop(directImportCounts);
            drop(firstImports);
            drop(rows);
          }
        }
        """.replace("EXTERNAL_COUNT", missingExternal ? "0" : "1"));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.callable_dependency_products");
  }
}
