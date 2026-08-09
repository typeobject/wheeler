package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for callable structural aggregate products. */
final class NativeCompilerAggregateStructuralOwnersExampleTest {
  private static final String SOURCE =
      "private long read(long[4] values, long index) { return values[index]; }";

  @Test
  void bindsADirectFixedArrayParameterToItsDescriptor() throws Exception {
    VirtualMachine machine = new VirtualMachine(
        program(/* duplicate= */ false), SOURCE.getBytes(StandardCharsets.US_ASCII));

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(0, machine.global("owner"));
    assertEquals(0, machine.global("valueStructure"));
  }

  @Test
  void rejectsDuplicateStructuralDescriptorsBeforePublication() throws Exception {
    VirtualMachine machine = new VirtualMachine(
        program(/* duplicate= */ true), SOURCE.getBytes(StandardCharsets.US_ASCII));

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(-1, machine.global("owner"));
    assertEquals(73, machine.global("valueStructure"));
  }

  private static Program program(boolean duplicate) throws Exception {
    int typeStart = SOURCE.indexOf("long[4]");
    int valuesStart = SOURCE.indexOf("values");
    int indexStart = SOURCE.indexOf("index");
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.aggregate_indexed_owners"));
    sources.put("AggregateStructuralOwnersExample.w", """
        module example.aggregate_structural_owners;

        import wheeler.compiler.closure.aggregate_indexed_owners;

        classical class AggregateStructuralOwnersExample {
          state long valid = 0;
          state long owner = 91;
          state long valueStructure = 73;

          entry void main(borrow utf8 source) {
            region rows = new region(/* bytes= */ 124416, /* allocations= */ 11);
            words aggregates = allocate(rows, /* length= */ 832);
            words values = allocate(rows, /* length= */ 7168);
            words operations = allocate(rows, /* length= */ 2048);
            words destinations = allocate(rows, /* length= */ 256);
            words owners = allocate(rows, /* length= */ 256);
            words placements = allocate(rows, /* length= */ 768);
            words ownerAggregates = allocate(rows, /* length= */ 256);
            words ownerCases = allocate(rows, /* length= */ 256);
            words cases = allocate(rows, /* length= */ 640);
            words members = allocate(rows, /* length= */ 2048);
            words valueStructures = allocate(rows, /* length= */ 1024);
            set(aggregates, 0, 2);
            set(aggregates, 64, %d);
            set(aggregates, 128, 7);
            set(values, 0, 0);
            set(values, 1, 0);
            set(values, 1024, %d);
            set(values, 1025, %d);
            set(values, 2048, 6);
            set(values, 2049, 5);
            set(values, 3072, 0);
            set(values, 3073, 1);
            set(operations, 0, 4);
            set(owners, 0, 0);
            set(placements, 0, 0);
            set(ownerAggregates, 0, -1);
            set(valueStructures, 0, 73);
            %s
            AggregateIndexedOwnerPlan plan = deriveAggregateIndexedOwners(
              source,
              /* operationCount= */ 1,
              operations,
              destinations,
              owners,
              placements,
              /* valueCount= */ 2,
              values,
              valueStructures,
              /* aggregateCount= */ %d,
              aggregates,
              /* caseCount= */ 0,
              cases,
              /* memberCount= */ 0,
              members,
              ownerAggregates,
              ownerCases
            );
            if (plan.valid) {
              valid = 1;
            }
            owner = ownerAggregates[0];
            valueStructure = valueStructures[0];
            drop(valueStructures);
            drop(members);
            drop(cases);
            drop(ownerCases);
            drop(ownerAggregates);
            drop(placements);
            drop(owners);
            drop(destinations);
            drop(operations);
            drop(values);
            drop(aggregates);
            drop(rows);
          }
        }
        """.formatted(
            typeStart,
            valuesStart,
            indexStart,
            duplicate
                ? "set(aggregates, 1, 2); set(aggregates, 65, " + typeStart
                    + "); set(aggregates, 129, 7);"
                : "",
            duplicate ? 2 : 1));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.aggregate_structural_owners");
  }
}
