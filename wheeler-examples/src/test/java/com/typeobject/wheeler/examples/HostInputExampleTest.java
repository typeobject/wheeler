package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;

class HostInputExampleTest {
  @Test
  void explicitStrictUtf8InputExecutesAndRewindsWithoutAmbientState() throws Exception {
    var program = new WheelerCompiler().compile(
        Path.of("src/main/wheeler/HostInput.w"));
    assertThrows(VmTrap.class, () -> new VirtualMachine(program));
    VirtualMachine machine = new VirtualMachine(
        program, "A¢".getBytes(StandardCharsets.UTF_8));
    var initial = machine.snapshot();

    machine.run();

    assertEquals(MachineStatus.HALTED, machine.status());
    assertEquals(3, machine.global("byteLength"));
    assertEquals(2, machine.global("scalarCount"));
    assertEquals(65, machine.global("firstScalar"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }
}
