package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;

class CounterExampleTest {
  @Test
  void checkedInCounterCompilesEncodesAndRuns() throws Exception {
    Path source = Path.of("src/main/wheeler/Counter.w");
    byte[] artifact = new WheelerCompiler().compileToBytecode(Files.readString(source));
    VirtualMachine machine = new VirtualMachine(new BytecodeReader().read(artifact));

    machine.run();

    assertEquals(MachineStatus.HALTED, machine.status());
    assertEquals(0, machine.global("count"));
  }
}
