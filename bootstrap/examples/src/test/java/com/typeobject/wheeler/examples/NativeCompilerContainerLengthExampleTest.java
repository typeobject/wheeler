package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.MachineSnapshot;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.util.LinkedHashMap;
import org.junit.jupiter.api.Test;

/** Measures container limits without claiming a maximum-size semantic artifact. */
final class NativeCompilerContainerLengthExampleTest {
  @Test
  void measuresTheLastAlignedByteWithoutAllocatingOrChangingAnyInput() throws Exception {
    for (int lastLength : new int[] {1_048_191, 1_048_192}) {
      VirtualMachine machine = machine(lastLength);
      MachineSnapshot initial = machine.snapshot();
      prepare(machine);
      MachineSnapshot prepared = machine.snapshot();
      while (machine.global("published") == 0) {
        machine.step();
      }
      assertEquals(16_777_216, machine.global("length"));
      assertInputs(prepared, machine.snapshot());
      machine.run();
      rewind(machine, initial);
    }
  }

  @Test
  void rejectsTheFirstExcessByteBeforeAllocationOrMutation() throws Exception {
    VirtualMachine machine = machine(1_048_193);
    MachineSnapshot initial = machine.snapshot();
    prepare(machine);
    MachineSnapshot prepared = machine.snapshot();
    assertThrows(VmTrap.class, machine::run);
    assertEquals(-1, machine.global("length"));
    assertEquals(0, machine.global("published"));
    assertInputs(prepared, machine.snapshot());
    rewind(machine, initial);
  }

  private static void prepare(VirtualMachine machine) {
    while (machine.global("prepared") == 0) {
      machine.step();
    }
  }

  private static void assertInputs(MachineSnapshot before, MachineSnapshot after) {
    assertEquals(before.regions(), after.regions());
    assertEquals(before.buffers(), after.buffers());
  }

  private static void rewind(VirtualMachine machine, MachineSnapshot initial) {
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }

  private static VirtualMachine machine(int lastLength) throws Exception {
    var sources = new LinkedHashMap<String, String>();
    CoreSources.addBinaryClosure(sources);
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.closure.linked_container"));
    sources.put("ContainerLength.w", """
        module example.container_length;

        import wheeler.compiler.closure.linked_container;

        classical class ContainerLength {
          state long prepared = 0;
          state long published = 0;
          state long length = -1;

          entry void main() {
            region directory = new region(/* bytes= */ 2098688, /* allocations= */ 4);
            bytes archive = allocateBytes(directory, 2097152);
            words types = allocate(directory, 64);
            words starts = allocate(directory, 64);
            words lengths = allocate(directory, 64);
            long section = 0;
            while (section < 8) limit 8 {
              set(types, section, section + 1);
              set(lengths, section, 2097152);
              section += 1;
            }
            set(lengths, 0, 24);
            set(types, 8, 10);
            set(types, 9, 13);
            set(lengths, 8, 1048576);
            set(lengths, 9, %d);
            set(types, 63, 17);
            set(starts, 63, 19);
            set(lengths, 63, 23);
            prepared = 1;
            length = canonicalContainerLength(archive, 2097152, 10, types, starts, lengths);
            published = 1;
            drop(lengths);
            drop(starts);
            drop(types);
            drop(archive);
            drop(directory);
          }
        }
        """.formatted(lastLength));
    return new VirtualMachine(new WheelerCompiler().compileModuleFiles(
        sources, "example.container_length"));
  }
}
