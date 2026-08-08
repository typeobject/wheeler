package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
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

/** Native evidence for canonical linked function-section emission. */
final class NativeCompilerLinkedFunctionSectionExampleTest {
  @Test
  void emitsExactDescriptorAndTypeExtents() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false), null, 4_358_152);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(44, machine.global("sectionBytes"));
    assertEquals(1, machine.global("published"));
    assertArrayEquals(expected(), machine.hostOutput());
  }

  @Test
  void rejectsCodeExtentMismatchBeforePublication() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true), null, 4_358_152);

    assertThrows(
        VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("published"));
  }

  private static byte[] expected() {
    ByteBuffer output = ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN);
    output.putInt(1);
    output.putInt(0);
    output.putInt(0);
    output.putInt(0);
    output.putInt(0);
    output.putInt(8);
    output.putInt(-1);
    output.putInt(0);
    output.putInt(0);
    output.putInt(0);
    output.putInt(0);
    return output.array();
  }

  private static Program program(boolean badCodeExtent) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.linked_function_section"));
    sources.put("LinkedFunctionSectionExample.w", """
        module example.linked_function_section;

        import wheeler.compiler.closure.linked_function_section;

        classical class LinkedFunctionSectionExample {
          state long sectionBytes = 0;
          state long published = 0;

          entry void main(borrow mut bytes output) {
            region rows = new region(/* bytes= */ 8814592, /* allocations= */ 3);
            words functions = allocate(rows, /* length= */ 49152);
            words functionNames = allocate(rows, /* length= */ 4096);
            words linkedTypes = allocate(rows, /* length= */ 1048576);
            set(functions, 20480, 8);
            sectionBytes = emitLinkedFunctionSection(
              /* functionCount= */ 1,
              functions,
              /* stringCount= */ 1,
              functionNames,
              /* linkedTypeCount= */ 0,
              linkedTypes,
              /* linkedCodeBytes= */ LINKED_CODE_BYTES,
              output
            );
            published = 1;
            setOutputLength(output, sectionBytes);
            drop(linkedTypes);
            drop(functionNames);
            drop(functions);
            drop(rows);
          }
        }
        """.replace("LINKED_CODE_BYTES", badCodeExtent ? "7" : "8"));
    return new WheelerCompiler().compileModuleFiles(sources, "example.linked_function_section");
  }
}
