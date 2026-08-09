package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for final aggregate IDs in linked local-type windows. */
final class NativeCompilerLinkedLocalTypesExampleTest {
  @Test
  void rewritesLocalAndProjectedAggregateIdsByModuleOwner() throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(false), typeBytes(), 1);

    machine.run();

    assertEquals(2, machine.global("typeCount"));
    assertEquals(0x1000_0000L, machine.global("firstType"));
    assertEquals(0x1000_0001L, machine.global("secondType"));
    assertEquals(1, machine.global("published"));
  }

  @Test
  void rewritesOneExactSignedCarrierToItsImportedDescriptor() throws Exception {
    byte[] source = ByteBuffer.allocate(8).order(ByteOrder.LITTLE_ENDIAN)
        .putInt(1).putInt(0x1000_0000).array();
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(false, true), source, 1);

    machine.run();

    assertEquals(2, machine.global("typeCount"));
    assertEquals(0x1000_0001L, machine.global("firstType"));
    assertEquals(0x1000_0001L, machine.global("secondType"));
    assertEquals(1, machine.global("published"));
  }

  @Test
  void rejectsMissingOwnerDescriptorsBeforePublication() throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(true), typeBytes(), 1);

    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
  }

  private static byte[] typeBytes() {
    return ByteBuffer.allocate(8).order(ByteOrder.LITTLE_ENDIAN)
        .putInt(0x1000_0000).putInt(0x1000_0000).array();
  }

  private static Program program(boolean missingOwner) throws Exception {
    return program(missingOwner, false);
  }

  private static Program program(boolean missingOwner, boolean carrier) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.linked_local_types"));
    sources.put("LinkedLocalTypesExample.w", """
        module example.linked_local_types;

        import wheeler.compiler.closure.linked_local_types;

        classical class LinkedLocalTypesExample {
          state long typeCount = 0;
          state long firstType = 0;
          state long secondType = 0;
          state long published = 0;

          entry void main(borrow byteview source, borrow mut bytes output) {
            region rows = new region(/* bytes= */ 10035200, /* allocations= */ 8);
            words artifactStarts = allocate(rows, /* length= */ 512);
            words artifactLengths = allocate(rows, /* length= */ 512);
            words functions = allocate(rows, /* length= */ 49152);
            words aggregates = allocate(rows, /* length= */ 36864);
            words finalDescriptors = allocate(rows, /* length= */ 4096);
            words projections = allocate(rows, /* length= */ 49152);
            words carrierProjections = allocate(rows, /* length= */ 65536);
            words outputTypes = allocate(rows, /* length= */ 1048576);
            set(artifactLengths, 0, bufferLength(source));
            set(functions, 0, 1);
            set(functions, 12288, 0);
            set(functions, 40960, 0);
            set(functions, 45056, 1);
            set(functions, 1, 3);
            set(functions, 12289, 0);
            set(functions, 40961, 4);
            set(functions, 45057, 1);
            set(aggregates, 0, 1);
            set(aggregates, 4096, 1);
            set(aggregates, 8192, 0);
            set(aggregates, 1, 1);
            set(aggregates, 4097, 2);
            set(aggregates, 8193, 0);
            set(finalDescriptors, 0, 0);
            set(finalDescriptors, 1, 1);
            set(projections, 0, 3);
            set(projections, 16384, 268435456);
            set(projections, 32768, 1);
            set(carrierProjections, 0, 1);
            set(carrierProjections, 16384, 0);
            set(carrierProjections, 32768, 0);
            set(carrierProjections, 49152, 1);
            typeCount = emitLinkedLocalTypes(
              source,
              bufferLength(source),
              artifactStarts,
              artifactLengths,
              /* functionCount= */ 2,
              functions,
              /* aggregateCount= */ 2,
              aggregates,
              finalDescriptors,
              /* projectionCount= */ %d,
              projections,
              /* carrierProjectionCount= */ %d,
              carrierProjections,
              outputTypes
            );
            firstType = outputTypes[0];
            secondType = outputTypes[1];
            published = 1;
            setOutputLength(output, 0);
            drop(outputTypes);
            drop(carrierProjections);
            drop(projections);
            drop(finalDescriptors);
            drop(aggregates);
            drop(functions);
            drop(artifactLengths);
            drop(artifactStarts);
            drop(rows);
          }
        }
        """.formatted(missingOwner ? 0 : 1, carrier ? 1 : 0));
    return new WheelerCompiler().compileModuleFiles(sources, "example.linked_local_types");
  }
}
