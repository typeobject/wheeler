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

/** Native evidence for retained source-call relocation linking. */
final class NativeCompilerSourceCallRelocationLinkProductsExampleTest {
  @Test
  void excludesStubInstructionsAndResolvesTheFinalTarget() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false));

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("retainedFunctions"));
    assertEquals(1, machine.global("retainedInstructions"));
    assertEquals(2, machine.global("excludedFunctions"));
    assertEquals(1, machine.global("resolvedTarget"));
    assertEquals(1, machine.global("published"));
  }

  @Test
  void rejectsAMismatchedRelocationOwnerBeforePublication() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true));

    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("published"));
  }

  private static Program program(boolean malformedOwner) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_call_relocation_link_products"));
    sources.put("SourceCallRelocationLinkProductsExample.w", """
        module example.source_call_relocation_link_products;

        import wheeler.compiler.closure.callable_function_rows;
        import wheeler.compiler.closure.source_call_relocation_link_products;
        import wheeler.compiler.opcodes;

        classical class SourceCallRelocationLinkProductsExample {
          state long retainedFunctions = 0;
          state long retainedInstructions = 0;
          state long excludedFunctions = 0;
          state long resolvedTarget = -1;
          state long published = 0;

          entry void main() {
            region products = new region(/* bytes= */ 1728512, /* allocations= */ 11);
            words instructionRows = allocate(products, /* length= */ 24576);
            words relocationRows = allocate(products, /* length= */ 768);
            words relocationOwners = allocate(products, /* length= */ 256);
            bytes relocationIdentities = allocateBytes(products, /* length= */ 8192);
            bytes callableIdentities = allocateBytes(products, /* length= */ 131072);
            bytes functionIdentities = allocateBytes(products, /* length= */ 131072);
            words hashSlots = allocate(products, /* length= */ 8192);
            words hashFunctions = allocate(products, /* length= */ 8192);
            words callableFunctions = allocate(products, /* length= */ 4096);
            words publishedFunctions = allocate(products, /* length= */ 4096);
            words resolvedTargets = allocate(products, /* length= */ 131072);
            set(instructionRows, 0, 0);
            set(instructionRows, 1, 1);
            set(instructionRows, 2, 2);
            set(instructionRows, 12288, OPCODE_CALL_VALUE);
            set(relocationOwners, 0, RELOCATION_OWNER);
            setByte(relocationIdentities, 0, 42);
            setByte(callableIdentities, 0, 9);
            setByte(callableIdentities, 32, 42);
            setByte(functionIdentities, 0, 9);
            setByte(functionIdentities, 32, 42);
            mapCallableFunctionRows(
              /* callableCount= */ 2,
              callableIdentities,
              /* functionCount= */ 2,
              functionIdentities,
              hashSlots,
              hashFunctions,
              callableFunctions,
              publishedFunctions
            );
            SourceCallRelocationLinkPlan plan = materializeSourceCallRelocationLinkProducts(
              /* localFunctionCount= */ 1,
              /* compiledFunctionCount= */ 3,
              /* compiledInstructionCount= */ 3,
              instructionRows,
              /* relocationCount= */ 1,
              relocationRows,
              relocationOwners,
              relocationIdentities,
              /* finalFunctionCount= */ 2,
              functionIdentities,
              hashSlots,
              hashFunctions,
              resolvedTargets
            );
            retainedFunctions = plan.functionCount;
            retainedInstructions = plan.instructionCount;
            excludedFunctions = plan.excludedFunctionCount;
            resolvedTarget = resolvedTargets[0];
            published = 1;
            drop(resolvedTargets);
            drop(publishedFunctions);
            drop(callableFunctions);
            drop(hashFunctions);
            drop(hashSlots);
            drop(functionIdentities);
            drop(callableIdentities);
            drop(relocationIdentities);
            drop(relocationOwners);
            drop(relocationRows);
            drop(instructionRows);
            drop(products);
          }
        }
        """.replace("RELOCATION_OWNER", malformedOwner ? "1" : "0"));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.source_call_relocation_link_products");
  }
}
