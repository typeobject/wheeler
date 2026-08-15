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

/** Native evidence for identity-based final function assignment. */
final class NativeCompilerCallableFunctionRowsExampleTest {
  @Test
  void mapsCallablesAndImportsByStableIdentity() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false, false));

    machine.run();

    assertEquals(1, machine.global("firstCallableFunction"));
    assertEquals(0, machine.global("secondCallableFunction"));
    assertEquals(1, machine.global("importedFunction"));
    assertEquals(1, machine.global("published"));
  }

  @Test
  void rejectsDuplicateFunctionIdentitiesBeforePublication() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true, false));

    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
  }

  @Test
  void rejectsAStalePackageBoundIdentityBeforePublication() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false, true));

    assertThrows(VmTrap.class, machine::run);
    assertEquals(-1, machine.global("importedFunction"));
    assertEquals(0, machine.global("published"));
  }

  private static Program program(boolean duplicate, boolean stale) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.callable_function_rows"));
    sources.put("CallableFunctionRowsExample.w", """
        module example.callable_function_rows;

        import wheeler.compiler.closure.callable_function_rows;

        classical class CallableFunctionRowsExample {
          state long firstCallableFunction = -1;
          state long secondCallableFunction = -1;
          state long importedFunction = -1;
          state long published = 0;

          entry void main() {
            region rows = new region(/* bytes= */ 991232, /* allocations= */ 8);
            bytes callableIdentities = allocateBytes(rows, /* length= */ 131072);
            bytes functionIdentities = allocateBytes(rows, /* length= */ 131072);
            bytes importedIdentities = allocateBytes(rows, /* length= */ 8192);
            words hashSlots = allocate(rows, /* length= */ 8192);
            words hashFunctions = allocate(rows, /* length= */ 8192);
            words callableFunctions = allocate(rows, /* length= */ 4096);
            words publishedRows = allocate(rows, /* length= */ 4096);
            words importedTargets = allocate(rows, /* length= */ 65536);
            long identityByte = 0;
            while (identityByte < 32) limit 32 {
              setByte(callableIdentities, identityByte, 2);
              setByte(callableIdentities, 32 + identityByte, 1);
              setByte(functionIdentities, identityByte, 1);
              setByte(functionIdentities, 32 + identityByte, SECOND_IDENTITY);
              setByte(importedIdentities, identityByte, IMPORTED_IDENTITY);
              identityByte += 1;
            }
            mapCallableFunctionRows(
              /* callableCount= */ 2,
              callableIdentities,
              /* functionCount= */ 2,
              functionIdentities,
              hashSlots,
              hashFunctions,
              callableFunctions,
              publishedRows
            );
            resolveImportedIdentityFunctionTargets(
              /* relocationCount= */ 1,
              importedIdentities,
              /* functionCount= */ 2,
              functionIdentities,
              hashSlots,
              hashFunctions,
              importedTargets
            );
            firstCallableFunction = callableFunctions[0];
            secondCallableFunction = callableFunctions[1];
            importedFunction = importedTargets[0];
            published = 1;
            drop(importedTargets);
            drop(publishedRows);
            drop(callableFunctions);
            drop(hashFunctions);
            drop(hashSlots);
            drop(importedIdentities);
            drop(functionIdentities);
            drop(callableIdentities);
            drop(rows);
          }
        }
        """.replace("SECOND_IDENTITY", duplicate ? "1" : "2")
            .replace("IMPORTED_IDENTITY", stale ? "3" : "2"));
    return new WheelerCompiler().compileModuleFiles(sources, "example.callable_function_rows");
  }
}
