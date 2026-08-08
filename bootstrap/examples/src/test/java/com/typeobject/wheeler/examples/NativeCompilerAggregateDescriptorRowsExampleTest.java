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

/** Native evidence for identity-based final aggregate descriptor assignment. */
final class NativeCompilerAggregateDescriptorRowsExampleTest {
  @Test
  void assignsPerKindIdsAndResolvesImportedProducts() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false));

    machine.run();

    assertEquals(0, machine.global("firstRecord"));
    assertEquals(1, machine.global("secondRecord"));
    assertEquals(2, machine.global("thirdRecord"));
    assertEquals(0, machine.global("firstVariant"));
    assertEquals(1, machine.global("importedRecord"));
    assertEquals(0, machine.global("importedVariant"));
    assertEquals(1, machine.global("published"));
  }

  @Test
  void rejectsDuplicateOwnerKindAndSourceIdsBeforePublication() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true));

    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
  }

  private static Program program(boolean duplicate) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.aggregate_descriptor_rows"));
    sources.put("AggregateDescriptorRowsExample.w", """
        module example.aggregate_descriptor_rows;

        import wheeler.compiler.closure.aggregate_descriptor_rows;

        classical class AggregateDescriptorRowsExample {
          state long firstRecord = -1;
          state long secondRecord = -1;
          state long thirdRecord = -1;
          state long firstVariant = -1;
          state long importedRecord = -1;
          state long importedVariant = -1;
          state long published = 0;

          entry void main() {
            region rows = new region(/* bytes= */ 610304, /* allocations= */ 9);
            words aggregates = allocate(rows, /* length= */ 36864);
            words modulePublished = allocate(rows, /* length= */ 512);
            bytes moduleIdentities = allocateBytes(rows, /* length= */ 16384);
            words finalDescriptors = allocate(rows, /* length= */ 4096);
            words descriptorPublished = allocate(rows, /* length= */ 4096);
            bytes relocationIdentities = allocateBytes(rows, /* length= */ 131072);
            words relocationKinds = allocate(rows, /* length= */ 4096);
            words relocationTypeIds = allocate(rows, /* length= */ 4096);
            words targets = allocate(rows, /* length= */ 4096);
            set(aggregates, 0, 1);
            set(aggregates, 4096, 1);
            set(aggregates, 8192, 0);
            set(aggregates, 1, 1);
            set(aggregates, 4097, 2);
            set(aggregates, 8193, 0);
            set(aggregates, 2, 4);
            set(aggregates, 4098, 1);
            set(aggregates, 8194, 0);
            set(aggregates, 3, 1);
            set(aggregates, 4099, 1);
            set(aggregates, 8195, THIRD_TYPE_ID);
            set(aggregates, 4, 4);
            set(aggregates, 4100, 2);
            set(aggregates, 8196, 2);
            set(modulePublished, 1, 1);
            set(modulePublished, 2, 1);
            long identityByte = 0;
            while (identityByte < 32) limit 32 {
              setByte(moduleIdentities, 32 + identityByte, 1);
              setByte(moduleIdentities, 64 + identityByte, 2);
              setByte(relocationIdentities, identityByte, 2);
              setByte(relocationIdentities, 32 + identityByte, 1);
              identityByte += 1;
            }
            assignFinalAggregateDescriptorRows(
              /* aggregateCount= */ 5,
              aggregates,
              modulePublished,
              moduleIdentities,
              finalDescriptors,
              descriptorPublished
            );
            set(relocationKinds, 0, 1);
            set(relocationTypeIds, 0, 0);
            set(relocationKinds, 1, 4);
            set(relocationTypeIds, 1, 0);
            resolveAggregateIdentityDescriptorTargets(
              /* relocationCount= */ 2,
              relocationIdentities,
              relocationKinds,
              relocationTypeIds,
              /* aggregateCount= */ 5,
              aggregates,
              moduleIdentities,
              finalDescriptors,
              targets
            );
            firstRecord = finalDescriptors[0];
            secondRecord = finalDescriptors[1];
            firstVariant = finalDescriptors[2];
            thirdRecord = finalDescriptors[3];
            importedRecord = targets[0];
            importedVariant = targets[1];
            published = 1;
            drop(targets);
            drop(relocationTypeIds);
            drop(relocationKinds);
            drop(relocationIdentities);
            drop(descriptorPublished);
            drop(finalDescriptors);
            drop(moduleIdentities);
            drop(modulePublished);
            drop(aggregates);
            drop(rows);
          }
        }
        """.replace("THIRD_TYPE_ID", duplicate ? "0" : "1"));
    return new WheelerCompiler().compileModuleFiles(sources, "example.aggregate_descriptor_rows");
  }
}
