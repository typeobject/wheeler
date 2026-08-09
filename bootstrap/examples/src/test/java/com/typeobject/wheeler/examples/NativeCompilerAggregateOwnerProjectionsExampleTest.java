package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for instruction-local aggregate owner projections. */
final class NativeCompilerAggregateOwnerProjectionsExampleTest {
  @Test
  void projectsCreateMoveLoanReleaseAndDropEvents() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false));

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("projectionValid"));
    assertEquals(5, machine.global("eventCount"));
    assertEquals(3, machine.global("firstAggregate"));
    assertEquals(5, machine.global("firstMember"));
    assertEquals(3, machine.global("lastAggregate"));
    assertEquals(5, machine.global("lastMember"));
  }

  @Test
  void leavesProjectionRowsUntouchedWhenMoveTypesDisagree() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true));

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(0, machine.global("projectionValid"));
    assertEquals(91, machine.global("firstAggregate"));
    assertEquals(73, machine.global("firstMember"));
  }

  private static Program program(boolean mismatchedMove) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.aggregate_owner_projections"));
    sources.put("AggregateOwnerProjectionsExample.w", """
        module example.aggregate_owner_projections;

        import wheeler.compiler.closure.aggregate_owner_projections;

        classical class AggregateOwnerProjectionsExample {
          state long projectionValid = 0;
          state long eventCount = 0;
          state long firstAggregate = 0;
          state long firstMember = 0;
          state long lastAggregate = 0;
          state long lastMember = 0;

          entry void main() {
            region rows = new region(/* bytes= */ 983040, /* allocations= */ 3);
            words events = allocate(rows, /* length= */ 40960);
            words projections = allocate(rows, /* length= */ 65536);
            words projected = allocate(rows, /* length= */ 16384);
            set(events, 0, 5);
            set(events, 1, 1);
            set(events, 2, 2);
            set(events, 3, 3);
            set(events, 4, 4);
            set(events, 24576, 1);
            set(events, 24577, 2);
            set(events, 24578, 3);
            set(events, 24579, 3);
            set(events, 24580, -1);
            set(events, 32768, -1);
            set(events, 32769, 1);
            set(events, 32770, 2);
            set(events, 32771, 2);
            set(events, 32772, 2);
            set(projections, 0, 0);
            set(projections, 1, 0);
            set(projections, 16384, 1);
            set(projections, 16385, 2);
            set(projections, 32768, 3);
            set(projections, 32769, %d);
            set(projections, 49152, 5);
            set(projections, 49153, 5);
            set(projected, 0, 91);
            set(projected, 8192, 73);
            AggregateOwnerProjectionPlan plan = projectInstructionOwnerEvents(
              /* eventCount= */ 5,
              events,
              /* projectionCount= */ 2,
              projections,
              projected
            );
            if (plan.valid) {
              projectionValid = 1;
            }
            eventCount = plan.eventCount;
            firstAggregate = projected[0];
            firstMember = projected[8192];
            lastAggregate = projected[4];
            lastMember = projected[8196];
            drop(projected);
            drop(projections);
            drop(events);
            drop(rows);
          }
        }
        """.formatted(mismatchedMove ? 4 : 3));
    return new WheelerCompiler().compileModuleFiles(sources, "example.aggregate_owner_projections");
  }
}
