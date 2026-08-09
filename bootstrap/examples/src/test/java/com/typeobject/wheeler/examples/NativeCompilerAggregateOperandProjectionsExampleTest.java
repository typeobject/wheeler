package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for temporary aggregate operand projections. */
final class NativeCompilerAggregateOperandProjectionsExampleTest {
  @Test
  void projectsImportedAggregateConstructionOperands() throws Exception {
    VirtualMachine machine = machine(false);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("projectionValid"));
    assertEquals(1, machine.global("relocationCount"));
    assertEquals(33, machine.global("targetAggregate"));
    assertEquals(1, machine.global("targetKind"));
    assertEquals(9, machine.global("identityPrefix"));
  }

  @Test
  void rejectsDuplicateOperandProjectionsBeforePublication() throws Exception {
    VirtualMachine machine = machine(true);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(0, machine.global("projectionValid"));
    assertEquals(91, machine.global("targetAggregate"));
    assertEquals(73, machine.global("identityPrefix"));
  }

  private static VirtualMachine machine(boolean duplicate) throws Exception {
    byte[] artifact = ByteBuffer.allocate(24).order(ByteOrder.LITTLE_ENDIAN)
        .putLong(16, 7).array();
    return VirtualMachine.withBinaryInput(program(duplicate), artifact);
  }

  private static Program program(boolean duplicate) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.aggregate_operand_projections"));
    sources.put("AggregateOperandProjectionsExample.w", """
        module example.aggregate_operand_projections;

        import wheeler.compiler.closure.aggregate_operand_projections;

        classical class AggregateOperandProjectionsExample {
          state long projectionValid = 0;
          state long relocationCount = 0;
          state long targetAggregate = 0;
          state long targetKind = 0;
          state long identityPrefix = 0;

          entry void main(borrow byteview input) {
            region rows = new region(/* bytes= */ 1474560, /* allocations= */ 5);
            words instructions = allocate(rows, /* length= */ 24576);
            words projections = allocate(rows, /* length= */ 65536);
            bytes projectionIdentities = allocateBytes(rows, /* length= */ 524288);
            words relocations = allocate(rows, /* length= */ 12288);
            bytes relocationIdentities = allocateBytes(rows, /* length= */ 131072);
            set(instructions, 8192, 0);
            set(instructions, 12288, 1280);
            set(projections, 0, 2);
            set(projections, 16384, 1);
            set(projections, 32768, 7);
            set(projections, 49152, 33);
            setByte(projectionIdentities, 0, 9);
            set(projections, 1, 2);
            set(projections, 16385, 1);
            set(projections, 32769, 7);
            set(projections, 49153, 34);
            setByte(projectionIdentities, 32, 8);
            set(relocations, 4096, 91);
            setByte(relocationIdentities, 0, 73);
            AggregateOperandProjectionPlan plan = projectAggregateOperandRelocations(
              input,
              /* moduleOwner= */ 2,
              /* instructionCount= */ 1,
              instructions,
              /* projectionCount= */ %d,
              projections,
              projectionIdentities,
              relocations,
              relocationIdentities
            );
            if (plan.valid) {
              projectionValid = 1;
            }
            relocationCount = plan.relocationCount;
            targetAggregate = relocations[4096];
            targetKind = relocations[8192];
            identityPrefix = relocationIdentities[0];
            drop(relocationIdentities);
            drop(relocations);
            drop(projectionIdentities);
            drop(projections);
            drop(instructions);
            drop(rows);
          }
        }
        """.formatted(duplicate ? 2 : 1));
    return new WheelerCompiler().compileModuleFiles(sources, "example.aggregate_operand_projections");
  }
}
