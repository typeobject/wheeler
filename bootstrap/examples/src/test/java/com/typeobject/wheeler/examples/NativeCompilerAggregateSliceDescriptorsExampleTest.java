package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for source-local slice descriptor selection. */
final class NativeCompilerAggregateSliceDescriptorsExampleTest {
  private static final String SOURCE = """
      private void read(long[4] values, long offset, long length) {
        long[] window = slice(values, offset, length);
      }
      """.strip();

  @Test
  void derivesASliceConstructorDescriptorFromItsDestinationType() throws Exception {
    VirtualMachine machine = new VirtualMachine(
        program(/* descriptorKind= */ 3), SOURCE.getBytes(StandardCharsets.US_ASCII));

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(0, machine.global("sliceDescriptor"));
    assertEquals(0, machine.global("valueStructure"));
  }

  @Test
  void rejectsANonsliceDescriptorBeforePublication() throws Exception {
    VirtualMachine machine = new VirtualMachine(
        program(/* descriptorKind= */ 2), SOURCE.getBytes(StandardCharsets.US_ASCII));

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(-1, machine.global("sliceDescriptor"));
    assertEquals(73, machine.global("valueStructure"));
  }

  private static Program program(int descriptorKind) throws Exception {
    int typeStart = SOURCE.indexOf("long[]");
    int nameStart = SOURCE.indexOf("window");
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.aggregate_indexed_owners"));
    sources.put("AggregateSliceDescriptorsExample.w", """
        module example.aggregate_slice_descriptors;

        import wheeler.compiler.closure.aggregate_indexed_owners;

        classical class AggregateSliceDescriptorsExample {
          state long valid = 0;
          state long sliceDescriptor = -1;
          state long valueStructure = 73;

          entry void main(borrow utf8 source) {
            region rows = new region(/* bytes= */ 126464, /* allocations= */ 12);
            words aggregates = allocate(rows, /* length= */ 832);
            words values = allocate(rows, /* length= */ 7168);
            words operations = allocate(rows, /* length= */ 2048);
            words destinations = allocate(rows, /* length= */ 256);
            words owners = allocate(rows, /* length= */ 256);
            words placements = allocate(rows, /* length= */ 768);
            words ownerAggregates = allocate(rows, /* length= */ 256);
            words ownerCases = allocate(rows, /* length= */ 256);
            words sliceDescriptors = allocate(rows, /* length= */ 256);
            words cases = allocate(rows, /* length= */ 640);
            words members = allocate(rows, /* length= */ 2048);
            words valueStructures = allocate(rows, /* length= */ 1024);
            set(aggregates, 0, %d);
            set(aggregates, 64, %d);
            set(aggregates, 128, 6);
            set(values, 0, 0);
            set(values, 1024, %d);
            set(values, 2048, 6);
            set(values, 3072, 3);
            set(operations, 0, 5);
            set(destinations, 0, 3);
            set(placements, 0, 0);
            set(ownerAggregates, 0, -1);
            set(ownerCases, 0, -1);
            set(sliceDescriptors, 0, -1);
            set(valueStructures, 0, 73);
            AggregateIndexedOwnerPlan plan = deriveAggregateIndexedOwners(
              source,
              /* operationCount= */ 1,
              operations,
              destinations,
              owners,
              placements,
              /* valueCount= */ 1,
              values,
              valueStructures,
              /* aggregateCount= */ 1,
              aggregates,
              /* caseCount= */ 0,
              cases,
              /* memberCount= */ 0,
              members,
              ownerAggregates,
              ownerCases,
              sliceDescriptors
            );
            if (plan.valid) {
              valid = 1;
            }
            sliceDescriptor = sliceDescriptors[0];
            valueStructure = valueStructures[0];
            drop(valueStructures);
            drop(members);
            drop(cases);
            drop(sliceDescriptors);
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
        """.formatted(descriptorKind, typeStart, nameStart));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.aggregate_slice_descriptors");
  }
}
