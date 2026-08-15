package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for generated inverse relocation coordinates. */
final class NativeCompilerGeneratedInverseRelocationsExampleTest {
  @Test
  void ordersInverseCallsAndRetainsSharedTargetIdentities() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false));

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("published"));
    assertEquals(0, machine.global("firstInstruction"));
    assertEquals(3, machine.global("secondInstruction"));
    assertEquals(9, machine.global("firstTarget"));
    assertEquals(9, machine.global("secondTarget"));
    assertEquals(1, machine.global("firstIdentity"));
    assertEquals(2, machine.global("secondIdentity"));
  }

  @Test
  void rejectsDuplicateForwardCoordinatesAtomically() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true));

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(0, machine.global("published"));
    assertEquals(77, machine.global("firstInstruction"));
    assertEquals(88, machine.global("firstOwner"));
    assertEquals(99, machine.global("firstIdentity"));
  }

  private static Program program(boolean malformed) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.generated_inverse_relocations"));
    sources.put("GeneratedInverseRelocationsExample.w", """
        module example.generated_inverse_relocations;

        import wheeler.compiler.closure.generated_inverse_relocations;

        classical class GeneratedInverseRelocationsExample {
          state long published = 0;
          state long firstInstruction = 0;
          state long secondInstruction = 0;
          state long firstTarget = 0;
          state long secondTarget = 0;
          state long firstOwner = 0;
          state long firstIdentity = 0;
          state long secondIdentity = 0;

          entry void main() {
            region inputs = new region(/* bytes= */ 18944, /* allocations= */ 4);
            words callableRows = allocate(inputs, /* length= */ 320);
            words relocationRows = allocate(inputs, /* length= */ 768);
            words relocationOwners = allocate(inputs, /* length= */ 256);
            bytes relocationIdentities = allocateBytes(inputs, /* length= */ 8192);
            set(callableRows, 64, 6);
            set(relocationRows, 0, 4);
            set(relocationRows, 1, SECOND_FORWARD_INSTRUCTION);
            set(relocationRows, 256, 9);
            set(relocationRows, 257, 9);
            setByte(relocationIdentities, 0, 1);
            setByte(relocationIdentities, 32, 2);
            region outputs = new region(/* bytes= */ 16384, /* allocations= */ 3);
            words inverseRows = allocate(outputs, /* length= */ 768);
            words inverseOwners = allocate(outputs, /* length= */ 256);
            bytes inverseIdentities = allocateBytes(outputs, /* length= */ 8192);
            set(inverseRows, 0, 77);
            set(inverseOwners, 0, 88);
            setByte(inverseIdentities, 0, 99);
            GeneratedInverseRelocationPlan plan = materializeGeneratedInverseRelocations(
              /* callableCount= */ 1,
              callableRows,
              /* relocationCount= */ 2,
              relocationRows,
              relocationOwners,
              relocationIdentities,
              inverseRows,
              inverseOwners,
              inverseIdentities
            );
            if (plan.valid) {
              published = 1;
            }
            firstInstruction = inverseRows[0];
            secondInstruction = inverseRows[1];
            firstTarget = inverseRows[256];
            secondTarget = inverseRows[257];
            firstOwner = inverseOwners[0];
            firstIdentity = inverseIdentities[0];
            secondIdentity = inverseIdentities[32];
            drop(inverseIdentities);
            drop(inverseOwners);
            drop(inverseRows);
            drop(outputs);
            drop(relocationIdentities);
            drop(relocationOwners);
            drop(relocationRows);
            drop(callableRows);
            drop(inputs);
          }
        }
        """.replace("SECOND_FORWARD_INSTRUCTION", malformed ? "4" : "1"));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.generated_inverse_relocations");
  }
}
