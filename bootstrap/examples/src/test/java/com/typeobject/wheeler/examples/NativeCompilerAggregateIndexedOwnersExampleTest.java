package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for structural array owners produced by field chains. */
final class NativeCompilerAggregateIndexedOwnersExampleTest {
  private static final String SOURCE = "box.values[number]";

  @Test
  void derivesAnIndexedOwnerFromItsExactFieldProducer() throws Exception {
    VirtualMachine machine = new VirtualMachine(
        program(/* structuralKind= */ 2), SOURCE.getBytes(StandardCharsets.US_ASCII));

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(1, machine.global("indexedOwner"));
    assertEquals(-1, machine.global("indexedCase"));
  }

  @Test
  void rejectsANonarrayTargetBeforeOwnerPublication() throws Exception {
    VirtualMachine machine = new VirtualMachine(
        program(/* structuralKind= */ 1), SOURCE.getBytes(StandardCharsets.US_ASCII));

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(-1, machine.global("indexedOwner"));
    assertEquals(-1, machine.global("indexedCase"));
  }

  private static Program program(int structuralKind) throws Exception {
    int memberStart = SOURCE.indexOf("values");
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.aggregate_indexed_owners"));
    sources.put("AggregateIndexedOwnersExample.w", """
        module example.aggregate_indexed_owners;

        import wheeler.compiler.closure.aggregate_indexed_owners;

        classical class AggregateIndexedOwnersExample {
          state long valid = 0;
          state long indexedOwner = 91;
          state long indexedCase = 73;

          entry void main(borrow utf8 source) {
            region rows = new region(/* bytes= */ 124416, /* allocations= */ 11);
            words operations = allocate(rows, /* length= */ 2048);
            words destinations = allocate(rows, /* length= */ 256);
            words owners = allocate(rows, /* length= */ 256);
            words placements = allocate(rows, /* length= */ 768);
            words values = allocate(rows, /* length= */ 7168);
            words valueStructures = allocate(rows, /* length= */ 1024);
            words aggregates = allocate(rows, /* length= */ 832);
            words cases = allocate(rows, /* length= */ 640);
            words members = allocate(rows, /* length= */ 2048);
            words ownerAggregates = allocate(rows, /* length= */ 256);
            words ownerCases = allocate(rows, /* length= */ 256);
            set(operations, 0, 3);
            set(operations, 1, 4);
            set(operations, 768, %d);
            set(operations, 1024, 6);
            set(destinations, 0, 5);
            set(owners, 1, 5);
            set(placements, 0, 0);
            set(placements, 1, 0);
            set(aggregates, 0, 1);
            set(aggregates, 1, %d);
            set(aggregates, 320, 0);
            set(aggregates, 384, 1);
            set(members, 0, 0);
            set(members, 256, -1);
            set(members, 512, %d);
            set(members, 768, 6);
            set(members, 1536, 1);
            set(members, 1792, 1);
            set(ownerAggregates, 0, 0);
            set(ownerAggregates, 1, -1);
            set(ownerCases, 0, -1);
            set(ownerCases, 1, -1);
            AggregateIndexedOwnerPlan plan = deriveAggregateIndexedOwners(
              source,
              /* operationCount= */ 2,
              operations,
              destinations,
              owners,
              placements,
              /* valueCount= */ 0,
              values,
              valueStructures,
              /* aggregateCount= */ 2,
              aggregates,
              /* caseCount= */ 0,
              cases,
              /* memberCount= */ 1,
              members,
              ownerAggregates,
              ownerCases
            );
            if (plan.valid) {
              valid = 1;
            }
            indexedOwner = ownerAggregates[1];
            indexedCase = ownerCases[1];
            drop(ownerCases);
            drop(ownerAggregates);
            drop(members);
            drop(cases);
            drop(aggregates);
            drop(valueStructures);
            drop(values);
            drop(placements);
            drop(owners);
            drop(destinations);
            drop(operations);
            drop(rows);
          }
        }
        """.formatted(memberStart, structuralKind, memberStart));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.aggregate_indexed_owners");
  }
}
