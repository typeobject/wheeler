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

/** Native evidence for atomic canonical container publication. */
final class NativeCompilerAtomicLinkedContainerExampleTest {
  @Test
  void publishesOneVerifiedContainerAndIdentity() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false));

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(304, machine.global("length"));
    assertEquals(6, machine.global("sections"));
    assertEquals(87, machine.global("magic"));
    assertEquals(1, machine.global("published"));
  }

  @Test
  void rejectsMalformedSectionsBeforePublication() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true));

    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("published"));
  }

  private static Program program(boolean malformed) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.atomic_linked_container"));
    CoreSources.addBinaryClosure(sources);
    sources.put("FixedBinary.w", CoreSources.read("encoding/FixedBinary.w"));
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.put("AtomicLinkedContainerExample.w", """
        module example.atomic_linked_container;

        import wheeler.compiler.closure.atomic_linked_container;

        classical class AtomicLinkedContainerExample {
          state long length = 0;
          state long sections = 0;
          state long magic = 0;
          state long published = 0;

          entry void main() {
            region inputs = new region(/* bytes= */ 1592, /* allocations= */ 4);
            bytes sectionBytes = allocateBytes(inputs, /* length= */ 56);
            words sectionTypes = allocate(inputs, /* length= */ 64);
            words sectionStarts = allocate(inputs, /* length= */ 64);
            words sectionLengths = allocate(inputs, /* length= */ 64);
            long section = 0;
            while (section < 6) limit 6 {
              set(sectionTypes, section, section + 1);
              setByte(sectionBytes, section, section + 1);
              section += 1;
            }
            set(sectionTypes, 1, SECOND_TYPE);
            set(sectionStarts, 1, 24);
            set(sectionStarts, 2, 28);
            set(sectionStarts, 3, 44);
            set(sectionStarts, 4, 48);
            set(sectionStarts, 5, 52);
            set(sectionLengths, 0, 24);
            set(sectionLengths, 1, 4);
            set(sectionLengths, 2, 16);
            set(sectionLengths, 3, 4);
            set(sectionLengths, 4, 4);
            set(sectionLengths, 5, 4);
            region outputs = new region(/* bytes= */ 544, /* allocations= */ 2);
            bytes container = allocateBytes(outputs, /* length= */ 512);
            bytes identity = allocateBytes(outputs, /* length= */ 32);
            AtomicLinkedContainerPlan plan = publishAtomicLinkedContainer(
              sectionBytes,
              /* sectionBytes= */ 56,
              /* sectionCount= */ 6,
              sectionTypes,
              sectionStarts,
              sectionLengths,
              container,
              identity
            );
            length = plan.length;
            sections = plan.sectionCount;
            magic = container[0];
            published = 1;
            drop(identity);
            drop(container);
            drop(outputs);
            drop(sectionLengths);
            drop(sectionStarts);
            drop(sectionTypes);
            drop(sectionBytes);
            drop(inputs);
          }
        }
        """.replace("SECOND_TYPE", malformed ? "1" : "2"));
    return new WheelerCompiler().compileModuleFiles(sources, "example.atomic_linked_container");
  }
}
